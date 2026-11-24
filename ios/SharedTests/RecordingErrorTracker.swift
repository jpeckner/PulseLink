// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import Foundation

// In both test targets, each testing its own app's copy of ErrorTracker.
#if os(watchOS)
  @testable import PulseLinkWatch
#else
  @testable import Runner
#endif

/// An `ErrorTracker` that records each error instead of logging it.
///
/// `@unchecked Sendable` because errors can be reported from any thread:
/// the lock guards `recorded`, which is the only mutable state.
final class RecordingErrorTracker: ErrorTracker, @unchecked Sendable {
  /// One call to `logError`.
  struct Entry: Equatable {
    let message: String
    let category: String
    let errorDescription: String?
  }

  private let lock = NSLock()
  private var recorded: [Entry] = []

  /// Everything reported so far, oldest first.
  var errors: [Entry] {
    lock.withLock { recorded }
  }

  func logError(_ message: String, category: String, error: (any Error)?) {
    let entry = Entry(
      message: message,
      category: category,
      errorDescription: error.map { String(describing: $0) }
    )
    lock.withLock { recorded.append(entry) }
  }
}
