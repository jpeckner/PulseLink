import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/domain/strap_ble_identifier.dart';
import 'package:pulselink/domain/strap_ble_name.dart';

part 'discovered_strap.freezed.dart';

/// A heart-rate strap found by a scan: nearby, or already connected to the
/// phone.
@freezed
abstract class DiscoveredStrap with _$DiscoveredStrap {
  const factory({
    /// Identifies the strap, so it can be connected to later.
    required StrapBleIdentifier id,

    /// The name the strap advertises, or null if it doesn't advertise one.
    required StrapBleName? name,

    /// Whether it was already connected to the phone when found, by this app
    /// or another one.
    required bool isConnected,
  }) = _DiscoveredStrap;
}
