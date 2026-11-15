// The contract for opening this app's page in the phone's Settings app.
// Pigeon generates the Dart, Swift and Kotlin sides from this file.
// Regenerate with tool/regenerate.sh.
//
// Only lib/data/app_settings/ uses the generated Dart; everything above it
// sees the AppSettings interface.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/data/app_settings/app_settings_api.pigeon.dart',
    dartPackageName: 'pulselink',
    swiftOut: 'ios/Runner/AppSettingsApi.pigeon.swift',
    // ble_api.dart's generated code already declares the error class, and
    // both files are compiled into the same module.
    swiftOptions: SwiftOptions(includeErrorClass: false),
    kotlinOut:
        'android/app/src/main/kotlin/com/jpeckner/pulselink/AppSettingsApi.pigeon.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.jpeckner.pulselink',
      includeErrorClass: false,
    ),
  ),
)
@HostApi()
abstract class AppSettingsApi {
  /// Opens this app's page in the Settings app, where the user can allow
  /// Bluetooth. Completes with whether it opened.
  @async
  bool openAppSettings();
}
