import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';

part 'strap_connection_failure.freezed.dart';

/// Why the app couldn't get heart-rate data from a strap. Each is an expected
/// outcome that the screen explains, not an error.
@freezed
sealed class StrapConnectionFailure with _$StrapConnectionFailure {
  /// The phone can't use Bluetooth, for the reason in [problem].
  const factory bluetooth(BluetoothProblem problem) = BluetoothFailure;

  /// The strap couldn't be reached: it's off, out of range, or connected to
  /// another app.
  const factory strapUnreachable() = StrapUnreachable;

  /// The device doesn't offer the standard Heart Rate Service, so it isn't a
  /// heart-rate strap.
  const factory notAHeartRateStrap() = NotAHeartRateStrap;

  /// The strap was connected, then dropped: it went out of range, was
  /// switched off, or ran out of battery.
  const factory connectionLost() = StrapConnectionLost;
}
