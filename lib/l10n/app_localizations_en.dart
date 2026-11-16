// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PulseLink';

  @override
  String get disclaimer =>
      'For learning and fitness use only. Not a medical device.';

  @override
  String get findStrapTooltip => 'Find strap';

  @override
  String get demoBadge => 'Demo';

  @override
  String batteryPercent(int percent) {
    return '$percent%';
  }

  @override
  String batteryLabel(int percent) {
    return 'Strap battery $percent percent';
  }

  @override
  String batteryLowLabel(int percent) {
    return 'Strap battery $percent percent, low';
  }

  @override
  String get waitingForData => 'Waiting for heart-rate data…';

  @override
  String get beatsPerMinuteUnit => 'bpm';

  @override
  String get noBeatsPerMinute => '--';

  @override
  String beatsPerMinuteLabel(int beatsPerMinute) {
    String _temp0 = intl.Intl.pluralLogic(
      beatsPerMinute,
      locale: localeName,
      other: '$beatsPerMinute beats per minute',
      one: '1 beat per minute',
    );
    return '$_temp0';
  }

  @override
  String staleBeatsPerMinuteLabel(int beatsPerMinute) {
    String _temp0 = intl.Intl.pluralLogic(
      beatsPerMinute,
      locale: localeName,
      other: 'Last reading $beatsPerMinute beats per minute, out of date',
      one: 'Last reading 1 beat per minute, out of date',
    );
    return '$_temp0';
  }

  @override
  String get noHeartRateLabel => 'No heart-rate reading';

  @override
  String get noDataFromStrap => 'No data from strap';

  @override
  String lastReadingAt(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Last reading $timeString';
  }

  @override
  String updatedAt(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Updated $timeString';
  }

  @override
  String get skinContact => 'Skin contact';

  @override
  String get noSkinContact => 'No skin contact';

  @override
  String get connectedNoHeartRateYet => 'Strap connected, no heart rate yet';

  @override
  String get readingOutOfRange => 'Strap reading out of range';

  @override
  String get strapUnreachableTitle => 'Can\'t reach the strap';

  @override
  String get strapUnreachableDetail =>
      'Make sure it\'s on, being worn and nearby, and not connected to another app.';

  @override
  String get notAHeartRateStrapTitle => 'Not a heart-rate strap';

  @override
  String get notAHeartRateStrapDetail =>
      'This device doesn\'t send heart-rate data.';

  @override
  String get strapDisconnectedTitle => 'Strap disconnected';

  @override
  String get strapDisconnectedDetail =>
      'Make sure it\'s on, being worn and nearby, then try again.';

  @override
  String get bluetoothOffTitle => 'Bluetooth is off';

  @override
  String get bluetoothOffDetail =>
      'Turn on Bluetooth to connect to your strap.';

  @override
  String get bluetoothUnavailableTitle => 'Bluetooth isn\'t available';

  @override
  String get bluetoothUnavailableDetail =>
      'This phone can\'t connect to a heart-rate strap.';

  @override
  String get bluetoothPermissionTitle => 'Bluetooth permission needed';

  @override
  String get bluetoothPermissionDetail =>
      'Allow PulseLink to use Bluetooth in Settings, then try again.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get tryAgain => 'Try again';

  @override
  String get openSettingsFailed =>
      'Couldn\'t open Settings. Open the Settings app, then find PulseLink there.';

  @override
  String get pickerTitle => 'Find your strap';

  @override
  String get lookingForStraps => 'Looking for heart-rate straps…';

  @override
  String get lookingHint =>
      'Put your strap on so it wakes up, and keep it close to your phone.';

  @override
  String get tipsTitle => 'Still not finding it?';

  @override
  String get tipsBody =>
      'Dampen the strap where it touches your skin, so it can sense your heart.\n\nA strap connects to one device at a time. If another phone, watch or gym machine is connected to it, disconnect it there.';

  @override
  String get unnamedStrap => 'Unnamed heart-rate strap';

  @override
  String get strapConnectedLabel => 'Connected';

  @override
  String get tapToConnect => 'Tap your strap to connect to it.';
}
