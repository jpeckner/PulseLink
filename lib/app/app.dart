import 'package:material_ui/material_ui.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/blocs/strap_battery/strap_battery_cubit.dart';
import 'package:pulselink/data/app_settings.dart';
import 'package:pulselink/data/strap_scanner.dart';
import 'package:pulselink/domain/discovered_strap.dart';
import 'package:pulselink/l10n/l10n.dart';
import 'package:pulselink/ui/live/live_heart_rate_screen.dart';
import 'package:pulselink/ui/picker/strap_picker_screen.dart';

/// Root widget. Owns theming and passes dependencies to screens through their
/// constructors.
class PulseLinkApp extends StatelessWidget {
  const new({
    required this.liveHeartRateCubit,
    required this.strapBatteryCubit,
    required this.strapScanner,
    required this.appSettings,
    required this.onStrapSelected,
    this.debugControls,
    this.onTitleLongPress,
    super.key,
  });

  /// Owned by the caller, which starts and closes it.
  final LiveHeartRateCubit liveHeartRateCubit;

  /// Owned by the caller, which closes it.
  final StrapBatteryCubit strapBatteryCubit;

  /// Used by the strap picker, which scans only while it's open.
  final StrapScanner strapScanner;

  /// Opened from the screens when Bluetooth permission is denied.
  final AppSettings appSettings;

  /// Called with the strap picked in the strap picker.
  final ValueChanged<DiscoveredStrap> onStrapSelected;

  /// Debug tooling for the live screen. Only supplied in non-release builds.
  final Widget? debugControls;
  final VoidCallback? onTitleLongPress;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: pulseLinkLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: LiveHeartRateScreen(
        cubit: liveHeartRateCubit,
        batteryCubit: strapBatteryCubit,
        appSettings: appSettings,
        buildStrapPicker: (_) =>
            StrapPickerScreen(scanner: strapScanner, appSettings: appSettings),
        onStrapSelected: onStrapSelected,
        debugControls: debugControls,
        onTitleLongPress: onTitleLongPress,
      ),
    );
  }

  static ThemeData _theme(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.red,
      brightness: brightness,
    ),
  );
}
