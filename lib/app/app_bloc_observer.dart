// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:pulselink/data/tracker_service.dart';

/// Logs every Bloc and Cubit state change with a timestamp, and reports
/// their errors.
///
/// A first step toward the in-app debug log planned for Milestone 6.
class AppBlocObserver extends BlocObserver {
  /// Errors are reported to `tracker` as non-fatal.
  const new({required this._tracker});

  final TrackerService _tracker;

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
    _tracker.logError(
      '${DateTime.now().toIso8601String()} ${bloc.runtimeType} error',
      name: 'bloc',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
