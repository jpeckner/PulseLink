# Where Swift is safer than Dart

Swift's compiler rejects many mistakes that Dart lets through to runtime.
This list, worked out on 2026-11-13 while asking how close lints and tools
could bring Dart to Swift, covers each gap and how PulseLink closes it. Most
of it landed on `refactor/Milestone2_SwiftParity` and `chore/SwiftParity`,
with `keep_pigeon_imports_local` added in Milestone 3.

The rules themselves are in `CLAUDE.md` ("No assertions", "Error
handling"), and the README lists every lint. This page is the reasoning
behind them. Native code (Swift and Kotlin) follows the same rules, enforced
by SwiftLint and detekt; see `CLAUDE.md`.

## Summary

| Gap | What Swift does | PulseLink's remedy | Status |
| --- | --- | --- | --- |
| [Catch-all switches](#1-catch-all-switches) | Every case, no silent `default` on your own enums | Dart 3 exhaustiveness, `no_catch_all_cases`, `use_switch_on_closed_types` | Closed |
| [Force unwraps and casts](#2-force-unwraps-casts-and-assertions) | `!` and `as!` stand out, and are easy to ban | Sound null safety, `no_assertions` | Closed |
| [SDK calls that throw](#3-sdk-calls-that-throw-on-bad-input) | `.first`, `Int("x")` return optionals | `no_assertions` flags `.first`, `int.parse` and the like | Closed |
| [`dynamic`](#4-dynamic) | No implicit `Any` | Strict language modes, `avoid_dynamic_calls`, `no_dynamic` | Closed |
| [Ignored results](#5-ignored-results) | Warns on any unused result | `no_ignored_results`, for enum and sealed types | Mostly closed |
| [`let` by default](#6-immutable-bindings) | `let` unless you write `var` | `prefer_final_*`, `parameter_assignments`, freezed | Closed |
| [Covariant generics](#7-covariant-generics) | Generics are invariant | `unsafe_variance` | Closed |
| [Unclosed resources](#8-unclosed-resources) | ARC frees what you drop | `close_sinks`, try/finally rule, failure tests | Closed |
| [Smaller compiler checks](#9-smaller-compiler-checks) | `override`, braces, dead-code warnings | `annotate_overrides`, braces lints, `find_unused_code` and more | Closed |
| [Access control](#10-access-control-on-generated-code) | `private`/`internal` on any declaration | `keep_pigeon_imports_local` | Closed for Pigeon |
| [Checked errors](#11-checked-errors) | `throws` and `try` in signatures | Typed results, error-handling rule and review skill, catch lints | Partly: by convention |
| [Integer overflow](#12-integer-overflow) | Crashes on overflow | Range-checked value types at the edges | Partly: no tool |
| [Data races](#13-data-races) | `Sendable` and actor checks | Isolates; `isClosed` checks; main-thread rule for native code | Partly: by convention |
| [Value semantics](#14-value-semantics) | Arrays and structs are copied | freezed models with read-only collections | Partly: by convention |
| [Open classes](#15-classes-open-by-default) | Subclassing outside the module needs `open` | Not adopted; `final class` on value types | Accepted gap |

## Closed by tooling

### 1. Catch-all switches

**Swift:** a switch must cover every case, and adding an enum case breaks
every switch that doesn't handle it, as long as there's no `default`.

**Dart:** Dart 3 checks exhaustiveness on enums and sealed classes, but a
`default` or `_` case silently absorbs a new case, and an `if (x case ...)`,
`is` or `==` test for one case skips the others without a word.

**Remedy:** fixed sets of cases are modelled as enums or sealed classes,
never `int` or `String`. The `no_catch_all_cases` lint bans `default`, `_`
and untyped-variable catch-alls when switching on an enum, `bool`, sealed type
or record of them. `use_switch_on_closed_types` bans picking out one case
with `if case`, `is` or `==`. A switch with an explicit do-nothing case is
used instead. The `==` check was added after the 2026-11-13 review, and found
one enum comparison to fix, in a test helper.

### 2. Force unwraps, casts and assertions

**Swift:** `!`, `as!`, `try!`, implicitly unwrapped optionals and
`fatalError` are explicit and easy to find, and SwiftLint can ban them.

**Dart:** sound null safety is as strong as Swift's optionals, but `!`,
unchecked `as`, `late` fields read before they're set, `assert` and thrown
`Error`s all fail at runtime, and `late` hides the risk the way `Type!` does.

**Remedy:** the "No assertions" rule, enforced by the `no_assertions` lint
outside tests: no `!`, unchecked `as`, `late` without an initializer,
`assert`, freezed `@Assert`, or thrown `Error`. Invalid states are made
unrepresentable with sealed classes and value types, and untrusted input
returns a typed result or `null`. `use_late_for_private_fields_and_variables`,
which `very_good_analysis` turns on, is turned off, since it pushes toward
`late`. A truly needed exception needs sign-off and a comment.

### 3. SDK calls that throw on bad input

**Swift:** `array.first`, `Int("x")` and `Double("x")` return optionals.

**Dart:** `.first`, `.last`, `.single`, `.reduce` and `.elementAt` throw a
`StateError` on an empty collection, and `int.parse` and `DateTime.parse`
throw on bad text.

**Remedy:** `no_assertions` also flags these, pointing to `firstOrNull`,
`tryParse` and the like.

### 4. `dynamic`

**Swift:** no implicit `Any`; using an `Any` needs a cast first.

**Dart:** `dynamic` turns off type checking: any member can be called on it,
and mistakes surface at runtime.

**Remedy:** `very_good_analysis` turns on the `strict-casts`,
`strict-inference` and `strict-raw-types` language modes, which catch
implicit `dynamic`, and `avoid_dynamic_calls`. The `no_dynamic` lint flags
every written `dynamic`, including in type arguments such as
`Map<String, dynamic>`, which the built-in `avoid_annotating_with_dynamic`
misses. `Object?` is used instead, so every use needs a type check, as with
Swift's `Any`.

### 5. Ignored results

**Swift:** warns whenever a function's result is unused, unless the function
is marked `@discardableResult`.

**Dart:** warns only when a function is marked `@useResult`, so calling
`start()` and dropping its typed result would silently lose "Bluetooth is
off".

**Remedy:** the `no_ignored_results` lint flags a thrown-away value of an
enum or sealed type, including the value an `await` produces. Discarding one
on purpose is written `final _ = ...;`, with a comment. Results of other types
aren't covered, which is why this is "mostly closed": the typed results that
matter here are all enums or sealed classes.

### 6. Immutable bindings

**Swift:** `let` by default; the compiler suggests `let` for a `var` that
never changes.

**Dart:** variables are mutable unless marked `final`.

**Remedy:** `prefer_final_locals`, `prefer_final_fields`,
`prefer_final_in_for_each` and `parameter_assignments`, from
`very_good_analysis`. Models and states are freezed classes, which are
immutable.

### 7. Covariant generics

**Swift:** generic types are invariant, so an `[Int]` can't be passed where
an `[Any]` is mutated.

**Dart:** generics are covariant, so a `List<int>` can be passed as a
`List<num>`, and adding `1.5` to it then fails at runtime.

**Remedy:** `unsafe_variance` flags class designs that expose the hole.

### 8. Unclosed resources

**Swift:** ARC frees an object as soon as nothing refers to it.

**Dart:** a `StreamController`, subscription or timer that's never closed
keeps running and leaks.

**Remedy:** `close_sinks`, which `very_good_analysis` turns off for its false
positives and PulseLink turns on. The "Error handling" rule puts cleanup in
`try`/`finally`, and every cleanup path has a test with a dependency that
fails.

### 9. Smaller compiler checks

Swift builds these in; Dart needs lints for them:
- **`override` keyword:** `annotate_overrides`.
- **Braces on every `if` and loop body:**
  `curly_braces_in_flow_control_structures` and
  `always_put_control_body_on_new_line`.
- **Dead-code warnings and Periphery:** analyzer warnings for private code,
  `unreachable_from_main`, and the pre-merge skill's `find_unused_code` for
  public declarations.
- **Value types with honest equality and return types:**
  `avoid_implementing_value_types` and `prefer_void_to_null`.

### 10. Access control on generated code

**Swift:** any declaration can be `private`, `fileprivate` or `internal`.

**Dart:** privacy is per library, with a leading `_`, and Pigeon can't make
its generated fields private, so every field is public and mutable, such as
the raw `int` in `BleBatteryLevel.percent`.

**Remedy:** the `keep_pigeon_imports_local` lint keeps Pigeon's types in the
folder that holds them, where the data source turns them into domain types
such as `BatteryLevel`. Nothing else in the app sees a raw Pigeon type.

## Partly closed, by convention

### 11. Checked errors

**Swift:** `throws` in a signature, and `try` at every call that can throw,
so the compiler knows what can fail.

**Dart:** nothing says whether a function throws, and any call can throw
anything. No lint can tell what throws.

**Remedy:** the "Error handling" rule and its review:
- expected failures (Bluetooth off, permission denied, strap out of range)
  are typed results at the data layer, not exceptions, so callers must
  handle every case, and `no_ignored_results` stops them being dropped;
- `avoid_catches_without_on_clauses` makes catches name a type, and the rule
  bans swallowing an error;
- `unawaited_futures` and `discarded_futures` catch a forgotten `await`;
- the `error-handling-review` skill checks new async code, cleanup and catch
  blocks before a commit;
- every cleanup path has a failure test.

### 12. Integer overflow

**Swift:** arithmetic that overflows crashes, rather than giving a wrong
number.

**Dart:** integers silently wrap around on 64-bit platforms, and no lint
can see it.

**Remedy:** numbers from outside are range-checked where they enter, as
value types with a `tryFrom` that returns null: `BeatsPerMinute` (1 to 250)
and `BatteryLevel` (0 to 100). The Heart Rate Measurement parser reads only
8- and 16-bit values, each through a reader that checks the packet's length
first, so it can neither overflow nor read past the end. So no out-of-range
value reaches the screen as a reading.

### 13. Data races

**Swift:** `Sendable` and actors let the compiler check data races, and
`@MainActor` checks what runs on the main thread.

**Dart:** isolates share no memory, so there are no data races between
threads. The remaining risk is state changing across an `await`.

**Remedy:** cubits check `isClosed` after an `await` before emitting, and
`use_build_context_synchronously` stops a widget using its context after an
`await`. Native code calls Flutter only on the main thread: `@MainActor`
types in Swift, and posting to the main looper in Kotlin (see "Calling
Flutter from native code" in `CLAUDE.md`). No lint checks threads, so reviews
do.

### 14. Value semantics

**Swift:** arrays, dictionaries and structs are values: passing one copies
it (cheaply, on write), so no one else can change yours.

**Dart:** lists and maps are shared references, and anyone holding one can
change it.

**Remedy:** models and states are freezed classes, whose collections are
read-only, and value types such as `BeatsPerMinute` are immutable. A lint
banning mutable `List`s in public APIs was considered and not adopted: in a
single app whose models are already freezed, it would add little.

## Accepted gap

### 15. Classes open by default

**Swift:** a class can only be subclassed outside its module if it's marked
`open`, and `final` stops subclassing entirely.

**Dart:** any class can be extended or implemented by any code unless it's
marked `final`, `sealed`, `base` or `interface`.

**Decision:** not enforced. A lint requiring a modifier on every class would
mostly touch widgets, in an app no other code extends. Value types are
declared `final class` (such as `BeatsPerMinute`), and closed sets of cases
are `sealed`.

## What no tool closes

Checked errors, integer overflow, data-race checking and copy-on-write
values are language features with no Dart equivalent. The conventions above
are the defence, along with reviews and tests. A paid tool, DCM (Dart Code
Metrics), has ready-made rules for some of these, such as ignored results
and throwing collection methods; the project's own lint plugin covers the
ones that matter here instead.
