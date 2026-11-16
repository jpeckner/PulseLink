import Foundation

/// What the watch screen shows, worked out from the latest snapshot, when
/// the iPhone stopped being reachable, and the time. Plain values, so tests can check
/// every case without SwiftUI or WatchConnectivity; `HeartRateScreen` turns
/// them into text.
struct WatchHeartRateDisplay: Equatable {
  /// A reading this old or older is stale: shown as out of date, not as
  /// the current heart rate. The same threshold as the phone's
  /// `LiveHeartRateCubit`.
  static let staleAfter: TimeInterval = 10

  /// How long the iPhone must stay unreachable before the screen says so.
  /// WatchConnectivity reports it unreachable for a moment whenever the app
  /// wakes, such as on raising the wrist, and the banner would flash.
  static let unreachableGrace: TimeInterval = 5

  /// The big number.
  let readout: WatchReadout

  /// What's going on, under the number.
  let status: WatchStatus

  /// Where the phone's heart rate comes from, or nil before the first
  /// snapshot.
  let source: HeartRateSource?

  /// True shows "iPhone not reachable" over the rest: the iPhone has been
  /// unreachable for at least `unreachableGrace`.
  let showsPhoneNotReachable: Bool

  /// `phoneUnreachableSince` is when the iPhone stopped being reachable, or
  /// nil while it's reachable.
  init(snapshot: HeartRateSnapshot?, phoneUnreachableSince: Date?, now: Date) {
    showsPhoneNotReachable = phoneUnreachableSince.map {
      // A start ahead of `now`, if the clock was set back, counts as 0.
      max(now.timeIntervalSince($0), 0) >= Self.unreachableGrace
    } ?? false
    guard let snapshot else {
      readout = .none
      status = .noSnapshotYet
      source = nil
      return
    }
    source = snapshot.source

    let reading = snapshot.latestReading
    let isStale = reading.map { Self.isStale($0, now: now) } ?? false
    let isCurrent: Bool
    switch snapshot.status {
    case .receiving:
      isCurrent = !isStale
    case .noStrap, .waiting, .failed:
      // The phone has had no reading since it started waiting or failed,
      // or has no strap at all, so the last one isn't current however
      // recent it is.
      isCurrent = false
    }

    switch reading {
    case .measured(let beatsPerMinute, _):
      readout = isCurrent ? .current(beatsPerMinute) : .outOfDate(beatsPerMinute)
    case .unavailable, nil:
      readout = .none
    }

    switch snapshot.status {
    case .noStrap:
      status = .noStrap
    case .waiting:
      status = .waiting(lastReadingAt: reading?.measuredAt)
    case .failed(let failure):
      status = .failed(failure, lastReadingAt: reading?.measuredAt)
    case .receiving:
      switch reading {
      case nil:
        // The phone only says it's receiving once it has a reading, so
        // this doesn't happen in practice.
        status = .waiting(lastReadingAt: nil)
      case .measured(_, let measuredAt):
        status = isStale ? .noDataFromStrap(lastReadingAt: measuredAt) : .updated(measuredAt)
      case .unavailable(let reason, let measuredAt):
        status = isStale
          ? .noDataFromStrap(lastReadingAt: measuredAt)
          : .unavailable(reason, measuredAt: measuredAt)
      }
    }
  }

  /// Whether `reading` is at least `staleAfter` old at `now`. A reading
  /// stamped ahead of `now`, because the phone's clock runs ahead of the
  /// watch's, counts as age 0, as on the phone.
  static func isStale(_ reading: HeartRateReading, now: Date) -> Bool {
    let age = now.timeIntervalSince(reading.measuredAt)
    return max(age, 0) >= staleAfter
  }
}

/// The big number on the watch screen.
enum WatchReadout: Equatable {
  /// No usable bpm: "--".
  case none

  /// The current heart rate.
  case current(BeatsPerMinute)

  /// The last heart rate, no longer current: shown dimmed, as on the phone.
  case outOfDate(BeatsPerMinute)
}

/// What's going on, shown under the number.
enum WatchStatus: Equatable {
  /// No snapshot has ever arrived from the phone.
  case noSnapshotYet

  /// No strap has been picked on the phone.
  case noStrap

  /// The phone is starting up or connecting to the strap.
  case waiting(lastReadingAt: Date?)

  /// A fresh reading arrived at this time.
  case updated(Date)

  /// A fresh sample without a trustworthy heart rate, for this reason.
  case unavailable(HeartRateUnavailableReason, measuredAt: Date)

  /// The phone says it's receiving, but the last sample is stale: the
  /// strap, the phone, or the link to the watch has stopped sending.
  case noDataFromStrap(lastReadingAt: Date)

  /// The phone can't get heart-rate data, for this reason.
  case failed(StrapConnectionFailure, lastReadingAt: Date?)
}
