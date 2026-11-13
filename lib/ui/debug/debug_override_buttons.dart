import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/blocs/debug_override/debug_override_cubit.dart';
import 'package:pulselink/blocs/debug_override/debug_override_state.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';

/// Debug and profile builds only. While revealed, shows two buttons: one
/// switches whether the strap can detect skin contact, the other cycles
/// through the conditions that kind of strap can be in.
class DebugOverrideButtons extends StatelessWidget {
  const new({required this.cubit, super.key});

  final DebugOverrideCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebugOverrideCubit, DebugOverrideState>(
      bloc: cubit,
      builder: (context, state) => switch (state) {
        DebugOverrideHidden() => const SizedBox.shrink(),
        DebugOverrideShown(:final readingOverride) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: cubit.toggleSkinContactDetection,
                icon: const Icon(Icons.sensors),
                label: Text(_detectionLabel(readingOverride.detection)),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: cubit.cycleCondition,
                icon: const Icon(Icons.bug_report_outlined),
                label: Text('Override: ${_conditionLabel(readingOverride)}'),
              ),
            ],
          ),
        ),
      },
    );
  }

  static String _detectionLabel(SkinContactDetection detection) =>
      switch (detection) {
        SkinContactDetection.supported => 'Skin-contact detection: supported',
        SkinContactDetection.notSupported =>
          'Skin-contact detection: not supported',
      };

  static String _conditionLabel(ReadingOverride readingOverride) =>
      switch (readingOverride) {
        DetectingStrapOverride(:final condition) => switch (condition) {
          DetectingStrapCondition.normal => 'Normal',
          DetectingStrapCondition.stale => 'No data (stale)',
          DetectingStrapCondition.noSkinContact => 'No skin contact',
          DetectingStrapCondition.zeroBpm => 'Zero bpm',
        },
        NonDetectingStrapOverride(:final condition) => switch (condition) {
          NonDetectingStrapCondition.normal => 'Normal',
          NonDetectingStrapCondition.stale => 'No data (stale)',
          NonDetectingStrapCondition.zeroBpm => 'Zero bpm',
        },
      };
}
