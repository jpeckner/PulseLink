import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // `nonisolated` because AppDelegate is main-actor isolated (it's a
  // UIApplicationDelegate), but Flutter declares this protocol without any
  // actor isolation, so a main-actor method can't satisfy it. Nothing here
  // touches main-actor state: it only registers with the engine.
  nonisolated func didInitializeImplicitFlutterEngine(
    _ engineBridge: FlutterImplicitEngineBridge
  ) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // The channel keeps the scanner for as long as the engine runs.
    ScanForHeartRateStrapsStreamHandler.register(
      with: engineBridge.applicationRegistrar.messenger(),
      streamHandler: BleStrapScanner()
    )
  }
}
