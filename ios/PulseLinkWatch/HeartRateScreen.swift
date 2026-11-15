import SwiftUI

/// The watch's heart-rate screen for one `WatchHeartRateDisplay`. The words
/// match the phone app's live screen.
struct HeartRateScreen: View {
  let display: WatchHeartRateDisplay

  var body: some View {
    ScrollView {
      VStack(spacing: 6) {
        if !display.isPhoneReachable {
          Label("iPhone not reachable", systemImage: "iphone.slash")
            .font(.footnote)
            .foregroundStyle(.orange)
        }
        if let source = display.source {
          SourceTag(source: source)
        }
        Readout(readout: display.readout)
        StatusLines(status: display.status)
      }
      .frame(maxWidth: .infinity)
      .multilineTextAlignment(.center)
    }
  }
}

/// "Demo" in demo mode, and nothing for a strap, as on the phone.
private struct SourceTag: View {
  let source: HeartRateSource

  var body: some View {
    switch source {
    case .demo:
      Text("Demo")
        .font(.caption2)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(.quaternary, in: Capsule())
    case .strap:
      EmptyView()
    }
  }
}

private struct Readout: View {
  let readout: WatchReadout

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 4) {
      Text(number)
        .font(.system(size: 48, weight: .semibold, design: .rounded))
        .monospacedDigit()
      Text("bpm")
        .font(.title3)
    }
    .foregroundStyle(isOutOfDate ? .secondary : .primary)
    .opacity(isOutOfDate ? 0.5 : 1)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
  }

  private var number: String {
    switch readout {
    case .none:
      return "--"
    case .current(let beatsPerMinute), .outOfDate(let beatsPerMinute):
      return String(beatsPerMinute.value)
    }
  }

  private var isOutOfDate: Bool {
    switch readout {
    case .outOfDate:
      return true
    case .none, .current:
      return false
    }
  }

  private var accessibilityLabel: String {
    switch readout {
    case .none:
      return "No heart-rate reading"
    case .current(let beatsPerMinute):
      return "\(beatsPerMinute.value) beats per minute"
    case .outOfDate(let beatsPerMinute):
      return "Last reading \(beatsPerMinute.value) beats per minute, out of date"
    }
  }
}

private struct StatusLines: View {
  let status: WatchStatus

  var body: some View {
    switch status {
    case .noSnapshotYet:
      Text("Open PulseLink on your iPhone")
        .font(.footnote)
        .foregroundStyle(.secondary)
    case .waiting(let lastReadingAt):
      Text("Waiting for heart-rate data…")
        .font(.footnote)
      if let lastReadingAt {
        LastReading(at: lastReadingAt, isProblem: false)
      }
    case .updated(let measuredAt):
      Text("Updated \(Self.time(measuredAt))")
        .font(.footnote)
    case .unavailable(let reason, let measuredAt):
      UnavailableReason(reason: reason)
      Text("Updated \(Self.time(measuredAt))")
        .font(.footnote)
        .foregroundStyle(.secondary)
    case .noDataFromStrap(let lastReadingAt):
      Label("No data from strap", systemImage: "antenna.radiowaves.left.and.right.slash")
        .font(.footnote)
        .foregroundStyle(.red)
      LastReading(at: lastReadingAt, isProblem: true)
    case .failed(let failure, let lastReadingAt):
      Text(Self.title(failure))
        .font(.footnote)
        .foregroundStyle(.red)
      if let lastReadingAt {
        LastReading(at: lastReadingAt, isProblem: true)
      }
    }
  }

  /// A time with seconds, such as "10:04:31 AM", like the phone's.
  static func time(_ date: Date) -> String {
    date.formatted(date: .omitted, time: .standard)
  }

  /// The phone's title for each failure.
  private static func title(_ failure: StrapConnectionFailure) -> String {
    switch failure {
    case .bluetooth(.off):
      return "Bluetooth is off"
    case .bluetooth(.unavailable):
      return "Bluetooth isn't available"
    case .bluetooth(.permissionDenied):
      return "Bluetooth permission needed"
    case .strapUnreachable:
      return "Can't reach the strap"
    case .notAHeartRateStrap:
      return "Not a heart-rate strap"
    case .connectionLost:
      return "Strap disconnected"
    }
  }
}

private struct LastReading: View {
  let at: Date
  let isProblem: Bool

  var body: some View {
    Text("Last reading \(StatusLines.time(at))")
      .font(.caption2)
      .foregroundStyle(isProblem ? .red : .secondary)
  }
}

/// Why a fresh sample has no heart rate, worded and coloured as on the
/// phone: a bpm of 0 is information, the others are problems.
private struct UnavailableReason: View {
  let reason: HeartRateUnavailableReason

  var body: some View {
    switch reason {
    case .noSkinContact:
      Text("No skin contact")
        .font(.footnote)
        .foregroundStyle(.red)
    case .zeroBeatsPerMinute:
      Text("Strap connected, no heart rate yet")
        .font(.footnote)
    case .implausibleBeatsPerMinute:
      Text("Strap reading out of range")
        .font(.footnote)
        .foregroundStyle(.red)
    }
  }
}

// MARK: - Previews

// Debug builds only, previews and their helpers alike, so none of it ships
// in a release build. See "SwiftUI previews" in CLAUDE.md.
#if DEBUG
private let previewNow = Date()

private func previewDisplay(
  status: HeartRateStatus,
  reading: HeartRateReading?,
  source: HeartRateSource = .strap,
  isPhoneReachable: Bool = true
) -> WatchHeartRateDisplay {
  WatchHeartRateDisplay(
    snapshot: HeartRateSnapshot(sentAt: previewNow, source: source, status: status, latestReading: reading),
    isPhoneReachable: isPhoneReachable,
    now: previewNow
  )
}

private func previewMeasured(_ value: Int, secondsAgo: TimeInterval) -> HeartRateReading? {
  BeatsPerMinute(value).map { .measured($0, measuredAt: previewNow.addingTimeInterval(-secondsAgo)) }
}

#Preview("Live") {
  HeartRateScreen(display: previewDisplay(status: .receiving, reading: previewMeasured(72, secondsAgo: 1)))
}

#Preview("Demo") {
  HeartRateScreen(
    display: previewDisplay(status: .receiving, reading: previewMeasured(72, secondsAgo: 1), source: .demo)
  )
}

#Preview("Stale") {
  HeartRateScreen(display: previewDisplay(status: .receiving, reading: previewMeasured(72, secondsAgo: 30)))
}

#Preview("No skin contact") {
  HeartRateScreen(
    display: previewDisplay(
      status: .receiving,
      reading: .unavailable(.noSkinContact, measuredAt: previewNow)
    )
  )
}

#Preview("Strap disconnected") {
  HeartRateScreen(
    display: previewDisplay(status: .failed(.connectionLost), reading: previewMeasured(72, secondsAgo: 20))
  )
}

#Preview("iPhone not reachable") {
  HeartRateScreen(
    display: previewDisplay(
      status: .receiving,
      reading: previewMeasured(72, secondsAgo: 40),
      isPhoneReachable: false
    )
  )
}

#Preview("Never heard from the phone") {
  HeartRateScreen(display: WatchHeartRateDisplay(snapshot: nil, isPhoneReachable: true, now: previewNow))
}
#endif
