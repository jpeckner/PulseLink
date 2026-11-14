import 'dart:async';

import 'package:pulselink/data/strap_data_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

/// A [StrapDataSource] that tests drive by hand with [emit], and that records
/// how it was used.
class StubStrapDataSource implements StrapDataSource {
  new({this.isSimulated = false});

  @override
  final bool isSimulated;

  // Synchronous, so a sample reaches listeners as soon as [emit] returns.
  final _controller = StreamController<HeartRateSample>.broadcast(sync: true);
  final _connectionLost = StreamController<StrapConnectionFailure>.broadcast(
    sync: true,
  );

  int startCount = 0;
  int stopCount = 0;
  bool isDisposed = false;

  /// When set, [dispose] fails with this error, after closing [samples].
  Exception? disposeError;

  /// What [start] completes with.
  StrapDataSourceStartResult startResult =
      const StrapDataSourceStartResult.started();

  /// When true, [start] doesn't complete until [finishStart] is called, or
  /// until [stop] or [dispose] cancels it, as the [StrapDataSource] contract
  /// requires. Lets tests act while a start is in progress, as with a real
  /// strap that takes seconds to connect.
  bool holdStart = false;

  Completer<StrapDataSourceStartResult>? _pendingStart;

  /// Whether a held [start] is still in progress.
  bool get isStarting => _pendingStart != null;

  bool get hasListener => _controller.hasListener;

  bool get hasConnectionLostListener => _connectionLost.hasListener;

  void emit(HeartRateSample sample) => _controller.add(sample);

  /// Reports a lost connection, as a strap going out of range would.
  void loseConnection(StrapConnectionFailure failure) =>
      _connectionLost.add(failure);

  /// Completes a held [start] with [startResult].
  void finishStart() => _completePendingStart(startResult);

  @override
  Stream<HeartRateSample> get samples => _controller.stream;

  @override
  Stream<StrapConnectionFailure> get connectionLost => _connectionLost.stream;

  /// Counts each call, including ones that join a held start in progress.
  @override
  Future<StrapDataSourceStartResult> start() {
    startCount++;
    // A start in progress is joined, as the contract requires.
    if (_pendingStart case final pending?) {
      return pending.future;
    }
    if (!holdStart) {
      return Future.value(startResult);
    }
    final pending = Completer<StrapDataSourceStartResult>();
    _pendingStart = pending;
    return pending.future;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _completePendingStart(const StrapDataSourceStartResult.cancelled());
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
    _completePendingStart(const StrapDataSourceStartResult.cancelled());
    await _controller.close();
    await _connectionLost.close();
    if (disposeError case final error?) {
      throw error;
    }
  }

  void _completePendingStart(StrapDataSourceStartResult result) {
    final pending = _pendingStart;
    _pendingStart = null;
    pending?.complete(result);
  }
}
