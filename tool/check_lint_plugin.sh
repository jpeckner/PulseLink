#!/usr/bin/env bash
# Proves the pulselink_lints analyzer plugin is running, and that every rule
# enabled in analysis_options.yaml reports.
#
# Run from anywhere: tool/check_lint_plugin.sh
# CI and the pre-merge-checks skill run it. A plugin that fails to load (a
# wrong path, or a version clash after a Flutter upgrade) makes `flutter
# analyze` report "No issues found!" instead of failing, so a clean analyze
# alone doesn't show the rules ran. This script writes a file that breaks
# each rule, analyzes it, checks each rule reported, and deletes the file. If
# a rule is missing, it rebuilds the plugin once and checks again, in case
# the analysis server's cached copy of it is out of date.

set -euo pipefail

cd "$(dirname "$0")/.."

probe=lib/lint_plugin_probe.dart
if [[ -e "$probe" ]]; then
  echo "$probe already exists. Remove it and rerun." >&2
  exit 2
fi
trap 'rm -f "$probe"' EXIT

# One violation per rule. Add one here when adding a rule.
cat > "$probe" <<'EOF'
// Written by tool/check_lint_plugin.sh, which deletes it when it finishes.
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/data/ble/ble_api.pigeon.dart';

BleBatteryLevel? keepPigeonImportsLocal;

enum _Probe { a, b }

int noCatchAllCases(_Probe p) => switch (p) {
  _Probe.a => 1,
  _ => 2,
};

int noAssertions(int? x) => x!;

int useSwitchOnClosedTypes(_Probe p) => [if (p case _Probe.a) 1].length;

_Probe _probeResult() => _Probe.a;

void noIgnoredResults() => _probeResult();

void noDynamic(List<dynamic> values) {}

const noHardcodedUiStrings = Text('Hello');
EOF

# The rules enabled under `plugins: pulselink_lints: diagnostics:`.
rules=$(awk '
  /^plugins:/ { in_plugins = 1; next }
  in_plugins && /^[^ #]/ { in_plugins = 0 }
  in_plugins && /diagnostics:/ { in_diagnostics = 1; next }
  in_diagnostics && /^ *[a-z_]+: *true/ { sub(/:.*/, ""); gsub(/ /, ""); print }
' analysis_options.yaml)
if [[ -z "$rules" ]]; then
  echo 'No pulselink_lints rules are enabled in analysis_options.yaml.' >&2
  exit 1
fi

# Analyzes the probe and sets `output`, and `missing` to the enabled rules
# that didn't report.
check() {
  # The probe is meant to have issues, so analyze's exit code doesn't matter.
  output=$(flutter analyze --no-fatal-infos --no-fatal-warnings "$probe" 2>&1 || true)
  missing=()
  for rule in $rules; do
    grep -q "$probe:.*• $rule\$" <<<"$output" || missing+=("$rule")
  done
}

check

if (( ${#missing[@]} > 0 )); then
  # The analysis server runs a compiled copy of the plugin, cached under
  # ~/.dartServer/.plugin_manager and rebuilt when the plugin's files look
  # newer than it. Switching branches can leave a copy built from another
  # branch's plugin that still looks current, so it silently lacks rules
  # added since. Touching the plugin's files forces a rebuild; their contents
  # don't change.
  echo "Not reported: ${missing[*]}. Rebuilding the analysis server's" \
    'cached copy of the plugin and checking again.'
  find tool/pulselink_lints/lib -name '*.dart' -exec touch {} +
  check
fi

if (( ${#missing[@]} > 0 )); then
  echo "$output"
  echo "Not reported: ${missing[*]}. Either the plugin isn't running, or" \
    "the probe in $0 has no violation for that rule." >&2
  exit 1
fi

for rule in $rules; do
  echo "OK: $rule reported."
done
