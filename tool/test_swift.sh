#!/usr/bin/env bash
# Runs the Swift tests in ios/RunnerTests on an iPhone simulator. Fails if a
# test fails, and if no test ran.
#
# Run from anywhere on macOS: tool/test_swift.sh
# The pre-merge-checks skill runs it. CI doesn't yet: it runs on Linux until
# Milestone 7 adds a macOS job.
#
# Needs Flutter's iOS project config, which `flutter build ios --config-only`
# (or tool/regenerate.sh) writes. The simulator is the first available
# iPhone on the newest iOS runtime. xcodebuild tests on a clone of it, so a
# simulator that's already open is left alone.

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -e ios/Flutter/Generated.xcconfig ]]; then
  echo "No ios/Flutter/Generated.xcconfig. Run 'flutter build ios --config-only' first." >&2
  exit 1
fi

simulator=$(xcrun simctl list devices available --json | python3 -c '
import json, re, sys

def version(runtime):
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    return (int(match[1]), int(match[2])) if match else None

devices = json.load(sys.stdin)["devices"]
runtimes = sorted(
    (r for r in devices if version(r) and devices[r]),
    key=version,
    reverse=True,
)
for runtime in runtimes:
    for device in devices[runtime]:
        if device["name"].startswith("iPhone"):
            print(device["udid"])
            sys.exit(0)
')
if [[ -z "$simulator" ]]; then
  echo 'No iPhone simulator is available. Add one in Xcode > Window > Devices and Simulators.' >&2
  exit 1
fi

log=$(mktemp)
trap 'rm -f "$log"' EXIT
# xcodebuild won't write a result bundle over an old one.
results=build/ios-tests/results.xcresult
rm -rf "$results"

echo "==> Swift tests on simulator $simulator"
set +e
# -collect-test-diagnostics never: otherwise a failing test makes xcodebuild
# spend up to 10 minutes collecting simulator logs.
xcodebuild test \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -destination "id=$simulator" \
  -derivedDataPath build/ios-tests \
  -resultBundlePath "$results" \
  -collect-test-diagnostics never \
  > "$log" 2>&1
status=$?
set -e

if (( status != 0 )); then
  grep -E "^Test case '.*' failed on|error:" "$log" || true
  tail -20 "$log"
  echo "xcodebuild test failed (exit $status)." >&2
  exit "$status"
fi

# The counts come from the result bundle rather than xcodebuild's output,
# where lines from parallel test runs can interleave. A parameterized test
# counts once.
summary=$(xcrun xcresulttool get test-results summary --path "$results")
passed=$(python3 -c 'import json, sys; print(json.load(sys.stdin).get("passedTests", 0))' <<<"$summary")
if (( passed == 0 )); then
  tail -20 "$log"
  echo 'xcodebuild reported success, but no test ran.' >&2
  exit 1
fi
echo "$passed tests passed."
