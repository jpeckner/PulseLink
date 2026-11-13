/// Why the app couldn't get heart-rate data from a strap. Each is an expected
/// outcome that the screen explains, not an error.
enum StrapConnectionFailure {
  /// Bluetooth is turned off.
  bluetoothOff,

  /// This phone can't use Bluetooth LE, or the app doesn't support it on this
  /// platform yet.
  bluetoothUnavailable,

  /// The user hasn't allowed the app to use Bluetooth.
  bluetoothPermissionDenied,

  /// The strap couldn't be reached: it's off, out of range, or connected to
  /// another app.
  strapUnreachable,

  /// The device doesn't offer the standard Heart Rate Service, so it isn't a
  /// heart-rate strap.
  notAHeartRateStrap,
}
