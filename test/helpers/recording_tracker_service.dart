// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:pulselink/data/tracker_service.dart';

/// One call to [TrackerService.logError].
typedef LoggedError = ({
  String message,
  String name,
  Object error,
  StackTrace? stackTrace,
  bool fatal,
});

/// A [TrackerService] that records each error instead of logging it.
class RecordingTrackerService implements TrackerService {
  final errors = <LoggedError>[];

  @override
  void logError(
    String message, {
    required String name,
    required Object error,
    StackTrace? stackTrace,
    bool fatal = false,
  }) => errors.add((
    message: message,
    name: name,
    error: error,
    stackTrace: stackTrace,
    fatal: fatal,
  ));
}
