// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/domain/strap_ble_name.dart';

import '../helpers/discovered_strap.dart';

void main() {
  group('StrapBleName', () {
    group('tryFrom', () {
      test('accepts a name', () {
        expect(
          StrapBleName.tryFrom('Polar H10 12345678')?.value,
          'Polar H10 12345678',
        );
      });

      test('trims surrounding whitespace', () {
        expect(StrapBleName.tryFrom('  TICKR  ')?.value, 'TICKR');
      });

      test('returns null for an empty or blank string', () {
        expect(StrapBleName.tryFrom(''), isNull);
        expect(StrapBleName.tryFrom('   '), isNull);
        expect(StrapBleName.tryFrom('\t\n'), isNull);
      });
    });

    test('has value equality', () {
      expect(strapNameOf('TICKR'), strapNameOf('TICKR'));
      expect(strapNameOf('TICKR').hashCode, strapNameOf('TICKR').hashCode);
      expect(strapNameOf('TICKR'), isNot(strapNameOf('Polar H10')));
      expect(strapNameOf(' TICKR '), strapNameOf('TICKR'));
    });

    test('is not equal to a plain String with the same value', () {
      // Comparing unrelated types on purpose, to prove it's false.
      // ignore: unrelated_type_equality_checks
      expect(strapNameOf('TICKR') == 'TICKR', isFalse);
    });

    test('prints as the bare name', () {
      expect('${strapNameOf('TICKR')}', 'TICKR');
    });
  });
}
