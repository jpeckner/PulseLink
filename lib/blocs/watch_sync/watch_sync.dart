import 'dart:async';
import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:clock/clock.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_state.dart';
import 'package:pulselink/data/watch_bridge.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/watch_heart_rate_snapshot.dart';

/// Keeps the Apple Watch app showing what the live heart-rate screen shows.
///
/// Sends a [WatchHeartRateSnapshot] for the current state when started, then
/// one for each change, both as a live message (for an open watch app) and
/// as the application context (for the watch app's next launch).
///
/// Staleness isn't sent: the watch works it out from the reading's
/// timestamp, so it's right even when snapshots stop arriving. A change
/// that's only the reading going stale is therefore not sent.
class WatchSync {
  new({
    required this._heartRate,
    required this._bridge,
    this._log = _developerLog,
  });

  final StateStreamable<LiveHeartRateState> _heartRate;
  final WatchBridge _bridge;
  final void Function(String message) _log;

  StreamSubscription<LiveHeartRateState>? _subscription;
  bool _isClosed = false;

  /// The latest sample, kept while the source waits or fails, so the watch
  /// can still show the last bpm and when it was measured.
  HeartRateSample? _latestReading;

  /// Whether the last state was simulated, to tell when the source switches
  /// between demo mode and a strap.
  bool? _lastIsSimulated;

  /// What the last snapshot sent said, apart from when it was sent.
  _SnapshotContent? _lastSent;

  /// The last delivery result logged for each kind of send, so a result is
  /// logged only when it changes rather than once a second.
  String? _lastLiveResult;
  String? _lastContextResult;

  /// Sends the current state, then each change. Safe to call more than once;
  /// does nothing after [close].
  void start() {
    if (_isClosed || _subscription != null) {
      return;
    }
    _onState(_heartRate.state);
    // No onError: a Cubit's stream never carries errors.
    _subscription = _heartRate.stream.listen(_onState);
  }

  /// Stops sending. Snapshots already on their way still arrive.
  Future<void> close() async {
    _isClosed = true;
    try {
      await _subscription?.cancel();
    } finally {
      // Dropped even if unsubscribing failed, so start() can't resubscribe
      // through it; _isClosed stops that anyway. The error still reaches the
      // caller.
      _subscription = null;
    }
  }

  void _onState(LiveHeartRateState state) {
    // Guards against a stream that still delivers after a failed cancel.
    if (_isClosed) {
      return;
    }

    // A demo bpm must never be shown as a strap's, or the other way round.
    switch ((_lastIsSimulated, state.isSimulated)) {
      case (true, false) || (false, true):
        _latestReading = null;
      case (null, true) || (null, false) || (true, true) || (false, false):
        // The first state, or the same source as before.
        break;
    }
    _lastIsSimulated = state.isSimulated;

    final WatchHeartRateStatus status;
    switch (state) {
      case LiveHeartRateNoStrap():
        status = const WatchHeartRateStatus.noStrap();
      case LiveHeartRateWaiting():
        status = const WatchHeartRateStatus.waiting();
      case LiveHeartRateReading(:final sample):
        _latestReading = sample;
        status = const WatchHeartRateStatus.receiving();
      case LiveHeartRateConnectionFailed(:final failure):
        status = WatchHeartRateStatus.failed(failure);
    }

    final content = (
      isSimulated: state.isSimulated,
      status: status,
      latestReading: _latestReading,
    );
    if (content == _lastSent) {
      return;
    }
    _lastSent = content;

    final snapshot = WatchHeartRateSnapshot(
      sentAt: clock.now(),
      isSimulated: content.isSimulated,
      status: content.status,
      latestReading: content.latestReading,
    );
    // Not awaited: the screen doesn't wait for the watch. Expected failures,
    // such as the watch app being closed, come back as results, which are
    // logged. A bridge only throws on a bug; that's left uncaught for the
    // zone's error handler to report. Future.sync makes a bridge that
    // throws before returning a future fail the same way, so one failing
    // call doesn't stop the other.
    unawaited(
      Future.sync(() => _bridge.sendLiveSnapshot(snapshot)).then(_onLiveResult),
    );
    unawaited(
      Future.sync(() => _bridge.updateApplicationContext(snapshot))
          .then(_onContextResult),
    );
  }

  void _onLiveResult(WatchDeliveryResult result) {
    final description = _describe(result);
    if (description == _lastLiveResult) {
      return;
    }
    _lastLiveResult = description;
    _log('Live snapshots: $description');
  }

  void _onContextResult(WatchDeliveryResult result) {
    final description = _describe(result);
    if (description == _lastContextResult) {
      return;
    }
    _lastContextResult = description;
    _log('Application context: $description');
  }

  static String _describe(WatchDeliveryResult result) => switch (result) {
    WatchDeliveryResult.sent => 'sent',
    WatchDeliveryResult.pending => 'held until the session is activated',
    WatchDeliveryResult.watchUnreachable =>
      "dropped, the watch app isn't reachable",
    WatchDeliveryResult.noWatchApp =>
      'dropped, no paired watch has the app installed',
    WatchDeliveryResult.unsupported =>
      "dropped, this device can't talk to a watch",
    WatchDeliveryResult.failed => 'failed',
  };

  static void _developerLog(String message) =>
      developer.log(message, name: 'watch');
}

/// A snapshot without its `sentAt`, to tell whether anything changed.
typedef _SnapshotContent = ({
  bool isSimulated,
  WatchHeartRateStatus status,
  HeartRateSample? latestReading,
});
