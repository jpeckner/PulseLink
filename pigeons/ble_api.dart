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

/// A nearby device advertising the Heart Rate Service.
class BleStrapFound extends BleScanEvent {
  new(this.id, this.name);

  /// Identifies the device to the native BLE stack: a UUID on iOS, a MAC
  /// address on Android.
  final String id;

  /// The advertised name, if it has one.
  final String? name;
}

/// The phone can't scan, for [reason]. Scanning resumes, with a
/// [BleScanStarted], if the reason goes away while the stream is listened to.
class BleScanFailed extends BleScanEvent {
  new(this.reason);

  final BleScanFailureReason reason;
}

@EventChannelApi()
abstract class BleScanApi {
  /// Scans for heart-rate straps (devices advertising service 0x180D) while
  /// listened to. Cancelling the subscription stops the scan.
  BleScanEvent scanForHeartRateStraps();
}
