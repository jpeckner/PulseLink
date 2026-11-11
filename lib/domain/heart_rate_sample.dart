import 'package:freezed_annotation/freezed_annotation.dart';

part 'heart_rate_sample.freezed.dart';

/// Whether the sensor reports skin contact (Heart Rate Measurement flag bits
/// 1-2).
enum SensorContact {
  /// The sensor doesn't report contact status.
  notSupported,

  /// The sensor supports contact detection and reports no contact.
  notDetected,

  /// The sensor supports contact detection and reports contact.
  detected,
}

/// One heart-rate reading, stamped with the time it was received.
@freezed
class HeartRateSample({
  required final int bpm,
  required final DateTime timestamp,
  required final SensorContact contact,
  final List<Duration> rrIntervals = const [],
}) with _$HeartRateSample {
  /// False when the sensor reports no skin contact or a bpm of 0. Such
  /// readings must not be shown as a heart rate.
  bool get hasUsableBpm => bpm > 0 && contact != SensorContact.notDetected;
}
