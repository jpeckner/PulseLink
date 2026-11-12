import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:pulselink/app/app.dart';
import 'package:pulselink/app/app_bloc_observer.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/data/fake_heart_rate_source.dart';

/// The composition root: builds the app's object graph and hands it to the
/// widgets through constructors, so a missing dependency is a compile error,
/// not a runtime lookup failure. These objects live as long as the app.
void main() {
  Bloc.observer = const AppBlocObserver();

  // Demo mode until real BLE arrives in Milestone 3.
  final liveHeartRateCubit = LiveHeartRateCubit(source: FakeHeartRateSource());
  // Not awaited: runApp shouldn't wait for the source. FakeHeartRateSource's
  // start() can't fail. A real BLE source's can (Bluetooth off, permission
  // denied), so in Milestone 3 start() returns a typed result that the cubit
  // turns into a state the screen shows, rather than an error dropped here.
  unawaited(liveHeartRateCubit.start());

  runApp(PulseLinkApp(liveHeartRateCubit: liveHeartRateCubit));
}
