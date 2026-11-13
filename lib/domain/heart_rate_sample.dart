import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/domain/beats_per_minute.dart';

part 'heart_rate_sample.freezed.dart';

/// Whether a measured sample's strap is touching the wearer's skin. This is
/// about skin contact only, never Bluetooth connectivity. There's no "no skin
/// contact" value: a packet reporting no skin contact becomes an
/// [UnavailableHeartRateSample].
enum SkinContact {
  /// The strap detects skin contact.
  detected,

  /// The strap can't detect skin contact, so it can't say either way.
  notSupported,
}

/// Why a well-formed packet carries no trustworthy heart rate.
enum HeartRateUnavailableReason {
  /// The strap reports no skin contact, so any bpm it sends is meaningless.
  noSkinContact,

  /// The sensor sent a bpm of 0, meaning it has no reading.
  zeroBeatsPerMinute,

  /// The sensor sent a bpm above [BeatsPerMinute.max], which is almost
  /// certainly a corrupt packet or a sensor fault rather than a heartbeat.
  implausibleBeatsPerMinute,
}

/// One packet's worth of heart-rate data, stamped with the time it arrived.
///
/// Either a [MeasuredHeartRateSample], which has a bpm safe to show and
/// record, or an [UnavailableHeartRateSample], which has none. Both mean the
/// sensor is connected and sending, so both count as fresh data. Only the
/// measured case has a `beatsPerMinute` field, so code can't show an
/// untrustworthy value by mistake.
@freezed
sealed class HeartRateSample with _$HeartRateSample {
  /// A usable reading.
  const factory measured({
    required BeatsPerMinute beatsPerMinute,
    required DateTime timestamp,
    required SkinContact skinContact,
    @Default(<Duration>[]) List<Duration> rrIntervals,
  }) = MeasuredHeartRateSample;

  /// The sensor is sending, but has no trustworthy heart rate.
  const factory unavailable({
    required DateTime timestamp,
    required HeartRateUnavailableReason reason,
  }) = UnavailableHeartRateSample;
}
