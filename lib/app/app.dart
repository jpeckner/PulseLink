import 'package:material_ui/material_ui.dart';
import 'package:pulselink/ui/home/home_screen.dart';

/// Root widget. Owns theming and (later) the Bloc providers and routes.
class PulseLinkApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulseLink',
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const HomeScreen(),
    );
  }

  static ThemeData _theme(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.red,
      brightness: brightness,
    ),
  );
}
