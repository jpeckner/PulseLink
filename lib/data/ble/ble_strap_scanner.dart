import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pulselink/data/ble/ble_api.pigeon.dart';
import 'package:pulselink/data/strap_scanner.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';
import 'package:pulselink/domain/discovered_strap.dart';
import 'package:pulselink/domain/strap_ble_identifier.dart';
import 'package:pulselink/domain/strap_ble_name.dart';

/// A [StrapScanner] backed by the phone's own Bluetooth stack, through the
/// Pigeon contract in pigeons/ble_api.dart: CoreBluetooth on iOS, and
/// Android's Bluetooth LE APIs on Android.
class BleStrapScanner implements StrapScanner {
  /// [events] stands in for the platform channel in tests.
  new({Stream<BleScanEvent>? events})
    // Created once and reused: each call makes a new event channel, and a
    // second one for the same channel would take over the first one's
    // messages.
    : _events = events ?? scanForHeartRateStraps();

  final Stream<BleScanEvent> _events;

  @override
  Stream<StrapScanEvent> scan() => _events.transform(
    StreamTransformer.fromHandlers(
      handleData: (event, sink) {
        if (_toScanEvent(event) case final scanEvent?) {
          sink.add(scanEvent);
        }
      },
      handleError: (error, stackTrace, sink) {
        // The native side reports expected failures as BleScanFailed events,
        // so a PlatformException means the channel itself failed, such as a
        // native error. Either way the phone can't scan.
        if (error is PlatformException) {
          sink.add(const .failed(.unavailable));
        } else {
          // Anything else is a bug, such as the generated cast failing on a
          // message of the wrong type. Passed on, so it reaches the zone's
          // error handler rather than being hidden.
          //
          // A message that fails while being decoded never gets here:
          // Flutter's messenger reports it with FlutterError.reportError and
          // drops it. That's acceptable because decoding only fails if the
          // generated Dart and native code came from different versions of
          // pigeons/ble_api.dart, which tool/pigeon.sh (it generates all
          // three together) and CI's generated-code check prevent. And an
          // unreadable message has nothing in it the app could act on. If it
          // ever happened, the report would show it in the logs, and the
          // worst case is one missed event, such as the picker still showing
          // that it's looking.
          sink.addError(error, stackTrace);
        }
      },
    ),
  );

  /// The domain event for [event], or null if it should be left out.
  static StrapScanEvent? _toScanEvent(BleScanEvent event) => switch (event) {
    BleScanStarted() => const .scanning(),
    BleStrapFound(:final id, :final name, :final isConnected) => _strapFound(
      id,
      name,
      isConnected: isConnected,
    ),
    BleScanFailed(:final reason) => .failed(switch (reason) {
      BleScanFailureReason.poweredOff => BluetoothProblem.off,
      BleScanFailureReason.unauthorized => BluetoothProblem.permissionDenied,
      BleScanFailureReason.unsupported => BluetoothProblem.unavailable,
    }),
  };

  /// A strap found, or null if the native side gave it a blank identifier:
  /// a strap the app can't identify can't be connected to, so it isn't
  /// listed. A blank name means the strap has none to show.
  static StrapScanEvent? _strapFound(
    String id,
    String? name, {
    required bool isConnected,
  }) {
    final strapId = StrapBleIdentifier.tryFrom(id);
    if (strapId == null) {
      return null;
    }
    return StrapScanEvent.found(
      DiscoveredStrap(
        id: strapId,
        name: name == null ? null : StrapBleName.tryFrom(name),
        isConnected: isConnected,
      ),
    );
  }
}
