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

  bool get hasListener => _controller.hasListener;

  void emit(HeartRateSample sample) => _controller.add(sample);

  @override
  Stream<HeartRateSample> get samples => _controller.stream;

  @override
  Future<void> start() async => startCount++;

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> dispose() async {
    isDisposed = true;
    await _controller.close();
  }
}
