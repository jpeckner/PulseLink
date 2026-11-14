import 'dart:async';

import 'package:pulselink/data/heart_rate_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

/// A [HeartRateSource] that passes on whichever source is current: demo data
/// at launch, then a strap once one is picked. Everything above it keeps the
/// same source for the app's life, including the debug override in debug
/// builds, which therefore works on real strap data too.
///
/// It owns the current source, and disposes it when switching away or when
/// it's disposed itself.
class SwitchableHeartRateSource implements HeartRateSource {
  new(HeartRateSource initial) : _current = initial {
    _forwarding = initial.samples.listen(_samples.add);
  }

  HeartRateSource _current;
  final _samples = StreamController<HeartRateSample>.broadcast();
  // No onError where it's set: HeartRateSource.samples never carries errors.
  StreamSubscription<HeartRateSample>? _forwarding;
  bool _isDisposed = false;

  /// Whether the current source is simulated. It changes when [switchTo]
  /// switches between demo data and a strap.
  @override
  bool get isSimulated => _current.isSimulated;

  /// Samples from the current source only. A broadcast stream that stays
  /// open across switches, and closes on [dispose].
  @override
  Stream<HeartRateSample> get samples => _samples.stream;

  /// Starts the current source. After [dispose], completes with
  /// [HeartRateSourceStartCancelled] at once.
  @override
  Future<HeartRateSourceStartResult> start() =>
      _isDisposed ? Future.value(const .cancelled()) : _current.start();

  @override
  Future<void> stop() => _current.stop();

  /// Makes [next] the current source, and disposes the previous one, which
  /// cancels a start still in progress on it. [next] isn't started: callers
  /// start it, such as with `LiveHeartRateCubit.restart()`.
  ///
  /// After [dispose], it disposes [next] instead, since this owns it.
  Future<void> switchTo(HeartRateSource next) async {
    if (_isDisposed) {
      await next.dispose();
      return;
    }
    final previous = _current;
    // Cancelled and replaced before awaiting, so no sample from the previous
    // source is passed on after this call.
    final cancelling = _forwarding?.cancel();
    _current = next;
    _forwarding = next.samples.listen(_samples.add);
    try {
      await cancelling;
    } finally {
      // Dispose even if unsubscribing failed; the error still reaches the
      // caller.
      await previous.dispose();
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    try {
      final cancelling = _forwarding?.cancel();
      _forwarding = null;
      try {
        await cancelling;
      } finally {
        await _current.dispose();
      }
    } finally {
      // Close even if disposing failed; the error still reaches the caller.
      await _samples.close();
    }
  }
}
