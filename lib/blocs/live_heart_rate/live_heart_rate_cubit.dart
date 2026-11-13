import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:clock/clock.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_state.dart';
import 'package:pulselink/data/heart_rate_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

/// Turns a [HeartRateSource] into screen state: the latest sample, and whether
/// it has gone stale.
///
/// A sample is stale once it's older than [staleAfter], measured from its own
/// timestamp, even if the source still says it's connected.
class LiveHeartRateCubit extends Cubit<LiveHeartRateState> {
  new({
    required HeartRateSource source,
    this.staleAfter = const Duration(seconds: 10),
  }) : _source = source,
       super(LiveHeartRateState.waiting(isSimulated: source.isSimulated));

  final Duration staleAfter;

  final HeartRateSource _source;
  StreamSubscription<HeartRateSample>? _subscription;
  Timer? _staleTimer;

  /// Subscribes to the source and starts it. Safe to call more than once;
  /// does nothing after [close].
  Future<void> start() async {
    if (isClosed) {
      return;
    }
    // No onError: HeartRateSource.samples never carries errors.
    _subscription ??= _source.samples.listen(_onSample);
    await _source.start();
  }

  void _onSample(HeartRateSample sample) {
    _staleTimer?.cancel();
    // A timestamp ahead of the clock (the clock was set back, or the sample
    // was stamped by a clock running ahead) counts as age 0. Otherwise the
    // negative age would keep the sample fresh for longer than staleAfter.
    final age = clock.now().difference(sample.timestamp);
    final timeUntilStale = staleAfter - (age.isNegative ? Duration.zero : age);
    final isStale = timeUntilStale <= Duration.zero;

    emit(
      LiveHeartRateState.reading(
        sample: sample,
        isStale: isStale,
        isSimulated: _source.isSimulated,
      ),
    );

    if (!isStale) {
      _staleTimer = Timer(timeUntilStale, _markStale);
    }
  }

  void _markStale() {
    if (state case final LiveHeartRateReading reading) {
      emit(reading.copyWith(isStale: true));
    }
  }

  @override
  Future<void> close() async {
    try {
      // Stop delivery first: cancel() detaches the listener at once, so no
      // sample can arrive (and start a new stale timer) while the source is
      // stopping. The timer goes first because it can't throw; if cancel()
      // throws, no timer is left to fire into the closed cubit.
      _staleTimer?.cancel();
      final cancelSubscription = _subscription?.cancel();

      // Waits for the source to stop and the unsubscribe to finish.
      // Future.sync turns a stop() that throws before returning a future into
      // a failed future, so every failure is handled the same way.
      await Future.wait([Future.sync(_source.stop), ?cancelSubscription]);
    } finally {
      // Close even if stopping failed; the error still reaches the caller.
      await super.close();
    }
  }
}
