import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

import '../helpers/positive_int.dart';

final _timestamp = DateTime(2026, 11, 11);

void main() {
  group('HeartRateSample', () {
    group('measured', () {
      test('accepts contact detected or not reported', () {
        for (final contact in [
          MeasuredContact.detected,
          MeasuredContact.notReported,
        ]) {
          expect(
            HeartRateSample.measured(
              bpm: positiveInt(72),
              timestamp: _timestamp,
              contact: contact,
            ),
            isA<MeasuredHeartRateSample>(),
          );
        }
      });

      test('defaults to no RR intervals', () {
        final sample = HeartRateSample.measured(
          bpm: positiveInt(72),
          timestamp: _timestamp,
          contact: MeasuredContact.detected,
        ) as MeasuredHeartRateSample;
        expect(sample.rrIntervals, isEmpty);
      });

      test('has value equality, including RR intervals', () {
        HeartRateSample withRr(int ms) => HeartRateSample.measured(
          bpm: positiveInt(72),
          timestamp: _timestamp,
          contact: MeasuredContact.detected,
          rrIntervals: [Duration(milliseconds: ms)],
        );
        expect(withRr(800), withRr(800));
        expect(withRr(800), isNot(withRr(801)));
      });
    });

    group('unavailable', () {
      test('has value equality, including the reason', () {
        HeartRateSample unavailable(HeartRateUnavailableReason reason) =>
            HeartRateSample.unavailable(timestamp: _timestamp, reason: reason);
        expect(
          unavailable(HeartRateUnavailableReason.noContact),
          unavailable(HeartRateUnavailableReason.noContact),
        );
        expect(
          unavailable(HeartRateUnavailableReason.noContact),
          isNot(unavailable(HeartRateUnavailableReason.zeroBpm)),
        );
      });
    });

    test('exposes the timestamp on both cases without a switch', () {
      final samples = [
        HeartRateSample.measured(
          bpm: positiveInt(72),
          timestamp: _timestamp,
          contact: MeasuredContact.detected,
        ),
        HeartRateSample.unavailable(
          timestamp: _timestamp,
          reason: HeartRateUnavailableReason.zeroBpm,
        ),
      ];
      expect(samples.map((s) => s.timestamp), everyElement(_timestamp));
    });
  });
}
