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

/// Why a well-formed packet carries no trustworthy heart rate.
enum HeartRateUnavailableReason {
  /// The sensor reports no skin contact, so any bpm it sends is meaningless.
  noContact,

  /// The sensor sent a bpm of 0, meaning it has no reading.
  zeroBpm,
}

/// One packet's worth of heart-rate data, stamped with the time it arrived.
///
/// Either a [MeasuredHeartRateSample], which has a bpm safe to show and
/// record, or an [UnavailableHeartRateSample], which has none. Both mean the
/// sensor is connected and sending, so both count as fresh data. Only the
/// measured case has a `bpm` field, so code can't show an untrustworthy value
/// by mistake.
@freezed
sealed class HeartRateSample with _$HeartRateSample {
  /// A usable reading. [contact] is [SensorContact.detected] or
  /// [SensorContact.notSupported], never [SensorContact.notDetected].
  @Assert('bpm > 0', 'A measured sample needs a bpm above 0')
  @Assert(
    'contact != SensorContact.notDetected',
    'A sample without skin contact must be unavailable',
  )
  const factory measured({
    required int bpm,
    required DateTime timestamp,
    required SensorContact contact,
    @Default(<Duration>[]) List<Duration> rrIntervals,
  }) = MeasuredHeartRateSample;

  /// The sensor is sending, but has no trustworthy heart rate.
  const factory unavailable({
    required DateTime timestamp,
    required HeartRateUnavailableReason reason,
  }) = UnavailableHeartRateSample;
}
