// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import WatchConnectivity

/// The iPhone's side of WatchConnectivity: sends heart-rate snapshots to the
/// watch app, as live messages and as the application context.
///
/// `@MainActor` because Dart's calls (through `WatchLink`) and
/// WatchConnectivity's callbacks share its state. Unlike CoreBluetooth,
/// WatchConnectivity calls its delegate on a background queue, so each
/// delegate method below copies what it needs into `Sendable` values and
/// then hops to the main actor.
@MainActor
final class PhoneWatchSession: NSObject {
  /// The newest snapshot Dart asked to make the application context,
  /// whatever happened to it. It's sent again when the watch's state
  /// changes: once activation finishes, when the watch app is installed, and
  /// (live) when it opens. Dart only sends a snapshot when the heart rate
  /// changes, so without this a watch app installed or opened while the
  /// phone's state stays the same, such as Bluetooth off, would get nothing.
  private var latestSnapshot: HeartRateSnapshot?

  private var hasRequestedActivation = false

  /// Where failures to reach the watch, and normal events, are reported.
  /// Called from WatchConnectivity's background queue too, so it's
  /// `Sendable`.
  private let tracker: any ErrorTracker

  /// `nonisolated` so `WatchLink`, which has no actor isolation, can create
  /// one. It only sets up the properties above, which needs no particular
  /// thread.
  nonisolated init(tracker: any ErrorTracker) {
    self.tracker = tracker
    super.init()
  }

  /// The default session, or nil on a device that can't talk to a watch.
  /// Looked up on the main actor rather than stored by `init`, because
  /// `WCSession` isn't `Sendable`.
  private var session: WCSession? {
    WCSession.isSupported() ? WCSession.default : nil
  }

  /// Starts activating the session, once. Apple recommends doing it early,
  /// so `WatchLink` calls it at launch; sending also calls it, in case.
  func activate() {
    guard let session, !hasRequestedActivation else {
      return
    }
    hasRequestedActivation = true
    session.delegate = self
    session.activate()
  }

  /// Sends `snapshot` as a live message if the watch app is reachable, and
  /// otherwise drops it.
  func sendLive(_ snapshot: HeartRateSnapshot) -> WatchDeliveryOutcome {
    activate()
    switch LiveSnapshotAction(state) {
    case .send:
      guard let session else {
        return .unsupported
      }
      // No reply handler: the phone doesn't wait for the watch. The error
      // handler runs on a background queue, so it only reports.
      let tracker = tracker
      session.sendMessage(snapshot.dictionary, replyHandler: nil) { @Sendable error in
        tracker.logError("A live snapshot didn't reach the watch", category: "Watch", error: error)
      }
      return .sent
    case .drop(let outcome):
      return outcome
    }
  }

  /// Makes `snapshot` the application context, or holds it until the
  /// session is activated. Either way it's kept as `latestSnapshot`.
  func updateApplicationContext(_ snapshot: HeartRateSnapshot) -> WatchDeliveryOutcome {
    activate()
    latestSnapshot = snapshot
    switch ApplicationContextAction(state) {
    case .update:
      return setApplicationContext(snapshot)
    case .hold:
      return .pending
    case .drop(let outcome):
      return outcome
    }
  }

  private var state: WatchSessionState {
    guard let session else {
      return .unsupported
    }
    return WatchSessionState(
      activation: session.activationState,
      isPaired: session.isPaired,
      isWatchAppInstalled: session.isWatchAppInstalled,
      isReachable: session.isReachable
    )
  }

  private func setApplicationContext(_ snapshot: HeartRateSnapshot) -> WatchDeliveryOutcome {
    guard let session else {
      return .unsupported
    }
    do {
      try session.updateApplicationContext(snapshot.dictionary)
      return .sent
    } catch {
      tracker.logError("Couldn't update the application context", category: "Watch", error: error)
      return .failed
    }
  }

  /// Sets the latest snapshot as the application context once the session
  /// can take it.
  private func activationDidComplete(errorDescription: String?) {
    if let errorDescription {
      tracker.logError(
        "WatchConnectivity didn't activate: \(errorDescription)",
        category: "Watch",
        error: nil
      )
    }
    resendLatestContext()
  }

  /// Sets the latest snapshot as the application context again, if the
  /// session can take it now.
  private func resendLatestContext() {
    guard let latestSnapshot else {
      return
    }
    switch ApplicationContextAction(state) {
    case .update:
      // Nobody is waiting for this outcome; a failure is reported.
      _ = setApplicationContext(latestSnapshot)
    case .hold:
      // Still not activated, such as after an error; set on the next
      // activation.
      break
    case .drop(let outcome):
      tracker.logInfo(
        "Didn't resend the application context: \(String(describing: outcome))",
        category: "Watch"
      )
    }
  }

  /// The watch app may have just opened: sends it the latest snapshot live,
  /// so it doesn't wait for the heart rate to change.
  private func reachabilityDidChange() {
    guard let latestSnapshot else {
      return
    }
    switch LiveSnapshotAction(state) {
    case .send:
      // Nobody is waiting for this outcome; a failure is reported.
      _ = sendLive(latestSnapshot)
    case .drop:
      // The watch app closed or went out of range: nothing to send to.
      break
    }
  }

  /// The user switched to another Apple Watch. iOS requires activating
  /// again, which then sets the latest snapshot on the new watch.
  private func didDeactivate() {
    session?.activate()
  }
}

/// WatchConnectivity calls these on a background queue, so each is
/// `nonisolated`, copies what it needs into `Sendable` values, and hops to
/// the main actor before touching any state.
extension PhoneWatchSession: WCSessionDelegate {
  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    let errorDescription = error.map { String(describing: $0) }
    Task { @MainActor in
      self.activationDidComplete(errorDescription: errorDescription)
    }
  }

  nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
    // Nothing to do: the session deactivates next. Context updates until
    // then are held.
    tracker.logInfo("WatchConnectivity became inactive", category: "Watch")
  }

  nonisolated func sessionDidDeactivate(_ session: WCSession) {
    Task { @MainActor in
      self.didDeactivate()
    }
  }

  /// A watch was paired or unpaired, or the watch app was installed or
  /// removed.
  nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
    Task { @MainActor in
      self.resendLatestContext()
    }
  }

  nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
    Task { @MainActor in
      self.reachabilityDidChange()
    }
  }
}
