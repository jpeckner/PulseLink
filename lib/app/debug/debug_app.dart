// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:pulselink/app/app.dart';
import 'package:pulselink/app/composition.dart';
import 'package:pulselink/blocs/debug_override/debug_override_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/strap_selection.dart';
import 'package:pulselink/blocs/strap_battery/strap_battery_cubit.dart';
import 'package:pulselink/data/debug/fake_strap_data_source.dart';
import 'package:pulselink/data/debug_override_strap_data_source.dart';
import 'package:pulselink/data/switchable_strap_data_source.dart';
import 'package:pulselink/ui/debug/debug_override_buttons.dart';

/// The debug and profile app: the release app (see `releaseApp`), plus
/// debug tooling. It also starts with no strap, on real data. Long-pressing
/// the title shows the debug override buttons: the first switches between
/// demo data and real data, and the others fake strap conditions on top of
/// either.
///
/// Debug-only: main() uses it only when not in release mode, so release
/// builds contain neither it nor anything only it uses.
Widget debugApp(AppPlatform platform) {
  final source = SwitchableStrapDataSource.empty();
  // The override wraps the switchable source, so it works on a strap too.
  final overrideSource = DebugOverrideStrapDataSource(source);
  final overrideCubit = DebugOverrideCubit(source: overrideSource);
  // Before starting the source; see releaseApp.
  final batteryCubit = StrapBatteryCubit(source: overrideSource);
  final cubit = startedCubit(overrideSource);
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
    // Not awaited; see releaseApp.
    onStrapSelected: (strap) => unawaited(selection.select(strap)),
    debugControls: DebugOverrideButtons(
      cubit: overrideCubit,
      heartRate: cubit,
      // Not awaited, as for picking a strap. Real data means no strap until
      // one is picked, as at launch.
      onToggleDemoData: () => unawaited(
        source.isSimulated
            ? selection.clear()
            : selection.use(FakeStrapDataSource()),
      ),
    ),
    onTitleLongPress: overrideCubit.toggleVisibility,
  );
}
