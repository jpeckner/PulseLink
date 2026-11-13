import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pulselink/data/ble/ble_api.pigeon.dart';
import 'package:pulselink/data/strap_scanner.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';
import 'package:pulselink/domain/discovered_strap.dart';

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
      handleData: (event, sink) => sink.add(_toScanEvent(event)),
      handleError: (error, stackTrace, sink) {
        // The native side reports expected failures as BleScanFailed events,
        // so a PlatformException means the channel itself failed, such as a
        // native error. Either way the phone can't scan.
        if (error is PlatformException) {
          sink.add(const .failed(.unavailable));
        } else {
          // Anything else is a bug, such as a message that doesn't match the
          // contract. Passed on, so it reaches the zone's error handler
          // rather than being hidden.
          sink.addError(error, stackTrace);
        }
      },
    ),
  );

  static StrapScanEvent _toScanEvent(BleScanEvent event) => switch (event) {
    BleScanStarted() => const .scanning(),
    BleStrapFound(:final id, :final name) => .found(
      DiscoveredStrap(id: id, name: _nonBlank(name)),
    ),
    BleScanFailed(:final reason) => .failed(switch (reason) {
      BleScanFailureReason.poweredOff => BluetoothProblem.off,
      BleScanFailureReason.unauthorized => BluetoothProblem.permissionDenied,
      BleScanFailureReason.unsupported => BluetoothProblem.unavailable,
    }),
  };

  /// [name] with surrounding whitespace removed, or null if nothing's left:
  /// a strap that advertises a blank name has no name to show.
  static String? _nonBlank(String? name) {
    final trimmed = name?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
