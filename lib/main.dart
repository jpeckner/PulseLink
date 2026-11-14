import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:pulselink/app/app.dart';
import 'package:pulselink/app/app_bloc_observer.dart';

void main() {
  Bloc.observer = const AppBlocObserver();
  runApp(const PulseLinkApp());
}
