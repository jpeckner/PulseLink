import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/data/strap_data_source.dart';
import 'package:pulselink/data/switchable_strap_data_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

import '../helpers/beats_per_minute.dart';
import '../helpers/stub_strap_data_source.dart';

HeartRateSample _sample(int beatsPerMinute) => HeartRateSample.measured(
  beatsPerMinute: beatsPerMinuteOf(beatsPerMinute),
  timestamp: clock.now(),
  skinContact: SkinContact.detected,
);

/// Lets pending sample deliveries arrive: `samples` is asynchronous.
Future<void> _delivered() => Future<void>.delayed(Duration.zero);

void main() {
  group('SwitchableStrapDataSource connectionLost', () {
    late StubStrapDataSource demo;
    late StubStrapDataSource strap;
    late SwitchableStrapDataSource source;
    late List<StrapConnectionFailure> lost;

    setUp(() {
      demo = StubStrapDataSource(isSimulated: true);
      strap = StubStrapDataSource();
      source = SwitchableStrapDataSource(demo);
      lost = [];
      source.connectionLost.listen(lost.add);
    });

    tearDown(() => source.dispose());

    test('passes on lost connections from the current source only', () async {
      await source.switchTo(strap);
      expect(demo.hasConnectionLostListener, isFalse);
      strap.loseConnection(const StrapConnectionFailure.connectionLost());
      await _delivered();
      expect(lost, [const StrapConnectionFailure.connectionLost()]);
    });

    test('closes on dispose', () async {
      var closed = false;
      source.connectionLost.listen(null, onDone: () => closed = true);
      await source.dispose();
      expect(closed, isTrue);
    });
  });
  group('SwitchableStrapDataSource', () {
    late StubStrapDataSource demo;
    late StubStrapDataSource strap;
    late SwitchableStrapDataSource source;
    late List<HeartRateSample> samples;

    setUp(() {
      demo = StubStrapDataSource(isSimulated: true);
      strap = StubStrapDataSource();
      source = SwitchableStrapDataSource(demo);
      samples = [];
      source.samples.listen(samples.add);
    });

    tearDown(() => source.dispose());

    test('passes on the initial source: its samples, whether it is '
        'simulated, and starting and stopping', () async {
      expect(source.isSimulated, isTrue);
      expect(await source.start(), const StrapDataSourceStartResult.started());
      expect(demo.startCount, 1);

      demo.emit(_sample(72));
      await _delivered();
      expect(samples.map(_beatsPerMinute), [72]);

      await source.stop();
      expect(demo.stopCount, 1);
    });

    group('switchTo', () {
      test('passes on the new source from then on, and disposes the old '
          'one', () async {
        await source.switchTo(strap);
        expect(source.isSimulated, isFalse);
        expect(demo.isDisposed, isTrue);
        expect(demo.hasListener, isFalse);

        strap.emit(_sample(80));
        await _delivered();
        expect(samples.map(_beatsPerMinute), [80]);

        expect(
          await source.start(),
          const StrapDataSourceStartResult.started(),
        );
        expect(strap.startCount, 1);
        expect(demo.startCount, 0);
      });

      test("doesn't start the new source", () async {
        await source.switchTo(strap);
        expect(strap.startCount, 0);
      });

      test('cancels a start still in progress on the old source', () async {
        demo.holdStart = true;
        final starting = source.start();
        await source.switchTo(strap);
        expect(await starting, const StrapDataSourceStartResult.cancelled());
      });

      test('keeps the new source even if disposing the old one fails, and '
          'reports the failure', () async {
        final failure = Exception('dispose failed');
        demo.disposeError = failure;
        await expectLater(source.switchTo(strap), throwsA(same(failure)));
        expect(source.isSimulated, isFalse);
        strap.emit(_sample(80));
        await _delivered();
        expect(samples.map(_beatsPerMinute), [80]);
      });

      test('after dispose, disposes the new source instead', () async {
        await source.dispose();
        await source.switchTo(strap);
        expect(strap.isDisposed, isTrue);
        expect(
          await source.start(),
          const StrapDataSourceStartResult.cancelled(),
        );
      });
    });

    group('dispose', () {
      test('disposes the current source and closes samples', () async {
        var closed = false;
        source.samples.listen(null, onDone: () => closed = true);
        await source.dispose();
        expect(demo.isDisposed, isTrue);
        expect(closed, isTrue);
      });

      test('closes samples even if disposing the current source fails, and '
          'reports the failure', () async {
        final failure = Exception('dispose failed');
        demo.disposeError = failure;
        var closed = false;
        source.samples.listen(null, onDone: () => closed = true);
        await expectLater(source.dispose(), throwsA(same(failure)));
        expect(closed, isTrue);
      });

      test(
        'start afterwards is cancelled, without starting anything',
        () async {
          await source.dispose();
          expect(
            await source.start(),
            const StrapDataSourceStartResult.cancelled(),
          );
          expect(demo.startCount, 0);
        },
      );
    });
  });
}

int? _beatsPerMinute(HeartRateSample sample) => switch (sample) {
  MeasuredHeartRateSample(:final beatsPerMinute) => beatsPerMinute.value,
  UnavailableHeartRateSample() => null,
};
