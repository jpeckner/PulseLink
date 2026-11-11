import 'package:meta/meta.dart';

/// An integer guaranteed to be above 0.
///
/// Dart can't check this at compile time, so it's checked once, when the value
/// is created, in every build mode. Code that receives a [PositiveInt] can
/// rely on it without checking again.
@immutable
final class PositiveInt {
  /// Creates a [PositiveInt], throwing [ArgumentError] if [value] isn't above
  /// 0. For values the caller already knows are valid, such as constants. Use
  /// [tryFrom] for untrusted input.
  factory(int value) =>
      tryFrom(value) ??
      (throw ArgumentError.value(value, 'value', 'must be above 0'));

  const new _(this.value);

  /// Returns null if [value] isn't above 0.
  static PositiveInt? tryFrom(int value) =>
      value > 0 ? PositiveInt._(value) : null;

  final int value;

  @override
  bool operator ==(Object other) =>
      other is PositiveInt && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value';
}
