import 'package:bloc/bloc.dart';
import 'package:pulselink/blocs/debug_override/debug_override_state.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';

/// Debug and profile builds only. Shows and hides the override button, and
/// keeps the source's override in step with it.
class DebugOverrideCubit extends Cubit<DebugOverrideState> {
  new({required this._source}) : super(const DebugOverrideState.hidden());

  final DebugOverrideHeartRateSource _source;

  /// Shows the button, or hides it and turns the override off.
  void toggleVisibility() => _apply(switch (state) {
    DebugOverrideHidden() => const DebugOverrideState.shown(
      ReadingOverride.normal,
    ),
    DebugOverrideShown() => const DebugOverrideState.hidden(),
  });

  /// Moves to the next override. Does nothing while hidden.
  void cycleMode() {
    if (state case DebugOverrideShown(:final mode)) {
      _apply(DebugOverrideState.shown(mode.next));
    }
  }

  void _apply(DebugOverrideState next) {
    if (isClosed) return;
    // The source's mode is always derived from the state, never set apart
    // from it, so hiding the button can't leave an override running.
    _source.mode = switch (next) {
      DebugOverrideHidden() => ReadingOverride.normal,
      DebugOverrideShown(:final mode) => mode,
    };
    emit(next);
  }
}
