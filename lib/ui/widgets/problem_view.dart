import 'package:material_ui/material_ui.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';

/// What to tell the user about a problem: an icon, a short title, and what to
/// do about it.
typedef ProblemMessage = ({IconData icon, String title, String detail});

/// The message for [problem], shared by every screen that needs Bluetooth.
ProblemMessage bluetoothProblemMessage(BluetoothProblem problem) =>
    switch (problem) {
      BluetoothProblem.off => (
        icon: Icons.bluetooth_disabled,
        title: 'Bluetooth is off',
        detail: 'Turn on Bluetooth to connect to your strap.',
      ),
      BluetoothProblem.unavailable => (
        icon: Icons.bluetooth_disabled,
        title: "Bluetooth isn't available",
        detail: "This phone can't connect to a heart-rate strap.",
      ),
      BluetoothProblem.permissionDenied => (
        icon: Icons.lock_outline,
        title: 'Bluetooth permission needed',
        detail: 'Allow PulseLink to use Bluetooth in Settings, then try again.',
      ),
    };

/// Shows a [ProblemMessage], with a "Try again" button if [onTryAgain] is
/// given.
class ProblemView extends StatelessWidget {
  const new({required this.message, this.onTryAgain, super.key});

  final ProblemMessage message;
  final VoidCallback? onTryAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(message.icon, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(
          message.title,
          style: theme.textTheme.titleLarge,
          textAlign: .center,
        ),
        const SizedBox(height: 8),
        Text(
          message.detail,
          style: theme.textTheme.bodyLarge,
          textAlign: .center,
        ),
        if (onTryAgain case final tryAgain?) ...[
          const SizedBox(height: 24),
          FilledButton(onPressed: tryAgain, child: const Text('Try again')),
        ],
      ],
    );
  }
}
