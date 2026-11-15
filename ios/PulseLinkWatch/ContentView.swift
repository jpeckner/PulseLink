import SwiftUI

/// The watch app's only screen: the heart rate the iPhone last sent.
///
/// Redrawn every second, so a reading turns stale on time even when no
/// snapshot arrives, such as when the phone goes out of range. The system
/// slows this down when the wrist is lowered.
struct ContentView: View {
  let connection: PhoneConnection

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      HeartRateScreen(
        display: WatchHeartRateDisplay(
          snapshot: connection.snapshot,
          isPhoneReachable: connection.isPhoneReachable,
          now: context.date
        )
      )
    }
  }
}
