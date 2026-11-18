// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import Foundation
import os

/// Records a call that arrived off the main thread when it needed the main
/// thread.
private let threadingLog = Logger(
  subsystem: "com.jpeckner.pulselink",
  category: "MainThread"
)

/// Whether the caller is on the main thread. If not, logs a fault naming
/// `method`, so the caller can skip its work instead of letting
/// `MainActor.assumeIsolated` stop the app. See `CentralScan` for why its
/// entry points need the main thread.
func isOnMainThread(_ method: String = #function) -> Bool {
  if Thread.isMainThread {
    return true
  }
  threadingLog.fault(
    "\(method, privacy: .public) was called off the main thread, so it was skipped"
  )
  return false
}
