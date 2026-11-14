import Foundation
import Testing
import WatchConnectivity

@testable import Runner

/// A session that's activated, paired, has the watch app, and is reachable,
/// for tests to change one property at a time.
private func readyState() -> WatchSessionState {
  WatchSessionState(
    isSupported: true,
    activation: .activated,
    isPaired: true,
    isWatchAppInstalled: true,
    isReachable: true
  )
}

private func state(_ change: (inout WatchSessionState) -> Void) -> WatchSessionState {
  var state = readyState()
  change(&state)
  return state
}

struct LiveSnapshotActionTests {
  @Test
  func sendsWhenTheWatchAppIsReachable() {
    #expect(LiveSnapshotAction(readyState()) == .send)
  }

  @Test
  func dropsWhenTheWatchAppIsNotReachable() {
    #expect(LiveSnapshotAction(state { $0.isReachable = false }) == .drop(.watchUnreachable))
  }

  @Test(arguments: [WCSessionActivationState.notActivated, .inactive])
  func dropsUntilActivated(activation: WCSessionActivationState) {
    // Paired and reachable are meaningless before activation, so they don't
    // matter here.
    #expect(LiveSnapshotAction(state { $0.activation = activation }) == .drop(.watchUnreachable))
  }

  @Test
  func dropsWithoutAPairedWatch() {
    #expect(LiveSnapshotAction(state { $0.isPaired = false }) == .drop(.noWatchApp))
  }

  @Test
  func dropsWithoutTheWatchApp() {
    #expect(LiveSnapshotAction(state { $0.isWatchAppInstalled = false }) == .drop(.noWatchApp))
  }

  @Test
  func dropsOnADeviceThatCannotTalkToAWatch() {
    let unsupported = WatchSessionState(
      isSupported: false,
      activation: .notActivated,
      isPaired: false,
      isWatchAppInstalled: false,
      isReachable: false
    )

    #expect(LiveSnapshotAction(unsupported) == .drop(.unsupported))
  }
}

struct ApplicationContextActionTests {
  @Test
  func updatesWhenThereIsAWatchApp() {
    #expect(ApplicationContextAction(readyState()) == .update)
  }

  @Test
  func updatesEvenWhenTheWatchAppIsNotReachable() {
    // The application context is for when the watch app isn't open.
    #expect(ApplicationContextAction(state { $0.isReachable = false }) == .update)
  }

  @Test(arguments: [WCSessionActivationState.notActivated, .inactive])
  func holdsUntilActivated(activation: WCSessionActivationState) {
    #expect(ApplicationContextAction(state { $0.activation = activation }) == .hold)
  }

  @Test
  func dropsWithoutAPairedWatch() {
    #expect(ApplicationContextAction(state { $0.isPaired = false }) == .drop(.noWatchApp))
  }

  @Test
  func dropsWithoutTheWatchApp() {
    #expect(
      ApplicationContextAction(state { $0.isWatchAppInstalled = false }) == .drop(.noWatchApp)
    )
  }

  @Test
  func dropsOnADeviceThatCannotTalkToAWatch() {
    #expect(ApplicationContextAction(state { $0.isSupported = false }) == .drop(.unsupported))
  }
}

// Whole seconds and half seconds as milliseconds, which convert to Dates
// exactly.
private let sentAtMillis: Int64 = 1_794_000_010_000
private let measuredAtMillis: Int64 = 1_794_000_009_500
private let sentAt = Date(timeIntervalSince1970: 1_794_000_010)
private let measuredAt = Date(timeIntervalSince1970: 1_794_000_009.5)

private func pigeonSnapshot(
  source: WatchHeartRateSource = .strap,
  status: WatchHeartRateStatus = WatchReceiving(),
  latestReading: WatchHeartRateReading? = nil
) -> WatchHeartRateSnapshot {
  WatchHeartRateSnapshot(
    sentAtMillis: sentAtMillis,
    source: source,
    status: status,
    latestReading: latestReading
  )
}

/// A status type Pigeon didn't generate, standing in for a malformed one.
private struct UnknownStatus: WatchHeartRateStatus {}

/// A reading type Pigeon didn't generate, standing in for a malformed one.
private struct UnknownReading: WatchHeartRateReading {}

struct HeartRateSnapshotFromPigeonTests {
  @Test
  func convertsTheTimesFromMilliseconds() {
    let snapshot = HeartRateSnapshot(
      pigeonSnapshot(
        latestReading: WatchMeasuredReading(beatsPerMinute: 72, measuredAtMillis: measuredAtMillis)
      )
    )

    #expect(snapshot?.sentAt == sentAt)
    #expect(snapshot?.latestReading?.measuredAt == measuredAt)
  }

  @Test(arguments: [
    (WatchHeartRateSource.demo, HeartRateSource.demo),
    (.strap, .strap),
  ])
  func convertsEachSource(pigeon: WatchHeartRateSource, source: HeartRateSource) {
    #expect(HeartRateSnapshot(pigeonSnapshot(source: pigeon))?.source == source)
  }

  @Test
  func convertsWaitingAndReceiving() {
    #expect(HeartRateSnapshot(pigeonSnapshot(status: WatchWaiting()))?.status == .waiting)
    #expect(HeartRateSnapshot(pigeonSnapshot(status: WatchReceiving()))?.status == .receiving)
  }

  @Test(arguments: [
    (WatchStrapFailure.bluetoothOff, StrapConnectionFailure.bluetooth(.off)),
    (.bluetoothUnavailable, .bluetooth(.unavailable)),
    (.bluetoothPermissionDenied, .bluetooth(.permissionDenied)),
    (.strapUnreachable, .strapUnreachable),
    (.notAHeartRateStrap, .notAHeartRateStrap),
    (.connectionLost, .connectionLost),
  ])
  func convertsEachFailure(pigeon: WatchStrapFailure, failure: StrapConnectionFailure) {
    let snapshot = HeartRateSnapshot(pigeonSnapshot(status: WatchFailed(failure: pigeon)))

    #expect(snapshot?.status == .failed(failure))
  }

  @Test(arguments: [1, 72, 250])
  func convertsAMeasuredReading(value: Int64) throws {
    let snapshot = HeartRateSnapshot(
      pigeonSnapshot(
        latestReading: WatchMeasuredReading(
          beatsPerMinute: value,
          measuredAtMillis: measuredAtMillis
        )
      )
    )

    let beatsPerMinute = try #require(BeatsPerMinute(Int(value)))
    #expect(snapshot?.latestReading == .measured(beatsPerMinute, measuredAt: measuredAt))
  }

  @Test(arguments: [
    (WatchUnavailableReason.noSkinContact, HeartRateUnavailableReason.noSkinContact),
    (.zeroBeatsPerMinute, .zeroBeatsPerMinute),
    (.implausibleBeatsPerMinute, .implausibleBeatsPerMinute),
  ])
  func convertsAnUnavailableReading(
    pigeon: WatchUnavailableReason,
    reason: HeartRateUnavailableReason
  ) {
    let snapshot = HeartRateSnapshot(
      pigeonSnapshot(
        latestReading: WatchUnavailableReading(reason: pigeon, measuredAtMillis: measuredAtMillis)
      )
    )

    #expect(snapshot?.latestReading == .unavailable(reason, measuredAt: measuredAt))
  }

  @Test
  func convertsNoReading() {
    let snapshot = HeartRateSnapshot(pigeonSnapshot(latestReading: nil))

    #expect(snapshot != nil)
    #expect(snapshot?.latestReading == nil)
  }

  @Test(arguments: [Int64.min, -1, 0, 251, 65_535, Int64.max])
  func rejectsABeatsPerMinuteOutOfRange(value: Int64) {
    let snapshot = HeartRateSnapshot(
      pigeonSnapshot(
        latestReading: WatchMeasuredReading(
          beatsPerMinute: value,
          measuredAtMillis: measuredAtMillis
        )
      )
    )

    #expect(snapshot == nil)
  }

  @Test
  func rejectsAnUnknownStatus() {
    #expect(HeartRateSnapshot(pigeonSnapshot(status: UnknownStatus())) == nil)
  }

  @Test
  func rejectsAnUnknownReading() {
    #expect(HeartRateSnapshot(pigeonSnapshot(latestReading: UnknownReading())) == nil)
  }
}
