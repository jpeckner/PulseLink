import 'package:pulselink/data/heart_rate_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

/// How [DebugOverrideHeartRateSource] rewrites incoming samples.
enum ReadingOverride {
  /// Pass samples through unchanged.
  normal,

  /// Drop every sample, as if no data were arriving from the strap, so the
  /// reading goes stale after the stale threshold.
  stale,

  /// Replace each sample with an unavailable one: no skin contact.
  noSkinContact,

  /// Replace each sample with an unavailable one: bpm 0.
  zeroBpm;

  /// The next override in the cycle, wrapping back to [normal].
  ReadingOverride get next => switch (this) {
    normal => stale,
    stale => noSkinContact,
    noSkinContact => zeroBpm,
    zeroBpm => normal,
  };
}

/// Debug and profile builds only. Wraps any [HeartRateSource], real or fake,
/// and rewrites its samples according to [mode], so stale and unavailable
/// states can be shown on demand.
class DebugOverrideHeartRateSource implements HeartRateSource {
  new(this._inner);

  final HeartRateSource _inner;

  /// Applied to each sample as it arrives.
  ReadingOverride mode = ReadingOverride.normal;

  @override
  bool get isSimulated => _inner.isSimulated;

  @override
  Stream<HeartRateSample> get samples => _inner.samples.expand(_apply);

  @override
  Future<void> start() => _inner.start();

  @override
  Future<void> stop() => _inner.stop();

  @override
  Future<void> dispose() => _inner.dispose();

  Iterable<HeartRateSample> _apply(HeartRateSample sample) => switch (mode) {
    ReadingOverride.normal => [sample],
    ReadingOverride.stale => const [],
    ReadingOverride.noSkinContact => [
      HeartRateSample.unavailable(
        timestamp: sample.timestamp,
        reason: HeartRateUnavailableReason.noSkinContact,
      ),
    ],
    ReadingOverride.zeroBpm => [
      HeartRateSample.unavailable(
        timestamp: sample.timestamp,
        reason: HeartRateUnavailableReason.zeroBpm,
      ),
    ],
  };
}
