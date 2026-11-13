import 'dart:async';

import 'package:pulselink/data/heart_rate_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

/// A [HeartRateSource] that tests drive by hand with [emit], and that records
/// how it was used.
class StubHeartRateSource implements HeartRateSource {
  new({this.isSimulated = false});

  @override
  final bool isSimulated;

  // Synchronous, so a sample reaches listeners as soon as [emit] returns.
  final _controller = StreamController<HeartRateSample>.broadcast(sync: true);

  int startCount = 0;
  int stopCount = 0;
  bool isDisposed = false;

  /// What [start] completes with.
  HeartRateSourceStartResult startResult =
      const HeartRateSourceStartResult.started();

  /// When true, [start] doesn't complete until [finishStart] is called, or
  /// until [stop] or [dispose] cancels it, as the [HeartRateSource] contract
  /// requires. Lets tests act while a start is in progress, as with a real
  /// strap that takes seconds to connect.
  bool holdStart = false;

  Completer<HeartRateSourceStartResult>? _pendingStart;

  /// Whether a held [start] is still in progress.
  bool get isStarting => _pendingStart != null;

  bool get hasListener => _controller.hasListener;

  void emit(HeartRateSample sample) => _controller.add(sample);

  /// Completes a held [start] with [startResult].
  void finishStart() => _completePendingStart(startResult);

  @override
  Stream<HeartRateSample> get samples => _controller.stream;

  /// Counts each call, including ones that join a held start in progress.
  @override
  Future<HeartRateSourceStartResult> start() {
    startCount++;
    // A start in progress is joined, as the contract requires.
    if (_pendingStart case final pending?) {
      return pending.future;
    }
    if (!holdStart) {
      return Future.value(startResult);
    }
    final pending = Completer<HeartRateSourceStartResult>();
    _pendingStart = pending;
    return pending.future;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _completePendingStart(const HeartRateSourceStartResult.cancelled());
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
    _completePendingStart(const HeartRateSourceStartResult.cancelled());
    await _controller.close();
  }

  void _completePendingStart(HeartRateSourceStartResult result) {
    final pending = _pendingStart;
    _pendingStart = null;
    pending?.complete(result);
  }
}
