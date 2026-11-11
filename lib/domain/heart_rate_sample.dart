import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/domain/positive_int.dart';

part 'heart_rate_sample.freezed.dart';

/// Skin-contact status of a measured sample. There's no "no contact" value:
/// a packet reporting no contact becomes an [UnavailableHeartRateSample].
enum MeasuredContact {
  /// The sensor detects skin contact.
  detected,

  /// The sensor doesn't support contact detection, so it can't say.
  notReported,
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
  /// A usable reading.
  const factory measured({
    required PositiveInt bpm,
    required DateTime timestamp,
    required MeasuredContact contact,
    @Default(<Duration>[]) List<Duration> rrIntervals,
  }) = MeasuredHeartRateSample;

  /// The sensor is sending, but has no trustworthy heart rate.
  const factory unavailable({
    required DateTime timestamp,
    required HeartRateUnavailableReason reason,
  }) = UnavailableHeartRateSample;
}
