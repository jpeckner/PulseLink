import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:pulselink/data/app_settings.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';

/// What to tell the user about a problem: an icon, a short title, what to do
/// about it, and whether changing this app's settings fixes it.
typedef ProblemMessage = ({
  IconData icon,
  String title,
  String detail,
  bool isFixedInSettings,
});

/// The message for [problem], shared by every screen that needs Bluetooth.
ProblemMessage bluetoothProblemMessage(BluetoothProblem problem) =>
    switch (problem) {
      BluetoothProblem.off => (
        icon: Icons.bluetooth_disabled,
        title: 'Bluetooth is off',
        detail: 'Turn on Bluetooth to connect to your strap.',
        // Not this app's settings, and iOS doesn't let apps open the
        // Bluetooth page directly.
        isFixedInSettings: false,
      ),
      BluetoothProblem.unavailable => (
        icon: Icons.bluetooth_disabled,
        title: "Bluetooth isn't available",
        detail: "This phone can't connect to a heart-rate strap.",
        isFixedInSettings: false,
      ),
      BluetoothProblem.permissionDenied => (
        icon: Icons.lock_outline,
        title: 'Bluetooth permission needed',
        detail: 'Allow PulseLink to use Bluetooth in Settings, then try again.',
        isFixedInSettings: true,
      ),
    };

/// Shows a [ProblemMessage], with an "Open Settings" button if settings fix
/// it, and a "Try again" button if [onTryAgain] is given.
class ProblemView extends StatelessWidget {
  const new({
    required this.message,
    required this.appSettings,
    this.onTryAgain,
    super.key,
  });

  final ProblemMessage message;

  /// Opened by the "Open Settings" button.
  final AppSettings appSettings;

  final VoidCallback? onTryAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFixedInSettings = message.isFixedInSettings;
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
        if (isFixedInSettings) ...[
          const SizedBox(height: 24),
          FilledButton(
            // Not awaited: _openSettings never fails, and tells the user
            // itself if Settings didn't open.
            onPressed: () => unawaited(_openSettings(context)),
            child: const Text('Open Settings'),
          ),
        ],
        if (onTryAgain case final tryAgain?) ...[
          // Opening Settings is the fix, so it's the main button, and trying
          // again comes after it.
          if (isFixedInSettings) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: tryAgain, child: const Text('Try again')),
          ] else ...[
            const SizedBox(height: 24),
            FilledButton(onPressed: tryAgain, child: const Text('Try again')),
          ],
        ],
      ],
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    // Looked up before the await, since the view may be gone by the time
    // Settings answers.
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (await appSettings.open()) {
      return;
    }
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          "Couldn't open Settings. Open the Settings app, then find "
          'PulseLink there.',
        ),
      ),
    );
  }
}
