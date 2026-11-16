import os

private let watchLog = Logger(subsystem: "com.jpeckner.pulselink", category: "Watch")

/// Dart's calls to send heart-rate snapshots to the watch
/// (`WatchSessionApi`, declared in pigeons/watch_api.dart). Turns each into
/// the shared `HeartRateSnapshot`, then hands it to `PhoneWatchSession`.
///
/// Not `@MainActor`, like `BleStrapLink`: Pigeon's protocol has no actor
/// isolation. Each call converts its snapshot before hopping to the main
/// actor, so only `Sendable` values cross.
final class WatchLink {
  private let session = PhoneWatchSession()

  /// Starts activating WatchConnectivity straight away, as Apple recommends,
  /// rather than on Dart's first call.
  init() {
    let session = session
    Task { @MainActor in
      session.activate()
    }
  }
}

extension WatchLink: WatchSessionApi {
  func sendLiveSnapshot(snapshot: WatchHeartRateSnapshot) async throws -> WatchDeliveryOutcome {
    guard let snapshot = HeartRateSnapshot(snapshot) else {
      watchLog.fault("Dropped a malformed live snapshot from Dart")
      return .failed
    }
    // No thread check needed: awaiting a main-actor method runs it on the
    // main actor, whichever thread this started on.
    return await session.sendLive(snapshot)
  }

  func updateApplicationContext(
    snapshot: WatchHeartRateSnapshot
  ) async throws -> WatchDeliveryOutcome {
    guard let snapshot = HeartRateSnapshot(snapshot) else {
      watchLog.fault("Dropped a malformed application context from Dart")
      return .failed
    }
    return await session.updateApplicationContext(snapshot)
  }
}
