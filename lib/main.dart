import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pulselink/app/app.dart';
import 'package:pulselink/app/app_bloc_observer.dart';
import 'package:pulselink/blocs/debug_override/debug_override_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/data/ble/ble_strap_scanner.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';
import 'package:pulselink/data/fake_heart_rate_source.dart';
import 'package:pulselink/data/heart_rate_source.dart';
import 'package:pulselink/data/strap_scanner.dart';
import 'package:pulselink/ui/debug/debug_override_buttons.dart';

/// The composition root: builds the app's object graph and hands it to the
/// widgets through constructors, so a missing dependency is a compile error,
/// not a runtime lookup failure. These objects live as long as the app.
void main() {
  Bloc.observer = const AppBlocObserver();

  // Demo mode until connecting to a strap arrives later in Milestone 3.
  final HeartRateSource source = FakeHeartRateSource();
  final StrapScanner strapScanner = BleStrapScanner();

  if (kReleaseMode) {
    runApp(
      PulseLinkApp(
        liveHeartRateCubit: _startedCubit(source),
        strapScanner: strapScanner,
      ),
    );
  } else {
    // Debug and profile builds only. kReleaseMode is a compile-time constant,
    // so release builds contain neither this branch nor anything only it uses.
    final overrideSource = DebugOverrideHeartRateSource(source);
    final overrideCubit = DebugOverrideCubit(source: overrideSource);
    runApp(
      PulseLinkApp(
        liveHeartRateCubit: _startedCubit(overrideSource),
        strapScanner: strapScanner,
        debugControls: DebugOverrideButtons(cubit: overrideCubit),
        onTitleLongPress: overrideCubit.toggleVisibility,
      ),
    );
  }
}

LiveHeartRateCubit _startedCubit(HeartRateSource source) {
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
