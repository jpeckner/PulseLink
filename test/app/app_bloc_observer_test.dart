// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/app/app_bloc_observer.dart';

import '../helpers/recording_tracker_service.dart';

class _CounterCubit extends Cubit<int> {
  new() : super(0);
}

void main() {
  group('AppBlocObserver', () {
    test('notes a Bloc or Cubit state change', () async {
      final tracker = RecordingTrackerService();
      final cubit = _CounterCubit();
      addTearDown(cubit.close);

      AppBlocObserver(tracker: tracker)
          .onChange(cubit, const Change(currentState: 0, nextState: 1));

      final noted = tracker.infos.single;
      expect(noted.message, contains('_CounterCubit'));
      expect(noted.message, contains('nextState: 1'));
      expect(noted.name, 'bloc');
      expect(tracker.errors, isEmpty);
    });

    test('tracks a Bloc or Cubit error as non-fatal', () async {
      final tracker = RecordingTrackerService();
      final cubit = _CounterCubit();
      addTearDown(cubit.close);
      final error = StateError('failed');
      final stackTrace = StackTrace.current;

      AppBlocObserver(tracker: tracker).onError(cubit, error, stackTrace);

      final logged = tracker.errors.single;
      expect(logged.message, endsWith('_CounterCubit error'));
      expect(logged.name, 'bloc');
      expect(logged.error, same(error));
      expect(logged.stackTrace, same(stackTrace));
      expect(logged.fatal, isFalse);
    });
  });
}
