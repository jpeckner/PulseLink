import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// Flutter calls this once it has created the engine, which is when the
/// app's plugins and platform channels can be registered.
extension AppDelegate: FlutterImplicitEngineDelegate {
  // `nonisolated` because AppDelegate is main-actor isolated (it's a
  // UIApplicationDelegate), but Flutter declares this protocol without any
  // actor isolation, so a main-actor method can't satisfy it. Nothing here
  // touches main-actor state: it only registers with the engine.
  nonisolated func didInitializeImplicitFlutterEngine(
    _ engineBridge: FlutterImplicitEngineBridge
  ) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    // The channels keep these for as long as the engine runs.
    ScanForHeartRateStrapsStreamHandler.register(
      with: messenger,
      streamHandler: BleStrapScanner()
    )
    let strapLink = BleStrapLink()
    StrapEventsStreamHandler.register(with: messenger, streamHandler: strapLink)
    BleConnectionApiSetup.setUp(binaryMessenger: messenger, api: strapLink)
  }
}
