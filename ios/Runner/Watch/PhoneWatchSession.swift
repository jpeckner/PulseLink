import WatchConnectivity
import os

private let watchLog = Logger(subsystem: "com.jpeckner.pulselink", category: "Watch")

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
  /// An application context that arrived before the session could take it,
  /// set once activation finishes. Only the newest is kept.
  private var heldContext: HeartRateSnapshot?

  private var hasRequestedActivation = false

  /// `nonisolated` so `WatchLink`, which has no actor isolation, can create
  /// one. It only sets up the properties above, which needs no particular
  /// thread.
  nonisolated override init() {
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
      // handler runs on a background queue, so it only logs.
      session.sendMessage(snapshot.dictionary, replyHandler: nil) { @Sendable error in
        watchLog.error("A live snapshot didn't reach the watch: \(error.localizedDescription, privacy: .public)")
      }
      return .sent
    case .drop(let outcome):
      return outcome
    }
  }

  /// Makes `snapshot` the application context, or holds it until the
  /// session is activated.
  func updateApplicationContext(_ snapshot: HeartRateSnapshot) -> WatchDeliveryOutcome {
    activate()
    switch ApplicationContextAction(state) {
    case .update:
      heldContext = nil
      return setApplicationContext(snapshot)
    case .hold:
      heldContext = snapshot
      return .pending
    case .drop(let outcome):
      heldContext = nil
      return outcome
    }
  }

  private var state: WatchSessionState {
    WatchSessionState(
      isSupported: session != nil,
      activation: session?.activationState ?? .notActivated,
      isPaired: session?.isPaired ?? false,
      isWatchAppInstalled: session?.isWatchAppInstalled ?? false,
      isReachable: session?.isReachable ?? false
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
      watchLog.error("Couldn't update the application context: \(error.localizedDescription, privacy: .public)")
      return .failed
    }
  }

  /// Sets a held context once the session can take it.
  private func activationDidComplete(errorDescription: String?) {
    if let errorDescription {
      watchLog.error("WatchConnectivity didn't activate: \(errorDescription, privacy: .public)")
    }
    guard let held = heldContext else {
      return
    }
    switch ApplicationContextAction(state) {
    case .update:
      heldContext = nil
      // Nobody is waiting for this outcome; a failure is logged.
      _ = setApplicationContext(held)
    case .hold:
      // Still not activated, such as after an error; kept for the next
      // activation.
      break
    case .drop(let outcome):
      heldContext = nil
      watchLog.info("Dropped a held application context: \(String(describing: outcome), privacy: .public)")
    }
  }

  /// The user switched to another Apple Watch. iOS requires activating
  /// again, which then sets any held context on the new watch.
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
    watchLog.info("WatchConnectivity became inactive")
  }

  nonisolated func sessionDidDeactivate(_ session: WCSession) {
    Task { @MainActor in
      self.didDeactivate()
    }
  }
}
