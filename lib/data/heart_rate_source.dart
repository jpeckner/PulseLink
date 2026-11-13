import 'package:pulselink/domain/heart_rate_sample.dart';

/// Where heart-rate samples come from: a BLE strap, or a simulator for demo
/// mode and tests. Everything above the data layer depends only on this.
abstract interface class HeartRateSource {
  /// True when samples are simulated, so the UI can label them as such.
  bool get isSimulated;

  /// Samples as they arrive. A broadcast stream; it stays open across
  /// [start]/[stop] cycles and closes on [dispose].
  ///
  /// Never carries errors. A missing heart rate arrives as an unavailable
  /// sample; any other failure is reported as a typed result, never as a
  /// stream error, so listeners need no error handler.
  Stream<HeartRateSample> get samples;

  /// Starts producing samples. Calling it while already started does nothing.
  Future<void> start();

  /// Stops producing samples. Calling it while stopped does nothing.
  Future<void> stop();

  /// Releases resources. The source can't be used afterwards.
  Future<void> dispose();
}
