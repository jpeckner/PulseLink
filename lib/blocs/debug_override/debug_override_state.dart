import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';

part 'debug_override_state.freezed.dart';

/// Whether the debug override buttons are showing, and which override they
/// apply. There's no "hidden but overriding" case: hidden always means samples
/// pass through untouched.
@freezed
sealed class DebugOverrideState with _$DebugOverrideState {
  /// The buttons are hidden and samples pass through untouched.
  const factory hidden() = DebugOverrideHidden;

  /// The buttons are showing and [readingOverride] is applied to every sample.
  const factory shown(ReadingOverride readingOverride) = DebugOverrideShown;
}
