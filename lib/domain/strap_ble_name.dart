// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:meta/meta.dart';

/// The name a strap advertises over Bluetooth, such as "Polar H10 12345678".
///
/// The only way to get one is [tryFrom], which trims it and returns null if
/// nothing's left, so the app never shows a blank name.
@immutable
final class StrapBleName {
  const new _(this.value);

  /// [value] without surrounding whitespace, or null if that leaves nothing.
  static StrapBleName? tryFrom(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : StrapBleName._(trimmed);
  }

  final String value;

  @override
  bool operator ==(Object other) =>
      other is StrapBleName && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
