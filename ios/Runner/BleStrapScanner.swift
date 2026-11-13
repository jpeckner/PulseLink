import CoreBluetooth
import Flutter

/// Scans for heart-rate straps with CoreBluetooth while Dart listens to
/// `scanForHeartRateStraps` (see pigeons/ble_api.dart), and stops when Dart
/// cancels.
final class BleStrapScanner: ScanForHeartRateStrapsStreamHandler {
  private let scan = CentralScan()

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<BleScanEvent>) {
    scan.start(sendingTo: sink)
  }

  override func onCancel(withArguments arguments: Any?) {
    scan.stop()
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
final class CentralScan: NSObject, CBCentralManagerDelegate {
  private static let heartRateService = CBUUID(string: "180D")

  /// Created on the first scan rather than at launch, because creating it
  /// shows the Bluetooth permission prompt.
  private var central: CBCentralManager?

  /// Where events go while Dart is listening; nil otherwise.
  private var sink: PigeonEventSink<BleScanEvent>?

  func start(sendingTo sink: PigeonEventSink<BleScanEvent>) {
    self.sink = sink
    if let central {
      apply(ScanAction(central.state), to: central)
    } else {
      // Its first state arrives in centralManagerDidUpdateState.
      central = CBCentralManager(delegate: self, queue: nil)
    }
  }

  func stop() {
    sink = nil
    if let central, central.isScanning {
      central.stopScan()
    }
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    // Also called when Bluetooth is turned off or on mid-scan. Turning it
    // off stops the scan, so turning it back on starts it again here.
    apply(ScanAction(central.state), to: central)
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    sink?.success(
      BleStrapFound(
        id: peripheral.identifier.uuidString,
        name: Self.strapName(
          advertised: advertisementData[CBAdvertisementDataLocalNameKey] as? String,
          cached: peripheral.name
        )
      )
    )
  }

  /// The name to show for a strap: the one in its advertisement, which is
  /// current, or else the one iOS cached from an earlier connection.
  static func strapName(advertised: String?, cached: String?) -> String? {
    advertised ?? cached
  }

  private func apply(_ action: ScanAction, to central: CBCentralManager) {
    guard let sink else {
      // Dart isn't listening.
      return
    }
    switch action {
    case .scan:
      central.scanForPeripherals(withServices: [Self.heartRateService])
      sink.success(BleScanStarted())
    case .fail(let reason):
      sink.success(BleScanFailed(reason: reason))
    case .wait:
      break
    }
  }
}
