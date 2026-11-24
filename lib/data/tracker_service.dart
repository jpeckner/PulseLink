// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'dart:developer' as developer;

/// The one place errors are reported from: a bug, or a failure the app gets
/// past but shouldn't happen, such as a platform channel with no native
/// handler. Expected failures, and normal events such as a malformed packet
/// or the strap disconnecting, don't come here.
///
/// For now it logs through `dart:developer`. A crash reporting service, and
/// the in-app debug log planned for Milestone 6, would plug in here.
///
/// The app has one: main() creates it and passes it, through constructors,
/// to everything that reports errors, which takes it as a required argument.
/// Nothing else creates one, except tests.
class TrackerService {
  const new();

  /// Reports [error], described by [message], under [name] (such as `ble`):
  /// [fatal] for an error nothing caught, which may have left the app
  /// broken, or non-fatal for one that was caught and handled.
  void logError(
    String message, {
    required String name,
    required Object error,
    StackTrace? stackTrace,
    bool fatal = false,
  }) {
    // Redacted before anything leaves this method, so no report carries
    // personal information about the user.
    final redactedMessage = message.redactedValue;
    final redactedError = error.redactedValue;

    // Forward to your crash reporting service (e.g., Crashlytics, DataDog)
    // FirebaseCrashlytics.instance.recordError(
    //   redactedError,
    //   stackTrace,
    //   reason: redactedMessage,
    //   fatal: fatal,
    // );

    developer.log(
      redactedMessage,
      name: name,
      // dart:developer's SEVERE level, so tools show it as an error.
      level: 1000,
      error: redactedError,
      stackTrace: stackTrace,
    );
  }
}

/// Private to this file, so nothing else mistakes a placeholder for real
/// redaction.
extension on String {
  /// This text with any personally identifiable information about the user
  /// removed. A placeholder: nothing is removed yet.
  String get redactedValue => this;
}

extension on Object {
  /// This error, or one in its place, with any personally identifiable
  /// information about the user removed from what it says, such as its
  /// message. A placeholder: nothing is removed yet. An [Object], not the
  /// error's own type, since redacting usually means making a new error.
  Object get redactedValue => this;
}
