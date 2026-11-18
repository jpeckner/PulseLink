// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/domain/battery_level.dart';

void main() {
  group('BatteryLevel', () {
    group('tryFrom', () {
      test('accepts 0 to 100', () {
        expect(BatteryLevel.tryFrom(0)?.percent, 0);
        expect(BatteryLevel.tryFrom(85)?.percent, 85);
        expect(BatteryLevel.tryFrom(100)?.percent, 100);
      });

      test('returns null outside 0 to 100', () {
        expect(BatteryLevel.tryFrom(-1), isNull);
        expect(BatteryLevel.tryFrom(101), isNull);
        expect(BatteryLevel.tryFrom(255), isNull);
      });
    });

    test('is low below 20%', () {
      expect(BatteryLevel.tryFrom(19)?.isLow, isTrue);
      expect(BatteryLevel.tryFrom(20)?.isLow, isFalse);
    });

    test('has value equality, and prints as a percentage', () {
      expect(BatteryLevel.tryFrom(50), BatteryLevel.tryFrom(50));
      expect(
        BatteryLevel.tryFrom(50).hashCode,
        BatteryLevel.tryFrom(50).hashCode,
      );
      expect(BatteryLevel.tryFrom(50), isNot(BatteryLevel.tryFrom(51)));
      expect('${BatteryLevel.tryFrom(50)}', '50%');
    });
  });
}
