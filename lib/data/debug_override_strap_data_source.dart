import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/data/strap_data_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

part 'debug_override_strap_data_source.freezed.dart';

/// Whether a strap can detect skin contact. A property of the strap, not of
/// any one reading.
enum SkinContactDetection { supported, notSupported }

/// Conditions to simulate on a strap that can detect skin contact.
enum DetectingStrapCondition {
  /// Readings arrive as usual, with skin contact detected.
  normal,

  /// Drop every reading, as if no data were arriving from the strap, so the
  /// reading goes stale after the stale threshold.
  stale,

  /// The strap reports no skin contact.
  noSkinContact,

  /// The strap reports a bpm of 0.
  zeroBeatsPerMinute,

  /// The strap reports a bpm too high to be a heartbeat.
  implausibleBeatsPerMinute;

  /// The next condition, wrapping back to [normal].
  DetectingStrapCondition get next => switch (this) {
    normal => stale,
    stale => noSkinContact,
    noSkinContact => zeroBeatsPerMinute,
    zeroBeatsPerMinute => implausibleBeatsPerMinute,
    implausibleBeatsPerMinute => normal,
  };
}

/// Conditions to simulate on a strap that can't detect skin contact. There's
/// no "no skin contact": such a strap can't report it.
enum NonDetectingStrapCondition {
  /// Readings arrive as usual, with no skin-contact information.
  normal,

  /// Drop every reading, as if no data were arriving from the strap.
  stale,

  /// The strap reports a bpm of 0.
  zeroBeatsPerMinute,

  /// The strap reports a bpm too high to be a heartbeat.
  implausibleBeatsPerMinute;

  /// The next condition, wrapping back to [normal].
  NonDetectingStrapCondition get next => switch (this) {
    normal => stale,
    stale => zeroBeatsPerMinute,
    zeroBeatsPerMinute => implausibleBeatsPerMinute,
    implausibleBeatsPerMinute => normal,
  };
}

/// What [DebugOverrideStrapDataSource] simulates: a kind of strap, and a
/// condition that kind of strap can actually be in. Impossible combinations,
/// such as "no skin contact" on a strap that can't detect it, can't be built.
@freezed
sealed class ReadingOverride with _$ReadingOverride {
  const factory detectingStrap(DetectingStrapCondition condition) =
      DetectingStrapOverride;

  const factory nonDetectingStrap(NonDetectingStrapCondition condition) =
      NonDetectingStrapOverride;
}

/// Moves between overrides, for the debug buttons.
extension ReadingOverrideControls on ReadingOverride {
  SkinContactDetection get detection => switch (this) {
    DetectingStrapOverride() => SkinContactDetection.supported,
    NonDetectingStrapOverride() => SkinContactDetection.notSupported,
  };

  /// The same kind of strap, in its next condition.
  ReadingOverride get withNextCondition => switch (this) {
    DetectingStrapOverride(:final condition) => ReadingOverride.detectingStrap(
      condition.next,
    ),
    NonDetectingStrapOverride(:final condition) =>
      ReadingOverride.nonDetectingStrap(condition.next),
  };

  /// The other kind of strap. The condition carries over where that strap can
  /// be in it; otherwise it becomes normal.
  ReadingOverride get withOtherDetection => switch (this) {
    DetectingStrapOverride(:final condition) =>
      ReadingOverride.nonDetectingStrap(switch (condition) {
        DetectingStrapCondition.normal => NonDetectingStrapCondition.normal,
        DetectingStrapCondition.stale => NonDetectingStrapCondition.stale,
        DetectingStrapCondition.noSkinContact =>
          NonDetectingStrapCondition.normal,
        DetectingStrapCondition.zeroBeatsPerMinute =>
          NonDetectingStrapCondition.zeroBeatsPerMinute,
        DetectingStrapCondition.implausibleBeatsPerMinute =>
          NonDetectingStrapCondition.implausibleBeatsPerMinute,
      }),
    NonDetectingStrapOverride(:final condition) =>
      ReadingOverride.detectingStrap(switch (condition) {
        NonDetectingStrapCondition.normal => DetectingStrapCondition.normal,
        NonDetectingStrapCondition.stale => DetectingStrapCondition.stale,
        NonDetectingStrapCondition.zeroBeatsPerMinute =>
          DetectingStrapCondition.zeroBeatsPerMinute,
        NonDetectingStrapCondition.implausibleBeatsPerMinute =>
          DetectingStrapCondition.implausibleBeatsPerMinute,
      }),
  };
}

/// Debug and profile builds only. Wraps any [StrapDataSource], real or fake,
/// and rewrites its samples according to [readingOverride], so each strap
/// condition can be shown on demand.
class DebugOverrideStrapDataSource implements StrapDataSource {
  new(this._inner);

  final StrapDataSource _inner;
  SkinContactDetection? _reportedDetection;

  /// Applied to each sample as it arrives. Null passes samples through
  /// untouched.
  ReadingOverride? readingOverride;

  /// Whether the strap itself last indicated it can detect skin contact, or
  /// null if it hasn't said yet. Tracked from the incoming samples, before
  /// any override.
  SkinContactDetection? get reportedDetection => _reportedDetection;

  @override
  bool get isSimulated => _inner.isSimulated;

  @override
  Stream<HeartRateSample> get samples => _inner.samples.expand(_apply);

  @override
  Stream<StrapConnectionFailure> get connectionLost => _inner.connectionLost;

  @override
  Future<StrapDataSourceStartResult> start() => _inner.start();

  @override
  Future<void> stop() => _inner.stop();

  @override
  Future<void> dispose() => _inner.dispose();

  Iterable<HeartRateSample> _apply(HeartRateSample sample) {
    _noteReportedDetection(sample);
    return switch (readingOverride) {
      null => [sample],
      DetectingStrapOverride(:final condition) => switch (condition) {
        DetectingStrapCondition.normal => [_asDetectingStrap(sample)],
        DetectingStrapCondition.stale => const [],
        DetectingStrapCondition.noSkinContact => [
          _unavailable(sample, HeartRateUnavailableReason.noSkinContact),
        ],
        DetectingStrapCondition.zeroBeatsPerMinute => [
          _unavailable(sample, HeartRateUnavailableReason.zeroBeatsPerMinute),
        ],
        DetectingStrapCondition.implausibleBeatsPerMinute => [
          _unavailable(
            sample,
            HeartRateUnavailableReason.implausibleBeatsPerMinute,
          ),
        ],
      },
      NonDetectingStrapOverride(:final condition) => switch (condition) {
        NonDetectingStrapCondition.normal => [_asNonDetectingStrap(sample)],
        NonDetectingStrapCondition.stale => const [],
        NonDetectingStrapCondition.zeroBeatsPerMinute => [
          _unavailable(sample, HeartRateUnavailableReason.zeroBeatsPerMinute),
        ],
        NonDetectingStrapCondition.implausibleBeatsPerMinute => [
          _unavailable(
            sample,
            HeartRateUnavailableReason.implausibleBeatsPerMinute,
          ),
        ],
      },
    };
  }

  void _noteReportedDetection(HeartRateSample sample) {
    final detection = switch (sample) {
      MeasuredHeartRateSample(skinContact: SkinContact.detected) =>
        SkinContactDetection.supported,
      MeasuredHeartRateSample(skinContact: SkinContact.notSupported) =>
        SkinContactDetection.notSupported,
      // Only a strap that can detect skin contact can report its absence.
      UnavailableHeartRateSample(
        reason: HeartRateUnavailableReason.noSkinContact,
      ) =>
        SkinContactDetection.supported,
      // A bpm of 0, or one too high to be real, says nothing about
      // skin-contact detection.
      UnavailableHeartRateSample(
        reason: HeartRateUnavailableReason.zeroBeatsPerMinute ||
            HeartRateUnavailableReason.implausibleBeatsPerMinute,
      ) =>
        null,
    };
    _reportedDetection = detection ?? _reportedDetection;
  }

  static HeartRateSample _asDetectingStrap(HeartRateSample sample) =>
      switch (sample) {
        final MeasuredHeartRateSample measured => measured.copyWith(
          skinContact: SkinContact.detected,
        ),
        UnavailableHeartRateSample() => sample,
      };

  static HeartRateSample _asNonDetectingStrap(HeartRateSample sample) =>
      switch (sample) {
        final MeasuredHeartRateSample measured => measured.copyWith(
          skinContact: SkinContact.notSupported,
        ),
        // A strap that can't detect skin contact can't report its absence;
        // without a heart rate it reports bpm 0 instead.
        UnavailableHeartRateSample(
          reason: HeartRateUnavailableReason.noSkinContact,
        ) =>
          _unavailable(sample, HeartRateUnavailableReason.zeroBeatsPerMinute),
        UnavailableHeartRateSample(
          reason: HeartRateUnavailableReason.zeroBeatsPerMinute ||
              HeartRateUnavailableReason.implausibleBeatsPerMinute,
        ) =>
          sample,
      };

  static HeartRateSample _unavailable(
    HeartRateSample sample,
    HeartRateUnavailableReason reason,
  ) => HeartRateSample.unavailable(timestamp: sample.timestamp, reason: reason);
}
