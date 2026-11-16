import 'dart:developer' as developer;

import 'package:flutter/services.dart';
// Prefixed: the generated types share names with the domain types they
// carry, such as WatchHeartRateSnapshot.
import 'package:pulselink/data/watch/watch_api.pigeon.dart' as pigeon;
import 'package:pulselink/data/watch_bridge.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';
import 'package:pulselink/domain/watch_heart_rate_snapshot.dart';

/// A [WatchBridge] backed by the iPhone's WatchConnectivity code, through the
/// Pigeon contract in pigeons/watch_api.dart.
///
/// iOS only. The contract has no Android side, so on Android every call
/// returns [WatchDeliveryResult.unsupported].
class PigeonWatchBridge implements WatchBridge {
  /// [api] stands in for the platform channel in tests.
  new({pigeon.WatchSessionApi? api}) : _api = api ?? pigeon.WatchSessionApi();

  final pigeon.WatchSessionApi _api;

  @override
  Future<WatchDeliveryResult> sendLiveSnapshot(
    WatchHeartRateSnapshot snapshot,
  ) => _deliver(
    'sendLiveSnapshot',
    () => _api.sendLiveSnapshot(_toPigeon(snapshot)),
  );

  @override
  Future<WatchDeliveryResult> updateApplicationContext(
    WatchHeartRateSnapshot snapshot,
  ) => _deliver(
    'updateApplicationContext',
    () => _api.updateApplicationContext(_toPigeon(snapshot)),
  );

  /// Runs [send] and turns its outcome, or the platform channel failing,
  /// into a result.
  ///
  /// Only [PlatformException] is caught. Anything else is a bug, such as the
  /// generated cast failing on a reply of the wrong type, and is left for the
  /// zone's error handler rather than hidden as a result.
  Future<WatchDeliveryResult> _deliver(
    String call,
    Future<pigeon.WatchDeliveryOutcome> Function() send,
  ) async {
    try {
      return _resultFor(await send());
    } on PlatformException catch (error, stackTrace) {
      // The native side reports expected failures as outcomes, so this means
      // the channel itself failed. With no native handler (on Android, which
      // has no watch app), Pigeon reports 'channel-error'.
      final isMissingHandler = error.code == 'channel-error';
      developer.log(
        '$call failed on the platform channel',
        name: 'watch',
        error: error,
        stackTrace: stackTrace,
      );
      return isMissingHandler
          ? WatchDeliveryResult.unsupported
          : WatchDeliveryResult.failed;
    }
  }

  static WatchDeliveryResult _resultFor(
    pigeon.WatchDeliveryOutcome outcome,
  ) => switch (outcome) {
    pigeon.WatchDeliveryOutcome.sent => WatchDeliveryResult.sent,
    pigeon.WatchDeliveryOutcome.pending => WatchDeliveryResult.pending,
    pigeon.WatchDeliveryOutcome.watchUnreachable =>
      WatchDeliveryResult.watchUnreachable,
    pigeon.WatchDeliveryOutcome.noWatchApp => WatchDeliveryResult.noWatchApp,
    pigeon.WatchDeliveryOutcome.unsupported => WatchDeliveryResult.unsupported,
    pigeon.WatchDeliveryOutcome.failed => WatchDeliveryResult.failed,
  };

  static pigeon.WatchHeartRateSnapshot _toPigeon(
    WatchHeartRateSnapshot snapshot,
  ) => pigeon.WatchHeartRateSnapshot(
    sentAtMillis: snapshot.sentAt.millisecondsSinceEpoch,
    source: snapshot.isSimulated
        ? pigeon.WatchHeartRateSource.demo
        : pigeon.WatchHeartRateSource.strap,
    status: switch (snapshot.status) {
      WatchHeartRateNoStrap() => pigeon.WatchNoStrap(),
      WatchHeartRateWaiting() => pigeon.WatchWaiting(),
      WatchHeartRateReceiving() => pigeon.WatchReceiving(),
      WatchHeartRateFailed(:final failure) => pigeon.WatchFailed(
        failure: _failureFor(failure),
      ),
    },
    latestReading: switch (snapshot.latestReading) {
      null => null,
      MeasuredHeartRateSample(:final beatsPerMinute, :final timestamp) =>
        pigeon.WatchMeasuredReading(
          beatsPerMinute: beatsPerMinute.value,
          measuredAtMillis: timestamp.millisecondsSinceEpoch,
        ),
      UnavailableHeartRateSample(:final reason, :final timestamp) =>
        pigeon.WatchUnavailableReading(
          reason: _reasonFor(reason),
          measuredAtMillis: timestamp.millisecondsSinceEpoch,
        ),
    },
  );

  static pigeon.WatchStrapFailure _failureFor(StrapConnectionFailure failure) =>
      switch (failure) {
        BluetoothFailure(:final problem) => switch (problem) {
          BluetoothProblem.off => pigeon.WatchStrapFailure.bluetoothOff,
          BluetoothProblem.unavailable =>
            pigeon.WatchStrapFailure.bluetoothUnavailable,
          BluetoothProblem.permissionDenied =>
            pigeon.WatchStrapFailure.bluetoothPermissionDenied,
        },
        StrapUnreachable() => pigeon.WatchStrapFailure.strapUnreachable,
        NotAHeartRateStrap() => pigeon.WatchStrapFailure.notAHeartRateStrap,
        StrapConnectionLost() => pigeon.WatchStrapFailure.connectionLost,
      };

  static pigeon.WatchUnavailableReason _reasonFor(
    HeartRateUnavailableReason reason,
  ) => switch (reason) {
    HeartRateUnavailableReason.noSkinContact =>
      pigeon.WatchUnavailableReason.noSkinContact,
    HeartRateUnavailableReason.zeroBeatsPerMinute =>
      pigeon.WatchUnavailableReason.zeroBeatsPerMinute,
    HeartRateUnavailableReason.implausibleBeatsPerMinute =>
      pigeon.WatchUnavailableReason.implausibleBeatsPerMinute,
  };
}
