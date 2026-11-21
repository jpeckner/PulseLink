// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/app/uncaught_error_reporter.dart';

/// One call to the reporter's log function.
typedef _Logged = ({String message, Object error, StackTrace? stackTrace});

void main() {
  group('UncaughtErrorReporter', () {
    late List<_Logged> logged;
    late List<FlutterErrorDetails> presented;
    late UncaughtErrorReporter reporter;

    setUp(() {
      logged = [];
      presented = [];
      reporter = UncaughtErrorReporter(
        log: (message, error, stackTrace) => logged.add((
          message: message,
          error: error,
          stackTrace: stackTrace,
        )),
        presentFlutterError: presented.add,
      );
    });

    test('logs an uncaught error, and leaves it unhandled so the platform '
        'still prints it', () {
      final error = StateError('nobody awaited this');
      final stackTrace = StackTrace.current;

      expect(reporter.handlePlatformError(error, stackTrace), isFalse);
      expect(logged, hasLength(1));
      expect(logged.single.message, 'Uncaught error');
      expect(logged.single.error, same(error));
      expect(logged.single.stackTrace, same(stackTrace));
    });

    test('presents a Flutter error as Flutter would, then logs it with its '
        'library', () {
      final error = Exception('build failed');
      final details = FlutterErrorDetails(
        exception: error,
        stack: StackTrace.current,
        library: 'widgets library',
      );

      reporter.handleFlutterError(details);
      expect(presented, [same(details)]);
      expect(logged.single.message, 'Flutter error in widgets library');
      expect(logged.single.error, same(error));
      expect(logged.single.stackTrace, same(details.stack));
    });

    test('names an unknown library when the error has none', () {
      reporter.handleFlutterError(
        FlutterErrorDetails(exception: Exception('no library'), library: null),
      );
      expect(logged.single.message, 'Flutter error in an unknown library');
      expect(logged.single.stackTrace, isNull);
    });

    test("install routes Flutter's last-resort hooks to it", () {
      final originalFlutterOnError = FlutterError.onError;
      final dispatcher = PlatformDispatcher.instance;
      final originalPlatformOnError = dispatcher.onError;
      addTearDown(() {
        FlutterError.onError = originalFlutterOnError;
        dispatcher.onError = originalPlatformOnError;
      });

      reporter.install();

      FlutterError.reportError(
        FlutterErrorDetails(exception: Exception('reported')),
      );
      expect(presented, hasLength(1));
      // FlutterErrorDetails' default library.
      expect(logged.last.message, 'Flutter error in Flutter framework');

      final error = StateError('uncaught');
      expect(dispatcher.onError?.call(error, StackTrace.current), isFalse);
      expect(logged.last.error, same(error));
    });
  });
}
