import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

import '../helpers/positive_int.dart';
import '../helpers/stub_heart_rate_source.dart';

final _timestamp = DateTime(2026, 11, 11, 10, 52, 31);

final _measured = HeartRateSample.measured(
  bpm: positiveInt(72),
  timestamp: _timestamp,
  skinContact: SkinContact.detected,
);

void main() {
  group('ReadingOverride.next', () {
    test('cycles normal, stale, no skin contact, zero bpm, skin contact not '
        'supported, then wraps', () {
      expect(ReadingOverride.normal.next, ReadingOverride.stale);
      expect(ReadingOverride.stale.next, ReadingOverride.noSkinContact);
      expect(ReadingOverride.noSkinContact.next, ReadingOverride.zeroBpm);
      expect(
        ReadingOverride.zeroBpm.next,
        ReadingOverride.skinContactNotSupported,
      );
      expect(
        ReadingOverride.skinContactNotSupported.next,
        ReadingOverride.normal,
      );
    });
  });

  group('DebugOverrideHeartRateSource', () {
    late StubHeartRateSource inner;
    late DebugOverrideHeartRateSource source;
    late List<HeartRateSample> received;

    setUp(() {
      inner = StubHeartRateSource(isSimulated: true);
      source = DebugOverrideHeartRateSource(inner);
      received = [];
      source.samples.listen(received.add);
    });

    test('starts with no override', () {
      expect(source.mode, ReadingOverride.normal);
    });

    test('normal passes samples through unchanged', () {
      inner.emit(_measured);
      expect(received, [_measured]);
    });

    test('stale drops every sample', () {
      source.mode = ReadingOverride.stale;
      inner
        ..emit(_measured)
        ..emit(_measured);
      expect(received, isEmpty);
    });

    test('no skin contact replaces samples, keeping their timestamps', () {
      source.mode = ReadingOverride.noSkinContact;
      inner.emit(_measured);
      expect(received, [
        HeartRateSample.unavailable(
          timestamp: _timestamp,
          reason: HeartRateUnavailableReason.noSkinContact,
        ),
      ]);
    });

    test('zero bpm replaces samples, keeping their timestamps', () {
      source.mode = ReadingOverride.zeroBpm;
      inner.emit(_measured);
      expect(received, [
        HeartRateSample.unavailable(
          timestamp: _timestamp,
          reason: HeartRateUnavailableReason.zeroBpm,
        ),
      ]);
    });

    test(
      'skin contact not supported keeps bpm, timestamp and RR intervals',
      () {
        source.mode = ReadingOverride.skinContactNotSupported;
        final withRr = HeartRateSample.measured(
          bpm: positiveInt(72),
          timestamp: _timestamp,
          skinContact: SkinContact.detected,
          rrIntervals: const [Duration(milliseconds: 833)],
        );
        inner.emit(withRr);
        expect(received, [
          HeartRateSample.measured(
            bpm: positiveInt(72),
            timestamp: _timestamp,
            skinContact: SkinContact.notSupported,
            rrIntervals: const [Duration(milliseconds: 833)],
          ),
        ]);
      },
    );

    test('skin contact not supported passes unavailable samples through', () {
      source.mode = ReadingOverride.skinContactNotSupported;
      final unavailable = HeartRateSample.unavailable(
        timestamp: _timestamp,
        reason: HeartRateUnavailableReason.noSkinContact,
      );
      inner.emit(unavailable);
      expect(received, [unavailable]);
    });

    test('a mode change applies to the next sample', () {
      source.mode = ReadingOverride.stale;
      inner.emit(_measured);
      source.mode = ReadingOverride.normal;
      inner.emit(_measured);
      expect(received, [_measured]);
    });

    test('passes through isSimulated, start, stop and dispose', () async {
      expect(source.isSimulated, isTrue);
      expect(
        DebugOverrideHeartRateSource(StubHeartRateSource()).isSimulated,
        isFalse,
      );

      await source.start();
      await source.stop();
      await source.dispose();
      expect(inner.startCount, 1);
      expect(inner.stopCount, 1);
      expect(inner.isDisposed, isTrue);
    });
  });
}
