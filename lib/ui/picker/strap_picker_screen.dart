import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/blocs/strap_picker/strap_picker_cubit.dart';
import 'package:pulselink/blocs/strap_picker/strap_picker_state.dart';
import 'package:pulselink/data/app_settings.dart';
import 'package:pulselink/data/strap_scanner.dart';
import 'package:pulselink/domain/discovered_strap.dart';
import 'package:pulselink/ui/widgets/disclaimer_banner.dart';
import 'package:pulselink/ui/widgets/problem_view.dart';

/// Lists nearby heart-rate straps, scanning only while it's open.
class StrapPickerScreen extends StatelessWidget {
  const new({required this.scanner, required this.appSettings, super.key});

  final StrapScanner scanner;

  /// Opened when Bluetooth permission is denied.
  final AppSettings appSettings;

  @override
  Widget build(BuildContext context) {
    // The cubit lives as long as this screen: BlocProvider closes it, which
    // stops the scan, when the screen goes away. It doesn't await close(),
    // so a failure to stop goes to the zone's error handler.
    return BlocProvider(
      create: (_) => StrapPickerCubit(scanner: scanner)..start(),
      child: _StrapPickerView(appSettings: appSettings),
    );
  }
}

class _StrapPickerView extends StatelessWidget {
  const new({required this.appSettings});

  final AppSettings appSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find your strap')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<StrapPickerCubit, StrapPickerState>(
                  builder: (context, state) => switch (state) {
                    // Scrolls if the tips don't fit, such as on a small
                    // screen or with large text.
                    StrapPickerScanning(:final straps) when straps.isEmpty =>
                      const Center(
                        child: SingleChildScrollView(child: _LookingView()),
                      ),
                    StrapPickerScanning(:final straps) => _StrapList(
                      straps: straps,
                    ),
                    StrapPickerFailed(:final problem) => Center(
                      child: ProblemView(
                        message: bluetoothProblemMessage(problem),
                        appSettings: appSettings,
                      ),
                    ),
                  },
                ),
              ),
              const DisclaimerBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Looking for straps, with tips once it has found nothing for a while.
class _LookingView extends StatefulWidget {
  const new();

  /// How long to look before showing tips. A strap that's on and nearby
  /// usually turns up within a few seconds.
  static const tipsAfter = Duration(seconds: 15);

  @override
  State<_LookingView> createState() => _LookingViewState();
}

class _LookingViewState extends State<_LookingView> {
  // Starts again whenever this view does: when the picker opens, and when
  // scanning resumes after a Bluetooth problem.
  Timer? _tipsTimer;
  bool _showsTips = false;

  @override
  void initState() {
    super.initState();
    _tipsTimer = Timer(
      _LookingView.tipsAfter,
      () => setState(() => _showsTips = true),
    );
  }

  @override
  void dispose() {
    _tipsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          'Looking for heart-rate straps…',
          style: theme.textTheme.titleMedium,
          textAlign: .center,
        ),
        const SizedBox(height: 8),
        Text(
          'Put your strap on so it wakes up, and keep it close to your phone.',
          style: theme.textTheme.bodyMedium,
          textAlign: .center,
        ),
        if (_showsTips) ...[
          const SizedBox(height: 24),
          Text(
            'Still not finding it?',
            style: theme.textTheme.titleSmall,
            textAlign: .center,
          ),
          const SizedBox(height: 8),
          Text(
            'Dampen the strap where it touches your skin, so it can sense '
            'your heart.\n\n'
            'A strap connects to one device at a time. If another phone, '
            'watch or gym machine is connected to it, disconnect it there.',
            style: theme.textTheme.bodyMedium,
            textAlign: .center,
          ),
        ],
      ],
    );
  }
}

class _StrapList extends StatelessWidget {
  const new({required this.straps});

  final List<DiscoveredStrap> straps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Still scanning, so more straps may appear. Once a strap that's
        // already connected is listed, its check mark says it's ready, and a
        // moving bar would suggest it's still being looked for.
        if (!straps.any((strap) => strap.isConnected))
          const LinearProgressIndicator(),
        Expanded(
          child: ListView(
            children: [
              for (final strap in straps)
                ListTile(
                  leading: const Icon(Icons.monitor_heart_outlined),
                  title: Text(strap.name?.value ?? 'Unnamed heart-rate strap'),
                  trailing: strap.isConnected
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          semanticLabel: 'Connected',
                        )
                      : null,
                  // Closes the picker with this strap; the screen that
                  // opened it connects to it.
                  onTap: () => Navigator.of(context).pop(strap),
                ),
            ],
          ),
        ),
        Text(
          'Tap your strap to connect to it.',
          style: theme.textTheme.bodyMedium,
          textAlign: .center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
