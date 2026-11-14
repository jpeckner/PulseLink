# BLE Heart-Rate Monitor: Flutter + Apple Watch Build Plan

Nov 11, 2026 · @Justin

## Instructions for Claude

You are my pair programmer and Flutter tutor for this project. Build it with me one milestone at a time, following the plan below.

About me: I'm an experienced mobile engineering manager with a native background (Swift, Kotlin), including medical-device apps. I'm new to Flutter and Dart. I'm building this to learn Flutter, BLE and watchOS, and to show it in my portfolio.

How to work with me:

- Start each milestone by restating its goal and listing the files you'll create or change. Wait for my go-ahead before large changes.
- Explain Flutter and Dart ideas by comparing them to SwiftUI or Jetpack Compose where it helps.
- Write idiomatic, production-quality code: null safety, clear layering, no logic in widgets, and tests for every parser and state class.
- Keep changes small enough that I can run and check each step on a device.
- When there's a real design choice (a package, a state approach, a channel API), give me two options with trade-offs and a recommendation.
- Tell me when something needs a physical device, Xcode or Android Studio setup, or a permission change.
- Point out what would be done differently in a regulated medical app, briefly, when relevant.

Constraints:

- This is a learning and portfolio app, not a medical device. Make no medical claims and give no health advice.
- Use current stable Flutter and Dart. Check package versions on pub.dev rather than relying on memory.
- Keep the BLE and watch layers behind interfaces so they can be faked in tests.
- Avoid assertions as much as possible. Instead, build compile-time safe components that can't fail at runtime: make invalid states unrepresentable with sealed classes, dedicated enums and value types (such as `BeatsPerMinute`), and have untrusted input (BLE packets, platform-channel messages, stored data) return a typed result or `null` rather than fail. This covers anything in app code that fails at runtime because of a programmer error: `assert`, freezed `@Assert`, the `!` null-assertion operator, unchecked `as` casts, `late` fields that could be read before they're set, and functions or constructors that throw on invalid arguments (`ArgumentError`, `StateError` and the like). That includes SDK calls that throw on an empty collection or bad input, where Swift returns an optional: use `firstOrNull`, `tryParse` and the like instead of `.first` or `int.parse`. Test code is exempt: `expect`, `fail` and casts in tests are fine. The `no_assertions` lint (`tool/pulselink_lints`) enforces this outside tests.
- In the rare case where there's no alternative to an assertion, stop before writing it. Explain the case, the alternatives considered and why each doesn't work, and wait for my explicit sign-off before proceeding any further. Once I approve, leave a short comment at that line explaining why it's needed, and ignore the lint there.
- Native code (Swift in `ios/`, Kotlin in `android/`) follows the same rule, though no lint enforces it there yet. Swift: no `!` force unwraps, `as!` casts, implicitly unwrapped optionals (`Type!`) or `try!`, and no `fatalError`, `precondition` or `assert`; use `if let`, `guard let`, `as?` and `try?` or `do`/`catch`. Switch on the app's own enums without `default`; the `@unknown default` Swift requires for Apple's enums is fine, with a comment saying what it does and why. Kotlin: no `!!`, unchecked `as` casts or `lateinit`, and no `error()`, `require` or `check`; use `?.`, `?:`, `as?` and `firstOrNull()`, and write `when` on sealed classes and enums without `else`. Pigeon's generated `*.pigeon.swift` and `*.pigeon.kt` files are exempt.
- In Swift, declare a protocol conformance in its own extension whenever it adds anything (methods, properties, initializers or subscripts), such as `extension CentralScan: CBCentralManagerDelegate { ... }`. Then each protocol's members sit together, apart from the type's own. A conformance that adds nothing, such as `Equatable` synthesized for an enum, can stay on the type's declaration.
- Switch on closed types without a catch-all. Model a fixed set of cases as an enum or sealed class (not an `int`, a `String` or a plain abstract class), and when switching on it, list every case: no `default`, `_`, untyped variable or other catch-all. Then adding a case is a compile error at every switch that must handle it, as in Swift. The `no_catch_all_cases` lint (`tool/pulselink_lints`) enforces this; where a catch-all is truly needed, ignore the lint with a comment saying why. For the same reason, don't test a closed type for one case with `if (x case ...)`, `is` or `==`: those silently skip new cases, so use a switch, with an explicit do-nothing case where one applies. The `use_switch_on_closed_types` lint enforces this; a null check such as `if (x case final y?)` is still fine.
- Handle errors on purpose. Dart has no checked exceptions and no lint can tell what throws, so this rule and the tests are the check. Expected failures (Bluetooth off, permission denied, strap out of range, a failed write) are outcomes, not exceptions: data-layer implementations catch what packages and platform channels throw and return a typed result, so callers must handle every case. The `no_ignored_results` lint flags a typed result that's thrown away; to discard one on purpose, write `final _ = ...;` with a comment saying why. Cleanup in `close()`, `dispose()` and the like goes in `try`/`finally` so it always finishes, and the error still reaches the caller. Catch specific types (`on SomeException`), never swallow an error silently, and when an exception is left uncaught on purpose, add a short comment saying why and what handles it. Every cleanup path gets a test with a dependency that fails. Before committing changes to `lib/` that add async calls, cleanup code, catch blocks or data-layer implementations, run the `error-handling-review` project skill and resolve its findings.

## Project overview

The app, working name **PulseLink**, connects to a standard Bluetooth heart-rate chest strap, shows live heart rate on the iPhone and on an Apple Watch, and records workout sessions for later review.

Goals:

- Learn Flutter and Dart well enough to talk credibly about architecture, state management and platform channels.
- Get hands-on with the hard parts of medical-style mobile apps: BLE connection handling, reconnection, background limits and showing stale or missing data honestly.
- Learn how a Flutter iOS app works with a native SwiftUI watchOS app.
- Finish with a clean, tested, documented GitHub repo for my portfolio.

Non-goals for v1:

- A Wear OS watch app (Android runs the phone app only)
- Cloud sync, accounts or a backend
- Medical-grade accuracy, alerts or diagnosis

Disclaimer to include in the app and README: "For learning and fitness use only. Not a medical device."

## Tech stack and architecture

Flutter can't build watchOS apps, so the watch app is native SwiftUI. It talks to the Flutter app through Apple's WatchConnectivity framework, bridged into Dart with a platform channel.

| Layer | Choice | Notes |
| --- | --- | --- |
| Phone UI | Flutter (iOS + Android) | Material 3; one codebase |
| State | Bloc (flutter\_bloc) | Cubits for simple screens; a full Bloc for the connection state machine |
| BLE | CoreBluetooth (iOS) and Android's BLE APIs, through Pigeon platform channels | Scan, connect, subscribe to notifications; written by hand for learning, with Dart, Swift and Kotlin generated from one contract in `pigeons/` |
| Storage | `drift` (SQLite) | Sessions and samples |
| Charts | `fl_chart` | Session history graphs |
| Watch app | SwiftUI, watchOS | Embedded in the iOS Runner project |
| Phone-watch bridge | WatchConnectivity + Flutter `MethodChannel` / `EventChannel` | Written by hand for learning; the `watch_connectivity` package is the fallback |
| Tests | `flutter_test`, `mocktail`, bloc\_test, XCTest | Fakes for BLE and watch |
| CI | GitHub Actions | Analyze, test, build |

Layers in the Flutter app, top to bottom:

1. **UI**: widgets only. They rebuild from Bloc states (BlocBuilder) and send events.
2. **Blocs and Cubits**: connection state machine, live session, history.
3. **Domain**: plain Dart models (`HeartRateSample`, `Session`, `ConnectionState`) and the HR packet parser.
4. **Data**: `HeartRateSource` interface with `BleHeartRateSource` and `FakeHeartRateSource`; `StrapScanner` interface with `BleStrapScanner`; `SessionRepository` on drift; `WatchBridge` interface with a platform-channel implementation.

&#91;embedded content: PulseLink architecture · strap to phone to watch\]

Heart-rate packets enter only through the data layer, and watch messages leave only through it, so both can be swapped for fakes in tests.

Watch messaging, using the right WatchConnectivity API for each job:

- Live heart rate while the watch app is open: `sendMessage` (needs the watch reachable; drop samples if it isn't).
- Latest state when the watch app launches: `updateApplicationContext`, holding last bpm, timestamp and connection status.
- Watch commands such as start or stop a session: `sendMessage` from the watch, answered by the phone.

Every value shown on phone or watch carries its timestamp. The UI marks data older than 10 seconds as stale instead of showing it as current.

## Feature scope

MVP (phone):

- Scan for devices advertising the Heart Rate Service, then pick and pair one
- Live screen: big bpm number, last-updated time, connection status, sensor-contact indicator, battery level if available
- Clear states: scanning, connecting, connected, reconnecting, disconnected, Bluetooth off, permission denied
- Automatic reconnect to the last device after a drop or app restart
- Start and stop a session; store samples (bpm, RR intervals, timestamp)
- History list and session detail: duration, average, min and max, and a chart
- Demo mode using `FakeHeartRateSource`, so the app works with no hardware (also useful for screenshots and tests)

MVP (watch):

- Live bpm with a stale-data indicator and connection status
- Start and stop session buttons that control the phone
- Shows a clear "phone not reachable" state

Stretch, in priority order:

1. Watch complication showing the latest bpm and its age
2. iOS home-screen widget and Live Activity during a session
3. Heart-rate zones and an alert when you leave your zone
4. Export a session to CSV, and optionally write workouts to Apple Health / Health Connect
5. Heart-rate variability (RMSSD) from RR intervals
6. Watch connects to the strap directly with CoreBluetooth when the phone is away

## Milestones

Each milestone ends with something I can run on a device and a commit. Each one gets a short note in `docs/learning-log.md`.

1. **Setup and skeleton.** Install Flutter, Xcode and Android Studio. Create the project, folder structure, lint rules (`flutter_lints` or `very_good_analysis`), flutter\_bloc and an empty CI workflow.
   - Done when: the app runs on my iPhone and an Android phone, and CI is green.
2. **Domain and fake data.** Models, the HR packet parser with unit tests, the `HeartRateSource` interface, `FakeHeartRateSource` and the live screen in demo mode.
   - Done when: demo mode shows a moving bpm with timestamps, and the parser tests pass.
3. **Real BLE.** Permissions on both platforms, scan filtered by service UUID, device picker, connect, subscribe to notifications, battery level.
   - Done when: a real strap shows live bpm on both platforms.
4. **Reliability.** Connection state machine, automatic reconnect with backoff, Bluetooth off and on, permission denied, app backgrounded, remembering the last device, stale-data display.
   - Done when: I can walk out of range and back, toggle Bluetooth, and kill and reopen the app, and it always recovers or explains itself.
5. **Sessions and history.** drift schema, recording, history list, session detail with chart and stats.
   - Done when: a 20-minute session saves and charts correctly.
6. **Apple Watch app.** Add the watchOS target, write the Swift WatchConnectivity bridge and platform channels, build the SwiftUI live view and start/stop controls.
   - Done when: the watch shows live bpm and can start and stop a session, and handles "phone not reachable".
7. **Polish and portfolio.** Tests filled in, CI building iOS and Android, README with screenshots and a demo GIF, architecture doc, hazard table.
   - Done when: the repo is public and I can walk through it in an interview in 5 minutes.

Then pick stretch items, starting with the watch complication.

## BLE details

Most chest straps use the standard Bluetooth Heart Rate Service, so one parser works for every brand.

| Item | UUID | Use |
| --- | --- | --- |
| Heart Rate Service | `0x180D` | Filter scans by this |
| Heart Rate Measurement | `0x2A37` | Notify: live bpm, contact, RR intervals |
| Body Sensor Location | `0x2A38` | Read once (optional) |
| Battery Service / Battery Level | `0x180F` / `0x2A19` | Read, or notify if supported |

Heart Rate Measurement packet: byte 0 is a flags byte; the fields after it are little-endian.

- Bit 0: bpm format. 0 = one byte (uint8), 1 = two bytes (uint16).
- Bits 1-2: sensor contact. Bit 2 = feature supported, bit 1 = contact detected.
- Bit 3: energy expended present (uint16, kJ). Skip it if present.
- Bit 4: RR intervals present. Each one is a uint16 in units of 1/1024 second, and there can be several per packet.

Parser test fixtures to start with:

- `[0x16, 0x48, 0x00, 0x04]` → 72 bpm, contact detected, RR = \[1000 ms\]
- `[0x01, 0xB4, 0x00]` → 180 bpm (16-bit format), contact not supported
- Malformed or short packets → a parse error, never a crash or a wrong number

Platform setup:

- **iOS**: `NSBluetoothAlwaysUsageDescription` in Info.plist; the `bluetooth-central` background mode so notifications keep arriving while backgrounded. Background scans must filter by service UUID. BLE doesn't work in the iOS Simulator, so use a real iPhone.
- **Android 12+**: `BLUETOOTH_SCAN` (with `neverForLocation`) and `BLUETOOTH_CONNECT`. Android 11 and below: location permission is required to scan. To keep streaming in the background, use a foreground service of type `connectedDevice` (Android 14 also needs the matching foreground-service permission).

Reliability rules to build in:

- One connection state machine owns all transitions; the UI only renders its state.
- Reconnect with backoff (1, 2, 4, 8 seconds, then every 30 seconds), and stop when the user disconnects on purpose.
- Android: GATT error 133 is common, so retry after a short delay; don't start scans more than about 5 times in 30 seconds, or Android silently throttles them.
- Treat "no packet for 10 seconds" as stale, even if the link still says connected.
- Log every state change with a timestamp to an in-app debug screen. It makes BLE bugs much easier to diagnose.

Hardware: any strap that supports Bluetooth (not only ANT+), about $30-$100, such as a Polar H10, Wahoo TICKR or Coospo H6. Without one, a spare Android phone running nRF Connect can act as a fake heart-rate sensor (GATT server), alongside the app's own demo mode.

## Testing, CI and docs

Testing:

- Unit tests: packet parser (fixtures above), connection state machine Bloc (every transition, using bloc\_test), session stats.
- Widget tests: live screen in each connection state, including stale data.
- Fakes: `FakeHeartRateSource` with scripted drops and reconnects; `FakeWatchBridge`.
- Native: XCTest for message encoding and decoding on the watch side.
- Manual test checklist in `docs/test-plan.md`: out of range, Bluetooth toggled, app killed, phone locked, watch unreachable, strap battery low.

CI (GitHub Actions): `flutter analyze`, `dart format --set-exit-if-changed`, `flutter test` with coverage on every push; an Android build on Ubuntu and an iOS build on macOS (no code signing).

Docs to commit:

- `README.md`: what it does, screenshots, demo GIF, how to run, demo mode, disclaimer.
- `docs/architecture.md`: layers, the phone-watch design, and Mermaid sequence diagrams for connect-and-stream and watch start/stop.
- `docs/hazards.md`: a lightweight hazard table (hazard, cause, mitigation), such as stale bpm shown as current, or a session lost on crash. It mirrors how regulated teams think without claiming compliance.
- `docs/learning-log.md`: what I learned per milestone, with Flutter-vs-native notes. Useful interview material.

## Setup checklist and open questions

- [ ] Mac with current Xcode, plus watchOS simulator runtimes
- [ ] Flutter SDK (stable) and Android Studio; `flutter doctor` all green
- [ ] Physical iPhone and paired Apple Watch (BLE needs a real phone)
- [ ] Android phone for Android testing
- [ ] Apple Developer account. Free provisioning works on my own devices but expires every 7 days; the paid program is needed for TestFlight
- [ ] Bluetooth heart-rate strap, or a spare Android phone with nRF Connect
- [ ] Public GitHub repo with an MIT license

Open questions:

- Which features need a full Bloc (events) versus a simpler Cubit? Plan: Bloc for connection and sessions, Cubits elsewhere.
- Hand-written platform channels, or the `watch_connectivity` package? (Plan: hand-written, for learning.)
- App name and bundle ID
- Android-only Wear OS app later, or never?
