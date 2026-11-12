import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/blocs/debug_override/debug_override_cubit.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';
import 'package:pulselink/ui/debug/debug_override_button.dart';

import '../helpers/stub_heart_rate_source.dart';

void main() {
  group('DebugOverrideButton', () {
    late DebugOverrideHeartRateSource source;
    late DebugOverrideCubit cubit;

    setUp(() {
      source = DebugOverrideHeartRateSource(StubHeartRateSource());
      cubit = DebugOverrideCubit(source: source);
    });

    tearDown(() => cubit.close());

    Future<void> pumpButton(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DebugOverrideButton(cubit: cubit)),
      ),
    );

    testWidgets('is hidden until revealed', (tester) async {
      await pumpButton(tester);
      expect(find.byType(OutlinedButton), findsNothing);

      cubit.toggleVisibility();
      await tester.pump();
      expect(find.text('Override: Normal'), findsOneWidget);
    });

    testWidgets('each tap shows and applies the next override', (tester) async {
      cubit.toggleVisibility();
      await pumpButton(tester);

      for (final (label, mode) in [
        ('Override: No data (stale)', ReadingOverride.stale),
        ('Override: No skin contact', ReadingOverride.noSkinContact),
        ('Override: Zero bpm', ReadingOverride.zeroBpm),
        (
          'Override: Skin contact not supported',
          ReadingOverride.skinContactNotSupported,
        ),
        ('Override: Normal', ReadingOverride.normal),
      ]) {
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        expect(find.text(label), findsOneWidget);
        expect(source.mode, mode);
      }
    });

    testWidgets('disappears when hidden again', (tester) async {
      cubit.toggleVisibility();
      await pumpButton(tester);
      expect(find.byType(OutlinedButton), findsOneWidget);

      cubit.toggleVisibility();
      await tester.pump();
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('every label fits a 320 px wide screen without overflow', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      cubit.toggleVisibility();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              // Same horizontal padding as the live screen.
              padding: const EdgeInsets.all(24),
              child: DebugOverrideButton(cubit: cubit),
            ),
          ),
        ),
      );
      for (var i = 0; i < ReadingOverride.values.length; i++) {
        expect(tester.takeException(), isNull, reason: '${source.mode}');
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
      }
    });
  });
}
