import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/domain/discovered_strap.dart';
import 'package:pulselink/domain/strap_ble_identifier.dart';
import 'package:pulselink/domain/strap_ble_name.dart';

/// A [StrapBleIdentifier] for test fixtures. Fails the test, rather than
/// returning null, if [value] is blank.
StrapBleIdentifier strapIdOf(String value) =>
    StrapBleIdentifier.tryFrom(value) ?? fail('"$value" is not a valid id');

/// A [StrapBleName] for test fixtures. Fails the test, rather than returning
/// null, if [value] is blank.
StrapBleName strapNameOf(String value) =>
    StrapBleName.tryFrom(value) ?? fail('"$value" is not a valid name');

/// A [DiscoveredStrap] for test fixtures, with no name if [name] is null.
DiscoveredStrap discoveredStrapOf(String id, [String? name]) => DiscoveredStrap(
  id: strapIdOf(id),
  name: name == null ? null : strapNameOf(name),
  isConnected: false,
);

/// Like [discoveredStrapOf], for a strap already connected to the phone.
DiscoveredStrap connectedStrapOf(String id, [String? name]) =>
    discoveredStrapOf(id, name).copyWith(isConnected: true);
