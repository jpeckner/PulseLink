# PulseLink

A Flutter app that connects to a standard Bluetooth heart-rate chest strap, shows
live heart rate on an iPhone (or Android phone) and on an Apple Watch, and records
workout sessions for later review.

> **For learning and fitness use only. Not a medical device.**

## Status

Work in progress, built one milestone at a time. See the
[build plan](<BLE Heart-Rate Monitor Flutter + Apple Watch Build Plan.md>) and the
[learning log](docs/learning-log.md).

- [x] 1. Setup and skeleton
- [ ] 2. Domain and fake data (demo mode)
- [ ] 3. Real BLE
- [ ] 4. Reliability
- [ ] 5. Sessions and history
- [ ] 6. Apple Watch app
- [ ] 7. Polish and portfolio

## Tech stack

Flutter (iOS + Android), Material 3 via `material_ui`, `flutter_bloc` for state,
`very_good_analysis` for lints. iOS native dependencies use Swift Package
Manager only; no CocoaPods. The watchOS app (Milestone 6) is native SwiftUI,
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

BLE does not work in the iOS Simulator; use a physical iPhone. A demo mode that
needs no hardware arrives in Milestone 2.

Checks (the same ones CI runs):

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

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
