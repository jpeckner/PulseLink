import 'package:material_ui/material_ui.dart';
import 'package:pulselink/ui/widgets/disclaimer_banner.dart';

/// Placeholder home screen. Milestone 2 replaces the body with the live
/// heart-rate view driven by a Bloc.
class HomeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('PulseLink')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('-- bpm', style: textTheme.displayLarge),
                      const SizedBox(height: 8),
                      Text(
                        'No heart-rate source connected',
                        style: textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const DisclaimerBanner(),
            ],
          ),
        ),
      ),
    );
  }
}
