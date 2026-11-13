import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/domain/bpm.dart';

import '../helpers/bpm.dart';

void main() {
  group('Bpm', () {
    group('tryFrom', () {
      test('accepts 1 to Bpm.max', () {
        expect(Bpm.max, 250);
        expect(Bpm.tryFrom(1)?.value, 1);
        expect(Bpm.tryFrom(72)?.value, 72);
        expect(Bpm.tryFrom(250)?.value, 250);
      });

      test('returns null for 0 and below', () {
        expect(Bpm.tryFrom(0), isNull);
        expect(Bpm.tryFrom(-1), isNull);
      });

      test('returns null above Bpm.max', () {
        expect(Bpm.tryFrom(251), isNull);
        expect(Bpm.tryFrom(65535), isNull);
      });
    });

    test('has value equality', () {
      expect(bpmOf(72), bpmOf(72));
      expect(bpmOf(72).hashCode, bpmOf(72).hashCode);
      expect(bpmOf(72), isNot(bpmOf(73)));
      expect({bpmOf(72), bpmOf(72)}, hasLength(1));
    });

    test('is not equal to a plain int with the same value', () {
      // Comparing unrelated types on purpose, to prove it's false.
      // ignore: unrelated_type_equality_checks
      expect(bpmOf(72) == 72, isFalse);
    });

    test('prints as the bare number', () {
      expect(bpmOf(72).toString(), '72');
      expect('${bpmOf(72)} bpm', '72 bpm');
    });
  });
}
