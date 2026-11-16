import Foundation
import Testing
import WatchConnectivity

@testable import Runner

struct WatchSessionStateTests {
  @Test
  func isReachableWhenActivatedWithAReachableWatchApp() {
    let state = WatchSessionState(
      activation: .activated,
      isPaired: true,
      isWatchAppInstalled: true,
      isReachable: true
    )

    #expect(state == .watchAppReachable)
  }

  @Test
  func isNotReachableWhenTheWatchAppIsNotOpenOrInRange() {
    let state = WatchSessionState(
      activation: .activated,
      isPaired: true,
      isWatchAppInstalled: true,
      isReachable: false
    )

    #expect(state == .watchAppNotReachable)
  }

  @Test(arguments: [(false, true), (true, false), (false, false)])
  func hasNoWatchAppWithoutAPairedWatchThatHasTheApp(
    isPaired: Bool,
    isWatchAppInstalled: Bool
  ) {
    // Reachable is true to show it doesn't count without the app.
    let state = WatchSessionState(
      activation: .activated,
      isPaired: isPaired,
      isWatchAppInstalled: isWatchAppInstalled,
      isReachable: true
    )

    #expect(state == .noWatchApp)
  }

  @Test(arguments: [WCSessionActivationState.notActivated, .inactive])
  func isActivatingUntilActivated(activation: WCSessionActivationState) {
    // The other properties are true to show they don't count before
    // activation.
    let state = WatchSessionState(
      activation: activation,
      isPaired: true,
      isWatchAppInstalled: true,
      isReachable: true
    )

    #expect(state == .activating)
  }
}

struct LiveSnapshotActionTests {
  @Test(arguments: [
    (WatchSessionState.unsupported, LiveSnapshotAction.drop(.unsupported)),
    (.activating, .drop(.watchUnreachable)),
    (.noWatchApp, .drop(.noWatchApp)),
    (.watchAppNotReachable, .drop(.watchUnreachable)),
    (.watchAppReachable, .send),
  ])
  func eachSessionStateHasAnAction(state: WatchSessionState, action: LiveSnapshotAction) {
    #expect(LiveSnapshotAction(state) == action)
  }
}

struct ApplicationContextActionTests {
  @Test(arguments: [
    (WatchSessionState.unsupported, ApplicationContextAction.drop(.unsupported)),
    (.activating, .hold),
    (.noWatchApp, .drop(.noWatchApp)),
    // The application context is for when the watch app isn't open, so
    // it doesn't need to be reachable.
    (.watchAppNotReachable, .update),
    (.watchAppReachable, .update),
  ])
  func eachSessionStateHasAnAction(
    state: WatchSessionState,
    action: ApplicationContextAction
  ) {
    #expect(ApplicationContextAction(state) == action)
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
  func convertsNoStrapWaitingAndReceiving() {
    #expect(HeartRateSnapshot(pigeonSnapshot(status: WatchNoStrap()))?.status == .noStrap)
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
