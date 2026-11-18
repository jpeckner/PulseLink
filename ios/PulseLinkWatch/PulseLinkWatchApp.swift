// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import SwiftUI

/// The Apple Watch app. It shows the heart rate the iPhone app receives from
/// the strap; it doesn't connect to the strap itself.
@main
struct PulseLinkWatchApp: App {
  /// Lives as long as the app, so snapshots keep arriving while the screen
  /// is redrawn.
  @State private var connection = PhoneConnection()

  var body: some Scene {
    WindowGroup {
      ContentView(connection: connection)
        // Activated as soon as the app starts, as Apple recommends, so the
        // latest application context shows straight away.
        .task {
          connection.activate()
        }
    }
  }
}
