import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

import '../helpers/positive_int.dart';
import '../helpers/stub_heart_rate_source.dart';

final _timestamp = DateTime(2026, 11, 11, 10, 52, 31);

HeartRateSample _measured(SkinContact skinContact) => HeartRateSample.measured(
  bpm: positiveInt(72),
  timestamp: _timestamp,
  skinContact: skinContact,
  rrIntervals: const [Duration(milliseconds: 833)],
);

HeartRateSample _unavailable(HeartRateUnavailableReason reason) =>
    HeartRateSample.unavailable(timestamp: _timestamp, reason: reason);

const ReadingOverride Function(DetectingStrapCondition condition) _detecting =
    ReadingOverride.detectingStrap;
const ReadingOverride Function(NonDetectingStrapCondition condition)
_nonDetecting = ReadingOverride.nonDetectingStrap;

void main() {
  group('condition cycles', () {
    test(
      'a detecting strap cycles normal, stale, no skin contact, zero bpm',
      () {
        expect(
          DetectingStrapCondition.normal.next,
          DetectingStrapCondition.stale,
        );
        expect(
          DetectingStrapCondition.stale.next,
          DetectingStrapCondition.noSkinContact,
        );
        expect(
          DetectingStrapCondition.noSkinContact.next,
          DetectingStrapCondition.zeroBpm,
        );
        expect(
          DetectingStrapCondition.zeroBpm.next,
          DetectingStrapCondition.normal,
        );
      },
    );

    test('a non-detecting strap cycles normal, stale, zero bpm', () {
      expect(
        NonDetectingStrapCondition.normal.next,
        NonDetectingStrapCondition.stale,
      );
      expect(
        NonDetectingStrapCondition.stale.next,
        NonDetectingStrapCondition.zeroBpm,
      );
      expect(
        NonDetectingStrapCondition.zeroBpm.next,
        NonDetectingStrapCondition.normal,
      );
    });
  });

  group('ReadingOverrideControls', () {
    test('detection reflects the kind of strap', () {
      expect(
        _detecting(DetectingStrapCondition.zeroBpm).detection,
        SkinContactDetection.supported,
      );
      expect(
        _nonDetecting(NonDetectingStrapCondition.zeroBpm).detection,
        SkinContactDetection.notSupported,
      );
    });

    test('withNextCondition keeps the kind of strap', () {
      expect(
        _detecting(DetectingStrapCondition.stale).withNextCondition,
        _detecting(DetectingStrapCondition.noSkinContact),
      );
      expect(
        _nonDetecting(NonDetectingStrapCondition.stale).withNextCondition,
        _nonDetecting(NonDetectingStrapCondition.zeroBpm),
      );
    });

    group('withOtherDetection', () {
      test('carries over conditions both kinds of strap share', () {
        for (final (detecting, nonDetecting) in [
          (DetectingStrapCondition.normal, NonDetectingStrapCondition.normal),
          (DetectingStrapCondition.stale, NonDetectingStrapCondition.stale),
          (DetectingStrapCondition.zeroBpm, NonDetectingStrapCondition.zeroBpm),
        ]) {
          expect(
            _detecting(detecting).withOtherDetection,
            _nonDetecting(nonDetecting),
          );
          expect(
            _nonDetecting(nonDetecting).withOtherDetection,
            _detecting(detecting),
          );
        }
      });

      test('no skin contact becomes normal on a non-detecting strap', () {
        expect(
          _detecting(DetectingStrapCondition.noSkinContact).withOtherDetection,
          _nonDetecting(NonDetectingStrapCondition.normal),
        );
      });
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

    test('with no override, passes every sample through untouched', () {
      expect(source.readingOverride, isNull);
      final samples = [
        _measured(SkinContact.detected),
        _measured(SkinContact.notSupported),
        _unavailable(HeartRateUnavailableReason.noSkinContact),
        _unavailable(HeartRateUnavailableReason.zeroBpm),
      ]..forEach(inner.emit);
      expect(received, samples);
    });

    group('detecting strap', () {
      test('normal marks skin contact detected, keeping bpm and RR', () {
        source.readingOverride = _detecting(DetectingStrapCondition.normal);
        inner.emit(_measured(SkinContact.notSupported));
        expect(received, [_measured(SkinContact.detected)]);
      });

      test('normal passes unavailable samples through', () {
        source.readingOverride = _detecting(DetectingStrapCondition.normal);
        final samples = [
          _unavailable(HeartRateUnavailableReason.noSkinContact),
          _unavailable(HeartRateUnavailableReason.zeroBpm),
        ]..forEach(inner.emit);
        expect(received, samples);
      });

      test('stale drops every sample', () {
        source.readingOverride = _detecting(DetectingStrapCondition.stale);
        inner.emit(_measured(SkinContact.detected));
        expect(received, isEmpty);
      });

      test('no skin contact replaces samples, keeping timestamps', () {
        source.readingOverride = _detecting(
          DetectingStrapCondition.noSkinContact,
        );
        inner.emit(_measured(SkinContact.detected));
        expect(received, [
          _unavailable(HeartRateUnavailableReason.noSkinContact),
        ]);
      });

      test('zero bpm replaces samples, keeping timestamps', () {
        source.readingOverride = _detecting(DetectingStrapCondition.zeroBpm);
        inner.emit(_measured(SkinContact.detected));
        expect(received, [_unavailable(HeartRateUnavailableReason.zeroBpm)]);
      });
    });

    group('non-detecting strap', () {
      test('normal marks skin contact not supported, keeping bpm and RR', () {
        source.readingOverride = _nonDetecting(
          NonDetectingStrapCondition.normal,
        );
        inner.emit(_measured(SkinContact.detected));
        expect(received, [_measured(SkinContact.notSupported)]);
      });

      test('normal turns a real no-skin-contact sample into zero bpm', () {
        source.readingOverride = _nonDetecting(
          NonDetectingStrapCondition.normal,
        );
        inner
          ..emit(_unavailable(HeartRateUnavailableReason.noSkinContact))
          ..emit(_unavailable(HeartRateUnavailableReason.zeroBpm));
        expect(received, [
          _unavailable(HeartRateUnavailableReason.zeroBpm),
          _unavailable(HeartRateUnavailableReason.zeroBpm),
        ]);
      });

      test('stale drops every sample', () {
        source.readingOverride = _nonDetecting(
          NonDetectingStrapCondition.stale,
        );
        inner.emit(_measured(SkinContact.notSupported));
        expect(received, isEmpty);
      });

      test('zero bpm replaces samples, keeping timestamps', () {
        source.readingOverride = _nonDetecting(
          NonDetectingStrapCondition.zeroBpm,
        );
        inner.emit(_measured(SkinContact.notSupported));
        expect(received, [_unavailable(HeartRateUnavailableReason.zeroBpm)]);
      });
    });

    group('reportedDetection', () {
      test('is null until the strap says anything about it', () {
        expect(source.reportedDetection, isNull);
        inner.emit(_unavailable(HeartRateUnavailableReason.zeroBpm));
        expect(source.reportedDetection, isNull);
      });

      test('follows measured samples', () {
        inner.emit(_measured(SkinContact.notSupported));
        expect(source.reportedDetection, SkinContactDetection.notSupported);
        inner.emit(_measured(SkinContact.detected));
        expect(source.reportedDetection, SkinContactDetection.supported);
      });

      test('a no-skin-contact sample means detection is supported', () {
        inner.emit(_unavailable(HeartRateUnavailableReason.noSkinContact));
        expect(source.reportedDetection, SkinContactDetection.supported);
      });

      test('zero bpm keeps the last known value', () {
        inner
          ..emit(_measured(SkinContact.notSupported))
          ..emit(_unavailable(HeartRateUnavailableReason.zeroBpm));
        expect(source.reportedDetection, SkinContactDetection.notSupported);
      });

      test('reflects the strap, not the override', () {
        source.readingOverride = _detecting(DetectingStrapCondition.normal);
        inner.emit(_measured(SkinContact.notSupported));
        expect(received, [_measured(SkinContact.detected)]);
        expect(source.reportedDetection, SkinContactDetection.notSupported);
      });
    });

    test('a change of override applies to the next sample', () {
      source.readingOverride = _detecting(DetectingStrapCondition.stale);
      inner.emit(_measured(SkinContact.detected));
      source.readingOverride = null;
      inner.emit(_measured(SkinContact.detected));
      expect(received, [_measured(SkinContact.detected)]);
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
