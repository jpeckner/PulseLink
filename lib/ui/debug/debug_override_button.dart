import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/blocs/debug_override/debug_override_cubit.dart';
import 'package:pulselink/blocs/debug_override/debug_override_state.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';

/// Debug and profile builds only. While revealed, shows the current reading
/// override; each tap moves to the next one.
class DebugOverrideButton extends StatelessWidget {
  const new({required this.cubit, super.key});

  final DebugOverrideCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebugOverrideCubit, DebugOverrideState>(
      bloc: cubit,
      builder: (context, state) => switch (state) {
        DebugOverrideHidden() => const SizedBox.shrink(),
        DebugOverrideShown(:final mode) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: cubit.cycleMode,
            icon: const Icon(Icons.bug_report_outlined),
            label: Text('Override: ${_label(mode)}'),
          ),
        ),
      },
    );
  }

  static String _label(ReadingOverride mode) => switch (mode) {
    ReadingOverride.normal => 'Normal',
    ReadingOverride.stale => 'No data (stale)',
    ReadingOverride.noSkinContact => 'No skin contact',
    ReadingOverride.zeroBpm => 'Zero bpm',
    ReadingOverride.skinContactNotSupported => 'Skin contact not supported',
  };
}
