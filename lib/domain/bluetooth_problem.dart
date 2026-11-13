/// Why the phone can't use Bluetooth right now. Each is an expected outcome
/// the app explains, not an error.
enum BluetoothProblem {
  /// Bluetooth is turned off.
  off,

  /// This phone can't use Bluetooth LE, or the app doesn't support it on this
  /// platform yet.
  unavailable,

  /// The user hasn't allowed the app to use Bluetooth.
  permissionDenied,
}
