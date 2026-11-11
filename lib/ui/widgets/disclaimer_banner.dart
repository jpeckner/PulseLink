import 'package:material_ui/material_ui.dart';

const disclaimerText =
    'For learning and fitness use only. Not a medical device.';

/// The non-medical disclaimer, shown on every main screen.
class DisclaimerBanner extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      disclaimerText,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
