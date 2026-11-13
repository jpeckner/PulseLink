import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/blocs/debug_override/debug_override_cubit.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';
import 'package:pulselink/ui/debug/debug_override_buttons.dart';

import '../helpers/stub_heart_rate_source.dart';

const _supported = 'Skin-contact detection: supported';
const _notSupported = 'Skin-contact detection: not supported';

void main() {
  group('DebugOverrideButtons', () {
    late DebugOverrideHeartRateSource source;
    late DebugOverrideCubit cubit;

    setUp(() {
      source = DebugOverrideHeartRateSource(StubHeartRateSource());
      cubit = DebugOverrideCubit(source: source);
    });

    tearDown(() => cubit.close());

    Future<void> pumpButtons(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            // Same padding as the live screen.
            padding: const EdgeInsets.all(24),
            child: DebugOverrideButtons(cubit: cubit),
          ),
        ),
      ),
    );

    testWidgets('are hidden until revealed', (tester) async {
      await pumpButtons(tester);
      expect(find.byType(OutlinedButton), findsNothing);

      cubit.toggleVisibility();
      await tester.pump();
      expect(find.text(_supported), findsOneWidget);
      expect(find.text('Override: Normal'), findsOneWidget);
    });

    testWidgets('the condition button cycles what a detecting strap can do', (
      tester,
    ) async {
      cubit.toggleVisibility();
      await pumpButtons(tester);

      for (final label in [
        'Override: No data (stale)',
        'Override: No skin contact',
        'Override: Zero bpm',
        'Override: Implausible bpm',
        'Override: Normal',
      ]) {
        await tester.tap(find.textContaining('Override:'));
        await tester.pump();
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('a non-detecting strap skips no skin contact', (tester) async {
      cubit.toggleVisibility();
      await pumpButtons(tester);
      await tester.tap(find.text(_supported));
      await tester.pump();
      expect(find.text(_notSupported), findsOneWidget);

      for (final label in [
        'Override: No data (stale)',
        'Override: Zero bpm',
        'Override: Implausible bpm',
        'Override: Normal',
      ]) {
        await tester.tap(find.textContaining('Override:'));
        await tester.pump();
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('switching strap from no skin contact resets to normal', (
      tester,
    ) async {
      cubit.toggleVisibility();
      await pumpButtons(tester);
      await tester.tap(find.textContaining('Override:'));
      await tester.pump();
      await tester.tap(find.textContaining('Override:'));
      await tester.pump();
      expect(find.text('Override: No skin contact'), findsOneWidget);

      await tester.tap(find.text(_supported));
      await tester.pump();
      expect(find.text(_notSupported), findsOneWidget);
      expect(find.text('Override: Normal'), findsOneWidget);
    });

    testWidgets('disappear when hidden again', (tester) async {
      cubit.toggleVisibility();
      await pumpButtons(tester);
      expect(find.byType(OutlinedButton), findsNWidgets(2));

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
      await pumpButtons(tester);

      // Every condition on both kinds of strap.
      for (var strap = 0; strap < 2; strap++) {
        for (var i = 0; i < 4; i++) {
          expect(tester.takeException(), isNull);
          await tester.tap(find.textContaining('Override:'));
          await tester.pump();
        }
        await tester.tap(find.textContaining('Skin-contact detection:'));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });
  });
}
