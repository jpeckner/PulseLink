# PulseLink

Before working on this project, read and follow the "Instructions for Claude"
section of
[`BLE Heart-Rate Monitor Flutter + Apple Watch Build Plan.md`](<BLE Heart-Rate Monitor Flutter + Apple Watch Build Plan.md>).
It's the source of truth for how to work here. The rules below are repeated
from it because they apply to every change; keep the two in sync.

## No assertions

Avoid assertions as much as possible. Instead, build compile-time safe
components that can't fail at runtime:

- Make invalid states unrepresentable: sealed classes, dedicated enums and
  value types (such as `BeatsPerMinute`).
- Untrusted input (BLE packets, platform-channel messages, stored data) returns
  a typed result or `null` rather than failing.
- Switch on closed types without a catch-all. Model a fixed set of cases as an
  enum or sealed class (not an `int`, a `String` or a plain abstract class),
  and when switching on it, list every case: no `default`, `_`, untyped
  variable or other catch-all. Then adding a case is a compile error at every
  switch that must handle it, as in Swift. The `no_catch_all_cases` lint
  (`tool/pulselink_lints`) enforces this; where a catch-all is truly needed,
  ignore the lint with a comment saying why. For the same reason, don't test a
  closed type for one case with `if (x case ...)`, `is` or `==`: those
  silently skip new cases, so use a switch, with an explicit do-nothing case
  where one applies. The `use_switch_on_closed_types` lint enforces this; a
  null check such as `if (x case final y?)` is still fine.

This covers anything in app code that fails at runtime because of a programmer
error: `assert`, freezed `@Assert`, the `!` null-assertion operator, unchecked
`as` casts, `late` fields that could be read before they're set, and functions
or constructors that throw on invalid arguments (`ArgumentError`, `StateError`
and the like). That includes SDK calls that throw on an empty collection or
bad input, where Swift returns an optional: use `firstOrNull`, `tryParse` and
the like instead of `.first` or `int.parse`. Test code is exempt: `expect`,
`fail` and casts in tests are fine. The `no_assertions` lint
(`tool/pulselink_lints`) enforces this outside tests.

In the rare case where there's no alternative to an assertion, stop before
writing it. Explain the case, the alternatives considered and why each doesn't
work, and wait for explicit sign-off before proceeding any further. Once
approved, leave a short comment at that line explaining why it's needed, and
ignore the lint there.

Native code (Swift in `ios/`, Kotlin in `android/`) follows the same rule.
`tool/lint_native.sh` enforces it with SwiftLint (`.swiftlint.yml`) and
detekt (`android/config/detekt.yml`) on app code, and
`tool/check_native_lints.sh` proves each rule reports. The Runner and
PulseLinkWatch targets' SwiftLint build phases also run the Swift half on
every Xcode build, so findings show inline as errors, and every Android
build (Android Studio's Run, `flutter run`, `flutter build apk`) runs the
Kotlin half, so findings fail the build. Where a catch-all is truly needed,
disable the rule on that line with a comment saying why.

- Swift: no `!` force unwraps, `as!` casts, implicitly unwrapped optionals
  (`Type!`) or `try!`, and no `fatalError`, `precondition` or `assert`. Use
  `if let`, `guard let`, `as?` and `try?` or `do`/`catch`. Switch on the
  app's own enums without `default`. The `@unknown default` Swift requires
  for Apple's enums is fine, with a comment saying what it does and why.
- Kotlin: no `!!`, unchecked `as` casts or `lateinit`, and no `error()`,
  `require` or `check`. Use `?.`, `?:`, `as?` and `firstOrNull()`. Write
  `when` on sealed classes and enums without `else`.

Pigeon's generated `*.pigeon.swift` and `*.pigeon.kt` files are exempt.

## Swift protocol conformances

Declare a protocol conformance in its own extension whenever it adds
anything (methods, properties, initializers or subscripts), such as
`extension CentralScan: CBCentralManagerDelegate { ... }`. Then each
protocol's members sit together, apart from the type's own. A conformance
that adds nothing, such as `Equatable` synthesized for an enum, can stay
on the type's declaration. No lint checks this, so reviews do.

## SwiftUI previews

Preview code must never ship in a release build. Put every `#Preview`,
`PreviewProvider` and `PreviewModifier`, and the sample data and helpers
only previews use, inside `#if DEBUG` ... `#endif`, usually one block at the
end of the file. Only the Debug build configuration defines `DEBUG`, in the
Runner and PulseLinkWatch targets alike. `tool/check_swift_previews.py`
(run by `tool/lint_native.sh` and every Xcode build) reports a preview
outside `#if DEBUG`, and the pre-merge checks look for preview code in the
release binaries. Nothing marks a helper as preview-only, so reviews check
those.

## Calling Flutter from native code

Flutter only accepts calls from the platform's main thread: the main thread
on iOS, and the main (UI) thread on Android. That covers platform-channel
messages, Pigeon event sinks and Flutter API calls. Native code must never
send to Dart from any other thread.

- Swift: a type that holds Flutter channel state or sends to Dart is
  `@MainActor`. Where Flutter or a system framework calls in without actor
  isolation, check `isOnMainThread()` first. If that's false, skip the call,
  since the check has already logged a fault. Then use
  `MainActor.assumeIsolated`. Create CoreBluetooth managers with
  `queue: nil`, so their delegate methods run on the main queue.
- Kotlin: system callbacks such as `BluetoothGattCallback` and
  `ScanCallback` arrive on background threads. Post to the main looper, for
  example with `Handler(Looper.getMainLooper())`, before calling a Pigeon
  sink or channel.

No lint can tell which thread code runs on, so reviews check this.

## Error handling

Handle errors on purpose. Dart has no checked exceptions and no lint can tell
what throws, so this rule and the tests are the check.

- Expected failures (Bluetooth off, permission denied, strap out of range, a
  failed write) are outcomes, not exceptions. Data-layer implementations catch
  what packages and platform channels throw and return a typed result, so
  callers must handle every case. The `no_ignored_results` lint flags a typed
  result that's thrown away; to discard one on purpose, write
  `final _ = ...;` with a comment saying why.
- Cleanup in `close()`, `dispose()` and the like goes in `try`/`finally` so it
  always finishes, and the error still reaches the caller.
- Catch specific types (`on SomeException`) and never swallow an error
  silently. When an exception is left uncaught on purpose, add a short comment
  saying why and what handles it.
- Every cleanup path gets a test with a dependency that fails.

Before committing changes to `lib/` that add async calls, cleanup code, catch
blocks or data-layer implementations, run the `error-handling-review` project
skill (`.claude/skills/error-handling-review/`) and resolve its findings.
