import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/domain/heart_rate_measurement_parser.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/positive_int.dart';

final _timestamp = DateTime(2026, 11, 11, 10, 52, 31);

HeartRateParseResult _parse(List<int> bytes) =>
    parseHeartRateMeasurement(Uint8List.fromList(bytes), timestamp: _timestamp);

HeartRateSample _parseSample(List<int> bytes) => switch (_parse(bytes)) {
  HeartRateParseSuccess(:final sample) => sample,
  HeartRateParseFailure(:final error) => fail('Expected a sample, got $error'),
};

MeasuredHeartRateSample _parseMeasured(List<int> bytes) =>
    switch (_parseSample(bytes)) {
      final MeasuredHeartRateSample sample => sample,
      final UnavailableHeartRateSample sample => fail(
        'Expected a measured sample, got $sample',
      ),
    };

HeartRateParseError _parseError(List<int> bytes) => switch (_parse(bytes)) {
  HeartRateParseFailure(:final error) => error,
  HeartRateParseSuccess(:final sample) => fail('Expected an error: $sample'),
};

HeartRateSample _unavailable(HeartRateUnavailableReason reason) =>
    HeartRateSample.unavailable(timestamp: _timestamp, reason: reason);

void main() {
  group('parseHeartRateMeasurement', () {
    group('plan fixtures', () {
      test('[0x16, 0x48, 0x00, 0x04] is 72 bpm, contact, RR 1000 ms', () {
        expect(
          _parseSample([0x16, 0x48, 0x00, 0x04]),
          HeartRateSample.measured(
            bpm: PositiveInt(72),
            timestamp: _timestamp,
            contact: MeasuredContact.detected,
            rrIntervals: const [Duration(milliseconds: 1000)],
          ),
        );
      });

      test('[0x01, 0xB4, 0x00] is 180 bpm (uint16), contact unsupported', () {
        expect(
          _parseSample([0x01, 0xB4, 0x00]),
          HeartRateSample.measured(
            bpm: PositiveInt(180),
            timestamp: _timestamp,
            contact: MeasuredContact.notReported,
          ),
        );
      });
    });

    group('heart-rate value', () {
      test('reads uint8 bpm', () {
        expect(_parseMeasured([0x00, 0x3C]).bpm.value, 60);
      });

      test('reads uint16 bpm little-endian', () {
        expect(_parseMeasured([0x01, 0x2C, 0x01]).bpm.value, 300);
      });

      test('reads the full uint8 range', () {
        expect(_parseMeasured([0x00, 0xFF]).bpm.value, 255);
      });

      test('stamps the sample with the given timestamp', () {
        expect(_parseSample([0x00, 0x48]).timestamp, _timestamp);
      });
    });

    group('sensor contact', () {
      test('bit 2 clear: measured, contact not reported, whatever bit 1 '
          'says', () {
        expect(
          _parseMeasured([0x00, 0x48]).contact,
          MeasuredContact.notReported,
        );
        expect(
          _parseMeasured([0x02, 0x48]).contact,
          MeasuredContact.notReported,
        );
      });

      test('bits 1 and 2 set: measured, contact detected', () {
        expect(_parseMeasured([0x06, 0x48]).contact, MeasuredContact.detected);
      });
    });

    group('unavailable readings', () {
      test('bit 2 set, bit 1 clear: unavailable, no contact', () {
        expect(
          _parseSample([0x04, 0x48]),
          _unavailable(HeartRateUnavailableReason.noContact),
        );
      });

      test('bpm 0: unavailable, zero bpm', () {
        expect(
          _parseSample([0x00, 0x00]),
          _unavailable(HeartRateUnavailableReason.zeroBpm),
        );
        expect(
          _parseSample([0x06, 0x00]),
          _unavailable(HeartRateUnavailableReason.zeroBpm),
        );
      });

      test('uint16 bpm 0: unavailable, zero bpm', () {
        expect(
          _parseSample([0x01, 0x00, 0x00]),
          _unavailable(HeartRateUnavailableReason.zeroBpm),
        );
      });

      test('no contact and bpm 0: no contact wins', () {
        expect(
          _parseSample([0x04, 0x00]),
          _unavailable(HeartRateUnavailableReason.noContact),
        );
      });

      test('drops RR intervals when there is no contact', () {
        expect(
          _parseSample([0x14, 0x48, 0x00, 0x04]),
          _unavailable(HeartRateUnavailableReason.noContact),
        );
      });

      test('a malformed no-contact packet is still a parse failure', () {
        expect(
          _parseError([0x14, 0x48, 0x00]),
          HeartRateParseError.truncatedRrInterval,
        );
      });
    });

    group('energy expended', () {
      test('is skipped, and RR intervals after it are still read', () {
        final sample = _parseMeasured([0x18, 0x48, 0x10, 0x27, 0x00, 0x04]);
        expect(sample.bpm.value, 72);
        expect(sample.rrIntervals, const [Duration(milliseconds: 1000)]);
      });

      test('works with uint16 bpm', () {
        expect(_parseMeasured([0x09, 0xB4, 0x00, 0x10, 0x27]).bpm.value, 180);
      });
    });

    group('RR intervals', () {
      test('reads several per packet, in order', () {
        expect(
          _parseMeasured([0x10, 0x48, 0x00, 0x04, 0x00, 0x02]).rrIntervals,
          const [Duration(milliseconds: 1000), Duration(milliseconds: 500)],
        );
      });

      test('converts 1/1024 s units to microseconds, rounded', () {
        // 1/1024 s = 976.5625 µs.
        expect(_parseMeasured([0x10, 0x48, 0x01, 0x00]).rrIntervals, const [
          Duration(microseconds: 977),
        ]);
      });

      test('reads the full uint16 range', () {
        // 65535/1024 s = 63999.0234375 ms.
        expect(_parseMeasured([0x10, 0x48, 0xFF, 0xFF]).rrIntervals, const [
          Duration(microseconds: 63999023),
        ]);
      });

      test('flag set with no interval bytes gives an empty list', () {
        expect(_parseMeasured([0x10, 0x48]).rrIntervals, isEmpty);
      });

      test('are empty when the flag is clear, ignoring trailing bytes', () {
        expect(_parseMeasured([0x00, 0x48, 0x00, 0x04]).rrIntervals, isEmpty);
      });
    });

    test('ignores the reserved flag bits 5-7', () {
      expect(
        _parseSample([0xE0 | 0x06, 0x48]),
        HeartRateSample.measured(
          bpm: PositiveInt(72),
          timestamp: _timestamp,
          contact: MeasuredContact.detected,
        ),
      );
    });

    group('malformed packets fail instead of returning a wrong number', () {
      final cases = <String, (List<int>, HeartRateParseError)>{
        'empty packet': (<int>[], HeartRateParseError.empty),
        'flags only, uint8 bpm': (
          [0x00],
          HeartRateParseError.truncatedHeartRate,
        ),
        'flags only, uint16 bpm': (
          [0x01],
          HeartRateParseError.truncatedHeartRate,
        ),
        'one byte of a uint16 bpm': (
          [0x01, 0xB4],
          HeartRateParseError.truncatedHeartRate,
        ),
        'energy expended missing': (
          [0x08, 0x48],
          HeartRateParseError.truncatedEnergyExpended,
        ),
        'energy expended half there': (
          [0x08, 0x48, 0x10],
          HeartRateParseError.truncatedEnergyExpended,
        ),
        'one byte of an RR interval': (
          [0x10, 0x48, 0x00],
          HeartRateParseError.truncatedRrInterval,
        ),
        'RR interval cut short after a whole one': (
          [0x10, 0x48, 0x00, 0x04, 0x00],
          HeartRateParseError.truncatedRrInterval,
        ),
      };

      for (final MapEntry(key: name, value: (bytes, error)) in cases.entries) {
        test(name, () => expect(_parseError(bytes), error));
      }
    });

    test('reads a view into a larger buffer correctly', () {
      final buffer = Uint8List.fromList([0xAA, 0xBB, 0x16, 0x48, 0x00, 0x04]);
      final result = parseHeartRateMeasurement(
        Uint8List.sublistView(buffer, 2),
        timestamp: _timestamp,
      );
      expect(
        result,
        HeartRateParseResult.success(
          HeartRateSample.measured(
            bpm: PositiveInt(72),
            timestamp: _timestamp,
            contact: MeasuredContact.detected,
            rrIntervals: const [Duration(milliseconds: 1000)],
          ),
        ),
      );
    });
  });
}
