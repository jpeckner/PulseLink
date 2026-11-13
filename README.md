# PulseLink

A Flutter app that connects to a standard Bluetooth heart-rate chest strap, shows
live heart rate on an iPhone (or Android phone) and on an Apple Watch, and records
workout sessions for later review.

> **For learning and fitness use only. Not a medical device.**

## Status

Work in progress, built one milestone at a time. See the
[build plan](<BLE Heart-Rate Monitor Flutter + Apple Watch Build Plan.md>) and the
[learning log](docs/learning-log.md).

- [ ] 1. Setup and skeleton
- [ ] 2. Domain and fake data (demo mode)
- [ ] 3. Real BLE
- [ ] 4. Reliability
- [ ] 5. Sessions and history
- [ ] 6. Apple Watch app
- [ ] 7. Polish and portfolio

## Tech stack

Flutter (iOS + Android), Material 3 via `material_ui`, `flutter_bloc` for state,
`freezed` for immutable models and states, `very_good_analysis` for lints. iOS
native dependencies use Swift Package Manager only; no CocoaPods. The watchOS app (Milestone 6) is native SwiftUI,
bridged to Flutter with WatchConnectivity and platform channels.

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

For now the app always runs in **demo mode**: `FakeHeartRateSource` simulates a
strap, and the screen shows a "Demo" badge. Real BLE arrives in Milestone 3 and
needs a physical phone (BLE doesn't work in the iOS Simulator).

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

Lints come from `very_good_analysis`, plus
`always_put_control_body_on_new_line`. Together with
`curly_braces_in_flow_control_structures`, that means every `if`, `else`,
`for`, `while` and `do` body has braces, even a one-line `if (x) return;`.

`flutter analyze` also runs the project's own lint rules from
`tool/pulselink_lints`, an analyzer plugin enabled in `analysis_options.yaml`
(VS Code shows them too). After changing the plugin, restart the Dart analysis
server (in VS Code: "Dart: Restart Analysis Server"). The plugin is its own
package with its own checks; run `dart pub get` in its folder first
(`tool/regenerate.sh` does it):

```bash
cd tool/pulselink_lints && dart format lib test && dart analyze && dart test
```

<<<<<<< HEAD
=======
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

>>>>>>> f84f9c6 (chore(heart_rate_monitor): Milestone 2 - tooling)
## Debug tools

Debug and profile builds (never release builds) include a reading override
for exercising the app's warning states, with demo data or a real strap:

1. Long-press the **PulseLink** title. Two buttons appear above the
   disclaimer. They start out matching what the strap reports, so revealing
   them doesn't change anything on screen.
2. **Skin-contact detection: supported / not supported** switches between a
   strap that can detect skin contact and one that can't.
3. **Override: …** cycles through the conditions that kind of strap can be in:
   - Supported: **Normal → No data (stale) → No skin contact → Zero bpm**
   - Not supported: **Normal → No data (stale) → Zero bpm** (such a strap
     can't report no skin contact; switching to it from No skin contact
     resets to Normal)

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
