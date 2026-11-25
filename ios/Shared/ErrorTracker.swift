// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import Foundation
import os

/// Where native code reports errors that shouldn't happen (a bug, such as a
/// call off the main thread or a malformed message from Dart, or a system
/// failure the app gets past) through `logError`, and normal events worth
/// noting through `logInfo`. Expected failures go back to Dart as typed
/// results.
///
/// The Swift counterpart of Dart's `TrackerService`. Each app has one:
/// `AppDelegate` creates the iPhone app's and `PulseLinkWatchApp` the
/// watch app's, and passes it, through initializers, to everything that
/// reports errors. Tests pass one that records what it's given.
///
/// `Sendable` because WatchConnectivity calls in on background queues, and
/// errors are reported from there too.
protocol ErrorTracker: Sendable {
  /// Reports `message`, under `category` (such as "Watch"), with the
  /// `error` that caused it, if there was one.
  func logError(_ message: String, category: String, error: (any Error)?)

  /// Notes `message`, a normal event rather than an error, under
  /// `category`.
  func logInfo(_ message: String, category: String)
}

/// Logs to Apple's unified log at the error or info level, under the app's
/// subsystem (see `Logger.init(category:)`). A crash reporting service would
/// plug in here.
struct OSLogTracker: ErrorTracker {
  func logError(_ message: String, category: String, error: (any Error)?) {
    // Redacted before anything leaves this method, so no report carries
    // personal information about the user.
    let redactedMessage = message.redactedValue
    let redactedError = error?.redactedValue

    // Forward to your crash reporting service (e.g., Crashlytics, DataDog)
    //   Crashlytics.crashlytics().log(redactedMessage)
    //   if let redactedError { Crashlytics.crashlytics().record(error: redactedError) }

    let logger = Logger(category: category)
    if let redactedError {
      logger.error("\(redactedMessage, privacy: .public): \(String(describing: redactedError), privacy: .public)")
    } else {
      logger.error("\(redactedMessage, privacy: .public)")
    }
  }

  func logInfo(_ message: String, category: String) {
    // Redacted, as in logError.
    let redactedMessage = message.redactedValue

    // Forward to your crash reporting service (e.g., Crashlytics, DataDog),
    // as a breadcrumb sent with the next report
    //   Crashlytics.crashlytics().log(redactedMessage)

    Logger(category: category).info("\(redactedMessage, privacy: .public)")
  }
}

extension Logger {
  /// A logger under this app's subsystem: its bundle ID, which comes from
  /// the `PULSELINK_BUNDLE_ID` build setting, such as
  /// com.jpeckner.pulselink.debug in a Debug build or
  /// com.jpeckner.pulselink.watchkitapp on the watch. So each build's logs
  /// can be told apart, and no code repeats the ID.
  init(category: String) {
    // An app always has a bundle ID; the process name is only for code
    // running outside a bundle.
    let subsystem = Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
    self.init(subsystem: subsystem, category: category)
  }
}

// Private to this file, so nothing else mistakes a placeholder for real
// redaction.

private extension String {
  /// This text with any personally identifiable information about the user
  /// removed. A placeholder: nothing is removed yet.
  var redactedValue: String {
    self
  }
}

private extension Error {
  /// This error, or one in its place, with any personally identifiable
  /// information about the user removed from what it says, such as its
  /// description. A placeholder: nothing is removed yet. `any Error`, not
  /// the error's own type, since redacting usually means making a new one.
  var redactedValue: any Error {
    self
  }
}
