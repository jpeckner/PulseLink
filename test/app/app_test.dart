import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/app/app.dart';
import 'package:pulselink/ui/widgets/disclaimer_banner.dart';

void main() {
  group('PulseLinkApp', () {
    testWidgets('shows the home screen with the disclaimer', (tester) async {
      await tester.pumpWidget(const PulseLinkApp());

      expect(find.text('PulseLink'), findsOneWidget);
      expect(find.text('-- bpm'), findsOneWidget);
      expect(find.text(disclaimerText), findsOneWidget);
    });
  });
}
