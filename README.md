# PulseLink

A Flutter app that connects to a standard Bluetooth heart-rate chest strap, shows
live heart rate on an iPhone (or Android phone) and on an Apple Watch, and records
workout sessions for later review.

> **For learning and fitness use only. Not a medical device.**

## Status

Work in progress, built one milestone at a time. See the
[build plan](<BLE Heart-Rate Monitor Flutter + Apple Watch Build Plan.md>), the
[learning log](docs/learning-log.md), the
[architecture](docs/architecture.md) diagrams, and the
[manual test plan](docs/test-plan.md) for checks that need a real phone,
strap or watch.

- [x] 1. Setup and skeleton
- [x] 2. Domain and fake data (demo mode)
- [x] 3. Real BLE on iOS
- [x] 4. Real BLE on Android
- [x] 5. Apple Watch app
- [ ] 6. Reliability for iOS
- [ ] 7. Polish and portfolio (nice-to-have)
- [ ] 8. Sessions and history (nice-to-have)

## Tech stack

Flutter (iOS + Android), Material 3 via `material_ui`, `flutter_bloc` for state,
`freezed` for immutable models and states, `very_good_analysis` for lints. iOS
native dependencies use Swift Package Manager only; no CocoaPods. The watchOS
app is native SwiftUI. The phone talks to it over WatchConnectivity, in Swift,
which Dart calls through Pigeon.

```
lib/
  app/      app root, theme, Bloc observer
  ui/       widgets only; render state and send events
  blocs/    Blocs and Cubits
  domain/   plain Dart models and the heart-rate packet parser
  data/     BLE, storage and watch bridge, behind interfaces
```

## Running

Requires Flutter 3.50.0 (stable).

```bash
flutter pub get
flutter run
```

The app starts in **demo mode**: `FakeStrapDataSource` simulates a strap, and
the screen shows a "Demo" badge. On an iPhone, tap **Find strap** to pick a real
strap; that needs a physical phone, since BLE doesn't work in the iOS Simulator.
On Android (12 or later, with Bluetooth LE), **Find strap** works the same
way; the first scan asks for the Nearby devices permission, and the emulator
can't reach a real strap. On both platforms, streaming stops soon after the
app goes to the background; keeping it going comes in Milestone 6.

The iOS project includes an Apple Watch app, so Flutter needs a device ID to
run on an iOS simulator: `flutter run -d <id>`, with an ID from
`flutter devices`. The watch app comes with the iPhone app: the iPhone installs
it on its paired watch, which can take a minute. To run it straight away, or on
a watch simulator paired with the iPhone simulator, run the `PulseLinkWatch`
scheme from Xcode. It shows what the phone app shows, including demo mode.

Models and states use `freezed`, which generates `*.freezed.dart` files. They're
committed, and CI fails if they're out of date. After changing an annotated
class:

```bash
dart run build_runner build --delete-conflicting-outputs
```

To clean every build output and cache and regenerate everything (packages,
freezed code and, on macOS, the iOS project config), for example when builds
act strangely or after switching branches or upgrading Flutter:

```bash
tool/regenerate.sh
```

Checks (the same ones CI runs):

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

The Swift tests run on simulators: `ios/RunnerTests` on an iPhone and
`ios/PulseLinkWatchTests` on an Apple Watch (macOS only; CI doesn't run them
until Milestone 7):

```bash
tool/test_swift.sh
```

Lints come from `very_good_analysis`, plus
`always_put_control_body_on_new_line`. Together with
`curly_braces_in_flow_control_structures`, that means every `if`, `else`,
`for`, `while` and `do` body has braces, even a one-line `if (x) return;`.
A few more built-in lints bring it closer to Swift's compile-time checks:
`unsafe_variance`, `close_sinks`, `unreachable_from_main`,
`avoid_implementing_value_types` and `prefer_void_to_null`.
`analysis_options.yaml` says why each is on.

`flutter analyze` also runs the project's own lint rules from
`tool/pulselink_lints`, an analyzer plugin enabled in `analysis_options.yaml`
(VS Code shows them too):

- `keep_pigeon_imports_local`: a Pigeon-generated `*.pigeon.dart` file is
  imported only from its own folder (and subfolders), and never exported.
  Pigeon can't make a field private, so its raw types stay in the data layer,
  which converts them into domain types. Tests are exempt.
- `no_assertions`: no `!`, unchecked `as`, `late` without an initializer,
  `assert`, thrown `Error`, or SDK calls that throw where Swift returns an
  optional (`.first`, `int.parse`; use `firstOrNull`, `tryParse`), outside
  tests.
- `no_catch_all_cases`: no `default`, `_` or other catch-all when switching on
  an enum, `bool` or sealed type.
- `no_dynamic`: no written `dynamic`, including in type arguments such as
  `Map<String, dynamic>`; use `Object?` or a precise type.
- `no_hardcoded_ui_strings`: no string literal as a `Text`'s text or a
  user-facing argument such as `tooltip:`, `semanticLabel:`, `label:` or
  `title:`; it goes in `lib/l10n/app_en.arb` (see "Text and translations").
  Tests and debug-only code are exempt.
- `no_ignored_results`: no thrown-away value of an enum or sealed type, such
  as a typed result. Discard one on purpose with `final _ = ...;`.
- `use_switch_on_closed_types`: no `if (x case ...)`, `is` or `==` test that
  picks out some cases of an enum, `bool` or sealed type and skips the rest;
  use a switch. Null checks are fine.

After changing the plugin, restart the Dart analysis server (in VS Code:
"Dart: Restart Analysis Server"). The plugin is its own package with its own
checks; run `dart pub get` in its folder first (`tool/regenerate.sh` does it):

```bash
cd tool/pulselink_lints && dart format lib test && dart analyze && dart test
```

If the plugin fails to load, `flutter analyze` still reports no issues, so a
clean analyze doesn't prove the rules ran. `tool/check_lint_plugin.sh` does:
it analyzes a file that breaks each enabled rule and fails unless every one
reports. CI runs it after analyzing.

Locally, the analysis server runs a cached, compiled copy of the plugin
(under `~/.dartServer/.plugin_manager`). After switching branches, that copy
can be built from another branch's plugin and silently lack newer rules. The
script spots this and rebuilds it by touching the plugin's files. If an
editor shows a rule missing, touch `tool/pulselink_lints/lib/main.dart` and
restart the analysis server.

## Text and translations

Every string the app shows comes from `lib/l10n/app_en.arb`, through Flutter's
gen-l10n (`flutter_localizations` and `intl`, configured in `l10n.yaml`). It
generates `AppLocalizations`, with one typed getter or method per string, so
the UI reads `context.l10n.tryAgain`, and a missing or misspelled string is a
compile error. The app is English only for now.

To add a string:

1. Add it to `app_en.arb` with an `@` entry: a description, plus typed
   placeholders if it has any (`int`, or `DateTime` with a format such as
   `jms`). Use an ICU plural rather than choosing words in Dart.
2. Run `flutter gen-l10n` (`flutter run` and `flutter build` also do it), and
   commit the regenerated `lib/l10n/app_localizations*.dart`. CI fails if
   they're out of date.
3. Use it as `context.l10n.yourString`. Tests find text through
   `test/helpers/english.dart`.

The `no_hardcoded_ui_strings` lint flags a string literal in the UI. Debug-only
code (`debug_*.dart` files and `debug/` folders) is exempt, since release
builds drop it. To add a language later, add `app_<code>.arb` beside the
English one and regenerate; `MaterialApp` picks it up through
`AppLocalizations.supportedLocales`. The watch app's SwiftUI text isn't
covered yet.

## iOS build warnings

Every iOS build shows six Swift concurrency warnings, such as "sending 'api'
risks causing data races" or "var 'bleApiPigeonMethodCodec' is not
concurrency-safe". They're expected, and they're all in Pigeon's generated
`ios/Runner/*.pigeon.swift` files; the hand-written Swift has none.

- **Why they appear:** the Runner target turns on complete concurrency
  checking (`SWIFT_STRICT_CONCURRENCY = complete`), so the hand-written BLE
  code is checked for data races as strictly as Swift 6 checks it. That
  checking covers every file in the target, including generated ones.
- **What Pigeon 30.0.2 generates:**
  - a mutable global codec (`bleApiPigeonMethodCodec`);
  - `@async` host API handlers that pass the non-`Sendable` `api` and
    `reply` into a `Task`;
  - a reference to Flutter's `FlutterEndOfEventStream` global, which Flutter
    doesn't mark as concurrency-safe.

  Flutter calls all of these on the main thread, so none of them races in
  practice.
- **Why they aren't fixed or hidden:** `tool/pigeon.sh` regenerates those
  files, so hand edits would be lost, and Swift can't silence warnings for one
  file. Turning complete checking off would hide real problems in the
  hand-written code.
- **Why the app is still in Swift 5 mode:** Swift 6 mode turns these warnings
  into errors, so the app wouldn't build. Once Pigeon generates
  concurrency-safe Swift, switch the target to Swift 6.

Xcode's build log also has "Metadata extraction skipped, no
AppIntents.framework dependency found". Xcode prints that for any app that
doesn't use App Intents, and it's harmless.

## Debug tools

Debug and profile builds (never release builds) include a reading override
for exercising the app's warning states, with demo data or a real strap:

1. Long-press the **PulseLink** title. Two buttons appear above the
   disclaimer. They start out matching what the strap reports, so revealing
   them doesn't change anything on screen.
2. **Skin-contact detection: supported / not supported** switches between a
   strap that can detect skin contact and one that can't.
3. **Override: …** cycles through the conditions that kind of strap can be in:
   - Supported: **None → No data (stale) → No skin contact → Zero bpm →
     Implausible bpm**
   - Not supported: **None → No data (stale) → Zero bpm → Implausible bpm**
     (such a strap can't report no skin contact; switching to it from No skin
     contact resets to None)

   No data (stale) drops samples, so "No data from strap" appears after the
   real 10-second threshold.
4. Long-press the title again to hide the buttons and turn the override off.

Release builds don't contain this code: it's created only in the
non-release branch of `main()`, and because `kReleaseMode` is a compile-time
constant, the release compiler removes that branch.

## Commit messages

Commits follow the template in [`.gitmessage`](.gitmessage): a
conventional-commit subject, a why-focused body, and traceability trailers
(`Refs`, `Requirements`, `Risk-Controls`, `Safety-Impact`, `SOUP-Changes`,
`Verification`), modeled on how regulated teams trace changes. Git doesn't read
config from the repo, so enable it once per clone:

```bash
git config commit.template .gitmessage
```

## License

[MIT](LICENSE)
