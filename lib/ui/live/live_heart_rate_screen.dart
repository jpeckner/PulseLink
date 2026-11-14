import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_state.dart';
import 'package:pulselink/domain/discovered_strap.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';
import 'package:pulselink/ui/widgets/disclaimer_banner.dart';
import 'package:pulselink/ui/widgets/problem_view.dart';

/// Live heart rate: the latest bpm, when it arrived, skin contact, and a clear
/// "no data from strap" state once the reading goes stale.
class LiveHeartRateScreen extends StatelessWidget {
  const new({
    required this.cubit,
    required this.buildStrapPicker,
    required this.onStrapSelected,
    this.debugControls,
    this.onTitleLongPress,
    super.key,
  });

  final LiveHeartRateCubit cubit;

  /// Builds the screen that finds a strap, opened from the app bar.
  final WidgetBuilder buildStrapPicker;

  /// Called with the strap picked in the strap picker, if any.
  final ValueChanged<DiscoveredStrap> onStrapSelected;

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
          actions: [
            IconButton(
              icon: const Icon(Icons.bluetooth_searching),
              tooltip: 'Find strap',
              // Not awaited: it only opens the picker and passes on what it
              // returns; connecting reports through the cubit's state.
              onPressed: () => unawaited(_findStrap(context)),
            ),
            if (state.isSimulated) const _DemoBadge(),
          ],
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
                          LiveHeartRateConnectionFailed(:final failure) =>
                            _ConnectionFailedView(
                              failure: failure,
                              // Not awaited: start() reports how it went by
                              // changing the cubit's state, which this screen
                              // already shows. It only throws on a bug in a
                              // source, which is left to the zone's error
                              // handler (see main.dart).
                              onTryAgain: () => unawaited(cubit.start()),
                            ),
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

  /// Opens the strap picker, and passes on the strap picked there, if any.
  /// Closing the picker without picking one changes nothing.
  Future<void> _findStrap(BuildContext context) async {
    final strap = await Navigator.of(context)
        .push(MaterialPageRoute<DiscoveredStrap>(builder: buildStrapPicker));
    if (strap case final picked?) {
      onStrapSelected(picked);
    }
  }
}

class _WaitingView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _BeatsPerMinuteReadout(beatsPerMinute: null, isStale: false),
        const SizedBox(height: 16),
        Text(
          'Waiting for heart-rate data…',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

/// Why there's no heart rate, what to do about it, and a way to retry.
class _ConnectionFailedView extends StatelessWidget {
  const new({required this.failure, required this.onTryAgain});

  final StrapConnectionFailure failure;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return ProblemView(
      message: switch (failure) {
        BluetoothFailure(:final problem) => bluetoothProblemMessage(problem),
        StrapUnreachable() => (
          icon: Icons.sensors_off,
          title: "Can't reach the strap",
          detail:
              "Make sure it's on, being worn and nearby, and not connected "
              'to another app.',
        ),
        NotAHeartRateStrap() => (
          icon: Icons.heart_broken_outlined,
          title: 'Not a heart-rate strap',
          detail: "This device doesn't send heart-rate data.",
        ),
      },
      onTryAgain: onTryAgain,
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
        _BeatsPerMinuteReadout(
          beatsPerMinute: switch (sample) {
            MeasuredHeartRateSample(:final beatsPerMinute) =>
              beatsPerMinute.value,
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

class _BeatsPerMinuteReadout extends StatelessWidget {
  const new({required this.beatsPerMinute, required this.isStale});

  /// Null when there's no usable reading; shown as "--".
  final int? beatsPerMinute;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isStale
        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
        : theme.colorScheme.onSurface;
    final label = switch ((beatsPerMinute, isStale)) {
      (null, _) => 'No heart-rate reading',
      (final beatsPerMinute?, true) =>
        'Last reading $beatsPerMinute beats per minute, out of date',
      (final beatsPerMinute?, false) => '$beatsPerMinute beats per minute',
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
            beatsPerMinute?.toString() ?? '--',
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
      UnavailableHeartRateSample(
        reason: HeartRateUnavailableReason.zeroBeatsPerMinute,
      ) =>
        const Chip(
          avatar: Icon(Icons.info_outline),
          label: Text('Strap connected, no heart rate yet'),
        ),
      // Shown as an error, unlike a bpm of 0: the strap sent a value, but not
      // one that can be a heart rate.
      UnavailableHeartRateSample(
        reason: HeartRateUnavailableReason.implausibleBeatsPerMinute,
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
