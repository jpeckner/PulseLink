// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import SwiftUI

/// The watch app's only screen: the heart rate the iPhone last sent.
///
/// Redrawn every second, so a reading turns stale, and "iPhone not
/// reachable" appears, on time even when nothing arrives, such as when the
/// phone goes out of range. The system slows this down when the wrist is
/// lowered.
struct ContentView: View {
  let connection: PhoneConnection

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      HeartRateScreen(
        display: WatchHeartRateDisplay(
          snapshot: connection.snapshot,
          phoneUnreachableSince: connection.phoneUnreachableSince,
          now: context.date
        )
      )
    }
  }
}
