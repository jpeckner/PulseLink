import 'dart:async';

import 'package:pulselink/data/strap_data_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

/// A [StrapDataSource] that passes on whichever source is current: demo data
/// at launch, then a strap once one is picked. Everything above it keeps the
/// same source for the app's life, including the debug override in debug
/// builds, which therefore works on real strap data too.
///
/// It owns the current source, and disposes it when switching away or when
/// it's disposed itself.
class SwitchableStrapDataSource implements StrapDataSource {
  new(StrapDataSource initial) : _current = initial {
    _forwarding = initial.samples.listen(_samples.add);
    _forwardingLost = initial.connectionLost.listen(_connectionLost.add);
  }

  StrapDataSource _current;
  final _samples = StreamController<HeartRateSample>.broadcast();
  final _connectionLost = StreamController<StrapConnectionFailure>.broadcast();
  // No onError where these are set: neither of a source's streams carries
  // errors.
  StreamSubscription<HeartRateSample>? _forwarding;
  StreamSubscription<StrapConnectionFailure>? _forwardingLost;
  bool _isDisposed = false;

  /// Whether the current source is simulated. It changes when [switchTo]
  /// switches between demo data and a strap.
  @override
  bool get isSimulated => _current.isSimulated;

  /// Samples from the current source only. A broadcast stream that stays
  /// open across switches, and closes on [dispose].
  @override
  Stream<HeartRateSample> get samples => _samples.stream;

  /// Lost connections from the current source only. Stays open across
  /// switches, and closes on [dispose].
  @override
  Stream<StrapConnectionFailure> get connectionLost => _connectionLost.stream;

  /// Starts the current source. After [dispose], completes with
  /// [StrapDataSourceStartCancelled] at once.
  @override
  Future<StrapDataSourceStartResult> start() =>
      _isDisposed ? Future.value(const .cancelled()) : _current.start();

  @override
  Future<void> stop() => _current.stop();

  /// Makes [next] the current source, and disposes the previous one, which
  /// cancels a start still in progress on it. [next] isn't started: callers
  /// start it, such as with `LiveHeartRateCubit.restart()`.
  ///
  /// After [dispose], it disposes [next] instead, since this owns it.
  Future<void> switchTo(StrapDataSource next) async {
    if (_isDisposed) {
      await next.dispose();
      return;
    }
    final previous = _current;
    // Cancelled and replaced before awaiting, so nothing from the previous
    // source is passed on after this call.
    final cancelling = [?_forwarding?.cancel(), ?_forwardingLost?.cancel()];
    _current = next;
    _forwarding = next.samples.listen(_samples.add);
    _forwardingLost = next.connectionLost.listen(_connectionLost.add);
    try {
      // Waits for both, even if one fails.
      await Future.wait(cancelling);
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
      final cancelling = [?_forwarding?.cancel(), ?_forwardingLost?.cancel()];
      _forwarding = null;
      _forwardingLost = null;
      try {
        await Future.wait(cancelling);
      } finally {
        await _current.dispose();
      }
    } finally {
      // Close even if disposing failed; the error still reaches the caller.
      await _samples.close();
      await _connectionLost.close();
    }
  }
}
