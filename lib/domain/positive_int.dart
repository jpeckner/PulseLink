import 'package:meta/meta.dart';

/// An integer guaranteed to be above 0.
///
/// Dart can't check this at compile time, so the only way to get one is
/// [tryFrom], which returns null for anything else. Creating one can't fail,
/// and code that receives a [PositiveInt] can rely on it without checking
/// again.
@immutable
final class PositiveInt {
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
