# Learning log

What I learned per milestone, with Flutter-vs-native notes.

## Milestone 1: Setup and skeleton (2026-11-11)

Built: Flutter 3.50.0 project (iOS + Android), bundle ID `com.jpeckner.pulselink`,
layered folders, `very_good_analysis` lints, `flutter_bloc`, a smoke widget test
and a GitHub Actions workflow (format, analyze, test).

Flutter vs native:

- **`flutter create` gives you two real native projects.** `ios/` is a normal
  Xcode workspace and `android/` a normal Gradle project. Signing, `Info.plist`,
  Android permissions, and later the watchOS target all live there.
- **`pubspec.yaml` + `pubspec.lock`** play the role of `Package.swift` +
  `Package.resolved` (or a Gradle version catalog + lockfile). `^9.1.1` means
  "up to the next major version", like SPM's `.upToNextMajor(from:)`.
- **Material is a package now.** Since Flutter 3.47, `package:flutter/material.dart`
  is deprecated in favor of `package:material_ui`. The core
  `package:flutter/widgets.dart` stays in the SDK, similar to how Compose splits
  `foundation` from `material3`.
- **`StatelessWidget.build()`** is SwiftUI's `body` or a `@Composable` function
  with no state. Widgets are cheap, immutable descriptions; the framework diffs them.
- **`const` constructors** create compile-time canonical instances, so Flutter can
  skip rebuilding those subtrees. The linter pushes `const` everywhere for this reason.
- **Dart 3.14 constructors** can be written `const new({super.key});` instead of
  repeating the class name, much like Swift's `init`.
- **No CocoaPods.** Flutter now resolves iOS plugin code with Swift Package
  Manager: it generates a local `FlutterGeneratedPluginSwiftPackage` that the
  Runner target links, much like adding a local package in Xcode. The project
  pins this with `flutter: config: enable-swift-package-manager: true` in
  `pubspec.yaml`. `flutter doctor` still checks for CocoaPods on every Mac,
  so its warning there is harmless for this project.
- **`analysis_options.yaml`** is like a SwiftLint or detekt config, but the
  analyzer ships with the SDK, so lints show inline in the IDE and fail CI via
  `flutter analyze`.
- **`BlocObserver`** is a global hook on every Bloc/Cubit state change, like a
  Redux middleware. It will feed the in-app debug log in Milestone 4.

Regulated-app note: the Flutter SDK version (in CI) and the lint rule set (in
`analysis_options.yaml`) are both pinned. A regulated team would record every
third-party component and version as SOUP under IEC 62304.

## Milestone 2: Domain and fake data (2026-11-11)

Built: a sealed `HeartRateSample` (measured or unavailable), the Heart Rate
Measurement parser (sealed success/failure result), the `HeartRateSource`
interface with a simulated `FakeHeartRateSource`, `LiveHeartRateCubit` with a
10-second stale timer, and the live screen (bpm, update time, sensor status,
Demo badge, "no data from strap" state). 83 tests.

Flutter vs native:

- **Sealed classes + `switch`** work like a Swift enum with associated values
  or a Kotlin sealed class: `switch (result) { HeartRateParseSuccess(:final
  sample) => ..., HeartRateParseFailure(:final error) => ... }` must cover every
  case, or it doesn't compile. `(:final sample)` destructures a field, like
  `case .success(let sample)`.
- **Primary constructors (Dart 3.13+)** declare fields in the class header:
  `class Point({required final int x, required final int y})`, close to a
  Kotlin `data class` or a Swift `struct` with a memberwise init. freezed
  supports them for single-case classes; unions still use `const factory`
  constructors, so `HeartRateSample` moved to that form once it became sealed.
- **Making illegal states unrepresentable**: `HeartRateSample` was first one
  class with a `hasUsableBpm` getter, so any code could read `bpm` and forget
  to check. As a sealed type, only `MeasuredHeartRateSample` has a `bpm`, so
  showing an untrustworthy value doesn't compile. Same idea as replacing a
  Swift struct + `isValid` flag with an enum. Shared fields (`timestamp`) stay
  readable on the base type without a `switch`. Same for skin contact: a
  measured sample's `SkinContact` has only `detected` and `notSupported`, so
  "no skin contact" can't sneak in, and no runtime assert is needed to stop
  it.
- **`PositiveInt`** replaced a debug-only `assert(bpm > 0)`. Dart has no
  refinement types, so the check still happens at runtime, but once, at the
  boundary, and it can't fail: the only way to get one is `PositiveInt.tryFrom`,
  which returns null (like Swift's `UInt(exactly:)`), and callers must handle
  that case. There's deliberately no throwing constructor. It's a `final class`
  rather than a zero-cost extension type, because an extension type can be
  forged with `0 as PositiveInt`; the cost is writing `bpm.value`.
  `@immutable` (from `package:meta`) lets the analyzer enforce what the
  hand-written `==`/`hashCode` assume.
- **freezed** generates `==`, `hashCode`, `toString` and `copyWith` into a
  `part` file (`*.freezed.dart`). It's code generation via `build_runner`, like
  Kotlin's KSP or Swift macros, but the output is a checked-in source file
  rather than compiler-internal. Lists get deep equality automatically.
- **Reading bytes safely**: `ByteData.getUint16` (like Swift's
  `loadUnaligned` or Kotlin's `ByteBuffer`) throws `RangeError` past the end,
  so the parser uses a tiny private `_ByteReader` whose `uint8()`/`uint16()`
  return null when bytes run out. Reading past the end can't happen, and the
  separate length checks disappeared. Indexing a `Uint8List` respects a
  view's offset; reaching for `packet.buffer` would not, a classic bug the
  tests cover.
- **Streams** are Dart's `AsyncSequence` / Kotlin `Flow`. A *broadcast* stream
  allows many listeners, like a `SharedFlow`.
- **Dependency injection without runtime lookups**: `RepositoryProvider` /
  `BlocProvider` + `context.read<T>()` work like SwiftUI's `@EnvironmentObject`,
  including crashing at runtime if nothing was provided. PulseLink instead
  builds its objects in `main()` (a composition root, like an `AppDelegate`
  building the object graph) and passes them through constructors;
  `BlocBuilder(bloc: cubit)` then never does a lookup. A missing dependency is
  a compile error.
- **Testing time**: `fake_async` plus `package:clock` make timers and "now"
  controllable, like Kotlin's `TestDispatcher` virtual time. One trap: a stream
  subscription's `cancel()` completes on the real event loop, which fake time
  never runs, so the cubit's `close()` is tested with real async.
- **Async gaps in teardown**: `close()` first stopped the source and only then
  unsubscribed, so a sample arriving during the `await` started a new stale
  timer that later emitted into the closed cubit (a `StateError` crash). Fix:
  unsubscribe first; `cancel()` detaches the listener immediately. Same lesson
  as cancelling Combine subscriptions or coroutine jobs before releasing
  resources. A regression test uses a deliberately slow-stopping source.
- **Widget tests** pump a widget tree headlessly and query it with finders,
  like ViewInspector or Compose's `onNodeWithText`. `MockCubit` + `whenListen`
  script the states a screen sees.

Regulated-app notes: the parser never throws and never guesses; a malformed
packet is a typed failure, not a wrong number. A well-formed packet with no
skin contact or bpm 0 becomes an "unavailable" sample with no bpm at all, and
the UI says why ("No skin contact", "Strap connected, no heart rate yet")
without medical-sounding wording. Unavailable is distinct from stale: the strap
is still sending, so the stale timer keeps resetting. Staleness is measured
from each sample's own timestamp, so a delayed sample can't masquerade as
current. A regulated app would add a plausibility range check (say 25-250 bpm)
and log every rejected packet; logging comes with the Milestone 4 debug screen.
App code has no assertions or other programmer-error crash points (`assert`,
`!`, `as`, throwing constructors, provider lookups); invalid states are ruled
out by types instead, and any unavoidable exception needs explicit sign-off
(see `CLAUDE.md`).

### Debug override tooling

A long-press on the title reveals two debug-only buttons, for real or fake
sources: one sets whether the strap can detect skin contact, the other cycles
the conditions that kind of strap can be in (Normal, No data (stale), No skin
contact, Zero bpm; no "No skin contact" for a strap that can't detect it).

- **No preprocessor, but the same result.** Dart has no `#if DEBUG`, but
  `kReleaseMode` / `kDebugMode` are compile-time constants, so the release
  compiler deletes `if (!kReleaseMode) { ... }` and anything only it uses.
  Unlike `#if`, the code must still compile in every mode. All debug wiring
  lives in that one branch of `main()`; screens only see a generic optional
  `Widget` and `VoidCallback`, so no debug class or label is referenced
  elsewhere. Verified by searching the compiled release code for the button's
  label.
- **Decorator over the data layer.** `DebugOverrideHeartRateSource` wraps any
  `HeartRateSource`, so the override works the same for BLE and demo data and
  the cubit and UI don't know it exists.
- **Hidden means Normal, by construction.** The button state is sealed
  (`hidden | shown(mode)`), and the source's mode is derived from it, so
  "hidden but still overriding" can't happen.
- **Stale is an absence, not a value.** The Stale override drops samples and
  lets the real 10-second timer fire, so it tests the actual code path.
- **Newer Dart syntax met along the way:** `?debugControls` in a list adds the
  element only if it's non-null (no `!` needed), and `required this._source`
  initializes a private field from a parameter callers still name `source`.
- Native shake detection was considered and rejected: `sensors_plus` would ship
  its native code in release builds (plugins are registered in every build),
  and the iOS Simulator's Shake menu doesn't produce accelerometer data.

Regulated-app note: debug-only fault injection is standard in device
development; regulated teams keep evidence it's absent from release builds,
which the release-binary check provides.

### Skin contact vs. Bluetooth wording

"Contact" was ambiguous: "Sensor contact" could read as "the app can reach the
sensor", and "Signal lost" with a Wi-Fi icon suggested Wi-Fi. Now "skin
contact" always means the strap touching skin (`SkinContact`,
`noSkinContact`), Bluetooth and data wording never mentions contact, and the
stale state says "No data from strap" with a sensor-off icon. It deliberately
doesn't claim "Bluetooth disconnected": until Milestone 4's connection state,
the app can't tell a dropped link from a strap that stopped sending. Making the
text longer exposed an overflow on narrow screens, so a test now renders every
state at 320 px wide (Flutter fails a test on any overflow). The test font
draws every glyph as a full-width square, roughly twice as wide as Roboto, so
this also stands in for very large accessibility text sizes.

While stale, the skin-contact chip is hidden too: it describes the last
reading, which is out of date. `Visibility(maintainSize: true)` keeps its space
so the readout doesn't jump, and `Visibility.of(context)` lets tests check it's
hidden. Testing trap found along the way: re-pumping the same widget tree with
a mocked cubit keeps the `BlocBuilder`'s first state, so a test that pumps
several states silently checks only the first. A `UniqueKey` per pump fixes it,
and the 320 px test then caught an overflow it had been missing.

### Two-part debug override

The single override button mixed a property of the strap (can it detect skin
contact?) with what's happening right now (normal, no data, no skin contact,
zero bpm), so it split into two buttons. The override is a sealed type,
`detectingStrap(condition)` or `nonDetectingStrap(condition)`, with a separate
condition enum for each, so "no skin contact on a strap that can't detect it"
can't be built. Same pattern as the app's other sealed types, applied to debug
tooling. A strap without skin-contact detection can still report bpm 0; it's
how such a strap shows it has no heart rate. The buttons start from what the
strap last reported, so revealing them changes nothing on screen.


### Plausible bpm range

`PositiveInt` became `Bpm`, which only holds 1 to 250. The parser accepted
any uint16, so a corrupt packet could put 65535 bpm on screen as a real
reading. Now a well-formed packet above 250 becomes an unavailable sample with
reason `implausibleBpm`, and the screen shows "--" with "Strap reading out of
range". Putting the range in the type rather than only in the parser means
no source (parser, fake or a future one) can build a measured sample with an
impossible value, the same way `PositiveInt` already ruled out 0. Adding the
new reason was a compile error at every switch that had to handle it, which
is the point of the no-catch-all rule. The ceiling is a judgment call: adults
top out around 220 bpm, so 250 leaves headroom while catching corrupt values.
The debug override gained an "Implausible bpm" condition so the new state can
be checked on a device.
Later renamed `BeatsPerMinute` for clarity, along with everything named after
it: the sample's `beatsPerMinute` field and the `zeroBeatsPerMinute` and
`implausibleBeatsPerMinute` reasons. On-screen text still says "bpm".

## Milestone 3: Real BLE on iOS (2026-11-13 to 2026-11-14)

Built: Bluetooth scanning and connecting on iOS, written by hand in Swift on
CoreBluetooth behind a Pigeon contract. A strap picker that also lists
straps already connected to the phone. Live bpm from a real strap, and its
battery level. A typed failure for every expected problem (Bluetooth off,
permission denied with an Open Settings button, strap unreachable, not a
heart-rate strap, strap disconnected), each explained on screen. SwiftLint
and detekt for the native code. Android answers every BLE call with
"unsupported" until Milestone 4, so it stays in demo mode. 323 Dart tests and
10 Swift tests.

Milestones were renumbered when this one closed: Android BLE is now
Milestone 4, the Apple Watch app 5, and reliability (reconnecting,
backgrounding, remembering the strap, the debug log) 6. The earlier entries
keep the numbers they had then, so where they mention Milestone 4's debug log
or connection state, that's now Milestone 6.

### Why native BLE through Pigeon, not a plugin

Three options were weighed:
- `flutter_blue_plus`, the plan's first choice. Its license charges for
  for-profit use, and it needs `permission_handler` as well for Android's
  runtime permissions.
- `universal_ble`, which is BSD-licensed.
- Native code on each platform, talking to Dart over platform channels.

The third option came from Punch Through's
[Cross-Platform Flutter BLE Architecture: The Case for a Disciplined Hybrid](https://punchthrough.com/flutter-ble-architecture/).
It argues for native Swift and Kotlin modules that own the BLE mechanics,
with Dart owning orchestration and product logic. Not all of its reasons fit
an app this size: Dart's event-loop latency doesn't matter for one packet a
second, and this app talks to one standard GATT service, not many device
types.

Native won, even though everything gets written twice (Swift now, Kotlin in
Milestone 4):

- **The hard parts of BLE live in the native APIs.** Connection timeouts,
  background limits, state restoration and Android's GATT quirks are what
  this project is meant to teach, and a plugin hides them. Background
  reconnects in Milestone 6 also work best when the app owns its
  `CBCentralManager`.
- **Less third-party code at runtime.** The app depends only on Flutter and
  the OS frameworks. Pigeon runs at build time, and the code it generates is
  checked in and reviewed like any other source.
- **Native code handles the mechanics; Dart makes the decisions.** Swift
  scans, connects and forwards each Heart Rate Measurement as raw bytes. Dart
  parses them, tracks staleness and decides what the user sees. So there's
  one tested parser for both platforms, and the native layer stays thin.
  This is the same split as a Swift app keeping CoreBluetooth in one service
  class behind a protocol.

**Why Pigeon rather than raw `MethodChannel` and `EventChannel`:** raw
channels carry untyped maps (`Map<Object?, Object?>`), so every message would
be decoded by hand three times, in Dart, Swift and Kotlin, and could drift
apart. Pigeon is the Flutter team's code generator. It reads one Dart
contract (`pigeons/ble_api.dart`) and generates matching Dart, Swift and
Kotlin, much like generating clients from an OpenAPI or protobuf schema:
- a sealed class becomes a Swift protocol and a Kotlin sealed class;
- an enum stays an enum;
- an `@async` method becomes Swift `async throws` and a Kotlin `suspend fun`;
- an `@EventChannelApi` method becomes a stream.

What Pigeon 30 taught along the way:
- **One event-channel class per contract,** so both streams (scan, strap
  events) share `BleEventApi`.
- **Generated fields can't be private.** The `keep_pigeon_imports_local` lint
  keeps the raw types inside `lib/data/`, which turns them into domain types
  such as `StrapBleIdentifier`, so nothing above the data layer sees a raw
  string id.
- **Two contracts in one app clash.** Each generates its own error class, so
  `app_settings_api.dart` sets `includeErrorClass: false` and reuses
  `ble_api.dart`'s.
- **Its Swift isn't ready for strict concurrency,** which is why every iOS
  build shows warnings and the app stays in Swift 5 mode (see the README's
  "iOS build warnings").
- **A message that fails to decode is dropped by Flutter's messenger.** That
  only happens if the Dart and native sides come from different versions of
  the contract, which `tool/pigeon.sh` and CI rule out.

The Open Settings button went the same way. It's a second small Pigeon
contract rather than `url_launcher`, so it adds no plugin.

### CoreBluetooth lessons

- **Creating a `CBCentralManager` shows the permission prompt,** so it's
  created on the first scan, not at launch.
- **Bluetooth's state arrives later,** in `centralManagerDidUpdateState`.
  Scanning before `.poweredOn` does nothing. `ScanAction` turns each state
  into scan, fail with a reason, or wait (`.unknown`, `.resetting`): a pure
  enum, unit-tested without hardware. `@unknown default` waits for the next
  state, since Apple may add cases.
- **Turning Bluetooth off stops a scan.** Turning it back on calls the same
  delegate method again, so the scan resumes by itself.
- **Scans filter by the Heart Rate Service (`0x180D`).** Background scans
  require a filter anyway.
- **A connected strap stops advertising.** If any app on the phone is
  connected to it, a scan never finds it. `retrieveConnectedPeripherals(
  withServices:)` lists those straps, and the picker marks them with a check.
  A strap also talks to one device at a time, which is why the picker's tips
  say to disconnect it from other phones, watches and gym machines.
- **Identifiers are per-phone UUIDs, not MAC addresses.** iOS hides the MAC;
  Android uses it. Dart treats the id as opaque (`StrapBleIdentifier`).
  Connecting needs a `CBPeripheral`, which
  `retrievePeripherals(withIdentifiers:)` recovers from a UUID seen before,
  so there's no second scan.
- **Names come from two places:** the advertised local name, which is
  current, or the name iOS cached from an earlier connection. The advertised
  one wins.
- **CoreBluetooth never gives up on a connection attempt,** so
  `StrapConnection` times out after 10 seconds and reports the strap as
  unreachable.
- **Connecting takes four asynchronous steps,** and each can fail with an
  error: connect, discover services (Heart Rate and Battery), discover the
  characteristic, and subscribe with `setNotifyValue(true)` until
  `didUpdateNotificationState` confirms. An error along the way means the
  strap is unreachable, and trying again may work. A device that answers but
  lacks the characteristic is "not a heart-rate strap". Telling the two apart
  matters, because only one is worth retrying.
- **Battery level (`0x2A19`) is read once, then followed with notifications
  if the strap sends them.** A strap without the Battery Service still
  connects, and battery errors never fail the connection.
- **An unexpected disconnect arrives in `didDisconnectPeripheral`.** The
  screen shows "Strap disconnected" straight away, instead of waiting 10
  seconds for the reading to go stale.
- **iOS ends the app when the user changes its Bluetooth permission.** So
  after Open Settings, allowing Bluetooth means a fresh launch that can scan.
  Apps can only open their own page in Settings, not the Bluetooth page.
- **BLE doesn't work in the Simulator,** where CoreBluetooth reports
  `.unsupported`. Swift tests (Swift Testing's `@Test` and `#expect`) cover
  the pure decisions; the rest needs a phone and a strap, so it's in
  `docs/test-plan.md`.

### Threads and Swift concurrency

- **Flutter accepts channel messages only on its platform thread,** the main
  thread on iOS. Creating the central manager with `queue: nil` puts
  CoreBluetooth's callbacks on the main queue too.
- **`@MainActor` turns that convention into a compile-time check.** Flutter's
  and CoreBluetooth's protocols have no actor isolation, so each entry point
  checks `Thread.isMainThread`, logs a fault and skips the call if it's ever
  false, and only then uses `MainActor.assumeIsolated`. That combination can
  never crash. Kotlin will do the same by posting to the main looper.
- **Complete concurrency checking is on,** so the compiler checks the
  hand-written Swift for data races now, ahead of Swift 6 mode.

### Dart side

- **`StrapDataSource` has three implementations:** demo, BLE, and a
  switchable source that owns whichever one is current. Picking a strap
  switches from demo data to the strap. The debug override wraps the
  switchable source, so it works on a real strap too.
- **`start()` returns a sealed result** (started, cancelled, or failed with a
  `StrapConnectionFailure`) and never throws for expected failures. A
  `PlatformException` is caught at the data-layer boundary, logged and turned
  into "Bluetooth isn't available".
- **The real channels are tested without a phone.**
  `TestDefaultBinaryMessengerBinding` answers Pigeon's channel names using
  Pigeon's own codecs, so the generated encoding and decoding run end to end
  in a unit test.
- **Testing traps:**
  - closing a `StreamController` that was never listened to never completes,
    so a test that awaits it hangs;
  - `ListTile` merges its children's semantics, so a screen-reader label
    test has to match the whole merged label.

### Native lints

The no-assertions rule now covers native code too. SwiftLint bans `!`,
`as!`, `try!` and `fatalError`, and detekt bans `!!`, `lateinit` and
`error()`. They run on every Xcode and Gradle build and in CI, and
`tool/check_native_lints.sh` plants a violation of each rule to prove it
reports. Gradle's wrapper is gitignored, so on a fresh checkout the lint
script generates it with `flutter build apk --config-only`.

Regulated-app notes: every expected failure is a typed value shown with
advice, never a crash or a silent blank. The app never shows a reading after
the strap drops. The connection timeout is explicit rather than left to the
OS. Raw bytes are parsed in exactly one place. Third-party code at runtime is
limited to Flutter itself. A regulated team would also:
- trace each failure state to a requirement;
- treat "connected to the wrong strap" as a hazard (the picker shows names,
  which two identical straps share);
- keep signed evidence of each manual test run on real hardware.

## Milestone 4: Real BLE on Android (2026-11-14 to 2026-11-15)

Built: Bluetooth scanning and connecting on Android, written by hand in
Kotlin behind the same Pigeon contract as iOS. Runtime permissions, a scan
filtered by the Heart Rate Service that stays under Android's scan limit, the
picker's list of straps already connected, connecting with one retry after
GATT error 133, live bpm, the battery level, and the same typed failures as
iOS. Android now passes the Milestone 3 checks on a real phone. 323 Dart
tests and 29 Kotlin tests.

The Dart needed no changes: apart from one doc comment, nothing in `lib/`
changed. Every platform difference stayed below the Pigeon contract, which is
the payoff of the split chosen in Milestone 3.

Streaming in the background was built and works, but is shelved until
Milestone 6 (see the end of this entry).

### Android BLE needs more hand-holding than CoreBluetooth

The Kotlin (`LeScan`, `LeConnection`) is laid out like the Swift
(`CentralScan`, `StrapConnection`), so the two can be read side by side. The
differences are where Android leaves work to the app:
- **One GATT operation at a time.** Starting a second operation before the
  first one's callback makes the call return false, or on some phones drops
  it silently. CoreBluetooth queues operations itself; Android doesn't, so
  `GattQueue` runs them one at a time, with a timeout on each so a lost
  callback can't stall it.
- **Notifications take two steps.** `setCharacteristicNotification` only
  tells Android to pass notifications on; the app must also write the Client
  Characteristic Configuration descriptor (`0x2902`) to tell the strap to
  send them. iOS's `setNotifyValue(true)` does both.
- **GATT error 133** is Android's catch-all for a failed connection, often
  from a busy Bluetooth stack, and a second try usually works. Android
  doesn't name it publicly. `ConnectionChange` retries once after 600 ms,
  within the same 10-second timeout as iOS. Android gives up by itself only
  after about 30 seconds.
- **Every connection must be closed.** `disconnect()` ends the link, but only
  `close()` frees Android's connection slot, of which there are only a few.
  Leaked slots stay taken until the app is killed, so every way a connection
  ends goes through one `closeGatt()`.
- **Android 13 changed the GATT API.** Reads, notifications and descriptor
  writes gained versions that pass the value directly. The old ones keep it
  on a shared object that the next notification overwrites. With a minimum of
  Android 12, the app handles both: on Android 12 the value is copied before
  leaving the callback's thread.
- **Device ids are MAC addresses,** where iOS hides them behind per-phone
  UUIDs. Dart treats both as an opaque `StrapBleIdentifier`.
  `getRemoteDevice` throws on a malformed address, so the address is checked
  with `checkBluetoothAddress` first.
- **Listing straps already connected is less reliable than on iOS.** Android
  lists connected devices, but only knows a device's services if it cached
  them from an earlier connection. iOS's
  `retrieveConnectedPeripherals(withServices:)` doesn't depend on a cache.

### Permissions and scanning

- **Requiring Android 12 (`minSdk = 31`) takes location out of the picture.**
  `BLUETOOTH_SCAN` with `neverForLocation`, and `BLUETOOTH_CONNECT`, are
  enough. Before Android 12, scanning needed location permission and location
  services switched on.
- **Android asks explicitly; iOS asks by itself.** The app calls
  `requestPermissions` on the activity, and the answer comes back to
  `MainActivity.onRequestPermissionsResult`. So Android's `ScanAction` has a
  case iOS's lacks: ask for permission. After the user refuses twice, Android
  refuses by itself without showing the dialog, so the picker explains, and
  Open Settings is the way back.
- **More than 5 scan starts in 30 seconds return nothing,** with no error,
  just a log line. Opening and closing the picker can get there quickly.
  `ScanThrottle` delays a start that would break the limit.
- **Coming back from Settings isn't announced.** The scan rechecks the
  permission in `onResume`. (iOS restarts the app instead.)

### Threads and Pigeon in Kotlin

- **Android's BLE callbacks arrive on background threads,** so each
  `ScanCallback` and `BluetoothGattCallback` posts to the main looper before
  touching state or calling Dart. Each callback is tagged with its scan or
  connection, so a late one from something already stopped is ignored.
- **Pigeon's `@async` becomes a `suspend fun`,** which Pigeon calls in a
  coroutine on the main dispatcher. `connect` suspends once, with
  `suspendCoroutine`, and only one function resumes it, like the Swift's
  checked continuation.
- **Pigeon names Kotlin enum cases by splitting camel case,** so
  `notAHeartRateStrap` became `NOT_AHEART_RATE_STRAP`.
- **The Flutter engine lives as long as the activity.**
  `cleanUpFlutterEngine` stops the scan and closes the connection, since Dart
  can no longer do it.

### Testing and tooling

- **The decisions are pure Kotlin, tested on the computer.** `ScanAction`,
  `ScanThrottle`, `ConnectAction`, `ConnectionChange`, `GattQueue` and
  `BatteryValue` make no Android calls, so JUnit runs them on the JVM like
  `flutter test`, with no phone. Android's framework classes can't be
  created in these tests, but their constants (such as
  `BluetoothProfile.STATE_CONNECTED`) are compiled in and work.
  `tool/lint_native.sh` runs the tests, and fails if none ran. The
  connection itself is checked on a phone, in `docs/test-plan.md`.
- **Gradle's build caches can go stale.** Moving the launch screen out of
  `drawable-v21` broke the build until the cached resources under
  `build/app/intermediates` were deleted. The no-tests guard caught it.
- **Android lint needs a JDK.** Use Android Studio's, with `JAVA_HOME`
  pointing at its `jbr` folder.
- **Android lint earns its keep.** It caught that notification permission
  exists only from Android 13, which would have meant asking for a permission
  that's refused straight away on Android 12. It also suggested `core-ktx`,
  which the app only gets four levels deep inside Flutter's own dependencies,
  so the app doesn't use it.

### Background streaming, built and shelved

Android may freeze or end an app in the background within minutes. The
standard fix is a foreground service of type `connectedDevice`, with an
ongoing notification. `feat/Milestone4_ForegroundService` adds one that only
keeps the app alive while a strap is connected, plus a one-time request for
notification permission on Android 13 and later. It works on a real phone.

It's shelved, unmerged, until Milestone 6, so iOS (which needs the
`bluetooth-central` background mode) and Android gain background streaming
together. One lesson is worth keeping: Android crashes an app whose
foreground service is stopped before it calls `startForeground`, and a strap
dropping just after connecting would do exactly that. `KeepAliveState` holds
such a stop until the service is in the foreground.

Regulated-app notes: Android adds failure modes iOS doesn't have (error 133,
scan throttling, leaked connection slots), and each is handled in code rather
than left to the OS: a bounded retry, a throttle and a single close path. The
same contract and Dart logic run on both platforms, so one parser and one set
of failure states serve both. A regulated team would also:
- test across Android makers and versions, since Bluetooth stacks differ
  (error 133 is far more common on some phones);
- record which phones and Android versions each release was checked on.

## Milestone 5: Apple Watch app (2026-11-14 to 2026-11-15)

Built: a native SwiftUI watchOS app inside the iOS project, fed by the phone
over WatchConnectivity. The watch shows the live bpm with the time it was
measured, dims it with "No data from strap" once it's 10 seconds old, shows
why there's no heart rate (an unavailable reading or a connection failure),
tags demo data, says when the iPhone isn't reachable, and shows the latest
state as soon as it opens. It never connects to the strap itself. Checked on
paired simulators and on an iPhone 17 Pro Max with an Apple Watch Series 9.
363 Dart tests, 69 Swift tests (44 for the iPhone app, 25 for the watch) and
29 Kotlin tests.

`docs/architecture.md` has diagrams of the phone app, the watch app and
every message between them.

### The phone-watch bridge

- **Flutter can't build watchOS apps,** so the watch app is plain SwiftUI,
  and the phone's side of WatchConnectivity is Swift too. Dart only hands a
  snapshot to Swift through a second Pigeon contract, `pigeons/watch_api.dart`,
  with `@async` calls like BLE's. The contract has no Kotlin side, and
  `main()` starts the sync on iOS only. Hand-written over Pigeon, as planned,
  rather than the `watch_connectivity` package.
- **Pigeon's sealed classes become open protocols in Swift,** so a Swift
  `switch` over them needs a `default:`. That one place disables the
  no-catch-all lint, with a comment saying why; everything past it is the
  app's own closed enums.
- **A second contract in one app needs Pigeon options:** a distinct Swift
  class-name component, so its generated helpers don't clash with BLE's, and
  no second error class.
- **One snapshot, four shapes.** The Dart domain type, the Pigeon message,
  the Swift `HeartRateSnapshot`, and a dictionary on the wire, which is what
  WatchConnectivity carries. The dictionary is versioned and has a `kind`, so
  the watch can reject anything it doesn't understand, and watch-to-phone
  commands can come later. Its code lives in `ios/Shared`, compiled into both
  apps, so it's written once. Files go there only when both apps use them.
- **Two ways to send, used together.** `sendMessage` reaches the watch app
  only while it's open and in range, so live data that can't be delivered is
  dropped, never queued. `updateApplicationContext` keeps only the newest
  value and delivers it whenever the system likes, including before the
  watch app's next launch. The phone sends every change both ways, and the
  watch keeps whichever has the newest `sentAt`, since they can arrive in
  either order.
- **Dart only sends on a change,** so a steady state, such as Bluetooth off,
  would never reach a watch app installed or opened later. The phone keeps
  the latest snapshot and sends it again when activation finishes, when the
  watch app is installed, and when it becomes reachable.
- **Staleness is never sent.** The watch works it out from the reading's own
  timestamp, every second, so it's right even when the link drops and
  nothing arrives to say so.

### Threads and Swift concurrency

- **WatchConnectivity calls its delegate on a background queue,** unlike
  CoreBluetooth with `queue: nil`. So each callback copies what it needs
  into `Sendable` values and then hops with `Task { @MainActor in … }`.
- **`WCSession` isn't `Sendable`,** so the session class looks up
  `WCSession.default` when it needs it rather than storing it, and its
  initializer is `nonisolated` so non-isolated code can create it.
- **On the watch, `@Observable` replaces `ObservableObject`.** SwiftUI
  redraws when a property it read changes, with no `@Published`, much like
  a Cubit's state stream driving a `BlocBuilder`.

### Flutter and a watch target

- **Flutter looks for a companion watch app** through a shared scheme whose
  build settings include `WKCompanionAppBundleIdentifier`. It then leaves
  out `-sdk`, so `flutter run` on a simulator needs a device id
  (`-d <id>`).
- **The watch target needs `SUPPORTED_PLATFORMS`.** Flutter's project-level
  Release and Profile settings allow only `iphoneos`.
- **The xcodeproj gem, used to edit the project from scripts,** rewrites a
  Swift package reference comment and adds a stray `Foundation.framework`
  from a watchOS SDK path. Both need undoing after every run.
- **SwiftUI previews ship in release builds** unless they're inside
  `#if DEBUG`, and the iPhone app's Debug configuration didn't define
  `DEBUG` at all. Now both apps define it in Debug only, a lint reports any
  preview outside `#if DEBUG`, and the pre-merge checks look for preview
  code in the release binaries.

### Testing

- **Two Swift test targets on two simulators:** `RunnerTests` on an iPhone
  and `PulseLinkWatchTests` on a watch. `tool/test_swift.sh` reads the
  counts from the result bundles, since xcodebuild's output interleaves.
  It turns off diagnostics collection, which otherwise spends up to 10
  minutes after a failure.
- **What WatchConnectivity decides is tested without it.** The phone's
  session state is a five-case enum, and what to do with each send is a pure
  function of it. The watch's screen content is a pure function of the
  snapshot, reachability and the time.
- **Running on paired simulators found a bug the tests couldn't:** the sync
  sent its first snapshot before `runApp`, through a platform channel that
  didn't exist yet. Unit tests use fakes and never run `main()`.
  `WidgetsFlutterBinding.ensureInitialized()` now comes first.
- **Running on a real watch found one simulators can't:** "iPhone not
  reachable" flashed each time the wrist was raised. WatchConnectivity
  reports the iPhone unreachable for a moment while the app wakes. The
  watch now records when the iPhone became unreachable, and shows the
  banner only after 5 seconds of it.
- **Still open:** installing a new build of the iPhone app from Xcode can
  remove the watch app. It's tabled, and noted in `docs/test-plan.md`.

Regulated-app notes: the device that shows a reading judges whether it's
current, from when it was measured, so a dead link can't leave an old bpm
looking live. A timestamp ahead of the watch's clock counts as just
measured, so clock skew can't keep a reading fresh for longer. Demo data is
never shown as a strap's. Every message is checked before it's shown, and a
bad one is ignored, not half-shown. The banner's grace period trades
5 seconds of warning for no false alarms. A regulated team would also:
- write down the maximum delay between the strap and the watch, and test
  it;
- treat clock skew between phone and watch as a hazard with a stated bound;
- decide, with a clinician, how long "not reachable" may go unannounced.

## Milestone 6: Hardening and Enhancements (in progress)

Milestones were renumbered while this one was under way. The work after
Milestone 5 hardened what was there rather than adding the planned
reliability work, so Milestone 6 became Hardening and Enhancements, and
reliability (reconnecting, backgrounding, remembering the strap, the debug
log) moved to Milestone 7, a nice-to-have. Polish and portfolio is now
Milestone 8, and Sessions and history 9. The earlier entries keep the
numbers they had then, so where they mention Milestone 6, that's now
Milestone 7.
