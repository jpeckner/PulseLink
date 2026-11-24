---
name: error-handling-review
description: Reviews PulseLink changes against the project's error-handling rule (typed results at the data layer, try/finally cleanup, specific catches, commented non-catches, failure tests). Use when asked to review error handling, and before committing changes to lib/ that add async calls, cleanup code (close, dispose, stop, cancel), catch blocks, stream subscriptions, or data-layer implementations.
---

# Error-handling review

Dart has no checked exceptions and no lint can tell what throws, so this
review and the failure tests are the check. The rule being enforced is the
"Error handling" section of `CLAUDE.md` (kept in sync with the build plan).
Read it first.

This is a judgment-based review. It complements the tests; it doesn't replace
them.

## 1. Pick the scope

- If arguments name files, a directory or a commit range, review that.
- Otherwise review everything on this branch that isn't on `develop` (where
  feature branches start), plus uncommitted changes:
  `git diff develop...HEAD -- lib test` and `git diff HEAD -- lib test`.
- Skip generated files (`*.freezed.dart`, `*.g.dart`, `*.pigeon.*`), but
  review the Pigeon contracts in `pigeons/` and the hand-written native code
  behind them.

Read each changed file in full, not just the diff hunks: a cleanup bug is
usually about what runs after the changed line.

## 2. Check each item

For every finding, work out a concrete failure: which call throws, what's
skipped or leaked as a result, and what the user would see. Drop anything you
can't turn into a concrete failure.

**Cleanup paths** (`close()`, `dispose()`, `stop()`, anything releasing a
subscription, timer, controller or platform resource)

- Every step that must happen (above all `super.close()` / `super.dispose()`)
  is in a `finally`, or nothing before it can throw.
- Steps that can't throw (`Timer.cancel()`) come before ones that can, when
  skipping them would leave something able to fire later.
- A Future created now and awaited later has an error handler attached at once
  (`Future.wait`, or `await` straight away). Otherwise its failure is reported
  as unhandled while the code awaits something else.
- A call that could throw before returning a Future is wrapped in
  `Future.sync`, so it fails the same way as an async failure.
- The original error still reaches the caller: no `catch` that only exists to
  make cleanup finish.

**Data-layer boundary** (`lib/data/` implementations calling packages such as
Pigeon platform channels or `drift`)

- Expected failures (Bluetooth off, permission denied, out of range, a failed
  write) are caught as specific types and returned as a typed sealed result,
  not thrown through the interface.
- Every case of that result is handled by callers with an exhaustive `switch`
  that lists each case. A catch-all (`default`, `_`) is flagged by the
  `no_catch_all_cases` lint; an `if (x case ...)`, `is` or `==` check that
  handles one case and silently skips the rest by the
  `use_switch_on_closed_types` lint; and a result thrown away entirely by the
  `no_ignored_results` lint. Check that any `// ignore:` of them, and any
  `final _ = ...;` discard, has a reason that holds.

**Catch blocks**

- `on SomeException` with a specific type. No bare `catch`, no catching
  `Error` (those are programmer errors; see the no-assertions rule).
- Nothing swallowed silently: the error is turned into a result, reported,
  or rethrown with `rethrow` (not `throw e`, which loses the stack trace).
- An error that shouldn't happen is reported through the injected
  `TrackerService`, as non-fatal, not with `developer.log` or `print`, and
  its test checks the report with `RecordingTrackerService`. Expected
  failures and normal events aren't reported.
- A class that reports errors takes `TrackerService` as a required
  constructor argument with no default; only `main()` creates one.

**Deliberately uncaught exceptions**

- Each has a short comment at that call saying why it's left uncaught and what
  handles it.

**Futures and streams**

- `unawaited(...)` and fire-and-forget calls either can't fail or have a
  comment saying what happens if they do.
- `listen(...)` on a stream that can emit errors has an `onError`, or a
  comment saying where those errors go.
- Every subscription and timer is cancelled on every exit path.

**Tests**

- Every new or changed cleanup path has a test where a dependency fails.
  `test/helpers/failing_strap_data_source.dart` covers `StrapDataSource`; add
  similar helpers for other dependencies.
- Each case of a new typed result has a test.

## 3. Report

- List findings most severe first. For each: `file:line`, the item above it
  breaks, the concrete failure, and a suggested fix.
- If there are no findings, say so plainly, and name what was reviewed.
- Don't change code unless asked. Fixes still follow the no-assertions rule.
