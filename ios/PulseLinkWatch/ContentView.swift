import SwiftUI

/// A placeholder until the watch receives heart rate from the iPhone.
struct ContentView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "heart")
        .font(.title)
        .foregroundStyle(.red)
      Text("PulseLink")
        .font(.headline)
      Text("Heart rate from your iPhone will show here.")
        .font(.footnote)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
    }
    .padding()
  }
}

#Preview {
  ContentView()
}
