// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/l10n/l10n.dart';

import '../helpers/english.dart';

void main() {
  final time = DateTime(2026, 11, 16, 9, 41, 7);

  /// Pumps a widget that hands back `context.l10n`.
  Future<AppLocalizations> l10nIn(
    WidgetTester tester,
    Widget Function(Widget child) wrap,
  ) async {
    late AppLocalizations found;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            found = context.l10n;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return found;
  }

  group('context.l10n', () {
    testWidgets("uses the app's localizations inside the app", (tester) async {
      final l10n = await l10nIn(
        tester,
        (child) => MaterialApp(
          localizationsDelegates: pulseLinkLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
      expect(l10n.localeName, 'en');
      expect(l10n.updatedAt(time), 'Updated 9:41:07 AM');
    });

    testWidgets('falls back to US English outside them, without throwing', (
      tester,
    ) async {
      final l10n = await l10nIn(
        tester,
        (child) => Directionality(textDirection: .ltr, child: child),
      );
      expect(l10n.localeName, 'en_US');
      expect(l10n.lastReadingAt(time), startsWith('Last reading 9:41:07'));
    });
  });

  group('English strings', () {
    test('screen-reader bpm labels use the singular for 1', () {
      expect(english.beatsPerMinuteLabel(1), '1 beat per minute');
      expect(english.beatsPerMinuteLabel(72), '72 beats per minute');
      expect(
        english.staleBeatsPerMinuteLabel(1),
        'Last reading 1 beat per minute, out of date',
      );
      expect(
        english.staleBeatsPerMinuteLabel(72),
        'Last reading 72 beats per minute, out of date',
      );
    });

    test('battery strings', () {
      expect(english.batteryPercent(80), '80%');
      expect(english.batteryLabel(80), 'Strap battery 80 percent');
      expect(english.batteryLowLabel(15), 'Strap battery 15 percent, low');
    });
  });
}
