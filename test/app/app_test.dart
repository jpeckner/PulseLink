import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/app/app.dart';
import 'package:pulselink/blocs/debug_override/debug_override_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/ui/debug/debug_override_buttons.dart';
import 'package:pulselink/ui/widgets/disclaimer_banner.dart';

import '../helpers/beats_per_minute.dart';
import '../helpers/stub_heart_rate_source.dart';

void main() {
  group('PulseLinkApp', () {
    testWidgets('shows live samples from the cubit it is given', (
      tester,
    ) async {
      final source = StubHeartRateSource(isSimulated: true);
      final cubit = LiveHeartRateCubit(source: source);
      unawaited(cubit.start());
      await tester.pumpWidget(PulseLinkApp(liveHeartRateCubit: cubit));

      expect(find.text('PulseLink'), findsOneWidget);
      expect(find.text('Demo'), findsOneWidget);
      expect(find.text('--'), findsOneWidget);
      expect(find.text(disclaimerText), findsOneWidget);

      source.emit(
        HeartRateSample.measured(
          beatsPerMinute: beatsPerMinuteOf(72),
          timestamp: clock.now(),
          skinContact: SkinContact.detected,
        ),
      );
      await tester.pump();
      expect(find.text('72'), findsOneWidget);

      // The caller owns the cubit. Closing it here also cancels its stale
      // timer, which must not outlive the test.
      unawaited(cubit.close());
      await tester.pump();
    });

    testWidgets('debug wiring: long-press reveals the override buttons, '
        'which rewrite samples, and hiding them restores them', (tester) async {
      // Wired the way main() does in debug and profile builds.
      final source = StubHeartRateSource(isSimulated: true);
      final overrideSource = DebugOverrideHeartRateSource(source);
      final overrideCubit = DebugOverrideCubit(source: overrideSource);
      final cubit = LiveHeartRateCubit(source: overrideSource);
      unawaited(cubit.start());
      await tester.pumpWidget(
        PulseLinkApp(
          liveHeartRateCubit: cubit,
          debugControls: DebugOverrideButtons(cubit: overrideCubit),
          onTitleLongPress: overrideCubit.toggleVisibility,
        ),
      );
      HeartRateSample sample() => HeartRateSample.measured(
        beatsPerMinute: beatsPerMinuteOf(72),
        timestamp: clock.now(),
        skinContact: SkinContact.detected,
      );

      final readoutBefore = tester.getCenter(find.text('bpm'));
      await tester.longPress(find.text('PulseLink'));
      await tester.pump();
      expect(find.text('Override: Normal'), findsOneWidget);
      expect(find.text('Skin-contact detection: supported'), findsOneWidget);
      // Revealing the buttons doesn't move the readout.
      expect(tester.getCenter(find.text('bpm')), readoutBefore);

      // Normal -> No data (stale) -> No skin contact.
      await tester.tap(find.text('Override: Normal'));
      await tester.pump();
      await tester.tap(find.text('Override: No data (stale)'));
      await tester.pump();
      source.emit(sample());
      // The new state can land after the next frame; settle to be sure.
      await tester.pumpAndSettle();
      expect(find.text('--'), findsOneWidget);
      expect(find.text('No skin contact'), findsOneWidget);

      // A strap that can't detect skin contact: no skin contact isn't
      // possible, so the condition resets to normal and the bpm shows without
      // a skin-contact chip.
      await tester.tap(find.text('Skin-contact detection: supported'));
      await tester.pump();
      expect(find.text('Override: Normal'), findsOneWidget);
      source.emit(sample());
      await tester.pumpAndSettle();
      expect(find.text('72'), findsOneWidget);
      // The chip stays in the tree, invisible, to keep its space.
      expect(find.bySemanticsLabel('Skin contact'), findsNothing);

      // Hiding the buttons turns the override off.
      await tester.longPress(find.text('PulseLink'));
      await tester.pump();
      expect(find.textContaining('Override:'), findsNothing);
      source.emit(sample());
      // The new state can land after the next frame; settle to be sure.
      await tester.pumpAndSettle();
      expect(find.text('72'), findsOneWidget);

      unawaited(cubit.close());
      unawaited(overrideCubit.close());
      await tester.pump();
    });
  });
}
