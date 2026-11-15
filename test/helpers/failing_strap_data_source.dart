import 'dart:async';

import 'package:pulselink/data/strap_data_source.dart';
import 'package:pulselink/domain/battery_level.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

/// What [FailingStrapDataSource] throws, so tests can check it's passed on.
final strapDataSourceFailure = Exception('source failure');

/// The ways [FailingStrapDataSource] can fail. Each [description] reads as a
/// test name.
enum StrapDataSourceFailure {
  stop('stop() fails'),
  stopBeforeFuture('stop() throws before returning a future'),
  unsubscribe('unsubscribing fails'),
  unsubscribeBeforeFuture('unsubscribing throws before returning a future');

  new(this.description);

  final String description;
}

/// A source whose stop or unsubscribe fails, as a real BLE source's might.
/// Unsubscribing fails the same way for [samples] and [batteryLevel].
class FailingStrapDataSource implements StrapDataSource {
  new(this._failure)
    : _controller = StreamController(
        // Synchronous, so a sample reaches the listener as soon as [emit]
        // returns.
        sync: true,
        onCancel: _onCancel(_failure),
      ),
      _batteryLevel = StreamController(onCancel: _onCancel(_failure));

  final StrapDataSourceFailure _failure;

  // Single-subscription: unlike a broadcast stream, its cancel() returns the
  // onCancel future, so the unsubscribe failure reaches the listener.
  final StreamController<HeartRateSample> _controller;
  final StreamController<BatteryLevel?> _batteryLevel;

  static Future<void> Function()? _onCancel(StrapDataSourceFailure failure) =>
      switch (failure) {
        StrapDataSourceFailure.unsubscribe => () => Future<void>.error(
          strapDataSourceFailure,
        ),
        StrapDataSourceFailure.stop ||
        StrapDataSourceFailure.stopBeforeFuture ||
        StrapDataSourceFailure.unsubscribeBeforeFuture => null,
      };

  /// Whether anything is listening to [batteryLevel].
  bool get hasBatteryLevelListener => _batteryLevel.hasListener;

  bool get hasListener => _controller.hasListener;

  void emit(HeartRateSample sample) => _controller.add(sample);

  @override
  bool get isSimulated => false;

  @override
  Stream<HeartRateSample> get samples => _failing(_controller.stream);

  @override
  Stream<StrapConnectionFailure> get connectionLost => const Stream.empty();

  @override
  Stream<BatteryLevel?> get batteryLevel => _failing(_batteryLevel.stream);

  Stream<T> _failing<T>(Stream<T> stream) => switch (_failure) {
    StrapDataSourceFailure.unsubscribeBeforeFuture => _ThrowingCancelStream(
      stream,
    ),
    StrapDataSourceFailure.stop ||
    StrapDataSourceFailure.stopBeforeFuture ||
    StrapDataSourceFailure.unsubscribe => stream,
  };

  @override
  Future<StrapDataSourceStartResult> start() async =>
      const StrapDataSourceStartResult.started();

  @override
  Future<void> stop() => switch (_failure) {
    StrapDataSourceFailure.stop => Future.error(strapDataSourceFailure),
    StrapDataSourceFailure.stopBeforeFuture => throw strapDataSourceFailure,
    StrapDataSourceFailure.unsubscribe ||
    StrapDataSourceFailure.unsubscribeBeforeFuture => Future.value(),
  };

  @override
  Future<void> dispose() => _controller.close();
}

/// A stream whose subscriptions unsubscribe, then throw from cancel() before
/// returning a future, as a hand-written stream class could.
class _ThrowingCancelStream<T> extends Stream<T> {
  new(this._inner);

  final Stream<T> _inner;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
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

class _ThrowingCancelSubscription<T> implements StreamSubscription<T> {
  new(this._inner);

  final StreamSubscription<T> _inner;

  @override
  Future<void> cancel() {
    unawaited(_inner.cancel());
    throw strapDataSourceFailure;
  }

  @override
  void onData(void Function(T data)? handleData) => _inner.onData(handleData);

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
