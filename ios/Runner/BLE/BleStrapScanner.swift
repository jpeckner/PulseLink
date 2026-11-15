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
    // Flutter calls stream handlers on its platform thread, which on iOS is
    // the main thread, but FlutterStreamHandler has no actor isolation, so
    // Swift can't know that. The guard checks it; assumeIsolated then tells
    // the compiler, and can't fail because the guard has just checked. If
    // Flutter ever broke that contract, the scan wouldn't start and the
    // picker would keep showing that it's looking, with a fault in the log.
    guard isOnMainThread() else {
      return
    }
    // Pigeon's generated PigeonEventSink isn't marked Sendable, so Swift
    // won't hand it to main-actor code, even though it's created and used
    // only on the main thread. `nonisolated(unsafe)` switches off that one
    // check for this one value: safe because everything that uses the sink
    // runs on the main thread, which the guard has just checked.
    nonisolated(unsafe) let mainThreadSink = sink
    let scan = scan
    MainActor.assumeIsolated {
      scan.start(sendingTo: mainThreadSink)
    }
  }

  override func onCancel(withArguments arguments: Any?) {
    // See onListen. If this were ever skipped, the scan would keep running
    // until the next start or stop.
    guard isOnMainThread() else {
      return
    }
    let scan = scan
    MainActor.assumeIsolated {
      scan.stop()
    }
  }
}
