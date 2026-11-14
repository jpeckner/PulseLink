import SwiftUI

/// The Apple Watch app. It shows the heart rate the iPhone app receives from
/// the strap; it doesn't connect to the strap itself.
@main
struct PulseLinkWatchApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
