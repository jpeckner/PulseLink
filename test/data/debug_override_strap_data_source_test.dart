// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/data/debug_override_strap_data_source.dart';
import 'package:pulselink/data/strap_data_source.dart';
import 'package:pulselink/domain/battery_level.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

import '../helpers/beats_per_minute.dart';
import '../helpers/failing_strap_data_source.dart';
import '../helpers/stub_strap_data_source.dart';

final _timestamp = DateTime(2026, 11, 11, 10, 52, 31);

HeartRateSample _measured(SkinContact skinContact) => HeartRateSample.measured(
  beatsPerMinute: beatsPerMinuteOf(72),
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
  test('DebugOverrideStrapDataSource passes on the battery level', () async {
    final inner = StubStrapDataSource();
    final source = DebugOverrideStrapDataSource(inner);
    final levels = <BatteryLevel?>[];
    source.batteryLevel.listen(levels.add);
    inner.reportBatteryLevel(BatteryLevel.tryFrom(60));
    expect(levels, [BatteryLevel.tryFrom(60)]);
    await source.dispose();
  });
  test('DebugOverrideStrapDataSource passes on lost connections', () async {
    final inner = StubStrapDataSource();
    final source = DebugOverrideStrapDataSource(inner);
    final lost = <StrapConnectionFailure>[];
    source.connectionLost.listen(lost.add);
    inner.loseConnection(const StrapConnectionFailure.connectionLost());
    expect(lost, [const StrapConnectionFailure.connectionLost()]);
    await source.dispose();
  });
  group('condition cycles', () {
    test('a detecting strap cycles normal, stale, no skin contact, zero bpm, '
        'implausible bpm', () {
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
        DetectingStrapCondition.zeroBeatsPerMinute,
      );
      expect(
        DetectingStrapCondition.zeroBeatsPerMinute.next,
        DetectingStrapCondition.implausibleBeatsPerMinute,
      );
      expect(
        DetectingStrapCondition.implausibleBeatsPerMinute.next,
        DetectingStrapCondition.normal,
      );
    });

    test('a non-detecting strap cycles normal, stale, zero bpm, implausible '
        'bpm', () {
      expect(
        NonDetectingStrapCondition.normal.next,
        NonDetectingStrapCondition.stale,
      );
      expect(
        NonDetectingStrapCondition.stale.next,
        NonDetectingStrapCondition.zeroBeatsPerMinute,
      );
      expect(
        NonDetectingStrapCondition.zeroBeatsPerMinute.next,
        NonDetectingStrapCondition.implausibleBeatsPerMinute,
      );
      expect(
        NonDetectingStrapCondition.implausibleBeatsPerMinute.next,
        NonDetectingStrapCondition.normal,
      );
    });
  });

  group('ReadingOverrideControls', () {
    test('detection reflects the kind of strap', () {
      expect(
        _detecting(DetectingStrapCondition.zeroBeatsPerMinute).detection,
        SkinContactDetection.supported,
      );
      expect(
        _nonDetecting(NonDetectingStrapCondition.zeroBeatsPerMinute).detection,
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
        _nonDetecting(NonDetectingStrapCondition.zeroBeatsPerMinute),
      );
    });

    group('withOtherDetection', () {
      test('carries over conditions both kinds of strap share', () {
        for (final (detecting, nonDetecting) in [
          (DetectingStrapCondition.normal, NonDetectingStrapCondition.normal),
          (DetectingStrapCondition.stale, NonDetectingStrapCondition.stale),
          (
            DetectingStrapCondition.zeroBeatsPerMinute,
            NonDetectingStrapCondition.zeroBeatsPerMinute,
          ),
          (
            DetectingStrapCondition.implausibleBeatsPerMinute,
            NonDetectingStrapCondition.implausibleBeatsPerMinute,
          ),
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

  group('DebugOverrideStrapDataSource', () {
    late StubStrapDataSource inner;
    late DebugOverrideStrapDataSource source;
    late List<HeartRateSample> received;

    setUp(() {
      inner = StubStrapDataSource(isSimulated: true);
      source = DebugOverrideStrapDataSource(inner);
      received = [];
      source.samples.listen(received.add);
    });

    test('with no override, passes every sample through untouched', () {
      expect(source.readingOverride, isNull);
      final samples = [
        _measured(SkinContact.detected),
        _measured(SkinContact.notSupported),
        _unavailable(HeartRateUnavailableReason.noSkinContact),
        _unavailable(HeartRateUnavailableReason.zeroBeatsPerMinute),
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
          _unavailable(HeartRateUnavailableReason.zeroBeatsPerMinute),
          _unavailable(HeartRateUnavailableReason.implausibleBeatsPerMinute),
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
        source.readingOverride = _detecting(
          DetectingStrapCondition.zeroBeatsPerMinute,
        );
        inner.emit(_measured(SkinContact.detected));
        expect(received, [
          _unavailable(HeartRateUnavailableReason.zeroBeatsPerMinute),
        ]);
      });

      test('implausible bpm replaces samples, keeping timestamps', () {
        source.readingOverride = _detecting(
          DetectingStrapCondition.implausibleBeatsPerMinute,
        );
        inner.emit(_measured(SkinContact.detected));
        expect(received, [
          _unavailable(HeartRateUnavailableReason.implausibleBeatsPerMinute),
        ]);
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
          ..emit(_unavailable(HeartRateUnavailableReason.zeroBeatsPerMinute));
        expect(received, [
          _unavailable(HeartRateUnavailableReason.zeroBeatsPerMinute),
          _unavailable(HeartRateUnavailableReason.zeroBeatsPerMinute),
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
          NonDetectingStrapCondition.zeroBeatsPerMinute,
        );
        inner.emit(_measured(SkinContact.notSupported));
        expect(received, [
          _unavailable(HeartRateUnavailableReason.zeroBeatsPerMinute),
        ]);
      });

      test('implausible bpm replaces samples, keeping timestamps', () {
        source.readingOverride = _nonDetecting(
          NonDetectingStrapCondition.implausibleBeatsPerMinute,
        );
        inner.emit(_measured(SkinContact.notSupported));
        expect(received, [
          _unavailable(HeartRateUnavailableReason.implausibleBeatsPerMinute),
        ]);
      });

      test('normal passes a real implausible-bpm sample through', () {
        source.readingOverride = _nonDetecting(
          NonDetectingStrapCondition.normal,
        );
        inner.emit(
          _unavailable(HeartRateUnavailableReason.implausibleBeatsPerMinute),
        );
        expect(received, [
          _unavailable(HeartRateUnavailableReason.implausibleBeatsPerMinute),
        ]);
      });
    });

    group('reportedDetection', () {
      test('is null until the strap says anything about it', () {
        expect(source.reportedDetection, isNull);
        inner.emit(_unavailable(HeartRateUnavailableReason.zeroBeatsPerMinute));
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

      test('zero or implausible bpm keeps the last known value', () {
        inner
          ..emit(_measured(SkinContact.notSupported))
          ..emit(_unavailable(HeartRateUnavailableReason.zeroBeatsPerMinute))
          ..emit(
            _unavailable(HeartRateUnavailableReason.implausibleBeatsPerMinute),
          );
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
        DebugOverrideStrapDataSource(StubStrapDataSource()).isSimulated,
        isFalse,
      );

      expect(await source.start(), const StrapDataSourceStartResult.started());
      await source.stop();
      await source.dispose();
      expect(inner.startCount, 1);
      expect(inner.stopCount, 1);
      expect(inner.isDisposed, isTrue);
    });

    test("passes through the wrapped source's start failure", () async {
      inner.startResult = const StrapDataSourceStartResult.failed(
        StrapConnectionFailure.bluetooth(BluetoothProblem.off),
      );
      expect(
        await source.start(),
        const StrapDataSourceStartResult.failed(
          StrapConnectionFailure.bluetooth(BluetoothProblem.off),
        ),
      );
    });

    test('a second start joins the one in progress', () async {
      inner
        ..holdStart = true
        ..startResult = const StrapDataSourceStartResult.failed(
          StrapConnectionFailure.strapUnreachable(),
        );
      final first = source.start();
      final second = source.start();
      inner.finishStart();
      const failed = StrapDataSourceStartResult.failed(
        StrapConnectionFailure.strapUnreachable(),
      );
      expect(await first, failed);
      expect(await second, failed);
    });

    test('stop cancels a start the wrapped source is still making', () async {
      inner.holdStart = true;
      final start = source.start();
      expect(inner.isStarting, isTrue);
      await source.stop();
      expect(await start, const StrapDataSourceStartResult.cancelled());
    });
  });

  group('DebugOverrideStrapDataSource passes cleanup errors on when', () {
    // Passing the source's stop as a function lets the matcher catch an
    // error thrown before a future is returned, as well as a failed future.
    for (final failure in [
      StrapDataSourceFailure.stop,
      StrapDataSourceFailure.stopBeforeFuture,
    ]) {
      test(failure.description, () async {
        final source = DebugOverrideStrapDataSource(
          FailingStrapDataSource(failure),
        );
        await expectLater(source.stop, throwsA(same(strapDataSourceFailure)));
      });
    }

    for (final throwsBeforeFuture in [false, true]) {
      final description = throwsBeforeFuture
          ? 'dispose() throws before returning a future'
          : 'dispose() fails';
      test(description, () async {
        final source = DebugOverrideStrapDataSource(
          _FailingDisposeSource(throwsBeforeFuture: throwsBeforeFuture),
        );
        await expectLater(
          source.dispose,
          throwsA(same(strapDataSourceFailure)),
        );
      });
    }
  });
}

/// A source whose dispose() fails, either with a failed future or by throwing
/// before it returns one.
class _FailingDisposeSource extends StubStrapDataSource {
  new({required this.throwsBeforeFuture});

  final bool throwsBeforeFuture;

  @override
  Future<void> dispose() => throwsBeforeFuture
      ? throw strapDataSourceFailure
      : Future.error(strapDataSourceFailure);
}
