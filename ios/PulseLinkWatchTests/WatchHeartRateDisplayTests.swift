import Foundation
import Testing

@testable import PulseLinkWatch

private let now = Date(timeIntervalSince1970: 1_794_000_100)

private func secondsAgo(_ seconds: TimeInterval) -> Date {
  now.addingTimeInterval(-seconds)
}

private func bpm(_ value: Int) throws -> BeatsPerMinute {
  try #require(BeatsPerMinute(value))
}

private func display(
  status: HeartRateStatus,
  reading: HeartRateReading?,
  source: HeartRateSource = .strap,
  phoneUnreachableSince: Date? = nil
) -> WatchHeartRateDisplay {
  WatchHeartRateDisplay(
    snapshot: HeartRateSnapshot(sentAt: now, source: source, status: status, latestReading: reading),
    phoneUnreachableSince: phoneUnreachableSince,
    now: now
  )
}

private let allFailures: [StrapConnectionFailure] = [
  .bluetooth(.off),
  .bluetooth(.unavailable),
  .bluetooth(.permissionDenied),
  .strapUnreachable,
  .notAHeartRateStrap,
  .connectionLost,
]

private let allUnavailableReasons: [HeartRateUnavailableReason] = [
  .noSkinContact,
  .zeroBeatsPerMinute,
  .implausibleBeatsPerMinute,
]

struct WatchHeartRateDisplayTests {
  @Test func beforeAnySnapshotAsksForThePhoneApp() {
    let display = WatchHeartRateDisplay(snapshot: nil, phoneUnreachableSince: nil, now: now)
    #expect(display.readout == .none)
    #expect(display.status == .noSnapshotYet)
    #expect(display.source == nil)
  }

  @Test func showsAFreshReadingAsCurrent() throws {
    let measuredAt = secondsAgo(1)
    let display = display(status: .receiving, reading: .measured(try bpm(72), measuredAt: measuredAt))
    #expect(display.readout == .current(try bpm(72)))
    #expect(display.status == .updated(measuredAt))
  }

  @Test(arguments: [9.999, 10, 30])
  func marksAReadingStaleFromTenSeconds(age: TimeInterval) throws {
    let measuredAt = secondsAgo(age)
    let display = display(status: .receiving, reading: .measured(try bpm(72), measuredAt: measuredAt))
    if age < WatchHeartRateDisplay.staleAfter {
      #expect(display.readout == .current(try bpm(72)))
      #expect(display.status == .updated(measuredAt))
    } else {
      #expect(display.readout == .outOfDate(try bpm(72)))
      #expect(display.status == .noDataFromStrap(lastReadingAt: measuredAt))
    }
  }

  @Test func treatsAReadingFromThePhonesFutureAsFresh() throws {
    let measuredAt = now.addingTimeInterval(60)
    let display = display(status: .receiving, reading: .measured(try bpm(72), measuredAt: measuredAt))
    #expect(display.readout == .current(try bpm(72)))
  }

  @Test(arguments: allUnavailableReasons)
  func showsWhyAFreshSampleHasNoHeartRate(reason: HeartRateUnavailableReason) {
    let measuredAt = secondsAgo(1)
    let display = display(status: .receiving, reading: .unavailable(reason, measuredAt: measuredAt))
    #expect(display.readout == .none)
    #expect(display.status == .unavailable(reason, measuredAt: measuredAt))
  }

  @Test(arguments: allUnavailableReasons)
  func showsAStaleUnavailableSampleAsNoData(reason: HeartRateUnavailableReason) {
    let measuredAt = secondsAgo(11)
    let display = display(status: .receiving, reading: .unavailable(reason, measuredAt: measuredAt))
    #expect(display.readout == .none)
    #expect(display.status == .noDataFromStrap(lastReadingAt: measuredAt))
  }

  @Test(arguments: allFailures)
  func showsAFailureWithTheLastReadingOutOfDate(failure: StrapConnectionFailure) throws {
    // Only a second old, but the phone has failed since, so not current.
    let measuredAt = secondsAgo(1)
    let display = display(status: .failed(failure), reading: .measured(try bpm(72), measuredAt: measuredAt))
    #expect(display.readout == .outOfDate(try bpm(72)))
    #expect(display.status == .failed(failure, lastReadingAt: measuredAt))
  }

  @Test(arguments: allFailures)
  func showsAFailureBeforeAnyReading(failure: StrapConnectionFailure) {
    let display = display(status: .failed(failure), reading: nil)
    #expect(display.readout == .none)
    #expect(display.status == .failed(failure, lastReadingAt: nil))
  }

  @Test func showsWaitingWithTheLastReadingOutOfDate() throws {
    let measuredAt = secondsAgo(1)
    let display = display(status: .waiting, reading: .measured(try bpm(72), measuredAt: measuredAt))
    #expect(display.readout == .outOfDate(try bpm(72)))
    #expect(display.status == .waiting(lastReadingAt: measuredAt))
  }

  @Test func showsWaitingBeforeAnyReading() {
    let display = display(status: .waiting, reading: nil)
    #expect(display.readout == .none)
    #expect(display.status == .waiting(lastReadingAt: nil))
  }

  @Test func showsReceivingWithoutAReadingAsWaiting() {
    let display = display(status: .receiving, reading: nil)
    #expect(display.readout == .none)
    #expect(display.status == .waiting(lastReadingAt: nil))
  }

  @Test(arguments: [HeartRateSource.demo, .strap])
  func passesOnTheSource(source: HeartRateSource) {
    #expect(display(status: .waiting, reading: nil, source: source).source == source)
  }

  @Test func showsAReachablePhoneAsReachable() {
    #expect(!display(status: .waiting, reading: nil, phoneUnreachableSince: nil).showsPhoneNotReachable)
  }

  /// WatchConnectivity reports the iPhone unreachable for a moment whenever
  /// the app wakes, such as on raising the wrist; that mustn't flash the
  /// banner.
  @Test(arguments: [0, 4.999, 5, 60])
  func showsAnUnreachablePhoneOnlyAfterTheGracePeriod(unreachableFor: TimeInterval) {
    let display = display(status: .waiting, reading: nil, phoneUnreachableSince: secondsAgo(unreachableFor))
    #expect(display.showsPhoneNotReachable == (unreachableFor >= WatchHeartRateDisplay.unreachableGrace))
  }

  @Test func treatsAnUnreachableStartAheadOfTheClockAsJustNow() {
    let display = display(status: .waiting, reading: nil, phoneUnreachableSince: now.addingTimeInterval(60))
    #expect(!display.showsPhoneNotReachable)
  }

  @Test func keepsShowingTheLastStateWhenThePhoneIsUnreachable() throws {
    let reading = HeartRateReading.measured(try bpm(72), measuredAt: secondsAgo(1))
    let display = display(status: .receiving, reading: reading, phoneUnreachableSince: secondsAgo(30))
    #expect(display.showsPhoneNotReachable)
    #expect(display.readout == .current(try bpm(72)))
  }

  @Test func showsAnUnreachablePhoneBeforeAnySnapshot() {
    let display = WatchHeartRateDisplay(snapshot: nil, phoneUnreachableSince: secondsAgo(30), now: now)
    #expect(display.showsPhoneNotReachable)
    #expect(display.status == .noSnapshotYet)
  }
}
