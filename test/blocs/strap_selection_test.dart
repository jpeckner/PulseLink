import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_state.dart';
import 'package:pulselink/blocs/live_heart_rate/strap_selection.dart';
import 'package:pulselink/data/ble/ble_api.pigeon.dart';
import 'package:pulselink/data/switchable_strap_data_source.dart';
import 'package:pulselink/domain/strap_ble_identifier.dart';

import '../helpers/discovered_strap.dart';
import '../helpers/stub_strap_data_source.dart';

void main() {
  group('StrapSelection', () {
    late StubStrapDataSource demo;
    late StubStrapDataSource strap;
    late SwitchableStrapDataSource source;
    late LiveHeartRateCubit cubit;
    late List<StrapBleIdentifier> created;
    late StrapSelection selection;

    setUp(() async {
      demo = StubStrapDataSource(isSimulated: true);
      strap = StubStrapDataSource();
      source = SwitchableStrapDataSource(demo);
      cubit = LiveHeartRateCubit(source: source);
      await cubit.start();
      created = [];
      selection = StrapSelection(
        source: source,
        cubit: cubit,
        createSource: (strapId) {
          created.add(strapId);
          return strap;
        },
      );
    });

    tearDown(() async {
      await cubit.close();
      await source.dispose();
    });

    test("switches to the picked strap's source and starts it, leaving "
        'demo mode', () async {
      await selection.select(discoveredStrapOf('strap-1', 'TICKR'));
      expect(created, [strapIdOf('strap-1')]);
      expect(demo.isDisposed, isTrue);
      expect(strap.startCount, 1);
      expect(cubit.state, const LiveHeartRateState.waiting(isSimulated: false));
    });

    test('use switches to the source it is given and starts it, as for '
        'demo data', () async {
      final other = StubStrapDataSource(isSimulated: true);
      addTearDown(other.dispose);
      await selection.use(other);
      expect(created, isEmpty);
      expect(demo.isDisposed, isTrue);
      expect(other.startCount, 1);
      expect(cubit.state, const LiveHeartRateState.waiting(isSimulated: true));
    });

    test('clear goes back to no strap, disposing the current source', () async {
      await selection.clear();
      expect(demo.isDisposed, isTrue);
      expect(cubit.state, const LiveHeartRateState.noStrap());
    });

    test('still switches and starts if disposing demo mode fails, and '
        'reports the failure', () async {
      final failure = Exception('dispose failed');
      demo.disposeError = failure;
      await expectLater(
        selection.select(discoveredStrapOf('strap-1')),
        throwsA(same(failure)),
      );
      expect(strap.startCount, 1);
      expect(cubit.state, const LiveHeartRateState.waiting(isSimulated: false));
    });
  });

  group('StrapSelection by default', () {
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

    test(
      'connects to the picked strap over the real platform channel',
      () async {
        final connected = <Object?>[];
        // Pigeon wraps each reply in a one-item list.
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockDecodedMessageHandler(connectChannel, (message) async {
            connected.add(message);
            return <Object?>[BleConnected()];
          })
          ..setMockDecodedMessageHandler(
            disconnectChannel,
            (_) async => <Object?>[null],
          )
          ..setMockStreamHandler(
            eventsChannel,
            MockStreamHandler.inline(onListen: (_, _) {}),
          );
        final source = SwitchableStrapDataSource(
          StubStrapDataSource(isSimulated: true),
        );
        final cubit = LiveHeartRateCubit(source: source);
        await cubit.start();

        await StrapSelection(
          source: source,
          cubit: cubit,
        ).select(discoveredStrapOf('strap-1', 'TICKR'));

        expect(connected, [
          ['strap-1'],
        ]);
        expect(
          cubit.state,
          const LiveHeartRateState.waiting(isSimulated: false),
        );

        await cubit.close();
        await source.dispose();
      },
    );
  });
}
