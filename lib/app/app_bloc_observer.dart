import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';

/// Logs every Bloc and Cubit state change with a timestamp.
///
/// A first step toward the in-app debug log planned for later in Milestone 3.
class AppBlocObserver extends BlocObserver {
  const new();

  @override
  void onChange(BlocBase<Object?> bloc, Change<Object?> change) {
    super.onChange(bloc, change);
    developer.log(
      '${DateTime.now().toIso8601String()} ${bloc.runtimeType} $change',
      name: 'bloc',
    );
  }

  @override
  void onError(BlocBase<Object?> bloc, Object error, StackTrace stackTrace) {
    developer.log(
      '${DateTime.now().toIso8601String()} ${bloc.runtimeType} error',
      name: 'bloc',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
