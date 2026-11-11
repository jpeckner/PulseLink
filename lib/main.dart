import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:pulselink/app/app.dart';
import 'package:pulselink/app/app_bloc_observer.dart';
import 'package:pulselink/data/fake_heart_rate_source.dart';

void main() {
  Bloc.observer = const AppBlocObserver();
  // Demo mode until real BLE arrives in Milestone 3.
  runApp(PulseLinkApp(heartRateSource: FakeHeartRateSource()));
}
