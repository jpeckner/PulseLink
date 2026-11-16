import 'package:material_ui/material_ui.dart';
import 'package:pulselink/l10n/l10n.dart';

/// The non-medical disclaimer, shown on every main screen.
class DisclaimerBanner extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      context.l10n.disclaimer,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
