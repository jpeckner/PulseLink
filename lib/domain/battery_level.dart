// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:meta/meta.dart';

/// A strap's battery level, as a percentage from 0 to 100.
///
/// The only way to get one is [tryFrom], which returns null for anything
/// outside that range, such as a corrupt byte from the strap.
@immutable
final class BatteryLevel {
  const new _(this.percent);

  /// Below this, [isLow] is true and the app warns that the strap needs
  /// charging or a new battery.
  static const lowBelow = 20;

  /// Returns null if [percent] is below 0 or above 100.
  static BatteryLevel? tryFrom(int percent) =>
      percent >= 0 && percent <= 100 ? BatteryLevel._(percent) : null;

  final int percent;

  /// Whether the strap needs charging or a new battery soon.
  bool get isLow => percent < lowBelow;

  @override
  bool operator ==(Object other) =>
      other is BatteryLevel && other.percent == percent;

  @override
  int get hashCode => percent.hashCode;

  @override
  String toString() => '$percent%';
}
