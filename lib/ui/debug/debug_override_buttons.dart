// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/blocs/debug_override/debug_override_cubit.dart';
import 'package:pulselink/blocs/debug_override/debug_override_state.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_state.dart';
import 'package:pulselink/data/debug_override_strap_data_source.dart';

/// Debug and profile builds only. While revealed, shows three buttons: the
/// first switches between demo data and real data, the second switches
/// whether the strap can detect skin contact, and the third cycles through
/// the conditions that kind of strap can be in.
class DebugOverrideButtons extends StatelessWidget {
  const new({
    required this.cubit,
    required this.heartRate,
    required this.onToggleDemoData,
    super.key,
  });

  final DebugOverrideCubit cubit;

  /// The live heart rate, which says whether its data is simulated.
  final LiveHeartRateCubit heartRate;

  /// Switches to demo data, or from it back to real data (no strap, until
  /// one is picked).
  final VoidCallback onToggleDemoData;

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
              BlocBuilder<LiveHeartRateCubit, LiveHeartRateState>(
                bloc: heartRate,
                buildWhen: (previous, current) =>
                    previous.isSimulated != current.isSimulated,
                builder: (context, heartRateState) => OutlinedButton.icon(
                  onPressed: onToggleDemoData,
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(_dataLabel(isDemo: heartRateState.isSimulated)),
                ),
              ),
              const SizedBox(height: 8),
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

  static String _dataLabel({required bool isDemo}) =>
      isDemo ? 'Data: Demo' : 'Data: Real strap';

  static String _detectionLabel(SkinContactDetection detection) =>
      switch (detection) {
        SkinContactDetection.supported => 'Skin-contact detection: supported',
        SkinContactDetection.notSupported =>
          'Skin-contact detection: not supported',
      };

  static String _conditionLabel(
    ReadingOverride readingOverride,
  ) => switch (readingOverride) {
    DetectingStrapOverride(:final condition) => switch (condition) {
      DetectingStrapCondition.normal => 'None',
      DetectingStrapCondition.stale => 'No data (stale)',
      DetectingStrapCondition.noSkinContact => 'No skin contact',
      DetectingStrapCondition.zeroBeatsPerMinute => 'Zero bpm',
      DetectingStrapCondition.implausibleBeatsPerMinute => 'Implausible bpm',
    },
    NonDetectingStrapOverride(:final condition) => switch (condition) {
      NonDetectingStrapCondition.normal => 'None',
      NonDetectingStrapCondition.stale => 'No data (stale)',
      NonDetectingStrapCondition.zeroBeatsPerMinute => 'Zero bpm',
      NonDetectingStrapCondition.implausibleBeatsPerMinute => 'Implausible bpm',
    },
  };
}
