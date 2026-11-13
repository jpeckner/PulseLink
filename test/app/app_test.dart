import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/app/app.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/ui/widgets/disclaimer_banner.dart';

import '../helpers/positive_int.dart';
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
          bpm: positiveInt(72),
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
  });
}
