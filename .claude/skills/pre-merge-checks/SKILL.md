---
name: pre-merge-checks
description: Run PulseLink's final checks on the current branch before it is merged into `develop`. Rebases the branch onto `develop` when it's safe, regenerates freezed code and lockfiles and commits the results, finds and removes unused code, fixes formatting, runs every CI check (analyze with all lints, shuffled tests with coverage, the lint plugin's own checks), builds iOS and Android release apps and checks no debug-only code is in them, reviews the diff against the no-assertions and error-handling rules, checks the branch's commits for secrets, message format, WIP leftovers and debug prints, and reports pass/fail per check. Use when asked to run pre-merge checks, final checks, "get this branch ready to merge", or "check the branch before I merge it", even if the user doesn't name this skill.
argument-hint: [notes, e.g. "skip sync", "no commits", "skip builds"]
---

# Pre-merge checks

Get the current branch to a state the user can merge into `develop` without surprises. The skill fixes and commits three kinds of problems itself:
- generated files (freezed code, `pubspec.lock`) that regenerate differently;
- formatting;
- unused code.

Everything else it reports. **It doesn't merge the branch into `develop` or push anything**; the user does that.

## Input

Arguments: `$ARGUMENTS`

Anything given is a note from the user, and notes override this skill's defaults, e.g. "skip sync", "no commits" or "skip builds". If the arguments are empty or still the placeholder text, run every step.

## Ground rules

- Run `export PATH="$HOME/development/flutter/bin:$PATH"` first; Flutter isn't on the default `PATH`.
- Write logs to your scratchpad directory (`$LOGS` below means that directory). Run long commands (`tool/regenerate.sh`, `flutter test`, `flutter build`) in the background and wait for them to finish. Don't run two Flutter builds at once; they share `build/`.
- Stage files by path, never with `git add -A`, `git add .` or `git commit -a`.
- Commit messages follow `.gitmessage` and the branch's own commits: `<type>(heart_rate_monitor): Milestone <N> - <topic>`, with `<N>` taken from the branch's latest commit. The subject must be 50 characters or less. The body is a short bullet list wrapped at 72, ending with `[AI-Generated 100% Claude <model>]`. Don't add a `Co-Authored-By` line; this repo's commits don't use one.
- Fixes follow `CLAUDE.md`: no assertions, and errors handled on purpose.

## 1. Preconditions

1. `git branch --show-current` must not be `develop` or `master`. If it is, stop and say so. Note `git rev-parse HEAD` as the starting HEAD for the report; `git reset --hard <starting HEAD>` undoes everything this run does.
2. `git status --porcelain` must print nothing. If anything is modified or untracked, stop and ask the user. The skill's commits would otherwise pick up their unfinished work, or its fixes would get mixed in with it.
3. Note whether the branch has the lint plugin: `git ls-files --error-unmatch tool/pulselink_lints/pubspec.yaml`. Steps 3 and 5 use it only if it's there.

## 2. Sync with `develop`

Run the checks against the code that will actually be merged.

```bash
# Only if `git remote` lists origin: fast-forward develop; fails rather than rewriting if they've diverged
git fetch origin develop:develop
git rev-list --count HEAD..develop
```

- If the count is `0`, the branch already contains `develop`. Go on.
- Otherwise rebase. This repo keeps feature branches linear: they're rebased onto `develop`, and only `develop` gets merge commits. Rebase only if both of these hold:
  - `git rev-list --merges develop..HEAD` prints nothing, because a rebase would drop merge commits;
  - no remote branch has the branch's commits: `git branch -r --contains $(git rev-list develop..HEAD | tail -1)` prints nothing, or there's no remote.

  If both hold, run `git rebase develop`. If either fails, stop and ask the user whether to rebase or merge.
- If `git fetch origin develop:develop` refuses because the local `develop` has diverged, stop and tell the user. Don't reset either one.
- If the rebase has conflicts, stop. List the conflicting files and ask whether to resolve them or abort with `git rebase --abort`. If a `.freezed.dart` file conflicts, resolve its source file, then regenerate it rather than editing it by hand.

## 3. Regenerate and commit generated files

```bash
tool/regenerate.sh > "$LOGS/regenerate.log" 2>&1
```

It cleans `build/`, gets packages, runs `build_runner` and, on macOS, regenerates the iOS project config. If it fails, show the end of the log and stop. If the branch has the lint plugin and the script doesn't already fetch the plugin's packages, also run `(cd tool/pulselink_lints && dart pub get)`.

Then:

1. Run `git status --porcelain` and sort what changed:
   - **Generated output:** `*.freezed.dart`, `*.g.dart`, `pubspec.lock`, `tool/pulselink_lints/pubspec.lock`. This is out of date on the branch.
   - **Anything under `ios/` or `android/`.** Flutter's tool rewrites these files after an upgrade, or when plugins change. Stop, show `git diff --stat`, and ask the user whether to commit them. Native project changes need a human look.
   - **Anything else.** It's unexpected, so stop and report it.
2. Look for generated files left behind by a deleted or renamed source. `build_runner` doesn't remove them:
   ```bash
   for f in $(git ls-files '*.freezed.dart' '*.g.dart'); do
     src="${f%.freezed.dart}"; src="${src%.g.dart}.dart"
     grep -qF "part '$(basename "$f")';" "$src" 2>/dev/null || echo "Orphaned: $f"
   done
   ```
   Delete each orphan with `git rm`, since nothing can import it.
3. If there are changes, stage them by path and commit, e.g. `chore(heart_rate_monitor): Milestone 2 - generated`, with a body naming what was regenerated.

## 4. Unused code

This is PulseLink's counterpart to Periphery. `dart analyze` already reports unused *private* code (`unused_element`, `unused_field`, `unused_import`), and step 5 catches that. This step finds *public* top-level declarations in `lib/` that nothing uses:

```bash
REPO=$(git rev-parse --show-toplevel)
(cd .claude/skills/pre-merge-checks/find_unused_code && dart pub get > /dev/null && dart run bin/find_unused_code.dart "$REPO") > "$LOGS/unused.log" 2>&1
cat "$LOGS/unused.log"
```

It prints two groups:
- **Unused:** nothing refers to the declaration, apart from its own body and generated code.
- **Used only by tests:** only `test/` refers to it.

A use of any member (a constructor, method, field or enum value) counts as a use of its class. Unused public *members* aren't checked; mention that limit in the report.

**Look for an existing fix on another local branch first.** The user often has unmerged branches waiting, and one may already remove the same code:

```bash
git log --branches --not HEAD --format='%h %s' -- <files from the findings>
git branch --contains <sha>    # for each candidate, the branches that have it
```

Cherry-pick a candidate (`git cherry-pick <sha>`) only if `git show <sha>` shows that **every** change in it fixes one of the current findings, with nothing unrelated mixed in. Cherry-picking keeps the user's authorship, and git merges the identical change on both branches without a conflict later. If the commit mixes in other changes, or the cherry-pick conflicts (`git cherry-pick --abort`), write the fix yourself. Copy the commit's relevant changes exactly where they apply, so the two branches still merge cleanly.

Then handle each remaining **unused** finding. Prefer the first of these that fits:

1. **Delete it.** This is the usual case. Follow the deletion through:
   - tests and test helpers that only exercised it;
   - its `part` file (rerun `dart run build_runner build --delete-conflicting-outputs`);
   - imports left unused;
   - mentions in `README.md`, `lib/*/README.md` and `docs/`.
2. **Keep it with a comment**, when it has to stay: it's groundwork for an upcoming milestone in the build plan, or something outside Dart (a platform channel, reflection) uses it. Put `// unused-code: keep, <reason>` on the line above the declaration, after its doc comment. If you're not sure the code is planned, ask the user instead of guessing.

Never edit `*.freezed.dart` or `*.g.dart` by hand. If a finding points at a generated class, fix its source.

Rerun the tool until it reports nothing unused; deleting code often makes more code unused. Then rerun step 3's `build_runner` check, stage the changes by path and commit, e.g. `refactor(heart_rate_monitor): Milestone 2 - unused code`.

**Used only by tests** findings are informational. Report them, and don't delete them. At this stage of the project, they're usually the next milestone's groundwork, e.g. the Heart Rate Measurement parser before BLE arrives in Milestone 3.

Then check the dependencies (informational, don't change `pubspec.yaml`):

```bash
python3 .claude/skills/pre-merge-checks/check_dependencies.py
```

## 5. CI checks

These are the checks `.github/workflows/ci.yml` runs. Read the workflow first, and if it has steps not listed here, run those too.

### 5a. No CocoaPods

`ios/Podfile` must not exist; this project uses Swift Package Manager only. If it does, report a fail and don't delete it yourself.

### 5b. Formatting

```bash
dart format --output=none --set-exit-if-changed lib test
```

If it lists files, run `dart format lib test`, stage those files, and commit: `style(heart_rate_monitor): Milestone 2 - formatting`.

### 5c. Analyze

```bash
flutter analyze --fatal-infos --fatal-warnings > "$LOGS/analyze.log" 2>&1
```

This covers the very_good_analysis lints and, when the branch has it, the `pulselink_lints` plugin (`no_assertions`, `no_catch_all_cases`, `no_ignored_results`, `use_switch_on_closed_types`). `develop` passes CI, so any issue comes from the branch or from a Flutter upgrade, and fails the check. Fix only issues caused by this run's own commits, e.g. an import left unused by step 4. Report the rest with file, line and rule.

A clean analyze doesn't prove the plugin ran: if it fails to load, analyze reports "No issues found!" anyway. If the branch has `tool/check_lint_plugin.sh`, run it; it analyzes a file that breaks each enabled rule and fails unless every rule reports. A failure here fails the analyze check. If it says it rebuilt the plugin's cached copy and then passed, the first analyze ran with a stale copy, so run analyze again and use that result.

If the branch has the plugin but not the script, do the same by hand: add a file in `lib/` with a `_` case on an enum, run `flutter analyze`, check `no_catch_all_cases` is reported, then delete the file. The analysis server's cached copy of the plugin can be stale after switching branches; if a rule is missing, run `touch tool/pulselink_lints/lib/*.dart tool/pulselink_lints/lib/src/*.dart` and try once more before calling it a failure.

### 5d. Tests

```bash
flutter test --coverage --test-randomize-ordering-seed random > "$LOGS/test.log" 2>&1
grep -E "Shuffling test order|\[E\]|Some tests failed|All tests passed" "$LOGS/test.log"
```

CI runs tests in a fixed order. Shuffling also catches tests that depend on each other's order. Note the seed from the "Shuffling test order with --test-randomize-ordering-seed=N" line.

For each failing test file:
1. Rerun it once with the same seed: `flutter test <file> --test-randomize-ordering-seed <N>`.
2. Then rerun it 5 times with `random`.
3. Classify the failure:
   - **consistent:** it always fails;
   - **order-dependent:** it fails with that seed but passes in another order;
   - **flaky:** it passes on some runs and fails on others with the same order.

If a failure was caused by this run's commits, fix it, then commit the fix. Otherwise report it: branch logic is the user's to change.

### 5e. Lint plugin

If the branch has `tool/pulselink_lints`, run its own checks, as CI does:

```bash
(cd tool/pulselink_lints && dart format --output=none --set-exit-if-changed lib test && dart analyze --fatal-infos --fatal-warnings && dart test)
```

If the branch changed `.claude/skills/pre-merge-checks/find_unused_code/`, run `dart test` there too.

### 5f. Coverage of the branch's changes (informational)

```bash
python3 .claude/skills/pre-merge-checks/changed_line_coverage.py coverage/lcov.info
```

This lists lines the branch added or changed in `lib/` that no test runs, and changed lib files missing from the coverage report (no test loads them, or they only declare types). It doesn't affect the verdict. Point out uncovered lines in logic: parsers, cubits, data sources. Rendering code reached only through `kReleaseMode` is expected to be uncovered.

## 6. Release builds

CI doesn't build the apps yet; that comes in Milestone 7. Build both release apps, one after the other, in the background:

```bash
flutter build ios --release --no-codesign > "$LOGS/build-ios.log" 2>&1
flutter build apk --release > "$LOGS/build-android.log" 2>&1
```

- A failure here usually means native code is broken: Swift, Gradle, Swift Package Manager or a plugin. Show the first error in the log.
- If `flutter doctor` reports the Android or Xcode toolchain as missing, skip that build and say so.

Then check that no debug-only code is in either binary:

```bash
python3 .claude/skills/pre-merge-checks/check_release_binary.py \
  build/ios/iphoneos/Runner.app/Frameworks/App.framework/App \
  build/app/outputs/flutter-apk/app-release.apk
```

Debug tooling must never ship. Debug-only code lives in `debug_*.dart` files or `debug/` folders, and only the `if (!kReleaseMode)` branch of `main()` uses it, so the release compiler drops it. The script searches the compiled Dart code for the names and strings those files declare. A hit fails the check. Find what pulls that file into release code, usually an import outside the `kReleaseMode` branch, and report it.

## 7. Project rules

Review the branch's diff against the rules in `CLAUDE.md`.

**No assertions.** If `analysis_options.yaml` enables `no_assertions`, step 5c already failed on any assertion, so review the exceptions instead. List the ignores the branch added:

```bash
git diff develop...HEAD -- 'lib/*.dart' | grep -nE '^\+.*ignore(_for_file)?:.*no_assertions'
```

Each must have a comment next to it explaining why it's needed, which means the user signed it off. One without a reason, or an `ignore_for_file`, is a fail.

On a branch without the rule, list the added lines in `lib/` that might be assertions:

```bash
git diff develop...HEAD -- 'lib/*.dart' ':!*.freezed.dart' ':!*.g.dart' \
  | grep -nE '^\+.*(\bassert\(|@Assert|\blate\b|throw (ArgumentError|StateError|RangeError|UnsupportedError|UnimplementedError|Exception)|[A-Za-z0-9_)\]]![.;,)\[ ]| as [A-Z])' \
  | grep -vE "^\+\s*(//|import )"
```

Read each hit in context, since the pattern catches some false positives, e.g. `!` in a string. A real assertion passes only if the comment next to it explains why it's needed, which means the user signed it off. Otherwise it's a fail. Don't remove it yourself, because the rule needs the user's decision.

**Error handling.** If the diff adds async calls, cleanup code (`close`, `dispose`, `stop`, `cancel`), catch blocks, stream subscriptions or `lib/data/` implementations, run the `error-handling-review` skill on `develop...HEAD`. Include its findings in the report. Don't fix them unless the user asks.

**Rules kept in sync.** `CLAUDE.md` repeats rules from the build plan's "Instructions for Claude" section, and both must say the same thing. If the branch changes the rules in one, check the other changed to match:
```bash
git diff --stat develop...HEAD -- CLAUDE.md 'BLE Heart-Rate Monitor Flutter + Apple Watch Build Plan.md'
```

## 8. Branch hygiene

After step 2 the branch contains `develop`, so `develop..HEAD` is exactly what the user is about to merge.

**Secrets.** There are no API keys in this project yet, so this check looks for anything that shouldn't be committed:

```bash
git diff develop...HEAD | grep -nE '^\+.*((api[_-]?key|secret|token|password)\s*[:=]\s*["'"'"'][^"'"'"']{8,}|BEGIN [A-Z ]*PRIVATE KEY)' -i
git diff --name-only --diff-filter=A develop...HEAD | grep -E '\.(jks|keystore|p12|p8|pem|mobileprovision)$|key\.properties$|google-services\.json$|GoogleService-Info\.plist$|\.env$'
```

Both must print nothing. If either finds something, stop and tell the user which commits contain it. Removing it means rewriting history, which is their decision. Remind them that a secret should be rotated once it has been pushed anywhere.

**Commit messages.** For each commit in `git log --format='%h%x00%B%x00' develop..HEAD`, check:
- the subject matches `^(feat|fix|refactor|style|docs|test|chore)\(heart_rate_monitor\): Milestone [0-9]+ - .+` and is 50 characters or less;
- line 2 is blank;
- no body line is longer than 72 characters.

Report each problem with the commit. Don't reword the commits yourself.

**WIP commits.**
```bash
git log --format='%h %s' develop..HEAD | grep -iE '\bwip\b|^[0-9a-f]+ (fixup|squash|amend)!|\b(tmp|temp|todo)\b'
```

**Leftovers in the diff.** These are added lines only, with generated code excluded:
```bash
git diff develop...HEAD -- '*.dart' ':!*.freezed.dart' ':!*.g.dart' \
  | grep -nE '^\+.*(TODO|FIXME|XXX|HACK|\bprint\(|debugPrint\(|debugger\(|\bsolo: true|\bskip: (true|'"'"'))'
```
`print` and `debugPrint` don't belong in app code, and `solo:` or `skip:` in a test hides other tests. Report each match with its file. Some may be intentional, so don't remove them.

**Large files.**
```bash
git diff --name-only --diff-filter=AM develop...HEAD | while read -r f; do [ -f "$f" ] && [ "$(wc -c < "$f")" -gt 1000000 ] && echo "$f"; done
```

For WIP commits, leftovers and large files, report each one so the user can decide. Don't rewrite commits yourself.

## 9. Final state

`git status --porcelain` must print nothing. If anything remains, say what and why. Check whether it should have been part of one of this run's commits.

## 10. Report

Start with a one-line verdict: **ready to merge** or **not ready**, and why.

Then a table with one row per check, giving its status (pass / fixed / fail / info / skipped) and a short detail:
- sync
- generated code
- orphaned generated files
- unused code
- dependencies
- CocoaPods
- formatting
- analyze
- tests (with totals and the seed)
- lint plugin
- coverage of changes
- iOS release build
- Android release build
- debug code in release
- no assertions
- error handling
- rules in sync
- secrets
- commit messages
- WIP commits
- leftovers
- large files

Coverage and dependencies are always *info*.

Then:
- the commits this run made: `git log --format='%h %s' <starting HEAD>..HEAD`;
- each failure in full: file and line for analyzer issues, test names with consistent / order-dependent / flaky for tests;
- unused code you kept, with the reason, and the "used only by tests" list;
- for each commit you cherry-picked, the original commit and the branches that contain it. Say that merging those branches later won't conflict, and that the user can drop the cherry-pick if they'd rather merge one of those branches first;
- a reminder: **"If you'd like a review before merging, run `/code-review`."** Don't run it yourself.

Don't push, and don't merge into `develop`.
