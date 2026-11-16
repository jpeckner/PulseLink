import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_state.dart';
import 'package:pulselink/blocs/strap_battery/strap_battery_cubit.dart';
import 'package:pulselink/data/app_settings.dart';
import 'package:pulselink/domain/battery_level.dart';
import 'package:pulselink/domain/discovered_strap.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';
import 'package:pulselink/l10n/l10n.dart';
import 'package:pulselink/ui/widgets/disclaimer_banner.dart';
import 'package:pulselink/ui/widgets/problem_view.dart';

/// Live heart rate: the latest bpm, when it arrived, skin contact, and a clear
/// "no data from strap" state once the reading goes stale.
class LiveHeartRateScreen extends StatelessWidget {
  const new({
    required this.cubit,
    required this.batteryCubit,
    required this.appSettings,
    required this.buildStrapPicker,
    required this.onStrapSelected,
    this.debugControls,
    this.onTitleLongPress,
    this.noStrapDebugAction,
    super.key,
  });

  final LiveHeartRateCubit cubit;

  /// The strap's battery level, shown in the app bar once it's known.
  final StrapBatteryCubit batteryCubit;

  /// Opened when a problem is fixed in this app's settings, such as
  /// Bluetooth permission being denied.
  final AppSettings appSettings;

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

  /// Shown under the Find strap button while no strap is picked, such as a
  /// button that switches to demo data. Only supplied in non-release builds.
  final Widget? noStrapDebugAction;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveHeartRateCubit, LiveHeartRateState>(
      bloc: cubit,
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onLongPress: onTitleLongPress,
            child: Text(context.l10n.appTitle),
          ),
          actions: [
            BlocBuilder<StrapBatteryCubit, BatteryLevel?>(
              bloc: batteryCubit,
              builder: (context, level) {
                if (level case final known?) {
                  return _BatteryIndicator(level: known);
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(Icons.bluetooth_searching),
              tooltip: context.l10n.findStrapTooltip,
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
                          LiveHeartRateNoStrap() => _NoStrapView(
                            // Not awaited, as for the app bar's button.
                            onFindStrap: () => unawaited(_findStrap(context)),
                            debugAction: noStrapDebugAction,
                          ),
                          LiveHeartRateWaiting() => const _WaitingView(),
                          LiveHeartRateReading(:final sample, :final isStale) =>
                            _ReadingView(sample: sample, isStale: isStale),
                          LiveHeartRateConnectionFailed(:final failure) =>
                            _ConnectionFailedView(
                              failure: failure,
                              appSettings: appSettings,
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

/// No strap picked yet: asks for one.
class _NoStrapView extends StatelessWidget {
  const new({required this.onFindStrap, required this.debugAction});

  final VoidCallback onFindStrap;
  final Widget? debugAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.monitor_heart_outlined,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.noStrapTitle,
          style: theme.textTheme.titleLarge,
          textAlign: .center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.noStrapDetail,
          style: theme.textTheme.bodyLarge,
          textAlign: .center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onFindStrap,
          icon: const Icon(Icons.bluetooth_searching),
          label: Text(l10n.findStrapButton),
        ),
        if (debugAction case final action?) ...[
          const SizedBox(height: 12),
          action,
        ],
      ],
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
        const _BeatsPerMinuteReadout(beatsPerMinute: null, isStale: false),
        const SizedBox(height: 16),
        Text(
          context.l10n.waitingForData,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

/// Why there's no heart rate, what to do about it, and a way to retry.
class _ConnectionFailedView extends StatelessWidget {
  const new({
    required this.failure,
    required this.appSettings,
    required this.onTryAgain,
  });

  final StrapConnectionFailure failure;
  final AppSettings appSettings;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ProblemView(
      message: switch (failure) {
        BluetoothFailure(:final problem) => bluetoothProblemMessage(
          l10n,
          problem,
        ),
        StrapUnreachable() => (
          icon: Icons.sensors_off,
          title: l10n.strapUnreachableTitle,
          detail: l10n.strapUnreachableDetail,
          isFixedInSettings: false,
        ),
        NotAHeartRateStrap() => (
          icon: Icons.heart_broken_outlined,
          title: l10n.notAHeartRateStrapTitle,
          detail: l10n.notAHeartRateStrapDetail,
          isFixedInSettings: false,
        ),
        StrapConnectionLost() => (
          icon: Icons.link_off,
          title: l10n.strapDisconnectedTitle,
          detail: l10n.strapDisconnectedDetail,
          isFixedInSettings: false,
        ),
      },
      appSettings: appSettings,
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
    final l10n = context.l10n;
    final time = sample.timestamp;
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
                      l10n.noDataFromStrap,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.lastReadingAt(time),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          )
        else
          Text(l10n.updatedAt(time), style: theme.textTheme.bodyLarge),
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
    final l10n = context.l10n;
    final color = isStale
        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
        : theme.colorScheme.onSurface;
    final label = switch ((beatsPerMinute, isStale)) {
      (null, _) => l10n.noHeartRateLabel,
      (final beatsPerMinute?, true) => l10n.staleBeatsPerMinuteLabel(
        beatsPerMinute,
      ),
      (final beatsPerMinute?, false) => l10n.beatsPerMinuteLabel(
        beatsPerMinute,
      ),
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
            beatsPerMinute?.toString() ?? l10n.noBeatsPerMinute,
            style: theme.textTheme.displayLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.beatsPerMinuteUnit,
            style: theme.textTheme.titleLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SkinContactChip extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.check_circle_outline),
      label: Text(context.l10n.skinContact),
    );
  }
}

/// Strap status: skin contact for a measured sample, or why there's no
/// reading. Never about Bluetooth connectivity.
class _StrapStatusChip extends StatelessWidget {
  const new({required this.sample});

  final HeartRateSample sample;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return switch (sample) {
      MeasuredHeartRateSample(skinContact: SkinContact.detected) =>
        const _SkinContactChip(),
      // The strap can't detect skin contact, so there's nothing to say. The
      // chip's space is kept so the readout sits where it does for a strap
      // that can.
      MeasuredHeartRateSample(skinContact: SkinContact.notSupported) =>
        const Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: _SkinContactChip(),
        ),
      UnavailableHeartRateSample(
        reason: HeartRateUnavailableReason.noSkinContact,
      ) =>
        Chip(
          avatar: Icon(Icons.error_outline, color: colors.error),
          label: Text(l10n.noSkinContact),
        ),
      UnavailableHeartRateSample(
        reason: HeartRateUnavailableReason.zeroBeatsPerMinute,
      ) =>
        Chip(
          avatar: const Icon(Icons.info_outline),
          label: Text(l10n.connectedNoHeartRateYet),
        ),
      // Shown as an error, unlike a bpm of 0: the strap sent a value, but not
      // one that can be a heart rate.
      UnavailableHeartRateSample(
        reason: HeartRateUnavailableReason.implausibleBeatsPerMinute,
      ) =>
        Chip(
          avatar: Icon(Icons.error_outline, color: colors.error),
          label: Text(l10n.readingOutOfRange),
        ),
    };
  }
}

/// The strap's battery level: an icon and a percentage, with a warning
/// icon in the error colour once it's low.
class _BatteryIndicator extends StatelessWidget {
  const new({required this.level});

  final BatteryLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final colour = level.isLow ? theme.colorScheme.error : null;
    return Semantics(
      label: level.isLow
          ? l10n.batteryLowLabel(level.percent)
          : l10n.batteryLabel(level.percent),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              level.isLow ? Icons.battery_alert : Icons.battery_std,
              size: 20,
              color: colour,
            ),
            Text(
              l10n.batteryPercent(level.percent),
              style: theme.textTheme.labelLarge?.copyWith(color: colour),
            ),
          ],
        ),
      ),
    );
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
        label: Text(context.l10n.demoBadge),
        labelStyle: TextStyle(color: colors.onTertiaryContainer),
        backgroundColor: colors.tertiaryContainer,
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
