import 'package:material_ui/material_ui.dart';
import 'package:pulselink/l10n/app_localizations.dart';
import 'package:pulselink/l10n/app_localizations_en.dart';

export 'package:pulselink/l10n/app_localizations.dart';

/// PulseLinkApp's localizations: the app's own strings, and material_ui's
/// translations of its widgets' text, plus the widgets and Cupertino ones.
///
/// Not AppLocalizations.localizationsDelegates, which names
/// flutter_localizations' copy of the Material translations; this app's
/// widgets come from material_ui. Loading the Material ones also loads intl's
/// date formats for each locale, which the strings with a time in them need.
const List<LocalizationsDelegate<Object?>> pulseLinkLocalizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

/// The app's user-facing strings: `context.l10n.tryAgain`.
///
/// Every string comes from lib/l10n/app_en.arb, through the AppLocalizations
/// class gen-l10n generates from it, so a missing or misspelled string is a
/// compile error. The `no_hardcoded_ui_strings` lint keeps string literals
/// out of the UI.
extension AppLocalizationsContext on BuildContext {
  /// The strings for this context's locale. US English outside PulseLinkApp's
  /// localizations (such as in a test that pumps a bare widget), where
  /// `AppLocalizations.of` returns null, rather than failing with `!`.
  ///
  /// `en_US` rather than `en`: intl knows only `en_US`'s date formats until
  /// the Material localizations load the rest, and the strings with a time
  /// in them would throw for any other locale.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizationsEn('en_US');
}
