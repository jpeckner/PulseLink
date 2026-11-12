import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/app/app.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/ui/widgets/disclaimer_banner.dart';

import '../helpers/positive_int.dart';
import '../helpers/stub_heart_rate_source.dart';

void main() {
  group('PulseLinkApp', () {
    testWidgets('starts the source and shows live samples from it', (
      tester,
    ) async {
      final source = StubHeartRateSource(isSimulated: true);
      await tester.pumpWidget(PulseLinkApp(heartRateSource: source));

      expect(source.startCount, 1);
      expect(find.text('PulseLink'), findsOneWidget);
      expect(find.text('Demo'), findsOneWidget);
      expect(find.text('--'), findsOneWidget);
      expect(find.text(disclaimerText), findsOneWidget);

      source.emit(
        HeartRateSample.measured(
          bpm: positiveInt(72),
          timestamp: clock.now(),
          contact: MeasuredContact.detected,
        ),
      );
      await tester.pump();
      expect(find.text('72'), findsOneWidget);

      // Unmounting closes the cubit, which stops the source and cancels its
      // stale timer. The app doesn't dispose a source it doesn't own.
      await tester.pumpWidget(const SizedBox());
      expect(source.stopCount, 1);
      expect(source.isDisposed, isFalse);
    });
  });
}
