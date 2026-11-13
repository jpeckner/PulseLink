import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/data/heart_rate_source.dart';
import 'package:pulselink/ui/live/live_heart_rate_screen.dart';

/// Root widget. Provides the data sources and app-wide Cubits to everything
/// below it, and owns theming.
class PulseLinkApp extends StatelessWidget {
  const new({required this.heartRateSource, super.key});

  /// Owned by the caller, which disposes it.
  final HeartRateSource heartRateSource;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<HeartRateSource>.value(
      value: heartRateSource,
      child: BlocProvider(
        create: (context) {
          final cubit = LiveHeartRateCubit(
            source: context.read<HeartRateSource>(),
          );
          unawaited(cubit.start());
          return cubit;
        },
        child: MaterialApp(
          title: 'PulseLink',
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: const LiveHeartRateScreen(),
        ),
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
