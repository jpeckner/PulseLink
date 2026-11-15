import 'dart:async';
import 'dart:developer' as developer;

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:pulselink/data/ble/ble_api.pigeon.dart';
import 'package:pulselink/data/strap_data_source.dart';
import 'package:pulselink/domain/battery_level.dart';
import 'package:pulselink/domain/heart_rate_measurement_parser.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_ble_identifier.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

/// Heart rate from a real strap, connected through the phone's own Bluetooth
/// stack via the Pigeon contract in pigeons/ble_api.dart (CoreBluetooth on
/// iOS). Each Heart Rate Measurement notification is stamped with the time
/// it arrives and parsed by [parseHeartRateMeasurement].
///
/// When a connected strap drops, it reports [StrapConnectionLost] on
/// [connectionLost]; starting it again reconnects. Reconnecting by itself
/// comes in Milestone 6.
class BleStrapDataSource implements StrapDataSource {
  /// Connects to the strap with `strapId`, from a scan. [api] and [events]
  /// stand in for the platform channels in tests.
  ///
  /// Only one source should be in use at a time: the native side connects to
  /// one strap, and each source opens its own event channel.
  new({
    required this._strapId,
    BleConnectionApi? api,
    Stream<BleStrapEvent>? events,
  }) : _api = api ?? BleConnectionApi(),
       _events = events ?? strapEvents();

  final StrapBleIdentifier _strapId;
  final BleConnectionApi _api;
  final Stream<BleStrapEvent> _events;
  final _samples = StreamController<HeartRateSample>.broadcast();
  final _connectionLost = StreamController<StrapConnectionFailure>.broadcast();
  final _batteryLevel = StreamController<BatteryLevel?>.broadcast();

  StreamSubscription<BleStrapEvent>? _subscription;
  Completer<StrapDataSourceStartResult>? _pendingStart;
  bool _isStarted = false;
  bool _isDisposed = false;

  @override
  bool get isSimulated => false;

  @override
  Stream<HeartRateSample> get samples => _samples.stream;

  /// Emits [StrapConnectionLost] when a connected strap drops.
  @override
  Stream<StrapConnectionFailure> get connectionLost => _connectionLost.stream;

  /// The strap's battery level, read after connecting and updated if the
  /// strap reports changes. Null after stopping or a drop.
  @override
  Stream<BatteryLevel?> get batteryLevel => _batteryLevel.stream;

  @override
  Future<StrapDataSourceStartResult> start() {
    if (_isDisposed) {
      return Future.value(const .cancelled());
    }
    if (_isStarted) {
      return Future.value(const .started());
    }
    // A start in progress is joined, as the contract requires.
    if (_pendingStart case final pending?) {
      return pending.future;
    }
    final pending = Completer<StrapDataSourceStartResult>();
    _pendingStart = pending;
    // Listening before connecting means no measurement sent just after
    // connecting is missed. Measurements only count once started.
    _subscription ??= _events.listen(_onEvent, onError: _onEventError);
    // Not awaited: stop() and dispose() complete `pending` themselves, so a
    // connect that never answers can't leave start() waiting. Expected
    // failures come back as results; anything else is a bug, left for the
    // zone's error handler.
    unawaited(_connect(pending));
    return pending.future;
  }

  @override
  Future<void> stop() async {
    final pending = _pendingStart;
    final wasActive = _isStarted || pending != null;
    _pendingStart = null;
    _isStarted = false;
    pending?.complete(const .cancelled());
    if (!wasActive) {
      return;
    }
    _batteryLevel.add(null);
    // Cleared before awaiting, so a start() meanwhile listens afresh.
    final cancelling = _subscription?.cancel();
    _subscription = null;
    try {
      await cancelling;
    } finally {
      // Also cancels a connection still in progress on the native side.
      await _disconnect();
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    try {
      await stop();
    } finally {
      // Close even if stopping failed; the error still reaches the caller.
      await _samples.close();
      await _connectionLost.close();
      await _batteryLevel.close();
    }
  }

  Future<void> _connect(Completer<StrapDataSourceStartResult> pending) async {
    final result = await _connectResult();
    // stop() or dispose() may have ended this start already, and completed
    // it as cancelled.
    if (!identical(_pendingStart, pending)) {
      return;
    }
    _pendingStart = null;
    switch (result) {
      case StrapDataSourceStarted():
        _isStarted = true;
        pending.complete(result);
      case StrapDataSourceStartCancelled() || StrapDataSourceStartFailed():
        // Not connected, so nothing to listen for until the next start.
        final cancelling = _subscription?.cancel();
        _subscription = null;
        try {
          await cancelling;
        } finally {
          // Complete even if cancelling failed, so start() never hangs; the
          // error still reaches the zone's error handler.
          pending.complete(result);
        }
    }
  }

  Future<StrapDataSourceStartResult> _connectResult() async {
    try {
      return switch (await _api.connect(_strapId.value)) {
        BleConnected() => const .started(),
        BleConnectCancelled() => const .cancelled(),
        BleConnectFailed(:final reason) => .failed(_failureFor(reason)),
      };
    } on PlatformException catch (error, stackTrace) {
      // The native side reports expected failures as BleConnectFailed, so
      // this means the channel itself failed, such as a missing native
      // handler. Either way the phone can't connect.
      developer.log(
        'Connecting failed on the platform channel',
        name: 'ble',
        error: error,
        stackTrace: stackTrace,
      );
      return const .failed(.bluetooth(.unavailable));
    }
  }

  Future<void> _disconnect() async {
    try {
      await _api.disconnect();
    } on PlatformException catch (error, stackTrace) {
      // Nothing more to do: the native side can't be told to let go, and
      // this source is stopped either way.
      developer.log(
        'Disconnecting failed on the platform channel',
        name: 'ble',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _onEvent(BleStrapEvent event) {
    switch (event) {
      case BleHeartRateMeasurement(:final value):
        if (!_isStarted) {
          return;
        }
        switch (parseHeartRateMeasurement(value, timestamp: clock.now())) {
          case HeartRateParseSuccess(:final sample):
            _samples.add(sample);
          case HeartRateParseFailure(:final error):
            // A malformed packet has no reading in it. It's logged rather
            // than sent, since samples never carry errors; if bad packets
            // keep coming, the live screen marks the last reading stale.
            developer.log(
              'Dropped a malformed Heart Rate Measurement: ${error.name}',
              name: 'ble',
            );
        }
      case BleStrapDisconnected():
        developer.log('The strap disconnected', name: 'ble');
        // Only a strap that was connected can be lost. A later start()
        // connects again.
        if (_isStarted) {
          _isStarted = false;
          _connectionLost.add(const .connectionLost());
          _batteryLevel.add(null);
        }
      case BleBatteryLevel(:final percent):
        if (!_isStarted) {
          return;
        }
        if (BatteryLevel.tryFrom(percent) case final level?) {
          _batteryLevel.add(level);
        } else {
          // Not a percentage, so not a level to show; most likely a corrupt
          // value. Logged rather than sent: the stream never carries errors.
          developer.log('Dropped a battery level of $percent', name: 'ble');
        }
    }
  }

  void _onEventError(Object error, StackTrace stackTrace) {
    if (error is PlatformException) {
      // A native error on the event stream. Measurements stop, and the live
      // screen marks the last reading stale.
      developer.log(
        'The strap event stream failed',
        name: 'ble',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }
    // Anything else is a bug, such as an event that doesn't match the
    // contract: reported to the zone's error handler rather than hidden.
    Zone.current.handleUncaughtError(error, stackTrace);
  }

  static StrapConnectionFailure _failureFor(
    BleConnectFailureReason reason,
  ) => switch (reason) {
    BleConnectFailureReason.poweredOff => const .bluetooth(.off),
    BleConnectFailureReason.unauthorized => const .bluetooth(.permissionDenied),
    BleConnectFailureReason.unsupported => const .bluetooth(.unavailable),
    BleConnectFailureReason.unreachable => const .strapUnreachable(),
    BleConnectFailureReason.notAHeartRateStrap => const .notAHeartRateStrap(),
  };
}
