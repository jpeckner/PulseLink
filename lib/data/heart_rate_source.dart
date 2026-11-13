import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

part 'heart_rate_source.freezed.dart';

/// How a call to [HeartRateSource.start] ended.
@freezed
sealed class HeartRateSourceStartResult with _$HeartRateSourceStartResult {
  /// The source is producing samples.
  const factory started() = HeartRateSourceStarted;

  /// [HeartRateSource.stop] or [HeartRateSource.dispose] was called before
  /// starting finished, so the source isn't producing samples. Nothing went
  /// wrong, so there's nothing to show.
  const factory cancelled() = HeartRateSourceStartCancelled;

  /// The source couldn't start, for an expected reason such as Bluetooth
  /// being off.
  const factory failed(StrapConnectionFailure failure) =
      HeartRateSourceStartFailed;
}

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

  /// Starts producing samples, and completes once the source is producing
  /// them or has failed to. Calling it while already started completes with
  /// [HeartRateSourceStarted] at once. Calling it while a start is still in
  /// progress joins that start: both calls complete with the same result,
  /// and the source makes only one attempt.
  ///
  /// Expected failures, such as Bluetooth being off, complete with
  /// [HeartRateSourceStartFailed]; they never throw.
  ///
  /// Calling [stop] or [dispose] before this completes cancels it: it then
  /// completes with [HeartRateSourceStartCancelled], and the source produces
  /// no samples. A real strap can take seconds to connect, so a caller that
  /// gives up (such as a screen being closed) must be able to stop it
  /// without leaving a connection running that nothing owns. After [dispose],
  /// it completes with [HeartRateSourceStartCancelled] at once.
  Future<HeartRateSourceStartResult> start();

  /// Stops producing samples, cancelling a [start] still in progress.
  /// Calling it while stopped does nothing.
  Future<void> stop();

  /// Releases resources, cancelling a [start] still in progress. The source
  /// can't be used afterwards.
  Future<void> dispose();
}
