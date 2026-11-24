// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/app/uncaught_error_reporter.dart';

import '../helpers/recording_tracker_service.dart';

void main() {
  group('UncaughtErrorReporter, once installed,', () {
    late RecordingTrackerService tracker;
    late List<FlutterErrorDetails> presented;

    setUp(() {
      tracker = RecordingTrackerService();
      presented = [];
      // The handlers are private, so each test reaches them through the
      // hooks install() sets, and puts the originals back afterwards.
      final originalFlutterOnError = FlutterError.onError;
      final originalPlatformOnError = PlatformDispatcher.instance.onError;
      addTearDown(() {
        FlutterError.onError = originalFlutterOnError;
        PlatformDispatcher.instance.onError = originalPlatformOnError;
      });
      UncaughtErrorReporter(
        tracker: tracker,
        presentFlutterError: presented.add,
      ).install();
    });

    test('logs an uncaught error as fatal, and leaves it unhandled so the '
        'platform still prints it', () {
      final error = StateError('nobody awaited this');
      final stackTrace = StackTrace.current;

      expect(
        PlatformDispatcher.instance.onError?.call(error, stackTrace),
        isFalse,
      );
      final logged = tracker.errors.single;
      expect(logged.message, 'Uncaught error');
      expect(logged.name, 'uncaught');
      expect(logged.error, same(error));
      expect(logged.stackTrace, same(stackTrace));
      expect(logged.fatal, isTrue);
    });

    test('presents a Flutter error as Flutter would, then logs it as fatal '
        'with its library', () {
      final error = Exception('build failed');
      final details = FlutterErrorDetails(
        exception: error,
        stack: StackTrace.current,
        library: 'widgets library',
      );

      FlutterError.reportError(details);
      expect(presented, [same(details)]);
      final logged = tracker.errors.single;
      expect(logged.message, 'Flutter error in widgets library');
      expect(logged.name, 'uncaught');
      expect(logged.error, same(error));
      expect(logged.stackTrace, same(details.stack));
      expect(logged.fatal, isTrue);
    });

    test('names an unknown library when the error has none', () {
      FlutterError.reportError(
        FlutterErrorDetails(exception: Exception('no library'), library: null),
      );
      final logged = tracker.errors.single;
      expect(logged.message, 'Flutter error in an unknown library');
      expect(logged.stackTrace, isNull);
    });

    test("uses FlutterErrorDetails' default library", () {
      FlutterError.reportError(
        FlutterErrorDetails(exception: Exception('reported')),
      );
      expect(
        tracker.errors.single.message,
        'Flutter error in Flutter framework',
      );
    });
  });
}
