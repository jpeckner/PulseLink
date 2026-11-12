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
Demo badge, signal-lost state). 77 tests.

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
  readable on the base type without a `switch`. Same for contact: a measured
  sample's `MeasuredContact` has only `detected` and `notReported`, so "no
  contact" can't sneak in, and no runtime assert is needed to stop it.
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
- **`ByteData`** reads little-endian integers from a `Uint8List`, like
  `Data.withUnsafeBytes` / `loadUnaligned` in Swift or `ByteBuffer.order(
  LITTLE_ENDIAN)` in Kotlin. `ByteData.sublistView` respects a view's offset;
  `packet.buffer` would not, a classic bug the tests cover.
- **Streams** are Dart's `AsyncSequence` / Kotlin `Flow`. A *broadcast* stream
  allows many listeners, like a `SharedFlow`.
- **`RepositoryProvider`** puts a dependency in the widget tree, like SwiftUI's
  `@Environment` or a Compose `CompositionLocal`; `context.read<T>()` looks it up.
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
the UI says why ("No sensor contact", "No reading from sensor") without
medical-sounding wording. Unavailable is distinct from stale: the strap is
still sending, so the stale timer keeps resetting. Staleness is measured from each
sample's own timestamp, so a delayed sample can't masquerade as current. A
regulated app would add a plausibility range check (say 25-250 bpm) and log
every rejected packet; logging comes with the Milestone 4 debug screen.
