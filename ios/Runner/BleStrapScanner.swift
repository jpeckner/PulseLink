// CoreBluetooth predates Swift concurrency, so its types (such as CBUUID and
// CBPeripheral) aren't marked Sendable. @preconcurrency treats that as
// unknown rather than as an error.
@preconcurrency import CoreBluetooth
import Flutter

/// Scans for heart-rate straps with CoreBluetooth while Dart listens to
/// `scanForHeartRateStraps` (see pigeons/ble_api.dart), and stops when Dart
/// cancels.
///
/// Not itself `@MainActor`: it subclasses Pigeon's generated handler, which
/// has no actor isolation, and a subclass can't change that. It hands each
/// call to `CentralScan`, which is.
final class BleStrapScanner: ScanForHeartRateStrapsStreamHandler {
  private let scan = CentralScan()

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<BleScanEvent>) {
    // Approved exception to the no-assertions rule (see CentralScan).
    // Flutter calls stream handlers on its platform thread, which on iOS is
    // the main thread, but FlutterStreamHandler has no actor isolation, so
    // Swift can't know that. assumeIsolated tells it, and stops the app here
    // if that's ever untrue, rather than letting the scan race.
    //
    // Pigeon's generated PigeonEventSink isn't marked Sendable, so Swift
    // won't hand it to main-actor code, even though it's created and used
    // only on the main thread. `nonisolated(unsafe)` switches off that one
    // check for this one value: safe because everything that uses the sink
    // runs on the main thread, which assumeIsolated has just checked.
    nonisolated(unsafe) let mainThreadSink = sink
    let scan = scan
    MainActor.assumeIsolated {
      scan.start(sendingTo: mainThreadSink)
    }
  }

  override func onCancel(withArguments arguments: Any?) {
    // Approved exception to the no-assertions rule; see onListen.
    let scan = scan
    MainActor.assumeIsolated {
      scan.stop()
    }
  }
}

/// What a scan does in each Bluetooth state.
enum ScanAction: Equatable {
  /// Bluetooth is ready: scan.
  case scan
  /// Bluetooth can't be used, for this reason.
  case fail(BleScanFailureReason)
  /// Bluetooth is about to change state; the change will say what to do.
  case wait

  init(_ state: CBManagerState) {
    switch state {
    case .poweredOn:
      self = .scan
    case .poweredOff:
      self = .fail(.poweredOff)
    case .unauthorized:
      self = .fail(.unauthorized)
    case .unsupported:
      self = .fail(.unsupported)
    case .unknown, .resetting:
      self = .wait
    @unknown default:
      // Swift requires this for an enum Apple may add cases to. A state
      // added in a later iOS can't be acted on, so wait for the next one.
      self = .wait
    }
  }
}

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
/// Neither framework says so in a way Swift can see, so the four entry
/// points (`BleStrapScanner.onListen` and `onCancel`, and the two delegate
/// methods below) use `MainActor.assumeIsolated`. That checks at runtime and
/// stops the app if the main-thread contract is ever broken: a crash that
/// points at the cause, instead of a silent data race. These are the
/// approved exceptions to the no-assertions rule in CLAUDE.md.
@MainActor
final class CentralScan: NSObject, CBCentralManagerDelegate {
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

  nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
    // Also called when Bluetooth is turned off or on mid-scan. Turning it
    // off stops the scan, so turning it back on starts it again here.
    let action = ScanAction(central.state)
    // Approved exception to the no-assertions rule (see the class comment).
    // CoreBluetooth calls this on the main queue because `start` passes
    // `queue: nil`, but its delegate protocol has no actor isolation, so
    // Swift can't know that.
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
    let found = BleStrapFound(
      id: peripheral.identifier.uuidString,
      name: Self.strapName(
        advertised: advertisementData[CBAdvertisementDataLocalNameKey] as? String,
        cached: peripheral.name
      )
    )
    // Approved exception to the no-assertions rule; see
    // centralManagerDidUpdateState.
    MainActor.assumeIsolated {
      sink?.success(found)
    }
  }

  /// The name to show for a strap: the one in its advertisement, which is
  /// current, or else the one iOS cached from an earlier connection.
  nonisolated static func strapName(advertised: String?, cached: String?) -> String? {
    advertised ?? cached
  }

  private func apply(_ action: ScanAction) {
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
