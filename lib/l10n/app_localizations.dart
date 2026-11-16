import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The app's name, in the app bar and the app switcher.
  ///
  /// In en, this message translates to:
  /// **'PulseLink'**
  String get appTitle;

  /// The non-medical disclaimer at the bottom of every main screen.
  ///
  /// In en, this message translates to:
  /// **'For learning and fitness use only. Not a medical device.'**
  String get disclaimer;

  /// Tooltip and screen-reader label for the app bar button that opens the strap picker.
  ///
  /// In en, this message translates to:
  /// **'Find strap'**
  String get findStrapTooltip;

  /// Badge in the app bar while the heart rate is simulated (demo mode).
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demoBadge;

  /// The strap's battery level next to its icon in the app bar.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String batteryPercent(int percent);

  /// Screen-reader label for the strap's battery level.
  ///
  /// In en, this message translates to:
  /// **'Strap battery {percent} percent'**
  String batteryLabel(int percent);

  /// Screen-reader label for the strap's battery level once it's low.
  ///
  /// In en, this message translates to:
  /// **'Strap battery {percent} percent, low'**
  String batteryLowLabel(int percent);

  /// Shown under the empty readout until the first heart-rate reading arrives.
  ///
  /// In en, this message translates to:
  /// **'Waiting for heart-rate data…'**
  String get waitingForData;

  /// Unit after the large heart-rate number: beats per minute.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get beatsPerMinuteUnit;

  /// Shown in place of the heart-rate number when there's no usable reading.
  ///
  /// In en, this message translates to:
  /// **'--'**
  String get noBeatsPerMinute;

  /// Screen-reader label for the current heart rate.
  ///
  /// In en, this message translates to:
  /// **'{beatsPerMinute, plural, =1{1 beat per minute} other{{beatsPerMinute} beats per minute}}'**
  String beatsPerMinuteLabel(int beatsPerMinute);

  /// Screen-reader label for the last heart rate once no new data has arrived for a while.
  ///
  /// In en, this message translates to:
  /// **'{beatsPerMinute, plural, =1{Last reading 1 beat per minute, out of date} other{Last reading {beatsPerMinute} beats per minute, out of date}}'**
  String staleBeatsPerMinuteLabel(int beatsPerMinute);

  /// Screen-reader label for the readout when there's no usable heart rate.
  ///
  /// In en, this message translates to:
  /// **'No heart-rate reading'**
  String get noHeartRateLabel;

  /// Warning shown once no heart-rate data has arrived for a while.
  ///
  /// In en, this message translates to:
  /// **'No data from strap'**
  String get noDataFromStrap;

  /// Under the 'No data from strap' warning: when the last reading arrived.
  ///
  /// In en, this message translates to:
  /// **'Last reading {time}'**
  String lastReadingAt(DateTime time);

  /// Under the heart rate: when the reading arrived.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String updatedAt(DateTime time);

  /// Chip saying the strap senses the skin.
  ///
  /// In en, this message translates to:
  /// **'Skin contact'**
  String get skinContact;

  /// Chip saying the strap doesn't sense the skin, so there's no heart rate.
  ///
  /// In en, this message translates to:
  /// **'No skin contact'**
  String get noSkinContact;

  /// Chip shown when the strap sends a heart rate of 0, as straps do while settling.
  ///
  /// In en, this message translates to:
  /// **'Strap connected, no heart rate yet'**
  String get connectedNoHeartRateYet;

  /// Chip shown when the strap sends a value that can't be a heart rate.
  ///
  /// In en, this message translates to:
  /// **'Strap reading out of range'**
  String get readingOutOfRange;

  /// Title when connecting to the strap failed or timed out.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the strap'**
  String get strapUnreachableTitle;

  /// What to do when the strap can't be reached.
  ///
  /// In en, this message translates to:
  /// **'Make sure it\'s on, being worn and nearby, and not connected to another app.'**
  String get strapUnreachableDetail;

  /// Title when the picked device doesn't offer heart-rate data.
  ///
  /// In en, this message translates to:
  /// **'Not a heart-rate strap'**
  String get notAHeartRateStrapTitle;

  /// Explains a device that isn't a heart-rate strap.
  ///
  /// In en, this message translates to:
  /// **'This device doesn\'t send heart-rate data.'**
  String get notAHeartRateStrapDetail;

  /// Title when a connected strap drops.
  ///
  /// In en, this message translates to:
  /// **'Strap disconnected'**
  String get strapDisconnectedTitle;

  /// What to do when the strap has dropped.
  ///
  /// In en, this message translates to:
  /// **'Make sure it\'s on, being worn and nearby, then try again.'**
  String get strapDisconnectedDetail;

  /// Title when the phone's Bluetooth is turned off.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off'**
  String get bluetoothOffTitle;

  /// What to do when Bluetooth is off.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth to connect to your strap.'**
  String get bluetoothOffDetail;

  /// Title when the phone can't use Bluetooth LE at all.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth isn\'t available'**
  String get bluetoothUnavailableTitle;

  /// Explains a phone without usable Bluetooth LE.
  ///
  /// In en, this message translates to:
  /// **'This phone can\'t connect to a heart-rate strap.'**
  String get bluetoothUnavailableDetail;

  /// Title when the user hasn't allowed the app to use Bluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission needed'**
  String get bluetoothPermissionTitle;

  /// What to do when Bluetooth permission is denied.
  ///
  /// In en, this message translates to:
  /// **'Allow PulseLink to use Bluetooth in Settings, then try again.'**
  String get bluetoothPermissionDetail;

  /// Button that opens this app's page in the phone's Settings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Button that retries connecting after a problem.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Snack bar when the phone wouldn't open this app's Settings page.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Settings. Open the Settings app, then find PulseLink there.'**
  String get openSettingsFailed;

  /// Title of the strap picker screen.
  ///
  /// In en, this message translates to:
  /// **'Find your strap'**
  String get pickerTitle;

  /// Shown while the picker scans and hasn't found a strap yet.
  ///
  /// In en, this message translates to:
  /// **'Looking for heart-rate straps…'**
  String get lookingForStraps;

  /// Hint under 'Looking for heart-rate straps'.
  ///
  /// In en, this message translates to:
  /// **'Put your strap on so it wakes up, and keep it close to your phone.'**
  String get lookingHint;

  /// Heading for tips shown after scanning for a while without finding a strap.
  ///
  /// In en, this message translates to:
  /// **'Still not finding it?'**
  String get tipsTitle;

  /// Tips for finding a strap; two paragraphs separated by a blank line.
  ///
  /// In en, this message translates to:
  /// **'Dampen the strap where it touches your skin, so it can sense your heart.\n\nA strap connects to one device at a time. If another phone, watch or gym machine is connected to it, disconnect it there.'**
  String get tipsBody;

  /// Picker entry for a strap that doesn't advertise a name.
  ///
  /// In en, this message translates to:
  /// **'Unnamed heart-rate strap'**
  String get unnamedStrap;

  /// Screen-reader label for the check mark on a strap already connected to the phone.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get strapConnectedLabel;

  /// Instruction under the list of straps found.
  ///
  /// In en, this message translates to:
  /// **'Tap your strap to connect to it.'**
  String get tapToConnect;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
