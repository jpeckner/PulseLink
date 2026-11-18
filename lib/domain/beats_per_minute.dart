// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:meta/meta.dart';

/// A heart rate in beats per minute that's plausible for a person: from 1 to
/// [max].
///
/// Dart can't check the range at compile time, so the only way to get one is
/// [tryFrom], which returns null for anything else. A measured sample holds a
/// [BeatsPerMinute], so no code can show or record a bpm of 0, or a corrupt
/// value such as 65535, as if it were a heart rate.
@immutable
final class BeatsPerMinute {
  const new _(this.value);

  /// The highest bpm treated as a real reading. Maximal exercise in adults
  /// tops out around 220 bpm; above 250, a strap's value is far more likely to
  /// be a corrupt packet or a sensor fault than a heartbeat.
  static const max = 250;

  /// Returns null if [value] is below 1 or above [max].
  static BeatsPerMinute? tryFrom(int value) =>
      value >= 1 && value <= max ? BeatsPerMinute._(value) : null;

  final int value;

  @override
  bool operator ==(Object other) =>
      other is BeatsPerMinute && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value';
}
