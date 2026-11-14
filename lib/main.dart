import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pulselink/app/app.dart';
import 'package:pulselink/app/app_bloc_observer.dart';
import 'package:pulselink/blocs/debug_override/debug_override_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/strap_selection.dart';
import 'package:pulselink/blocs/strap_battery/strap_battery_cubit.dart';
import 'package:pulselink/data/ble/ble_strap_scanner.dart';
import 'package:pulselink/data/debug_override_strap_data_source.dart';
import 'package:pulselink/data/fake_strap_data_source.dart';
import 'package:pulselink/data/strap_data_source.dart';
import 'package:pulselink/data/strap_scanner.dart';
import 'package:pulselink/data/switchable_strap_data_source.dart';
import 'package:pulselink/domain/discovered_strap.dart';
import 'package:pulselink/ui/debug/debug_override_buttons.dart';

/// The composition root: builds the app's object graph and hands it to the
/// widgets through constructors, so a missing dependency is a compile error,
/// not a runtime lookup failure. These objects live as long as the app.
void main() {
  Bloc.observer = const AppBlocObserver();

  // Demo mode at launch, until a strap is picked in the strap picker.
  final source = SwitchableStrapDataSource(FakeStrapDataSource());
  final StrapScanner strapScanner = BleStrapScanner();

  if (kReleaseMode) {
    // Created before starting the source, which reports its battery level as
    // it starts; a broadcast stream doesn't replay it to later listeners.
    final batteryCubit = StrapBatteryCubit(source: source);
    final cubit = _startedCubit(source);
    runApp(
      PulseLinkApp(
        liveHeartRateCubit: cubit,
        strapBatteryCubit: batteryCubit,
        strapScanner: strapScanner,
        onStrapSelected: _selectStrap(source, cubit),
      ),
    );
  } else {
    // Debug and profile builds only. kReleaseMode is a compile-time constant,
    // so release builds contain neither this branch nor anything only it uses.
    // The override wraps the switchable source, so it also works on a strap.
    final overrideSource = DebugOverrideStrapDataSource(source);
    final overrideCubit = DebugOverrideCubit(source: overrideSource);
    // Before starting the source; see the release branch above.
    final batteryCubit = StrapBatteryCubit(source: overrideSource);
    final cubit = _startedCubit(overrideSource);
    runApp(
      PulseLinkApp(
        liveHeartRateCubit: cubit,
        strapBatteryCubit: batteryCubit,
        strapScanner: strapScanner,
        onStrapSelected: _selectStrap(source, cubit),
        debugControls: DebugOverrideButtons(cubit: overrideCubit),
        onTitleLongPress: overrideCubit.toggleVisibility,
      ),
    );
  }
}

/// Switches the live heart rate to a strap picked in the strap picker.
ValueChanged<DiscoveredStrap> _selectStrap(
  SwitchableStrapDataSource source,
  LiveHeartRateCubit cubit,
) {
  final selection = StrapSelection(source: source, cubit: cubit);
  // Not awaited: the screen shows how connecting goes through the cubit's
  // state. select() only throws if disposing demo mode fails; that's left
  // for the zone's error handler, and the strap is still connected to.
  return (strap) => unawaited(selection.select(strap));
}

LiveHeartRateCubit _startedCubit(StrapDataSource source) {
  final cubit = LiveHeartRateCubit(source: source);
  // Not awaited: runApp shouldn't wait for the source. start() doesn't need
  // watching here: a source that can't start (Bluetooth off, permission
  // denied) reports it as a typed result, which the cubit turns into a state
  // the screen shows. start() only throws on a bug in a source; that's left
  // uncaught for the zone's error handler to report, and the screen keeps
  // showing that it's waiting.
  unawaited(cubit.start());
  return cubit;
}
