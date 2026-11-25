// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import CoreBluetooth

/// What a connection attempt does in each Bluetooth state.
enum ConnectAction: Equatable {
  /// Bluetooth is ready: connect.
  case connect
  /// Bluetooth can't be used, for this reason.
  case fail(BleConnectFailureReason)
  /// Bluetooth is about to change state; the change will say what to do.
  case wait
  /// Bluetooth is restarting. iOS drops every connection without calling
  /// the disconnect callback, and the strap it gave before is no longer
  /// valid. The state it settles in says what to do next.
  case reset

  init(_ state: CBManagerState) {
    switch state {
    case .poweredOn:
      self = .connect
    case .poweredOff:
      self = .fail(.poweredOff)
    case .unauthorized:
      self = .fail(.unauthorized)
    case .unsupported:
      self = .fail(.unsupported)
    case .unknown:
      self = .wait
    case .resetting:
      self = .reset
    @unknown default:
      // Swift requires this for an enum Apple may add cases to. A state
      // added in a later iOS can't be acted on, so wait for the next one.
      self = .wait
    }
  }

  /// Whether a strap that's connected in this state has been dropped, with
  /// no disconnect callback to say so.
  var dropsConnection: Bool {
    switch self {
    case .connect, .wait:
      false
    case .fail, .reset:
      true
    }
  }
}
