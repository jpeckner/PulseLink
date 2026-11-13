import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_state.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/ui/widgets/disclaimer_banner.dart';

/// Live heart rate: the latest bpm, when it arrived, skin contact, and a clear
/// "no data from strap" state once the reading goes stale.
class LiveHeartRateScreen extends StatelessWidget {
  const new({
    required this.cubit,
    this.debugControls,
    this.onTitleLongPress,
    super.key,
  });

  final LiveHeartRateCubit cubit;

  /// Shown just above the disclaimer, overlaid so it takes no layout space.
  /// Only supplied in non-release builds.
  final Widget? debugControls;

  /// Called when the title is long-pressed. Only supplied in non-release
  /// builds.
  final VoidCallback? onTitleLongPress;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveHeartRateCubit, LiveHeartRateState>(
      bloc: cubit,
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onLongPress: onTitleLongPress,
            child: const Text('PulseLink'),
          ),
          actions: [if (state.isSimulated) const _DemoBadge()],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  // Debug controls float over the bottom of this area rather
                  // than taking layout space, so the readout never moves when
                  // they appear or disappear, and debug and release layouts
                  // match.
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: switch (state) {
                          LiveHeartRateWaiting() => const _WaitingView(),
                          LiveHeartRateReading(:final sample, :final isStale) =>
                            _ReadingView(sample: sample, isStale: isStale),
                        },
                      ),
                      if (debugControls case final controls?)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: controls,
                        ),
                    ],
                  ),
                ),
                const DisclaimerBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _BpmReadout(bpm: null, isStale: false),
        const SizedBox(height: 16),
        Text(
          'Waiting for heart-rate data…',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _ReadingView extends StatelessWidget {
  const new({required this.sample, required this.isStale});

  final HeartRateSample sample;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat.jms().format(sample.timestamp);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BpmReadout(
          bpm: switch (sample) {
            MeasuredHeartRateSample(:final bpm) => bpm.value,
            UnavailableHeartRateSample() => null,
          },
          isStale: isStale,
        ),
        const SizedBox(height: 16),
        if (isStale)
          // Two short lines rather than one long one, so it fits narrow
          // screens without wrapping away from the icon.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sensors_off, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  // Flexible: wraps instead of overflowing with very large
                  // accessibility text sizes.
                  Flexible(
                    child: Text(
                      'No data from strap',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Last reading $time',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          )
        else
          Text('Updated $time', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        // A stale reading's skin-contact status is out of date too, so hide
        // it. Its space is kept so the readout doesn't jump when data stops.
        Visibility(
          visible: !isStale,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: _StrapStatusChip(sample: sample),
        ),
      ],
    );
  }
}

class _BpmReadout extends StatelessWidget {
  const new({required this.bpm, required this.isStale});

  /// Null when there's no usable reading; shown as "--".
  final int? bpm;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isStale
        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
        : theme.colorScheme.onSurface;
    final label = switch ((bpm, isStale)) {
      (null, _) => 'No heart-rate reading',
      (final bpm?, true) => 'Last reading $bpm beats per minute, out of date',
      (final bpm?, false) => '$bpm beats per minute',
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            bpm?.toString() ?? '--',
            style: theme.textTheme.displayLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'bpm',
            style: theme.textTheme.titleLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

const _skinContactChip = Chip(
  avatar: Icon(Icons.check_circle_outline),
  label: Text('Skin contact'),
);

/// Strap status: skin contact for a measured sample, or why there's no
/// reading. Never about Bluetooth connectivity.
class _StrapStatusChip extends StatelessWidget {
  const new({required this.sample});

  final HeartRateSample sample;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return switch (sample) {
      MeasuredHeartRateSample(skinContact: SkinContact.detected) =>
        _skinContactChip,
      // The strap can't detect skin contact, so there's nothing to say. The
      // chip's space is kept so the readout sits where it does for a strap
      // that can.
      MeasuredHeartRateSample(skinContact: SkinContact.notSupported) =>
        const Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: _skinContactChip,
        ),
      UnavailableHeartRateSample(
        reason: HeartRateUnavailableReason.noSkinContact,
      ) =>
        Chip(
          avatar: Icon(Icons.error_outline, color: colors.error),
          label: const Text('No skin contact'),
        ),
      UnavailableHeartRateSample(reason: HeartRateUnavailableReason.zeroBpm) =>
        const Chip(
          avatar: Icon(Icons.info_outline),
          label: Text('Strap connected, no heart rate yet'),
        ),
      // Shown as an error, unlike a bpm of 0: the strap sent a value, but not
      // one that can be a heart rate.
      UnavailableHeartRateSample(
        reason: HeartRateUnavailableReason.implausibleBpm,
      ) =>
        Chip(
          avatar: Icon(Icons.error_outline, color: colors.error),
          label: const Text('Strap reading out of range'),
        ),
    };
  }
}

class _DemoBadge extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Chip(
        label: const Text('Demo'),
        labelStyle: TextStyle(color: colors.onTertiaryContainer),
        backgroundColor: colors.tertiaryContainer,
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
