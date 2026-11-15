import Foundation
import Testing

@testable import PulseLinkWatch

private func snapshot(sentAt seconds: TimeInterval, status: HeartRateStatus = .waiting) -> HeartRateSnapshot {
  HeartRateSnapshot(
    sentAt: Date(timeIntervalSince1970: seconds),
    source: .demo,
    status: status,
    latestReading: nil
  )
}

/// These don't activate a session: `receive` and `reachabilityDidChange`
/// are what the WatchConnectivity callbacks call.
@MainActor
struct PhoneConnectionTests {
  @Test func startsWithNothingFromThePhone() {
    let connection = PhoneConnection()
    #expect(connection.snapshot == nil)
    #expect(!connection.isPhoneReachable)
  }

  @Test func showsTheFirstSnapshot() {
    let connection = PhoneConnection()
    connection.receive(snapshot(sentAt: 10))
    #expect(connection.snapshot == snapshot(sentAt: 10))
  }

  @Test func showsANewerSnapshot() {
    let connection = PhoneConnection()
    connection.receive(snapshot(sentAt: 10))
    connection.receive(snapshot(sentAt: 11, status: .receiving))
    #expect(connection.snapshot == snapshot(sentAt: 11, status: .receiving))
  }

  /// A live message and the application context can arrive in either
  /// order; the older one mustn't replace the newer.
  @Test func ignoresAnOlderSnapshot() {
    let connection = PhoneConnection()
    connection.receive(snapshot(sentAt: 11, status: .receiving))
    connection.receive(snapshot(sentAt: 10))
    #expect(connection.snapshot == snapshot(sentAt: 11, status: .receiving))
  }

  /// The same snapshot arrives twice, as a message and as the context.
  @Test func ignoresASnapshotSentAtTheSameTime() {
    let connection = PhoneConnection()
    connection.receive(snapshot(sentAt: 10, status: .receiving))
    connection.receive(snapshot(sentAt: 10))
    #expect(connection.snapshot == snapshot(sentAt: 10, status: .receiving))
  }

  @Test func followsReachability() {
    let connection = PhoneConnection()
    connection.reachabilityDidChange(true)
    #expect(connection.isPhoneReachable)
    connection.reachabilityDidChange(false)
    #expect(!connection.isPhoneReachable)
  }
}
