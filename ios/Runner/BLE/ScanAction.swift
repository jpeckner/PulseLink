// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import CoreBluetooth

/// What a scan does in each Bluetooth state.
enum ScanAction: Equatable {
  /// Bluetooth is ready: scan.
  case scan
  /// Bluetooth can't be used, for this reason.
  case fail(BleScanFailureReason)
  /// Bluetooth is about to change state; the change will say what to do.
  case wait

  init(_ state: CBManagerState) {
    switch state {
    case .poweredOn:
      self = .scan
    case .poweredOff:
      self = .fail(.poweredOff)
    case .unauthorized:
      self = .fail(.unauthorized)
    case .unsupported:
      self = .fail(.unsupported)
    case .unknown, .resetting:
      self = .wait
    @unknown default:
      // Swift requires this for an enum Apple may add cases to. A state
      // added in a later iOS can't be acted on, so wait for the next one.
      self = .wait
    }
  }
}
