// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import Observation
import WatchConnectivity
import os

private let phoneLog = Logger(subsystem: "com.jpeckner.pulselink.watchkitapp", category: "Phone")

/// The watch's side of WatchConnectivity: receives the iPhone app's
/// heart-rate snapshots, and tracks whether the iPhone is reachable.
///
/// Snapshots arrive two ways: as live messages while the watch app is open,
/// and as the application context, which is also there at launch. The two
/// can arrive in any order, so the newest by `sentAt` wins.
///
/// `@MainActor` because SwiftUI reads its state. WatchConnectivity calls its
/// delegate on a background queue, so each delegate method below decodes
/// what it needs into `Sendable` values, then hops to the main actor.
@MainActor
@Observable
final class PhoneConnection: NSObject {
  /// The newest snapshot received, or nil before the first.
  private(set) var snapshot: HeartRateSnapshot?

  /// When the iPhone stopped being reachable, or nil while it's reachable.
  /// Not a plain flag: WatchConnectivity reports the iPhone unreachable for
  /// a moment whenever the app wakes, such as on raising the wrist, so
  /// `WatchHeartRateDisplay` only shows it once it has lasted a while.
  ///
  /// Unreachable from launch until activation says otherwise. The phone
  /// app being closed doesn't make the iPhone unreachable; snapshots just
  /// stop arriving, and the last reading goes stale.
  private(set) var phoneUnreachableSince: Date? = Date()

  @ObservationIgnored private var hasRequestedActivation = false

  /// `nonisolated` so the app can create one as a property's initial
  /// value. It only sets up the properties above, which needs no particular
  /// thread.
  nonisolated override init() {
    super.init()
  }

  /// Starts activating the session, once. When it's activated, the latest
  /// application context and the iPhone's reachability are read.
  func activate() {
    guard WCSession.isSupported(), !hasRequestedActivation else {
      return
    }
    hasRequestedActivation = true
    let session = WCSession.default
    session.delegate = self
    session.activate()
  }

  /// Shows `snapshot`, unless the one already shown was sent at the same
  /// time or later.
  func receive(_ snapshot: HeartRateSnapshot) {
    if let current = self.snapshot, current.sentAt >= snapshot.sentAt {
      return
    }
    self.snapshot = snapshot
  }

  /// Records whether the iPhone is reachable, as of `date`. While it stays
  /// unreachable, the time it first became so is kept.
  func reachabilityDidChange(_ isReachable: Bool, at date: Date) {
    if isReachable {
      phoneUnreachableSince = nil
    } else if phoneUnreachableSince == nil {
      phoneUnreachableSince = date
    }
  }

  /// Decodes a message or application context, or logs why it couldn't,
  /// such as one from a newer phone app. Then the last good snapshot stays
  /// on screen.
  nonisolated private static func decode(
    _ dictionary: [String: Any],
    from channel: StaticString
  ) -> HeartRateSnapshot? {
    guard let snapshot = HeartRateSnapshot(dictionary: dictionary) else {
      phoneLog.error("Ignored a \(channel, privacy: .public) the watch can't read")
      return nil
    }
    return snapshot
  }
}

/// WatchConnectivity calls these on a background queue, so each is
/// `nonisolated`, turns what it needs into `Sendable` values, and hops to
/// the main actor before touching any state.
extension PhoneConnection: WCSessionDelegate {
  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    if let error {
      phoneLog.error("WatchConnectivity didn't activate: \(String(describing: error), privacy: .public)")
    }
    // Empty until the phone has set a context, such as on first launch.
    let context = session.receivedApplicationContext
    let snapshot = context.isEmpty ? nil : Self.decode(context, from: "application context")
    let isReachable = session.isReachable
    let changedAt = Date()
    Task { @MainActor in
      if let snapshot {
        self.receive(snapshot)
      }
      self.reachabilityDidChange(isReachable, at: changedAt)
    }
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveApplicationContext applicationContext: [String: Any]
  ) {
    guard let snapshot = Self.decode(applicationContext, from: "application context") else {
      return
    }
    Task { @MainActor in
      self.receive(snapshot)
    }
  }

  nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    guard let snapshot = Self.decode(message, from: "message") else {
      return
    }
    Task { @MainActor in
      self.receive(snapshot)
    }
  }

  nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
    let isReachable = session.isReachable
    let changedAt = Date()
    Task { @MainActor in
      self.reachabilityDidChange(isReachable, at: changedAt)
    }
  }
}
