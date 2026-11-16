import 'package:material_ui/material_ui.dart';

/// Switches to simulated heart-rate data, for trying the app and the watch
/// without a strap. Debug and profile builds only: it's shown under the Find
/// strap button while no strap is picked, and release builds never contain
/// it.
class DemoDataButton extends StatelessWidget {
  const new({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Debug tooling, so its text isn't localized.
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.science_outlined),
      label: const Text('Use demo data'),
    );
  }
}
