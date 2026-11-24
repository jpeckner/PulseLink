// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:flutter/foundation.dart';
import 'package:pulselink/data/tracker_service.dart';

/// Where errors that nothing else caught end up: the app's last resort.
///
/// Expected failures never get here: they're typed results, handled where
/// they happen (see "Error handling" in CLAUDE.md). What does get here is a
/// bug, such as a failed Future nobody awaits or a widget that throws while
/// building. This logs each one, so none goes unseen, and keeps Flutter's own
/// handling of it: the console, and the red error screen in debug builds.
class UncaughtErrorReporter {
  /// Errors are reported to `tracker` as fatal. Tests pass
  /// `presentFlutterError` in place of Flutter's default presentation.
  const new({
    required this._tracker,
    this._presentFlutterError = _presentAsFlutterWould,
  });

  final TrackerService _tracker;
  final void Function(FlutterErrorDetails details) _presentFlutterError;

  /// Routes Flutter's two last-resort hooks here. main() calls it first, so
  /// errors from anything after it are reported.
  void install() {
    FlutterError.onError = _handleFlutterError;
    PlatformDispatcher.instance.onError = _handlePlatformError;
  }

  /// An error while building, laying out or painting widgets, or anything
  /// else Flutter's framework reports. Flutter presents it as it would
  /// anyway, then it's logged.
  void _handleFlutterError(FlutterErrorDetails details) {
    _presentFlutterError(details);
    _tracker.logError(
      'Flutter error in ${details.library ?? 'an unknown library'}',
      name: _name,
      error: details.exception,
      stackTrace: details.stack,
      fatal: true,
    );
  }

  /// An error nothing handled: a failed Future nobody awaited, or an
  /// exception in a timer or stream callback with no error handler. It's
  /// logged, then reported as unhandled (false), so the platform still
  /// prints it to the device log as it would without this. That matters in
  /// release builds, where TrackerService's `dart:developer` log goes nowhere.
  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    _tracker.logError(
      'Uncaught error',
      name: _name,
      error: error,
      stackTrace: stackTrace,
      fatal: true,
    );
    return false;
  }

  /// Flutter's own presentation: [FlutterError.presentError] is a variable,
  /// so it's read when an error arrives, not when this is created.
  static void _presentAsFlutterWould(FlutterErrorDetails details) =>
      FlutterError.presentError(details);

  /// What errors are logged under.
  static const _name = 'uncaught';
}
