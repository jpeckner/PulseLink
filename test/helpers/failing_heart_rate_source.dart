import 'dart:async';

import 'package:pulselink/data/heart_rate_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

/// What [FailingHeartRateSource] throws, so tests can check it's passed on.
final heartRateSourceFailure = Exception('source failure');

/// The ways [FailingHeartRateSource] can fail. Each [description] reads as a
/// test name.
enum HeartRateSourceFailure {
  stop('stop() fails'),
  stopBeforeFuture('stop() throws before returning a future'),
  unsubscribe('unsubscribing fails'),
  unsubscribeBeforeFuture('unsubscribing throws before returning a future');

  new(this.description);

  final String description;
}

/// A source whose stop or unsubscribe fails, as a real BLE source's might.
class FailingHeartRateSource implements HeartRateSource {
  new(this._failure)
    : _controller = StreamController(
        // Synchronous, so a sample reaches the listener as soon as [emit]
        // returns.
        sync: true,
        onCancel: switch (_failure) {
          HeartRateSourceFailure.unsubscribe => () => Future<void>.error(
            heartRateSourceFailure,
          ),
          HeartRateSourceFailure.stop ||
          HeartRateSourceFailure.stopBeforeFuture ||
          HeartRateSourceFailure.unsubscribeBeforeFuture => null,
        },
      );

  final HeartRateSourceFailure _failure;

  // Single-subscription: unlike a broadcast stream, its cancel() returns the
  // onCancel future, so the unsubscribe failure reaches the listener.
  final StreamController<HeartRateSample> _controller;

  bool get hasListener => _controller.hasListener;

  void emit(HeartRateSample sample) => _controller.add(sample);

  @override
  bool get isSimulated => false;

  @override
  Stream<HeartRateSample> get samples => switch (_failure) {
    HeartRateSourceFailure.unsubscribeBeforeFuture => _ThrowingCancelStream(
      _controller.stream,
    ),
    HeartRateSourceFailure.stop ||
    HeartRateSourceFailure.stopBeforeFuture ||
    HeartRateSourceFailure.unsubscribe => _controller.stream,
  };

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() => switch (_failure) {
    HeartRateSourceFailure.stop => Future.error(heartRateSourceFailure),
    HeartRateSourceFailure.stopBeforeFuture => throw heartRateSourceFailure,
    HeartRateSourceFailure.unsubscribe ||
    HeartRateSourceFailure.unsubscribeBeforeFuture => Future.value(),
  };

  @override
  Future<void> dispose() => _controller.close();
}

/// A stream whose subscriptions unsubscribe, then throw from cancel() before
/// returning a future, as a hand-written stream class could.
class _ThrowingCancelStream extends Stream<HeartRateSample> {
  new(this._inner);

  final Stream<HeartRateSample> _inner;

  @override
  StreamSubscription<HeartRateSample> listen(
    void Function(HeartRateSample event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _ThrowingCancelSubscription(
    _inner.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    ),
  );
}

class _ThrowingCancelSubscription
    implements StreamSubscription<HeartRateSample> {
  new(this._inner);

  final StreamSubscription<HeartRateSample> _inner;

  @override
  Future<void> cancel() {
    unawaited(_inner.cancel());
    throw heartRateSourceFailure;
  }

  @override
  void onData(void Function(HeartRateSample data)? handleData) =>
      _inner.onData(handleData);

  @override
  void onError(Function? handleError) => _inner.onError(handleError);

  @override
  void onDone(void Function()? handleDone) => _inner.onDone(handleDone);

  @override
  void pause([Future<void>? resumeSignal]) => _inner.pause(resumeSignal);

  @override
  void resume() => _inner.resume();

  @override
  bool get isPaused => _inner.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => _inner.asFuture(futureValue);
}
