import CoreBluetooth

/// What a connection attempt does in each Bluetooth state.
enum ConnectAction: Equatable {
  /// Bluetooth is ready: connect.
  case connect
  /// Bluetooth can't be used, for this reason.
  case fail(BleConnectFailureReason)
  /// Bluetooth is about to change state; the change will say what to do.
  case wait

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
    case .unknown, .resetting:
      self = .wait
    @unknown default:
      // Swift requires this for an enum Apple may add cases to. A state
      // added in a later iOS can't be acted on, so wait for the next one.
      self = .wait
    }
  }
}
