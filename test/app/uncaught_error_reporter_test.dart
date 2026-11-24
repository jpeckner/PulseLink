// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/app/uncaught_error_reporter.dart';

/// One call to the reporter's log function.
typedef _Logged = ({String message, Object error, StackTrace? stackTrace});

void main() {
  group('UncaughtErrorReporter, once installed,', () {
    late List<_Logged> logged;
    late List<FlutterErrorDetails> presented;

    setUp(() {
      logged = [];
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
        log: (message, error, stackTrace) => logged.add((
          message: message,
          error: error,
          stackTrace: stackTrace,
        )),
        presentFlutterError: presented.add,
      ).install();
    });

    test('logs an uncaught error, and leaves it unhandled so the platform '
        'still prints it', () {
      final error = StateError('nobody awaited this');
      final stackTrace = StackTrace.current;

      expect(
        PlatformDispatcher.instance.onError?.call(error, stackTrace),
        isFalse,
      );
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

      FlutterError.reportError(details);
      expect(presented, [same(details)]);
      expect(logged.single.message, 'Flutter error in widgets library');
      expect(logged.single.error, same(error));
      expect(logged.single.stackTrace, same(details.stack));
    });

    test('names an unknown library when the error has none', () {
      FlutterError.reportError(
        FlutterErrorDetails(exception: Exception('no library'), library: null),
      );
      expect(logged.single.message, 'Flutter error in an unknown library');
      expect(logged.single.stackTrace, isNull);
    });

    test("uses FlutterErrorDetails' default library", () {
      FlutterError.reportError(
        FlutterErrorDetails(exception: Exception('reported')),
      );
      expect(logged.single.message, 'Flutter error in Flutter framework');
    });
  });
}
