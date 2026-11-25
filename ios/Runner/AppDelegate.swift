// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

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
    // The app's only error tracker: everything that reports errors gets
    // this one.
    let tracker = OSLogTracker()
    // The channels keep these for as long as the engine runs.
    ScanForHeartRateStrapsStreamHandler.register(
      with: messenger,
      streamHandler: BleStrapScanner(tracker: tracker)
    )
    let strapLink = BleStrapLink(tracker: tracker)
    StrapEventsStreamHandler.register(with: messenger, streamHandler: strapLink)
    BleConnectionApiSetup.setUp(binaryMessenger: messenger, api: strapLink)
    AppSettingsApiSetup.setUp(binaryMessenger: messenger, api: AppSettingsOpener())
    WatchSessionApiSetup.setUp(binaryMessenger: messenger, api: WatchLink(tracker: tracker))
  }
}
