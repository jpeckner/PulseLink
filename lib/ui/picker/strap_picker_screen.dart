import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/blocs/strap_picker/strap_picker_cubit.dart';
import 'package:pulselink/blocs/strap_picker/strap_picker_state.dart';
import 'package:pulselink/data/strap_scanner.dart';
import 'package:pulselink/domain/discovered_strap.dart';
import 'package:pulselink/ui/widgets/disclaimer_banner.dart';
import 'package:pulselink/ui/widgets/problem_view.dart';

/// Lists nearby heart-rate straps, scanning only while it's open.
class StrapPickerScreen extends StatelessWidget {
  const new({required this.scanner, super.key});

  final StrapScanner scanner;

  @override
  Widget build(BuildContext context) {
    // The cubit lives as long as this screen: BlocProvider closes it, which
    // stops the scan, when the screen goes away. It doesn't await close(),
    // so a failure to stop goes to the zone's error handler.
    return BlocProvider(
      create: (_) => StrapPickerCubit(scanner: scanner)..start(),
      child: const _StrapPickerView(),
    );
  }
}

class _StrapPickerView extends StatelessWidget {
  const new();

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
                    StrapPickerScanning(:final straps) when straps.isEmpty =>
                      const Center(child: _LookingView()),
                    StrapPickerScanning(:final straps) => _StrapList(
                      straps: straps,
                    ),
                    StrapPickerFailed(:final problem) => Center(
                      child: ProblemView(
                        message: bluetoothProblemMessage(problem),
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

class _LookingView extends StatelessWidget {
  const new();

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
        // Still scanning, so more straps may appear.
        const LinearProgressIndicator(),
        Expanded(
          child: ListView(
            children: [
              for (final strap in straps)
                ListTile(
                  leading: const Icon(Icons.monitor_heart_outlined),
                  title: Text(strap.name ?? 'Unnamed heart-rate strap'),
                ),
            ],
          ),
        ),
        Text(
          "Connecting to a strap isn't available yet.",
          style: theme.textTheme.bodyMedium,
          textAlign: .center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
