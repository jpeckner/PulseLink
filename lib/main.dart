import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pulselink/app/app_bloc_observer.dart';
import 'package:pulselink/app/composition.dart';
import 'package:pulselink/app/debug/debug_app.dart';
import 'package:pulselink/data/app_settings/platform_app_settings.dart';
import 'package:pulselink/data/ble/ble_strap_scanner.dart';
import 'package:pulselink/data/watch/pigeon_watch_bridge.dart';
import 'package:pulselink/data/watch_bridge.dart';

/// The composition root: gathers what the app needs from the platform, and
/// builds the release app or, in debug and profile builds, the debug one
/// (see lib/app/composition.dart). Dependencies reach the widgets through
/// constructors, so a missing one is a compile error, not a runtime lookup
/// failure.
void main() {
  // Before anything below reaches the platform: WatchSync sends its first
  // snapshot through a platform channel as soon as it starts, before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();

  final platform = AppPlatform(
    strapScanner: BleStrapScanner(),
    appSettings: PlatformAppSettings(),
    watchBridge: _watchBridge(),
  );
  if (kReleaseMode) {
    runApp(releaseApp(platform));
  } else {
    // Debug and profile builds only. kReleaseMode is a compile-time constant,
    // so release builds contain neither this branch nor anything only it
    // uses: no demo data and no debug override.
    runApp(debugApp(platform));
  }
}

/// The platform's watch app, if it has one. `WatchSync` works with any
/// `WatchBridge`, so supporting another wearable means giving its
/// platform's case a bridge here.
WatchBridge? _watchBridge() => switch (defaultTargetPlatform) {
  TargetPlatform.iOS => PigeonWatchBridge(),
  // No watch app to sync with yet. Wear OS would go in the Android case.
  TargetPlatform.android ||
  TargetPlatform.fuchsia ||
  TargetPlatform.linux ||
  TargetPlatform.macOS ||
  TargetPlatform.windows => null,
};
