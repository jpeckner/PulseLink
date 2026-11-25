// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:pulselink/app/app.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/strap_selection.dart';
import 'package:pulselink/blocs/strap_battery/strap_battery_cubit.dart';
import 'package:pulselink/blocs/watch_sync/watch_sync.dart';
import 'package:pulselink/data/app_settings.dart';
import 'package:pulselink/data/strap_data_source.dart';
import 'package:pulselink/data/strap_scanner.dart';
import 'package:pulselink/data/switchable_strap_data_source.dart';
import 'package:pulselink/data/tracker_service.dart';
import 'package:pulselink/data/watch_bridge.dart';
import 'package:pulselink/domain/strap_ble_identifier.dart';

/// What the app needs from the platform, and the app's tracker. main()
/// passes the real ones; tests pass stubs.
class AppPlatform {
  const new({
    required this.strapScanner,
    required this.appSettings,
    required this.watchBridge,
    required this.createStrapSource,
    required this.tracker,
  });

  /// Used by the strap picker, which scans only while it's open.
  final StrapScanner strapScanner;

  /// Opened from the screens when Bluetooth permission is denied.
  final AppSettings appSettings;

  /// The platform's watch app, if it has one; null where there's none.
  final WatchBridge? watchBridge;

  /// Makes the source for a picked strap: main() passes one that connects
  /// to a BLE strap; tests pass a stub.
  final StrapDataSource Function(StrapBleIdentifier strapId) createStrapSource;

  /// The app's one tracker, which main() creates, for what the app itself
  /// creates and that reports to it, such as `WatchSync`.
  final TrackerService tracker;
}

/// The release app: heart rate only from a strap the user picks, never
/// simulated or debug data. It starts with no strap, and asks for one.
///
/// Debug and profile builds use `debugApp` (lib/app/debug/debug_app.dart)
/// instead, which adds demo data and the debug override.
Widget releaseApp(AppPlatform platform) {
  final source = SwitchableStrapDataSource.empty();
  // Created before starting the source, which reports its battery level as
  // it starts; a broadcast stream doesn't replay it to later listeners.
  final batteryCubit = StrapBatteryCubit(source: source);
  final cubit = startedCubit(source);
  syncWatch(cubit, platform.watchBridge, platform.tracker);
  final selection = StrapSelection(
    source: source,
    cubit: cubit,
    createSource: platform.createStrapSource,
  );
  return PulseLinkApp(
    liveHeartRateCubit: cubit,
    strapBatteryCubit: batteryCubit,
    strapScanner: platform.strapScanner,
    appSettings: platform.appSettings,
    // Not awaited: the screen shows how connecting goes through the cubit's
    // state. select() only throws if disposing the previous source fails;
    // that's left for the zone's error handler, and the strap is still
    // connected to.
    onStrapSelected: (strap) => unawaited(selection.select(strap)),
  );
}

/// A cubit for [source], started. These live as long as the app.
LiveHeartRateCubit startedCubit(StrapDataSource source) {
  final cubit = LiveHeartRateCubit(source: source);
  // Not awaited: runApp shouldn't wait for the source. start() doesn't need
  // watching here: a source that can't start (Bluetooth off, permission
  // denied, no strap picked) reports it as a typed result, which the cubit
  // turns into a state the screen shows. start() only throws on a bug in a
  // source; that's left uncaught for the zone's error handler to report.
  unawaited(cubit.start());
  return cubit;
}

/// Keeps the platform's watch app, if it has one, showing what [cubit]
/// shows, and notes how delivery goes to [tracker]. Never closed: like the
/// cubits, it lives as long as the app.
void syncWatch(
  LiveHeartRateCubit cubit,
  WatchBridge? bridge,
  TrackerService tracker,
) {
  if (bridge case final watch?) {
    WatchSync(heartRate: cubit, bridge: watch, tracker: tracker).start();
  }
}
