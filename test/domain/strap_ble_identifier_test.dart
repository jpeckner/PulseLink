// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/domain/strap_ble_identifier.dart';

import '../helpers/discovered_strap.dart';

void main() {
  group('StrapBleIdentifier', () {
    group('tryFrom', () {
      test('accepts an iOS UUID and an Android MAC address as given', () {
        const uuid = 'E621E1F8-C36C-495A-93FC-0C247A3E6E5F';
        const mac = 'A0:9E:1A:12:34:56';
        expect(StrapBleIdentifier.tryFrom(uuid)?.value, uuid);
        expect(StrapBleIdentifier.tryFrom(mac)?.value, mac);
      });

      test('returns null for an empty or blank string', () {
        expect(StrapBleIdentifier.tryFrom(''), isNull);
        expect(StrapBleIdentifier.tryFrom('   '), isNull);
      });

      test('keeps surrounding whitespace, since the stack matches exactly', () {
        expect(StrapBleIdentifier.tryFrom(' id ')?.value, ' id ');
      });
    });

    test('has value equality', () {
      expect(strapIdOf('polar'), strapIdOf('polar'));
      expect(strapIdOf('polar').hashCode, strapIdOf('polar').hashCode);
      expect(strapIdOf('polar'), isNot(strapIdOf('tickr')));
      expect({strapIdOf('polar'), strapIdOf('polar')}, hasLength(1));
    });

    test('is not equal to a plain String with the same value', () {
      // Comparing unrelated types on purpose, to prove it's false.
      // ignore: unrelated_type_equality_checks
      expect(strapIdOf('polar') == 'polar', isFalse);
    });

    test('prints as the bare identifier', () {
      expect('${strapIdOf('polar')}', 'polar');
    });
  });
}
