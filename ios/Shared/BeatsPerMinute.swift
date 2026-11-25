// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

/// A heart rate in beats per minute that's plausible for a person: from 1 to
/// `BeatsPerMinute.range.upperBound`. The Swift counterpart of the Dart
/// `BeatsPerMinute` in lib/domain/beats_per_minute.dart, with the same range.
///
/// The only way to get one is the failable initializer, so no code can show
/// a bpm of 0, or a corrupt value such as 65535, as if it were a heart rate.
struct BeatsPerMinute: Equatable, Sendable {
  /// The bpm values treated as real readings. Above 250, a value is far more
  /// likely to be a corrupt packet or a sensor fault than a heartbeat.
  static let range = 1...250

  let value: Int

  /// Returns nil if `value` is outside `range`.
  init?(_ value: Int) {
    guard Self.range.contains(value) else {
      return nil
    }
    self.value = value
  }
}
