import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:pulselink/data/strap_data_source.dart';
import 'package:pulselink/domain/battery_level.dart';
import 'package:pulselink/domain/beats_per_minute.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

/// Simulated heart rate for demo mode, screenshots and tests.
///
/// Debug-only: only debug and profile builds can switch to it, and release
/// builds never contain it, which the pre-merge release-binary check proves.
/// Release builds show heart rate from a real strap only.
///
/// Emits one sample per [interval]. The bpm drifts smoothly toward a target
/// that changes every so often, like effort changing during a workout, with a
/// little beat-to-beat noise, always between [minBeatsPerMinute] and
/// [maxBeatsPerMinute]. Pass a seeded [Random] for repeatable output.
class FakeStrapDataSource implements StrapDataSource {
  new({Random? random, this.interval = const Duration(seconds: 1)})
    : _random = random ?? Random();

  /// The simulated bpm range. Fixed, so there's no invalid range to pass in.
  static const minBeatsPerMinute = 55;
  static const maxBeatsPerMinute = 175;
  static const _initialBeatsPerMinute = 72.0;

  final Duration interval;

  final Random _random;
  final _controller = StreamController<HeartRateSample>.broadcast();
  final _connectionLost = StreamController<StrapConnectionFailure>.broadcast();
  final _batteryLevel = StreamController<BatteryLevel?>.broadcast();
  Timer? _timer;
  double _beatsPerMinute = _initialBeatsPerMinute;
  double _targetBeatsPerMinute = _initialBeatsPerMinute;
  int _samplesUntilNewTarget = 0;

  @override
  bool get isSimulated => true;

  @override
  Stream<HeartRateSample> get samples => _controller.stream;

  /// Never emits: simulated data can't lose a connection.
  @override
  Stream<StrapConnectionFailure> get connectionLost => _connectionLost.stream;

  /// A steady [simulatedBatteryLevel] while started, and null once stopped,
  /// so demo mode shows a battery level without hardware.
  @override
  Stream<BatteryLevel?> get batteryLevel => _batteryLevel.stream;

  /// The battery level demo mode shows.
  static final BatteryLevel? simulatedBatteryLevel = BatteryLevel.tryFrom(80);

  /// Starts at once, so it's never still starting when [stop] is called.
  /// After [dispose], it does nothing and completes with
  /// [StrapDataSourceStartCancelled].
  @override
  Future<StrapDataSourceStartResult> start() async {
    if (_controller.isClosed) {
      return const StrapDataSourceStartResult.cancelled();
    }
    if (_timer == null) {
      _timer = Timer.periodic(interval, (_) => _emitSample());
      _batteryLevel.add(simulatedBatteryLevel);
    }
    return const StrapDataSourceStartResult.started();
  }

  @override
  Future<void> stop() async {
    if (_timer case final timer?) {
      timer.cancel();
      _timer = null;
      _batteryLevel.add(null);
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
    await _connectionLost.close();
    await _batteryLevel.close();
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
