import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:pulselink/data/heart_rate_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

/// Simulated heart rate for demo mode, screenshots and tests.
///
/// Emits one sample per [interval]. The bpm drifts smoothly toward a target
/// that changes every so often, like effort changing during a workout, with a
/// little beat-to-beat noise. Pass a seeded [Random] for repeatable output.
class FakeHeartRateSource implements HeartRateSource {
  new({
    Random? random,
    this.interval = const Duration(seconds: 1),
    this.minBpm = 55,
    this.maxBpm = 175,
    double initialBpm = 72,
  }) : _random = random ?? Random(),
       _bpm = initialBpm,
       _targetBpm = initialBpm;

  final Duration interval;
  final int minBpm;
  final int maxBpm;

  final Random _random;
  final _controller = StreamController<HeartRateSample>.broadcast();
  Timer? _timer;
  double _bpm;
  double _targetBpm;
  int _samplesUntilNewTarget = 0;

  @override
  bool get isSimulated => true;

  @override
  Stream<HeartRateSample> get samples => _controller.stream;

  @override
  Future<void> start() async {
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
      _targetBpm = minBpm + _random.nextDouble() * (maxBpm - minBpm);
      _samplesUntilNewTarget = 20 + _random.nextInt(40);
    }
    _samplesUntilNewTarget--;

    final noise = (_random.nextDouble() - 0.5) * 3;
    _bpm = (_bpm + (_targetBpm - _bpm) * 0.08 + noise).clamp(
      minBpm.toDouble(),
      maxBpm.toDouble(),
    );

    final bpm = _bpm.round();
    _controller.add(
      HeartRateSample(
        bpm: bpm,
        timestamp: clock.now(),
        contact: SensorContact.detected,
        rrIntervals: [Duration(microseconds: (60000000 / bpm).round())],
      ),
    );
  }
}
