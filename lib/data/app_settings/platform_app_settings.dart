import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:pulselink/data/app_settings.dart';
import 'package:pulselink/data/app_settings/app_settings_api.pigeon.dart';

/// Opens Settings through the Pigeon contract in
/// pigeons/app_settings_api.dart: iOS's page for this app, or Android's App
/// info page.
class PlatformAppSettings implements AppSettings {
  /// [api] stands in for the platform channel in tests.
  new({AppSettingsApi? api}) : _api = api ?? AppSettingsApi();

  final AppSettingsApi _api;

  @override
  Future<bool> open() async {
    try {
      return await _api.openAppSettings();
    } on PlatformException catch (error, stackTrace) {
      // The native side reports that it couldn't open Settings as false, so
      // this means the channel itself failed, such as a missing native
      // handler. Either way Settings didn't open.
      developer.log(
        'Opening Settings failed on the platform channel',
        name: 'settings',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
