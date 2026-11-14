import CoreBluetooth

/// Owns the `CBCentralManager` and turns its callbacks into scan events. A
/// separate class because a CoreBluetooth delegate must be an `NSObject`,
/// and the Pigeon stream handler can't be.
///
/// Why `@MainActor`: everything here has to happen on the main thread.
///
/// - Flutter only accepts messages to Dart (`sink.success`) from its
///   platform thread, which on iOS is the main thread.
/// - `central` and `sink` are read and written by two callers: Flutter
///   (starting and stopping the scan) and CoreBluetooth (state changes and
///   discoveries). Doing all of it on one thread is what stops those calls
///   from racing, such as a discovery being sent to a sink that `stop()` is
///   clearing at the same moment.
///
/// Both frameworks already call us on the main thread: Flutter by design,
/// and CoreBluetooth because `start` passes it `queue: nil`. `@MainActor`
/// turns that convention into something the compiler checks: code that
/// could touch this class from another thread doesn't compile.
///
/// Neither framework says so in a way Swift can see, so each of the four
/// entry points (`BleStrapScanner.onListen` and `onCancel`, and the two
/// delegate methods below) first checks `Thread.isMainThread`, then uses
/// `MainActor.assumeIsolated` to tell the compiler. On the main thread
/// `assumeIsolated` can't fail, so it never stops the app. If a framework
/// ever broke its contract, the entry point logs a fault and skips the
/// call: the scan might miss an event, but there's no crash and no data
/// race, and the log says what happened.
@MainActor
final class CentralScan: NSObject {
  private let heartRateService = CBUUID(string: "180D")

  /// Created on the first scan rather than at launch, because creating it
  /// shows the Bluetooth permission prompt.
  private var central: CBCentralManager?

  /// Where events go while Dart is listening; nil otherwise.
  private var sink: PigeonEventSink<BleScanEvent>?

  /// `nonisolated` so `BleStrapScanner`, which has no actor isolation, can
  /// create one. It only sets up the empty properties above, which needs no
  /// particular thread.
  nonisolated override init() {
    super.init()
  }

  func start(sendingTo sink: PigeonEventSink<BleScanEvent>) {
    self.sink = sink
    if let central {
      apply(ScanAction(central.state))
    } else {
      // `queue: nil` makes CoreBluetooth call the delegate methods on the
      // main queue, which the main-actor isolation above relies on. Its
      // first state arrives in centralManagerDidUpdateState.
      central = CBCentralManager(delegate: self, queue: nil)
    }
  }

  func stop() {
    sink = nil
    if let central, central.isScanning {
      central.stopScan()
    }
  }

  /// The name to show for a strap: the one in its advertisement, which is
  /// current, or else the one iOS cached from an earlier connection.
  nonisolated static func strapName(advertised: String?, cached: String?) -> String? {
    advertised ?? cached
  }
}

/// CoreBluetooth reports Bluetooth state changes and discovered straps here.
/// See `CentralScan` for why each method checks the thread first.
extension CentralScan: CBCentralManagerDelegate {
  nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
    // Also called when Bluetooth is turned off or on mid-scan. Turning it
    // off stops the scan, so turning it back on starts it again here.
    // CoreBluetooth calls this on the main queue because `start` passes
    // `queue: nil`, but its delegate protocol has no actor isolation, so
    // Swift can't know that. The guard checks it; see the class comment. If
    // this were ever skipped, the scan would miss one Bluetooth state change.
    guard isOnMainThread() else {
      return
    }
    let action = ScanAction(central.state)
    MainActor.assumeIsolated {
      apply(action)
    }
  }

  nonisolated func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    // See centralManagerDidUpdateState. If this were ever skipped, the
    // picker would miss one strap until CoreBluetooth reports it again.
    guard isOnMainThread() else {
      return
    }
    let found = BleStrapFound(
      id: peripheral.identifier.uuidString,
      name: Self.strapName(
        advertised: advertisementData[CBAdvertisementDataLocalNameKey] as? String,
        cached: peripheral.name
      )
    )
    MainActor.assumeIsolated {
      sink?.success(found)
    }
  }
}

private extension CentralScan {
  /// Acts on a Bluetooth state: starts scanning, or tells Dart why it can't.
  func apply(_ action: ScanAction) {
    guard let sink, let central else {
      // Dart isn't listening, or there's no central manager yet.
      return
    }
    switch action {
    case .scan:
      central.scanForPeripherals(withServices: [heartRateService])
      sink.success(BleScanStarted())
    case .fail(let reason):
      sink.success(BleScanFailed(reason: reason))
    case .wait:
      break
    }
  }
}
