import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:pulselink/data/heart_rate_source.dart';
import 'package:pulselink/domain/beats_per_minute.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

/// Simulated heart rate for demo mode, screenshots and tests.
///
/// Emits one sample per [interval]. The bpm drifts smoothly toward a target
/// that changes every so often, like effort changing during a workout, with a
/// little beat-to-beat noise, always between [minBeatsPerMinute] and
/// [maxBeatsPerMinute]. Pass a seeded [Random] for repeatable output.
class FakeHeartRateSource implements HeartRateSource {
  new({Random? random, this.interval = const Duration(seconds: 1)})
    : _random = random ?? Random();

  /// The simulated bpm range. Fixed, so there's no invalid range to pass in.
  static const minBeatsPerMinute = 55;
  static const maxBeatsPerMinute = 175;
  static const _initialBeatsPerMinute = 72.0;

  final Duration interval;

  final Random _random;
  final _controller = StreamController<HeartRateSample>.broadcast();
  Timer? _timer;
  double _beatsPerMinute = _initialBeatsPerMinute;
  double _targetBeatsPerMinute = _initialBeatsPerMinute;
  int _samplesUntilNewTarget = 0;

  @override
  bool get isSimulated => true;

  @override
  Stream<HeartRateSample> get samples => _controller.stream;

  /// Does nothing after [dispose].
  @override
  Future<void> start() async {
    if (_controller.isClosed) {
      return;
    }
    _timer ??= Timer.periodic(interval, (_) => _emitSample());
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  void _emitSample() {
    if (_samplesUntilNewTarget <= 0) {
      _targetBeatsPerMinute =
          minBeatsPerMinute +
          _random.nextDouble() * (maxBeatsPerMinute - minBeatsPerMinute);
      _samplesUntilNewTarget = 20 + _random.nextInt(40);
    }
    _samplesUntilNewTarget--;

    final noise = (_random.nextDouble() - 0.5) * 3;
    _beatsPerMinute =
        (_beatsPerMinute +
                (_targetBeatsPerMinute - _beatsPerMinute) * 0.08 +
                noise)
            .clamp(minBeatsPerMinute.toDouble(), maxBeatsPerMinute.toDouble());

    final now = clock.now();
    _controller.add(switch (BeatsPerMinute.tryFrom(_beatsPerMinute.round())) {
      final beatsPerMinute? => HeartRateSample.measured(
        beatsPerMinute: beatsPerMinute,
        timestamp: now,
        skinContact: SkinContact.detected,
        rrIntervals: [
          Duration(microseconds: (60000000 / beatsPerMinute.value).round()),
        ],
      ),
      // Unreachable while minBeatsPerMinute and maxBeatsPerMinute are within
      // BeatsPerMinute's range, but if the math ever left it, the screen says
      // so rather than show a wrong number.
      null => HeartRateSample.unavailable(
        timestamp: now,
        reason: HeartRateUnavailableReason.implausibleBeatsPerMinute,
      ),
    });
  }
}
