import WatchConnectivity

/// What `PhoneWatchSession` needs to know about its `WCSession` to decide
/// what to do with a snapshot. A plain value, so the decisions below can be
/// tested without a real session.
struct WatchSessionState: Equatable {
  /// Whether this device can talk to an Apple Watch at all (not on iPad).
  var isSupported: Bool

  var activation: WCSessionActivationState

  /// Whether an Apple Watch is paired. Only meaningful once activated.
  var isPaired: Bool

  /// Whether the paired watch has the watch app. Only meaningful once
  /// activated.
  var isWatchAppInstalled: Bool

  /// Whether the watch app is open and in range, so a live message can reach
  /// it now. Only meaningful once activated.
  var isReachable: Bool
}

/// What to do with a live snapshot in each session state.
enum LiveSnapshotAction: Equatable {
  /// Send it with `sendMessage`.
  case send

  /// Drop it, for this reason. Live snapshots are never queued: by the time
  /// the watch could take one, a newer one will be on its way.
  case drop(WatchDeliveryOutcome)

  init(_ state: WatchSessionState) {
    guard state.isSupported else {
      self = .drop(.unsupported)
      return
    }
    switch state.activation {
    case .activated:
      if !state.isPaired || !state.isWatchAppInstalled {
        self = .drop(.noWatchApp)
      } else if !state.isReachable {
        self = .drop(.watchUnreachable)
      } else {
        self = .send
      }
    case .notActivated, .inactive:
      // Can't send until activated; dropped like any unreachable moment.
      self = .drop(.watchUnreachable)
    @unknown default:
      // Swift requires this for an enum Apple may add cases to. A state
      // added in a later iOS isn't known to be usable, so don't send.
      self = .drop(.watchUnreachable)
    }
  }
}

/// What to do with an application context in each session state.
enum ApplicationContextAction: Equatable {
  /// Set it with `updateApplicationContext`.
  case update

  /// Keep it, and set it once the session is activated, unless a newer one
  /// replaces it first. The session is still activating, or is between
  /// watches (inactive, about to deactivate and activate again).
  case hold

  /// Drop it, for this reason.
  case drop(WatchDeliveryOutcome)

  init(_ state: WatchSessionState) {
    guard state.isSupported else {
      self = .drop(.unsupported)
      return
    }
    switch state.activation {
    case .activated:
      self = state.isPaired && state.isWatchAppInstalled ? .update : .drop(.noWatchApp)
    case .notActivated, .inactive:
      self = .hold
    @unknown default:
      // Swift requires this for an enum Apple may add cases to. A state
      // added in a later iOS may yet become activated, so keep the context
      // for then.
      self = .hold
    }
  }
}
