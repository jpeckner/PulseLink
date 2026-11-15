// The contract between Dart and the native BLE code. Pigeon generates the
// Dart, Swift and Kotlin sides from this file, so a message can't be sent
// with the wrong shape on either side. Regenerate with tool/regenerate.sh.
//
// Only the data layer (lib/data/ble/) uses the generated Dart; everything
// above it sees domain types.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/data/ble/ble_api.pigeon.dart',
    dartPackageName: 'pulselink',
    swiftOut: 'ios/Runner/BleApi.pigeon.swift',
    kotlinOut:
        'android/app/src/main/kotlin/com/jpeckner/pulselink/BleApi.pigeon.kt',
    kotlinOptions: KotlinOptions(package: 'com.jpeckner.pulselink'),
  ),
)
/// Why the phone can't scan.
enum BleScanFailureReason {
  /// Bluetooth is turned off.
  poweredOff,

  /// The user hasn't allowed the app to use Bluetooth.
  unauthorized,

  /// This device or platform can't scan for BLE devices.
  unsupported,
}

/// Something that happened during a scan.
sealed class BleScanEvent;

/// The phone is scanning. Sent when scanning begins, and again when it
/// resumes after a failure (such as Bluetooth being turned back on).
class BleScanStarted extends BleScanEvent;

/// A nearby device advertising the Heart Rate Service, or one offering it
/// that's already connected to the phone.
class BleStrapFound extends BleScanEvent {
  new(this.id, this.name, this.isConnected);

  /// Identifies the device to the native BLE stack: a UUID on iOS, a MAC
  /// address on Android.
  final String id;

  /// The advertised name, if it has one.
  final String? name;

  /// Whether it was already connected to the phone when found, by this app
  /// or another one.
  final bool isConnected;
}

/// The phone can't scan, for [reason]. Scanning resumes, with a
/// [BleScanStarted], if the reason goes away while the stream is listened to.
class BleScanFailed extends BleScanEvent {
  new(this.reason);

  final BleScanFailureReason reason;
}

/// Every event stream from the native BLE code. Pigeon allows one event
/// channel class per contract.
@EventChannelApi()
abstract class BleEventApi {
  /// Scans for heart-rate straps (devices advertising service 0x180D) while
  /// listened to. Cancelling the subscription stops the scan.
  BleScanEvent scanForHeartRateStraps();

  /// Events from the connected strap while listened to. Listen before
  /// calling [BleConnectionApi.connect], so no measurement is missed.
  BleStrapEvent strapEvents();
}

/// Why the phone couldn't connect to a strap.
enum BleConnectFailureReason {
  /// Bluetooth is turned off.
  poweredOff,

  /// The user hasn't allowed the app to use Bluetooth.
  unauthorized,

  /// This device or platform can't connect to BLE devices.
  unsupported,

  /// The strap couldn't be reached: it's off, out of range, connected to
  /// another app, or didn't answer in time.
  unreachable,

  /// The device doesn't offer a Heart Rate Measurement characteristic that
  /// sends notifications.
  notAHeartRateStrap,
}

/// How a call to [BleConnectionApi.connect] ended.
sealed class BleConnectResult;

/// Connected, and subscribed to Heart Rate Measurement notifications.
class BleConnected extends BleConnectResult;

/// [BleConnectionApi.disconnect] was called before connecting finished.
class BleConnectCancelled extends BleConnectResult;

/// Couldn't connect, for [reason].
class BleConnectFailed extends BleConnectResult {
  new(this.reason);

  final BleConnectFailureReason reason;
}

@HostApi()
abstract class BleConnectionApi {
  /// Connects to the strap with [strapId] (an id from [BleStrapFound]) and
  /// subscribes to its heart-rate notifications. Completes once that's done,
  /// or with why it couldn't be. Replaces any earlier connection.
  @async
  BleConnectResult connect(String strapId);

  /// Disconnects, cancelling a connection still in progress. Does nothing
  /// when not connected.
  void disconnect();
}

/// Something that happened on the connected strap.
sealed class BleStrapEvent;

/// One Heart Rate Measurement notification (characteristic 0x2A37), exactly
/// as the strap sent it. lib/domain/heart_rate_measurement_parser.dart
/// parses it.
class BleHeartRateMeasurement extends BleStrapEvent {
  new(this.value);

  final Uint8List value;
}

/// The strap disconnected without being asked to, such as by going out of
/// range.
class BleStrapDisconnected extends BleStrapEvent;

/// The strap's battery level (Battery Level characteristic 0x2A19), as it
/// sent it: meant to be a percentage from 0 to 100, but checked in Dart.
/// Sent when read after connecting, and whenever the strap reports a
/// change. Straps without the Battery Service never send one.
class BleBatteryLevel extends BleStrapEvent {
  new(this.percent);

  final int percent;
}
