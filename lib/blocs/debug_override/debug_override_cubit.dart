import 'package:bloc/bloc.dart';
import 'package:pulselink/blocs/debug_override/debug_override_state.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';

/// Debug and profile builds only. Shows and hides the override buttons, and
/// keeps the source's override in step with them.
class DebugOverrideCubit extends Cubit<DebugOverrideState> {
  new({required this._source}) : super(const DebugOverrideState.hidden());

  final DebugOverrideHeartRateSource _source;

  /// Shows the buttons, or hides them and turns the override off.
  void toggleVisibility() => _apply(switch (state) {
    DebugOverrideHidden() => DebugOverrideState.shown(_startingOverride()),
    DebugOverrideShown() => const DebugOverrideState.hidden(),
  });

  /// Switches between a strap that can detect skin contact and one that
  /// can't. Does nothing while hidden.
  void toggleSkinContactDetection() {
    switch (state) {
      case DebugOverrideShown(:final readingOverride):
        _apply(DebugOverrideState.shown(readingOverride.withOtherDetection));
      case DebugOverrideHidden():
        // No buttons are showing, so there's nothing to switch.
        break;
    }
  }

  /// Moves to the strap's next condition. Does nothing while hidden.
  void cycleCondition() {
    switch (state) {
      case DebugOverrideShown(:final readingOverride):
        _apply(DebugOverrideState.shown(readingOverride.withNextCondition));
      case DebugOverrideHidden():
        // No buttons are showing, so there's nothing to cycle.
        break;
    }
  }

  /// Matches what the strap last reported, so revealing the buttons doesn't
  /// change what's on screen. A strap that hasn't said yet is treated as one
  /// that can detect skin contact, like the demo source.
  ReadingOverride _startingOverride() => switch (_source.reportedDetection) {
    SkinContactDetection.notSupported =>
      const ReadingOverride.nonDetectingStrap(
        NonDetectingStrapCondition.normal,
      ),
    SkinContactDetection.supported || null =>
      const ReadingOverride.detectingStrap(DetectingStrapCondition.normal),
  };

  void _apply(DebugOverrideState next) {
    if (isClosed) {
      return;
    }
    // The source's override is always derived from the state, never set apart
    // from it, so hiding the buttons can't leave an override running.
    _source.readingOverride = switch (next) {
      DebugOverrideHidden() => null,
      DebugOverrideShown(:final readingOverride) => readingOverride,
    };
    emit(next);
  }
}
