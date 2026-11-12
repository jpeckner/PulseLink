import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';

part 'debug_override_state.freezed.dart';

/// Whether the debug override button is showing, and which override it
/// applies. There's no "hidden but overriding" case: hidden always means
/// [ReadingOverride.normal].
@freezed
sealed class DebugOverrideState with _$DebugOverrideState {
  /// The button is hidden and samples pass through unchanged.
  const factory hidden() = DebugOverrideHidden;

  /// The button is showing and [mode] is applied to every sample.
  const factory shown(ReadingOverride mode) = DebugOverrideShown;
}
