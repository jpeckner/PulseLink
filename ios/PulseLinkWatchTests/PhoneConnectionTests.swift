// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

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
  /// Unreachable from launch until activation says otherwise, so the
  /// banner shows only if activation takes longer than the grace period.
  @Test func startsWithNothingFromThePhone() {
    let before = Date()
    let connection = PhoneConnection()
    #expect(connection.snapshot == nil)
    let since = connection.phoneUnreachableSince
    #expect(since.map { $0 >= before && $0 <= Date() } == true)
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

  @Test func recordsWhenThePhoneBecameUnreachable() {
    let connection = PhoneConnection()
    connection.reachabilityDidChange(true, at: Date(timeIntervalSince1970: 10))
    #expect(connection.phoneUnreachableSince == nil)
    connection.reachabilityDidChange(false, at: Date(timeIntervalSince1970: 20))
    #expect(connection.phoneUnreachableSince == Date(timeIntervalSince1970: 20))
  }

  /// Another "unreachable" while already unreachable keeps the first time,
  /// so the grace period runs from when it started.
  @Test func keepsTheFirstUnreachableTime() {
    let connection = PhoneConnection()
    connection.reachabilityDidChange(true, at: Date(timeIntervalSince1970: 10))
    connection.reachabilityDidChange(false, at: Date(timeIntervalSince1970: 20))
    connection.reachabilityDidChange(false, at: Date(timeIntervalSince1970: 25))
    #expect(connection.phoneUnreachableSince == Date(timeIntervalSince1970: 20))
  }

  @Test func clearsTheUnreachableTimeWhenReachableAgain() {
    let connection = PhoneConnection()
    connection.reachabilityDidChange(true, at: Date(timeIntervalSince1970: 21))
    #expect(connection.phoneUnreachableSince == nil)
    connection.reachabilityDidChange(false, at: Date(timeIntervalSince1970: 30))
    #expect(connection.phoneUnreachableSince == Date(timeIntervalSince1970: 30))
  }
}
