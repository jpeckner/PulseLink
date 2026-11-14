import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/data/ble/ble_api.pigeon.dart';
import 'package:pulselink/data/ble/ble_strap_scanner.dart';
import 'package:pulselink/data/strap_scanner.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';

import '../../helpers/discovered_strap.dart';

void main() {
  group('BleStrapScanner', () {
    group('over the real platform channel', () {
      // The channel name Pigeon generates for scanForHeartRateStraps.
      const channel = EventChannel(
        'dev.flutter.pigeon.pulselink.BleEventApi.scanForHeartRateStraps',
        pigeonMethodCodec,
      );

      setUp(TestWidgetsFlutterBinding.ensureInitialized);

      tearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(channel, null),
      );

      /// Answers the channel the way the native side would.
      void mockNativeScanner(
        void Function(MockStreamHandlerEventSink events) onListen,
      ) => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            channel,
            MockStreamHandler.inline(onListen: (_, events) => onListen(events)),
          );

      test('decodes what the native side sends', () async {
        mockNativeScanner(
          (events) => events
            ..success(BleScanStarted())
            ..success(BleStrapFound(id: 'strap-1', name: 'TICKR'))
            ..success(BleScanFailed(reason: BleScanFailureReason.poweredOff)),
        );
        await expectLater(
          BleStrapScanner().scan(),
          emitsInOrder([
            const StrapScanEvent.scanning(),
            StrapScanEvent.found(discoveredStrapOf('strap-1', 'TICKR')),
            const StrapScanEvent.failed(BluetoothProblem.off),
          ]),
        );
      });

      test(
        'a native error is reported as Bluetooth being unavailable',
        () async {
          mockNativeScanner(
            (events) => events.error(code: 'native-error', message: 'failed'),
          );
          await expectLater(
            BleStrapScanner().scan(),
            emits(const StrapScanEvent.failed(BluetoothProblem.unavailable)),
          );
        },
      );
    });

    // Broadcast, like the platform channel's stream.
    late StreamController<BleScanEvent> platform;
    late BleStrapScanner scanner;
    late List<StrapScanEvent> events;
    late List<Object> errors;
    StreamSubscription<StrapScanEvent>? subscription;

    setUp(() {
      platform = StreamController<BleScanEvent>.broadcast(sync: true);
      scanner = BleStrapScanner(events: platform.stream);
      events = [];
      errors = [];
    });

    tearDown(() async {
      await subscription?.cancel();
      subscription = null;
      await platform.close();
    });

    /// Starts a scan, collecting what it sends in [events] and [errors].
    void listen() {
      subscription = scanner.scan().listen(events.add, onError: errors.add);
    }

    test('reports that scanning started', () async {
      listen();
      platform.add(BleScanStarted());
      expect(events, [const StrapScanEvent.scanning()]);
    });

    test('reports a strap found, with its name', () async {
      listen();
      platform.add(BleStrapFound(id: 'strap-1', name: 'Polar H10 12345678'));
      expect(events, [
        StrapScanEvent.found(
          discoveredStrapOf('strap-1', 'Polar H10 12345678'),
        ),
      ]);
    });

    group('a strap name', () {
      for (final (advertised, shown) in [
        (null, null),
        ('', null),
        ('   ', null),
        ('  TICKR  ', 'TICKR'),
      ]) {
        test('advertised as ${advertised == null ? 'nothing' : '"$advertised"'}'
            ' is ${shown == null ? 'none' : '"$shown"'}', () async {
          listen();
          platform.add(BleStrapFound(id: 'strap-1', name: advertised));
          expect(events, [
            StrapScanEvent.found(discoveredStrapOf('strap-1', shown)),
          ]);
        });
      }
    });

    test('leaves out a strap with a blank identifier', () {
      listen();
      platform
        ..add(BleStrapFound(id: '', name: 'No id'))
        ..add(BleStrapFound(id: '   ', name: 'Blank id'))
        ..add(BleStrapFound(id: 'strap-1', name: 'TICKR'));
      expect(events, [
        StrapScanEvent.found(discoveredStrapOf('strap-1', 'TICKR')),
      ]);
    });

    group('a failure', () {
      const problems = {
        BleScanFailureReason.poweredOff: BluetoothProblem.off,
        BleScanFailureReason.unauthorized: BluetoothProblem.permissionDenied,
        BleScanFailureReason.unsupported: BluetoothProblem.unavailable,
      };

      test('has a problem for every reason', () {
        expect(problems.keys, unorderedEquals(BleScanFailureReason.values));
      });

      for (final MapEntry(key: reason, value: problem) in problems.entries) {
        test('${reason.name} is reported as ${problem.name}', () async {
          listen();
          platform.add(BleScanFailed(reason: reason));
          expect(events, [StrapScanEvent.failed(problem)]);
        });
      }
    });

    test('a platform error is reported as Bluetooth being unavailable, '
        'and the scan carries on', () async {
      listen();
      platform
        ..addError(PlatformException(code: 'error'))
        ..add(BleScanStarted());
      expect(events, [
        const StrapScanEvent.failed(BluetoothProblem.unavailable),
        const StrapScanEvent.scanning(),
      ]);
      expect(errors, isEmpty);
    });

    test('any other error is a bug, so it is passed on', () async {
      listen();
      final bug = StateError('a message that breaks the contract');
      platform.addError(bug);
      expect(events, isEmpty);
      expect(errors, [bug]);
    });

    test('cancelling the scan stops listening to the platform, and '
        'listening again starts a new scan', () async {
      listen();
      expect(platform.hasListener, isTrue);
      await subscription?.cancel();
      expect(platform.hasListener, isFalse);

      listen();
      expect(platform.hasListener, isTrue);
      platform.add(BleScanStarted());
      expect(events, [const StrapScanEvent.scanning()]);
    });
  });
}
