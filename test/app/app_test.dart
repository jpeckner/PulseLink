// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/app/app.dart';
import 'package:pulselink/blocs/debug_override/debug_override_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/blocs/strap_battery/strap_battery_cubit.dart';
import 'package:pulselink/data/debug_override_strap_data_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/ui/debug/debug_override_buttons.dart';

import '../helpers/beats_per_minute.dart';
import '../helpers/english.dart';
import '../helpers/stub_app_settings.dart';
import '../helpers/stub_strap_data_source.dart';
import '../helpers/stub_strap_scanner.dart';

void main() {
  group('PulseLinkApp', () {
    testWidgets('shows live samples from the cubit it is given', (
      tester,
    ) async {
      final source = StubStrapDataSource(isSimulated: true);
      final cubit = LiveHeartRateCubit(source: source);
      final batteryCubit = StrapBatteryCubit(source: source);
      unawaited(cubit.start());
      await tester.pumpWidget(
        PulseLinkApp(
          liveHeartRateCubit: cubit,
          strapBatteryCubit: batteryCubit,
          strapScanner: StubStrapScanner(),
          appSettings: StubAppSettings(),
          onStrapSelected: (_) {},
        ),
      );

      expect(find.text('PulseLink'), findsOneWidget);
      expect(find.text('Demo'), findsOneWidget);
      expect(find.text('--'), findsOneWidget);
      expect(find.text(english.disclaimer), findsOneWidget);

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
      unawaited(batteryCubit.close());
      await tester.pump();
    });

    testWidgets('Find strap opens the picker, which scans with the scanner '
        'it is given', (tester) async {
      final source = StubStrapDataSource();
      final cubit = LiveHeartRateCubit(source: source);
      final batteryCubit = StrapBatteryCubit(source: source);
      final scanner = StubStrapScanner();
      await tester.pumpWidget(
        PulseLinkApp(
          liveHeartRateCubit: cubit,
          strapBatteryCubit: batteryCubit,
          strapScanner: scanner,
          appSettings: StubAppSettings(),
          onStrapSelected: (_) {},
        ),
      );
      await tester.tap(find.byTooltip('Find strap'));
      // Not pumpAndSettle: the picker's progress indicator never settles.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Find your strap'), findsOneWidget);
      expect(scanner.isScanning, isTrue);

      unawaited(cubit.close());
      unawaited(batteryCubit.close());
      await tester.pump();
    });

    testWidgets('debug wiring: long-press reveals the override buttons, '
        'which rewrite samples, and hiding them restores them', (tester) async {
      // Wired the way main() does in debug and profile builds.
      final source = StubStrapDataSource(isSimulated: true);
      final overrideSource = DebugOverrideStrapDataSource(source);
      final overrideCubit = DebugOverrideCubit(source: overrideSource);
      final cubit = LiveHeartRateCubit(source: overrideSource);
      final batteryCubit = StrapBatteryCubit(source: overrideSource);
      unawaited(cubit.start());
      await tester.pumpWidget(
        PulseLinkApp(
          liveHeartRateCubit: cubit,
          strapBatteryCubit: batteryCubit,
          strapScanner: StubStrapScanner(),
          appSettings: StubAppSettings(),
          onStrapSelected: (_) {},
          debugControls: DebugOverrideButtons(
            cubit: overrideCubit,
            heartRate: cubit,
            onToggleDemoData: () {},
          ),
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
      expect(find.text('Override: None'), findsOneWidget);
      expect(find.text('Skin-contact detection: supported'), findsOneWidget);
      // Revealing the buttons doesn't move the readout.
      expect(tester.getCenter(find.text('bpm')), readoutBefore);

      // None -> No data (stale) -> No skin contact.
      await tester.tap(find.text('Override: None'));
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
      expect(find.text('Override: None'), findsOneWidget);
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
      unawaited(batteryCubit.close());
      unawaited(overrideCubit.close());
      await tester.pump();
    });
  });
}
