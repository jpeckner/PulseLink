// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import Foundation

/// Whether the caller is on the main thread. If not, reports it to
/// `tracker`, naming `method`, so the caller can skip its work instead of
/// letting `MainActor.assumeIsolated` stop the app.
func isOnMainThread(reportingTo tracker: any ErrorTracker, _ method: String = #function) -> Bool {
  if Thread.isMainThread {
    return true
  }
  tracker.logError(
    "\(method) was called off the main thread, so it was skipped",
    category: "MainThread",
    error: nil
  )
  return false
}
