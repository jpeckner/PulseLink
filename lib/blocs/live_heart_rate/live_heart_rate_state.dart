import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

part 'live_heart_rate_state.freezed.dart';

/// What the live heart-rate screen shows.
@freezed
sealed class LiveHeartRateState with _$LiveHeartRateState {
  /// No sample has arrived yet.
  const factory waiting({required bool isSimulated}) = LiveHeartRateWaiting;

  /// The latest sample. [isStale] is true once it's older than the stale
  /// threshold, and the UI must then not present it as current.
  const factory reading({
    required HeartRateSample sample,
    required bool isStale,
    required bool isSimulated,
  }) = LiveHeartRateReading;
}
