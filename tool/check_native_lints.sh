#!/usr/bin/env bash
# Copyright (c) 2026 Justin Peckner
# SPDX-License-Identifier: MIT
# See the LICENSE file in the project root for the full license text.

# Proves the native linters are running, and that every rule they enforce
# reports and fails the lint.
#
# Run from anywhere: tool/check_native_lints.sh
# CI and the pre-merge-checks skill run it. A linter that silently does
# nothing (a download or Gradle step that's skipped, a config whose paths
# match nothing, a rule that's misspelled or switched off) makes
# tool/lint_native.sh pass without checking anything. This script writes a
# Swift file and a Kotlin file that break every rule, runs the real lint,
# checks that it failed and that each rule reported, and deletes the files.
# The Swift probe goes in the iOS app, the watch app and the code they
# share, so a config that stops linting any of them fails this check.
#
# The rules are read from .swiftlint.yml and android/config/detekt.yml, so a
# rule added there without a violation below fails this check.

set -euo pipefail

cd "$(dirname "$0")/.."

swift_probe=ios/Runner/NativeLintProbe.swift
# Different names, so each probe's findings can be told apart.
watch_swift_probe=ios/PulseLinkWatch/WatchNativeLintProbe.swift
shared_swift_probe=ios/Shared/SharedNativeLintProbe.swift
kotlin_probe=android/app/src/main/kotlin/com/jpeckner/pulselink/NativeLintProbe.kt
for probe in "$swift_probe" "$watch_swift_probe" "$shared_swift_probe" "$kotlin_probe"; do
  if [[ -e "$probe" ]]; then
    echo "$probe already exists. Remove it and rerun." >&2
    exit 2
  fi
done
# The probes aren't in the Xcode project, and are deleted before anything
# else could build the Kotlin one.
trap 'rm -f "$swift_probe" "$watch_swift_probe" "$shared_swift_probe" "$kotlin_probe"' EXIT

# One violation per rule. Add one here when adding a rule.
cat > "$swift_probe" <<'EOF'
// Written by tool/check_native_lints.sh, which deletes it when it finishes.
import Foundation

enum NativeLintProbe { case a, b }

func probeForceUnwrapping(_ value: Int?) -> Int { value! }

func probeForceCast(_ value: Any) -> Int { value as! Int }

func probeThrows() throws -> Int { 1 }
func probeForceTry() -> Int { try! probeThrows() }

var probeImplicitlyUnwrapped: Int!

func probeNoAssertions() { fatalError("probe") }

func probeNoErrorLevelLogging(_ logger: Logger) { logger.error("probe") }

func probeNoCatchAllCases(_ probe: NativeLintProbe) -> Int {
  switch probe {
  case .a:
    return 1
  default:
    return 2
  }
}

// Not inside #if DEBUG.
#Preview {
  Text("probe")
}
EOF
cp "$swift_probe" "$watch_swift_probe"
cp "$swift_probe" "$shared_swift_probe"

cat > "$kotlin_probe" <<'EOF'
// Written by tool/check_native_lints.sh, which deletes it when it finishes.
package com.jpeckner.pulselink

private sealed interface NativeLintProbe {
    object A : NativeLintProbe
    object B : NativeLintProbe
}

private fun probeUnsafeCallOnNullableType(value: Int?): Int = value!!

private class ProbeLateinitUsage {
    lateinit var value: String
}

private fun probeForbiddenMethodCall(): Nothing = error("probe")

private fun probeElseCase(probe: NativeLintProbe): Int =
    when (probe) {
        NativeLintProbe.A -> 1
        else -> 2
    }

// Both a cast that can never succeed (detekt's UnsafeCast) and an unchecked
// `as` (no_unchecked_cast).
private fun probeUnsafeCast(value: String): Int = value as Int
EOF

# Rule names from the configs: SwiftLint's only_rules (other than the
# custom_rules entry) and custom rule names, plus the preview check
# (tool/check_swift_previews.py); detekt's rules, all of which are turned
# on in its config.
swift_rules="$(awk '
  /^[a-z_]+:/ { section = $1; next }
  section == "only_rules:" && /^  - / { if ($2 != "custom_rules") print $2 }
  section == "custom_rules:" && /^  [a-z_]+:$/ { sub(/:$/, "", $1); print $1 }
' .swiftlint.yml)
swiftui_previews_debug_only"
kotlin_rules="$(awk '/^  [A-Z][A-Za-z]+:$/ { sub(/:$/, "", $1); print $1 }' \
  android/config/detekt.yml)
no_unchecked_cast"
if [[ "$swift_rules" == swiftui_previews_debug_only ||
  "$kotlin_rules" == no_unchecked_cast ]]; then
  echo 'Found no rules in .swiftlint.yml or android/config/detekt.yml.' >&2
  exit 1
fi

failed=0

# Runs one language's lint and checks it failed, with each rule reporting
# against each of its probe files.
check() {
  local language=$1 rules=$2
  shift 2
  local output status probe probe_name
  set +e
  output=$(tool/lint_native.sh "$language" 2>&1)
  status=$?
  set -e

  local missing=()
  for probe in "$@"; do
    probe_name=$(basename "$probe")
    for rule in $rules; do
      # The name starts the line or follows a slash, so one probe's name
      # doesn't match inside another's.
      grep -qE "(^|/)$probe_name:.*$rule" <<<"$output" ||
        missing+=("$rule in $probe_name")
    done
  done

  if (( status == 0 )) || (( ${#missing[@]} > 0 )); then
    echo "$output"
    if (( status == 0 )); then
      echo "The $language lint passed with a probe that breaks every rule." >&2
    fi
    if (( ${#missing[@]} > 0 )); then
      local joined
      joined=$(printf '%s; ' "${missing[@]}")
      echo "Not reported for $language: ${joined%; }. Either the linter" \
        "isn't running, or the probe in $0 has no violation for that rule." >&2
    fi
    failed=1
    return 0
  fi
  for rule in $rules; do
    echo "OK: $rule reported ($language)."
  done
}

check swift "$swift_rules" "$swift_probe" "$watch_swift_probe" "$shared_swift_probe"
check kotlin "$kotlin_rules" "$kotlin_probe"

exit "$failed"
