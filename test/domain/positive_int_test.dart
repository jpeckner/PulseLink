import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/domain/positive_int.dart';

import '../helpers/positive_int.dart';

void main() {
  group('PositiveInt', () {
    group('tryFrom', () {
      test('accepts values above 0', () {
        expect(PositiveInt.tryFrom(1)?.value, 1);
        expect(PositiveInt.tryFrom(72)?.value, 72);
        expect(PositiveInt.tryFrom(65535)?.value, 65535);
      });

      test('returns null for 0 and below', () {
        expect(PositiveInt.tryFrom(0), isNull);
        expect(PositiveInt.tryFrom(-1), isNull);
      });
    });

    test('has value equality', () {
      expect(positiveInt(72), positiveInt(72));
      expect(positiveInt(72).hashCode, positiveInt(72).hashCode);
      expect(positiveInt(72), isNot(positiveInt(73)));
      expect({positiveInt(72), positiveInt(72)}, hasLength(1));
    });

    test('is not equal to a plain int with the same value', () {
      // Comparing unrelated types on purpose, to prove it's false.
      // ignore: unrelated_type_equality_checks
      expect(positiveInt(72) == 72, isFalse);
    });

    test('prints as the bare number', () {
      expect(positiveInt(72).toString(), '72');
      expect('${positiveInt(72)} bpm', '72 bpm');
    });
  });
}
