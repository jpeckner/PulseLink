import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulselink/data/ble/ble_api.pigeon.dart';
import 'package:pulselink/data/ble/ble_heart_rate_source.dart';
import 'package:pulselink/data/heart_rate_source.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';
import 'package:pulselink/domain/heart_rate_measurement_parser.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

import '../../helpers/discovered_strap.dart';

class _MockConnectionApi extends Mock implements BleConnectionApi;

final _now = DateTime(2026, 11, 13, 9, 30);

/// 72 bpm, skin contact detected, one RR interval: the build plan's first
/// parser fixture.
final _packet = Uint8List.fromList([0x16, 0x48, 0x00, 0x04]);

/// Lets pending sample deliveries arrive: `samples` is asynchronous, like
/// every source's, so a sample reaches listeners just after it's added.
Future<void> _delivered() => Future<void>.delayed(Duration.zero);

const _started = HeartRateSourceStartResult.started();
const _cancelled = HeartRateSourceStartResult.cancelled();

void main() {
  group('BleHeartRateSource', () {
    late _MockConnectionApi api;
    late StreamController<BleStrapEvent> events;
    late BleHeartRateSource source;
    late List<HeartRateSample> samples;

    setUp(() {
      api = _MockConnectionApi();
      events = StreamController<BleStrapEvent>.broadcast(sync: true);
      source = BleHeartRateSource(
        strapId: strapIdOf('E621E1F8-C36C-495A-93FC-0C247A3E6E5F'),
        api: api,
        events: events.stream,
      );
      samples = [];
      source.samples.listen(samples.add);
      when(() => api.disconnect()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await source.dispose();
      await events.close();
    });

    test('is not simulated', () {
      expect(source.isSimulated, isFalse);
    });

    test('connects to its strap, then parses each measurement, stamped with '
        'the time it arrived', () async {
      when(() => api.connect(any())).thenAnswer((_) async => BleConnected());
      // The whole test runs under the fixed clock: the source reads the
      // clock in its event listener, which runs in the zone start() listened
      // from, not the zone the event was added in.
      await withClock(Clock.fixed(_now), () async {
        expect(await source.start(), _started);
        events.add(BleHeartRateMeasurement(value: _packet));
      });
      verify(() => api.connect('E621E1F8-C36C-495A-93FC-0C247A3E6E5F'))
          .called(1);
      await _delivered();
      expect(samples, [
        switch (parseHeartRateMeasurement(_packet, timestamp: _now)) {
          HeartRateParseSuccess(:final sample) => sample,
          HeartRateParseFailure() => fail('the fixture should parse'),
        },
      ]);
    });

    group('a failure to connect', () {
      final failures = {
        BleConnectFailureReason.poweredOff:
            const StrapConnectionFailure.bluetooth(BluetoothProblem.off),
        BleConnectFailureReason.unauthorized:
            const StrapConnectionFailure.bluetooth(
              BluetoothProblem.permissionDenied,
            ),
        BleConnectFailureReason.unsupported:
            const StrapConnectionFailure.bluetooth(
              BluetoothProblem.unavailable,
            ),
        BleConnectFailureReason.unreachable:
            const StrapConnectionFailure.strapUnreachable(),
        BleConnectFailureReason.notAHeartRateStrap:
            const StrapConnectionFailure.notAHeartRateStrap(),
      };

      test('has a failure for every reason', () {
        expect(failures.keys, unorderedEquals(BleConnectFailureReason.values));
      });

      for (final MapEntry(key: reason, value: failure) in failures.entries) {
        test('${reason.name} is reported as $failure', () async {
          when(() => api.connect(any()))
              .thenAnswer((_) async => BleConnectFailed(reason: reason));
          expect(
            await source.start(),
            HeartRateSourceStartResult.failed(failure),
          );
        });
      }

      test('on the platform channel is reported as Bluetooth being '
          'unavailable', () async {
        when(() => api.connect(any()))
            .thenThrow(PlatformException(code: 'channel-error'));
        expect(
          await source.start(),
          const HeartRateSourceStartResult.failed(
            StrapConnectionFailure.bluetooth(BluetoothProblem.unavailable),
          ),
        );
      });

      test('means measurements are ignored, and a later start connects '
          'again', () async {
        when(() => api.connect(any())).thenAnswer(
          (_) async =>
              BleConnectFailed(reason: BleConnectFailureReason.unreachable),
        );
        expect(
          await source.start(),
          const HeartRateSourceStartResult.failed(
            StrapConnectionFailure.strapUnreachable(),
          ),
        );
        events.add(BleHeartRateMeasurement(value: _packet));
        await _delivered();
        expect(samples, isEmpty);

        when(() => api.connect(any())).thenAnswer((_) async => BleConnected());
        expect(await source.start(), _started);
        verify(() => api.connect(any())).called(2);
      });
    });

    test('a cancelled connection is reported as cancelled', () async {
      when(() => api.connect(any()))
          .thenAnswer((_) async => BleConnectCancelled());
      expect(await source.start(), _cancelled);
    });

    group('while connecting', () {
      late Completer<BleConnectResult> connecting;

      setUp(() {
        connecting = Completer<BleConnectResult>();
        when(() => api.connect(any())).thenAnswer((_) => connecting.future);
      });

      test('a second start joins the first, which connects once', () async {
        final first = source.start();
        final second = source.start();
        connecting.complete(BleConnected());
        expect(await first, _started);
        expect(await second, _started);
        verify(() => api.connect(any())).called(1);
      });

      test('stop cancels the start and disconnects, and the connection '
          'finishing late changes nothing', () async {
        final starting = source.start();
        await source.stop();
        expect(await starting, _cancelled);
        verify(() => api.disconnect()).called(1);

        connecting.complete(BleConnected());
        await Future<void>.delayed(Duration.zero);
        events.add(BleHeartRateMeasurement(value: _packet));
        await _delivered();
        expect(samples, isEmpty);
      });

      test('dispose cancels the start', () async {
        final starting = source.start();
        await source.dispose();
        expect(await starting, _cancelled);
      });

      test('measurements before it finishes are ignored', () async {
        final starting = source.start();
        events.add(BleHeartRateMeasurement(value: _packet));
        connecting.complete(BleConnected());
        expect(await starting, _started);
        await _delivered();
        expect(samples, isEmpty);
      });
    });

    group('once connected', () {
      setUp(() {
        when(() => api.connect(any())).thenAnswer((_) async => BleConnected());
      });

      test('start again returns started without connecting again', () async {
        expect(await source.start(), _started);
        expect(await source.start(), _started);
        verify(() => api.connect(any())).called(1);
      });

      test('a malformed packet is dropped, not sent', () async {
        expect(await source.start(), _started);
        events
          ..add(BleHeartRateMeasurement(value: Uint8List(0)))
          ..add(BleHeartRateMeasurement(value: _packet));
        await _delivered();
        expect(samples, hasLength(1));
      });

      test('a native error on the event stream is dropped, and later '
          'measurements still arrive', () async {
        expect(await source.start(), _started);
        events
          ..addError(PlatformException(code: 'native-error'))
          ..add(BleHeartRateMeasurement(value: _packet));
        await _delivered();
        expect(samples, hasLength(1));
      });

      test('the strap disconnecting stops samples, and a later start '
          'connects again', () async {
        expect(await source.start(), _started);
        events
          ..add(BleStrapDisconnected())
          ..add(BleHeartRateMeasurement(value: _packet));
        await _delivered();
        expect(samples, isEmpty);

        expect(await source.start(), _started);
        verify(() => api.connect(any())).called(2);
      });

      test('the strap disconnecting reports a lost connection', () async {
        final lost = <StrapConnectionFailure>[];
        source.connectionLost.listen(lost.add);
        expect(await source.start(), _started);
        events.add(BleStrapDisconnected());
        await _delivered();
        expect(lost, [const StrapConnectionFailure.connectionLost()]);
      });

      test('stop disconnects and ignores later measurements', () async {
        expect(await source.start(), _started);
        await source.stop();
        verify(() => api.disconnect()).called(1);
        events.add(BleHeartRateMeasurement(value: _packet));
        await _delivered();
        expect(samples, isEmpty);
      });

      test('a platform failure to disconnect is logged, not thrown', () async {
        when(() => api.disconnect())
            .thenThrow(PlatformException(code: 'channel-error'));
        expect(await source.start(), _started);
        await expectLater(source.stop(), completes);
      });
    });

    test('a disconnect while not connected reports nothing', () async {
      final lost = <StrapConnectionFailure>[];
      source.connectionLost.listen(lost.add);
      events.add(BleStrapDisconnected());
      await _delivered();
      expect(lost, isEmpty);
    });

    test('dispose closes connectionLost', () async {
      var closed = false;
      source.connectionLost.listen(null, onDone: () => closed = true);
      await source.dispose();
      expect(closed, isTrue);
    });

    test('stop while stopped does nothing', () async {
      await source.stop();
      verifyNever(() => api.disconnect());
    });

    test('start after dispose is cancelled, without connecting', () async {
      await source.dispose();
      expect(await source.start(), _cancelled);
      verifyNever(() => api.connect(any()));
    });

    test('any other error on the event stream is a bug, so it reaches the '
        "zone's error handler", () async {
      when(() => api.connect(any())).thenAnswer((_) async => BleConnected());
      final bug = StateError('an event that breaks the contract');
      final reported = <Object>[];
      await runZonedGuarded(() async {
        expect(await source.start(), _started);
        events.addError(bug);
        await _delivered();
      }, (error, _) => reported.add(error));
      expect(reported, [bug]);
    });

    test('dispose closes samples even if disconnecting fails, and still '
        'reports the failure', () async {
      final failure = Exception('disconnect failed');
      when(() => api.connect(any())).thenAnswer((_) async => BleConnected());
      when(() => api.disconnect()).thenThrow(failure);
      var closed = false;
      source.samples.listen(null, onDone: () => closed = true);
      expect(await source.start(), _started);
      await expectLater(source.dispose(), throwsA(same(failure)));
      expect(closed, isTrue);
    });
  });

  group('BleHeartRateSource when stopping its event stream fails', () {
    late _MockConnectionApi api;
    late StreamController<BleStrapEvent> events;
    late BleHeartRateSource source;
    final failure = Exception('cancel failed');

    setUp(() {
      api = _MockConnectionApi();
      when(() => api.disconnect()).thenAnswer((_) async {});
      // A stream whose subscription fails to cancel.
      events = StreamController<BleStrapEvent>(onCancel: () => throw failure);
      source = BleHeartRateSource(
        strapId: strapIdOf('strap-1'),
        api: api,
        events: events.stream,
      );
    });

    tearDown(() => events.close());

    test('a failed connection still completes start, and reports the '
        'failure', () async {
      when(() => api.connect(any())).thenAnswer(
        (_) async =>
            BleConnectFailed(reason: BleConnectFailureReason.unreachable),
      );
      final reported = <Object>[];
      HeartRateSourceStartResult? result;
      await runZonedGuarded(() async {
        result = await source.start();
      }, (error, _) => reported.add(error));
      expect(
        result,
        const HeartRateSourceStartResult.failed(
          StrapConnectionFailure.strapUnreachable(),
        ),
      );
      expect(reported, [same(failure)]);
    });

    test('stop still disconnects, and reports the failure', () async {
      when(() => api.connect(any())).thenAnswer((_) async => BleConnected());
      expect(await source.start(), _started);
      await expectLater(source.stop(), throwsA(same(failure)));
      verify(() => api.disconnect()).called(1);
    });
  });

  group('BleHeartRateSource over the real platform channels', () {
    // The channel names Pigeon generates (see pigeons/ble_api.dart).
    const connectChannel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.pulselink.BleConnectionApi.connect',
      BleConnectionApi.pigeonChannelCodec,
    );
    const disconnectChannel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.pulselink.BleConnectionApi.disconnect',
      BleConnectionApi.pigeonChannelCodec,
    );
    const eventsChannel = EventChannel(
      'dev.flutter.pigeon.pulselink.BleEventApi.strapEvents',
      pigeonMethodCodec,
    );

    setUp(TestWidgetsFlutterBinding.ensureInitialized);

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockDecodedMessageHandler(connectChannel, null)
        ..setMockDecodedMessageHandler(disconnectChannel, null)
        ..setMockStreamHandler(eventsChannel, null);
    });

    test('connects, decodes measurements and disconnects the way the '
        'native side answers', () async {
      final connected = <Object?>[];
      var disconnects = 0;
      MockStreamHandlerEventSink? strap;
      // Pigeon wraps each reply in a one-item list.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockDecodedMessageHandler(connectChannel, (message) async {
          connected.add(message);
          return <Object?>[BleConnected()];
        })
        ..setMockDecodedMessageHandler(disconnectChannel, (_) async {
          disconnects++;
          return <Object?>[null];
        })
        ..setMockStreamHandler(
          eventsChannel,
          MockStreamHandler.inline(onListen: (_, events) => strap = events),
        );

      final source = BleHeartRateSource(strapId: strapIdOf('strap-1'));
      final samples = <HeartRateSample>[];
      source.samples.listen(samples.add);

      expect(await source.start(), _started);
      expect(connected, [
        ['strap-1'],
      ]);
      strap?.success(BleHeartRateMeasurement(value: _packet));
      await _delivered();
      expect(samples, hasLength(1));
      switch (samples.single) {
        case MeasuredHeartRateSample(:final beatsPerMinute):
          expect(beatsPerMinute.value, 72);
        case UnavailableHeartRateSample():
          fail('expected a measured sample');
      }

      await source.dispose();
      expect(disconnects, 1);
    });
  });
}
