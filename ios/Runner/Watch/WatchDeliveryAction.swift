// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import WatchConnectivity

/// What the phone's `WCSession` can do with a snapshot right now. A plain
/// value, so the decisions below can be tested without a real session, and
/// only states that mean something: whether a watch is paired, say, isn't
/// known until the session is activated.
enum WatchSessionState: Equatable {
  /// This device can't talk to an Apple Watch, such as an iPad.
  case unsupported

  /// Not activated yet, or between watches: inactive, about to deactivate
  /// and activate again after the user switched watches.
  case activating

  /// Activated, but there's no paired watch, or it doesn't have the app.
  case noWatchApp

  /// Activated, and the watch has the app, but it isn't open or the watch
  /// is out of range.
  case watchAppNotReachable

  /// Activated, and the watch app is open and in range: a live message can
  /// reach it now.
  case watchAppReachable

  /// The state of a session on a device that supports WatchConnectivity,
  /// from its properties. `isPaired`, `isWatchAppInstalled` and
  /// `isReachable` only count once `activation` is `.activated`.
  init(
    activation: WCSessionActivationState,
    isPaired: Bool,
    isWatchAppInstalled: Bool,
    isReachable: Bool
  ) {
    switch activation {
    case .activated:
      if !isPaired || !isWatchAppInstalled {
        self = .noWatchApp
      } else if isReachable {
        self = .watchAppReachable
      } else {
        self = .watchAppNotReachable
      }
    case .notActivated, .inactive:
      self = .activating
    @unknown default:
      // Swift requires this for an enum Apple may add cases to. A state
      // added in a later iOS isn't known to be usable yet, so treat it as
      // still activating: live snapshots are dropped, and the application
      // context is held for when the session is activated.
      self = .activating
    }
  }
}

/// What to do with a live snapshot in each session state.
enum LiveSnapshotAction: Equatable {
  /// Send it with `sendMessage`.
  case send

  /// Drop it, for this reason. Live snapshots are never queued: by the time
  /// the watch could take one, a newer one will be on its way.
  case drop(WatchDeliveryOutcome)

  init(_ state: WatchSessionState) {
    switch state {
    case .unsupported:
      self = .drop(.unsupported)
    case .activating, .watchAppNotReachable:
      // Can't send until activated; dropped like any unreachable moment.
      self = .drop(.watchUnreachable)
    case .noWatchApp:
      self = .drop(.noWatchApp)
    case .watchAppReachable:
      self = .send
    }
  }
}

/// What to do with an application context in each session state.
enum ApplicationContextAction: Equatable {
  /// Set it with `updateApplicationContext`.
  case update

  /// Keep it, and set it once the session is activated, unless a newer one
  /// replaces it first.
  case hold

  /// Drop it, for this reason.
  case drop(WatchDeliveryOutcome)

  init(_ state: WatchSessionState) {
    switch state {
    case .unsupported:
      self = .drop(.unsupported)
    case .activating:
      self = .hold
    case .noWatchApp:
      self = .drop(.noWatchApp)
    case .watchAppNotReachable, .watchAppReachable:
      // The application context is for when the watch app isn't open, so
      // it doesn't need to be reachable.
      self = .update
    }
  }
}
