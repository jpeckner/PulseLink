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

/// An `ErrorTracker` that records each error and info message instead of
/// logging it.
///
/// `@unchecked Sendable` because it can be called from any thread: the
/// lock guards `recorded` and `recordedInfo`, the only mutable state.
final class RecordingErrorTracker: ErrorTracker, @unchecked Sendable {
  /// One call to `logError`.
  struct Entry: Equatable {
    let message: String
    let category: String
    let errorDescription: String?
  }

  /// One call to `logInfo`.
  struct InfoEntry: Equatable {
    let message: String
    let category: String
  }

  private let lock = NSLock()
  private var recorded: [Entry] = []
  private var recordedInfo: [InfoEntry] = []

  /// Everything reported so far, oldest first.
  var errors: [Entry] {
    lock.withLock { recorded }
  }

  /// Every info message so far, oldest first.
  var infos: [InfoEntry] {
    lock.withLock { recordedInfo }
  }

  func logError(_ message: String, category: String, error: (any Error)?) {
    let entry = Entry(
      message: message,
      category: category,
      errorDescription: error.map { String(describing: $0) }
    )
    lock.withLock { recorded.append(entry) }
  }

  func logInfo(_ message: String, category: String) {
    let entry = InfoEntry(message: message, category: category)
    lock.withLock { recordedInfo.append(entry) }
  }
}
