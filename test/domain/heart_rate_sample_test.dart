import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

HeartRateSample _sample({
  int bpm = 72,
  SensorContact contact = SensorContact.detected,
}) => HeartRateSample(
  bpm: bpm,
  timestamp: DateTime(2026, 11, 11),
  contact: contact,
);

void main() {
  group('HeartRateSample', () {
    group('hasUsableBpm', () {
      test('is true with contact detected and bpm above 0', () {
        expect(_sample().hasUsableBpm, isTrue);
      });

      test('is true when the sensor does not report contact', () {
        expect(
          _sample(contact: SensorContact.notSupported).hasUsableBpm,
          isTrue,
        );
      });

      test('is false when the sensor reports no contact', () {
        expect(
          _sample(contact: SensorContact.notDetected).hasUsableBpm,
          isFalse,
        );
      });

      test('is false for bpm 0', () {
        expect(_sample(bpm: 0).hasUsableBpm, isFalse);
      });
    });

    test('has value equality, including RR intervals', () {
      HeartRateSample withRr(int ms) =>
          _sample().copyWith(rrIntervals: [Duration(milliseconds: ms)]);
      expect(withRr(800), withRr(800));
      expect(withRr(800), isNot(withRr(801)));
    });
  });
}
