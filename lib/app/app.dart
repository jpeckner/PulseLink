import 'package:material_ui/material_ui.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/ui/live/live_heart_rate_screen.dart';

/// Root widget. Owns theming and passes dependencies to screens through their
/// constructors.
class PulseLinkApp extends StatelessWidget {
  const new({
    required this.liveHeartRateCubit,
    this.debugControls,
    this.onTitleLongPress,
    super.key,
  });

  /// Owned by the caller, which starts and closes it.
  final LiveHeartRateCubit liveHeartRateCubit;

  /// Debug tooling for the live screen. Only supplied in non-release builds.
  final Widget? debugControls;
  final VoidCallback? onTitleLongPress;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulseLink',
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: LiveHeartRateScreen(
        cubit: liveHeartRateCubit,
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
