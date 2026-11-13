import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pulselink/app/app.dart';
import 'package:pulselink/app/app_bloc_observer.dart';
import 'package:pulselink/blocs/debug_override/debug_override_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';
import 'package:pulselink/data/fake_heart_rate_source.dart';
import 'package:pulselink/data/heart_rate_source.dart';
import 'package:pulselink/ui/debug/debug_override_buttons.dart';

/// The composition root: builds the app's object graph and hands it to the
/// widgets through constructors, so a missing dependency is a compile error,
/// not a runtime lookup failure. These objects live as long as the app.
void main() {
  Bloc.observer = const AppBlocObserver();

  // Demo mode until real BLE arrives in Milestone 3.
  final HeartRateSource source = FakeHeartRateSource();

  if (kReleaseMode) {
    runApp(PulseLinkApp(liveHeartRateCubit: _startedCubit(source)));
  } else {
    // Debug and profile builds only. kReleaseMode is a compile-time constant,
    // so release builds contain neither this branch nor anything only it uses.
    final overrideSource = DebugOverrideHeartRateSource(source);
    final overrideCubit = DebugOverrideCubit(source: overrideSource);
    runApp(
      PulseLinkApp(
        liveHeartRateCubit: _startedCubit(overrideSource),
        debugControls: DebugOverrideButtons(cubit: overrideCubit),
        onTitleLongPress: overrideCubit.toggleVisibility,
      ),
    );
  }
}

LiveHeartRateCubit _startedCubit(HeartRateSource source) {
  final cubit = LiveHeartRateCubit(source: source);
  // Not awaited: runApp shouldn't wait for the source. The sources used here
  // can't fail to start (FakeHeartRateSource, and the debug override that
  // only wraps it). A real BLE source's can (Bluetooth off, permission
  // denied), so in Milestone 3 start() returns a typed result that the cubit
  // turns into a state the screen shows, rather than an error dropped here.
  unawaited(cubit.start());
  return cubit;
}
