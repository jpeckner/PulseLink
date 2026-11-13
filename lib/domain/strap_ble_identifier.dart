import 'package:meta/meta.dart';

/// Identifies a strap to the phone's Bluetooth stack, so the app can connect
/// to it later: a UUID on iOS, a MAC address on Android. Only meaningful on
/// the phone that found the strap.
///
/// The only way to get one is [tryFrom], which returns null for a blank
/// string, so no strap can be identified by nothing.
@immutable
final class StrapBleIdentifier {
  const new _(this.value);

  /// Returns null if [value] is empty or only whitespace. Otherwise keeps
  /// [value] exactly as given, since the Bluetooth stack matches it exactly.
  static StrapBleIdentifier? tryFrom(String value) =>
      value.trim().isEmpty ? null : StrapBleIdentifier._(value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is StrapBleIdentifier && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
