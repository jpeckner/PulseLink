import 'package:freezed_annotation/freezed_annotation.dart';

part 'discovered_strap.freezed.dart';

/// A nearby heart-rate strap found by a scan.
@freezed
abstract class DiscoveredStrap with _$DiscoveredStrap {
  const factory({
    /// Identifies the strap to the phone's Bluetooth stack, so it can be
    /// connected to later. Only meaningful on the phone that found it.
    required String id,

    /// The name the strap advertises, or null if it doesn't advertise one.
    required String? name,
  }) = _DiscoveredStrap;
}
