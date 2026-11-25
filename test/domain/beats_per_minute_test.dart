// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/domain/beats_per_minute.dart';

import '../helpers/beats_per_minute.dart';

void main() {
  group('BeatsPerMinute', () {
    group('tryFrom', () {
      test('accepts 1 to BeatsPerMinute.max', () {
        expect(BeatsPerMinute.max, 250);
        expect(BeatsPerMinute.tryFrom(1)?.value, 1);
        expect(BeatsPerMinute.tryFrom(72)?.value, 72);
        expect(BeatsPerMinute.tryFrom(250)?.value, 250);
      });

      test('returns null for 0 and below', () {
        expect(BeatsPerMinute.tryFrom(0), isNull);
        expect(BeatsPerMinute.tryFrom(-1), isNull);
      });

      test('returns null above BeatsPerMinute.max', () {
        expect(BeatsPerMinute.tryFrom(251), isNull);
        expect(BeatsPerMinute.tryFrom(65535), isNull);
      });
    });

    test('has value equality', () {
      expect(beatsPerMinuteOf(72), beatsPerMinuteOf(72));
      expect(beatsPerMinuteOf(72).hashCode, beatsPerMinuteOf(72).hashCode);
      expect(beatsPerMinuteOf(72), isNot(beatsPerMinuteOf(73)));
      expect({beatsPerMinuteOf(72), beatsPerMinuteOf(72)}, hasLength(1));
    });

    test('is not equal to a plain int with the same value', () {
      // Comparing unrelated types on purpose, to prove it's false.
      // ignore: unrelated_type_equality_checks
      expect(beatsPerMinuteOf(72) == 72, isFalse);
    });

    test('prints as the bare number', () {
      expect(beatsPerMinuteOf(72).toString(), '72');
      expect('${beatsPerMinuteOf(72)} bpm', '72 bpm');
    });
  });
}
