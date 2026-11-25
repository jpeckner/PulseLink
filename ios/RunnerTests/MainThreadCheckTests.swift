// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import Foundation
import Testing

@testable import Runner

struct MainThreadCheckTests {
  @Test @MainActor
  func passesOnTheMainThreadWithoutReporting() {
    let tracker = RecordingErrorTracker()

    #expect(isOnMainThread(reportingTo: tracker, "probe()"))
    #expect(tracker.errors.isEmpty)
  }

  @Test
  func reportsACallOffTheMainThread() async {
    let tracker = RecordingErrorTracker()

    let isMain = await Task.detached {
      isOnMainThread(reportingTo: tracker, "probe()")
    }.value

    #expect(!isMain)
    #expect(
      tracker.errors == [
        RecordingErrorTracker.Entry(
          message: "probe() was called off the main thread, so it was skipped",
          category: "MainThread",
          errorDescription: nil
        ),
      ]
    )
  }
}
