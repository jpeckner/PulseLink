#!/usr/bin/env bash
# Runs the Swift tests: ios/RunnerTests on an iPhone simulator, then
# ios/PulseLinkWatchTests on an Apple Watch simulator. Fails if a test fails,
# and if either target ran no tests.
#
# Run from anywhere on macOS: tool/test_swift.sh
# The pre-merge-checks skill runs it. CI doesn't yet: it runs on Linux until
# Milestone 7 adds a macOS job.
#
# Needs Flutter's iOS project config, which `flutter build ios --config-only`
# (or tool/regenerate.sh) writes. Each simulator is the first available one
# of its kind on the newest runtime. xcodebuild tests on a clone of it, so a
# simulator that's already open is left alone.

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -e ios/Flutter/Generated.xcconfig ]]; then
  echo "No ios/Flutter/Generated.xcconfig. Run 'flutter build ios --config-only' first." >&2
  exit 1
fi

# Prints the UDID of the first available simulator whose name starts with
# $2, on the newest runtime of OS $1 (iOS or watchOS), or nothing.
find_simulator() {
  xcrun simctl list devices available --json | python3 -c '
import json, re, sys

os_name, name_prefix = sys.argv[1], sys.argv[2]

def version(runtime):
    match = re.search(rf"\.{os_name}-(\d+)-(\d+)$", runtime)
    return (int(match[1]), int(match[2])) if match else None

devices = json.load(sys.stdin)["devices"]
runtimes = sorted(
    (r for r in devices if version(r) and devices[r]),
    key=version,
    reverse=True,
)
for runtime in runtimes:
    for device in devices[runtime]:
        if device["name"].startswith(name_prefix):
            print(device["udid"])
            sys.exit(0)
' "$1" "$2"
}

log=$(mktemp)
trap 'rm -f "$log"' EXIT
total=0

# Runs scheme $1's tests on simulator $2, and adds the number that passed to
# $total. $3 names the tests in messages.
run_tests() {
  local scheme=$1 simulator=$2 label=$3
  # xcodebuild won't write a result bundle over an old one.
  local results="build/ios-tests/$scheme.xcresult"
  rm -rf "$results"

  echo "==> $label on simulator $simulator"
  set +e
  # -collect-test-diagnostics never: otherwise a failing test makes
  # xcodebuild spend up to 10 minutes collecting simulator logs.
  xcodebuild test \
    -workspace ios/Runner.xcworkspace \
    -scheme "$scheme" \
    -destination "id=$simulator" \
    -derivedDataPath build/ios-tests \
    -resultBundlePath "$results" \
    -collect-test-diagnostics never \
    > "$log" 2>&1
  local status=$?
  set -e

  if (( status != 0 )); then
    grep -E "^Test case '.*' failed on|error:" "$log" || true
    tail -20 "$log"
    echo "xcodebuild test failed for $label (exit $status)." >&2
    exit "$status"
  fi

  # The counts come from the result bundle rather than xcodebuild's output,
  # where lines from parallel test runs can interleave. A parameterized test
  # counts once.
  local summary passed
  summary=$(xcrun xcresulttool get test-results summary --path "$results")
  passed=$(python3 -c 'import json, sys; print(json.load(sys.stdin).get("passedTests", 0))' <<<"$summary")
  if (( passed == 0 )); then
    tail -20 "$log"
    echo "xcodebuild reported success, but no $label ran." >&2
    exit 1
  fi
  echo "$passed passed."
  total=$(( total + passed ))
}

iphone=$(find_simulator iOS iPhone)
if [[ -z "$iphone" ]]; then
  echo 'No iPhone simulator is available. Add one in Xcode > Window > Devices and Simulators.' >&2
  exit 1
fi
watch=$(find_simulator watchOS 'Apple Watch')
if [[ -z "$watch" ]]; then
  echo 'No Apple Watch simulator is available. Add one in Xcode > Window > Devices and Simulators.' >&2
  exit 1
fi

run_tests Runner "$iphone" 'iPhone app tests'
run_tests PulseLinkWatch "$watch" 'watch app tests'
echo "$total tests passed."
