#!/usr/bin/env bash
# Lints the hand-written Swift and Kotlin against CLAUDE.md's native-code
# rules. Fails on any finding, and if a linter doesn't run.
#
# Run from anywhere: tool/lint_native.sh [swift|kotlin|all]   (default: all)
# CI and the pre-merge-checks skill run it, and tool/check_native_lints.sh
# proves each rule reports. The Runner target's SwiftLint build phase runs
# `swift` on every Xcode build (including `flutter run` and `flutter build
# ios`), so findings show inline in Xcode and fail the build.
#
# Neither linter is stored in Git; each is downloaded the first time it's
# needed and cached outside the repo:
#   - SwiftLint: the release below, checked against its SHA-256, cached in
#     ~/.cache/pulselink (or $XDG_CACHE_HOME/pulselink).
#   - detekt: Gradle fetches the version pinned in android/settings.gradle.kts
#     into its own cache (~/.gradle).

set -euo pipefail

cd "$(dirname "$0")/.."

which="${1:-all}"

# SwiftLint release, and the SHA-256 GitHub publishes for each download.
swiftlint_version=0.65.1

swiftlint_binary() {
  local asset sha
  case "$(uname -s)-$(uname -m)" in
    Darwin-*)
      asset=portable_swiftlint.zip
      sha=c1e429b0599cf1b516f369a2d9ec04eaf0e436f3c12b637df8851fa52ff694d0
      ;;
    Linux-x86_64)
      asset=swiftlint_linux_amd64.zip
      sha=caeed6f4a679c35539ffaf124f6c4ab4a8416917f7d8796279dc52b74026059d
      ;;
    Linux-aarch64 | Linux-arm64)
      asset=swiftlint_linux_arm64.zip
      sha=9ffa52f478e6d8eb485d37d14715ffac90abc81c58f3370d598bf75be05605f8
      ;;
    *)
      echo "No SwiftLint download for $(uname -s) $(uname -m)." >&2
      return 1
      ;;
  esac

  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/pulselink/swiftlint-$swiftlint_version-${asset%.zip}"
  if [[ ! -d "$cache" ]]; then
    local download
    download=$(mktemp -d)
    echo "Downloading SwiftLint $swiftlint_version ($asset)..." >&2
    curl -fsSL -o "$download/$asset" \
      "https://github.com/realm/SwiftLint/releases/download/$swiftlint_version/$asset"
    if ! echo "$sha  $download/$asset" | shasum -a 256 -c - > /dev/null; then
      echo "SwiftLint download doesn't match its expected SHA-256." >&2
      rm -rf "$download"
      return 1
    fi
    # Unzipped next to the cache, then moved into place, so an interrupted
    # download never leaves a half-filled cache that looks complete.
    unzip -q "$download/$asset" -d "$download/unzipped"
    mkdir -p "$(dirname "$cache")"
    mv "$download/unzipped" "$cache"
    rm -rf "$download"
  fi

  local binary
  binary=$(find "$cache" -type f -name swiftlint | head -1)
  if [[ -z "$binary" ]]; then
    echo "No swiftlint binary in $cache. Delete it and rerun." >&2
    return 1
  fi
  chmod +x "$binary"
  echo "$binary"
}

lint_swift() {
  local swiftlint output
  swiftlint=$(swiftlint_binary)
  echo "==> SwiftLint $swiftlint_version"
  # Findings go to stdout; the "Done linting" summary goes to stderr.
  set +e
  output=$("$swiftlint" lint --strict --config .swiftlint.yml 2>&1)
  local status=$?
  set -e
  echo "$output" | grep -vE '^Linting |^Loading configuration' || true
  if (( status != 0 )); then
    return "$status"
  fi
  # Guards against a config that matches nothing: SwiftLint would pass.
  local files
  files=$(sed -nE 's/^Done linting! .* in ([0-9]+) files?\.$/\1/p' <<<"$output")
  if [[ -z "$files" || "$files" == 0 ]]; then
    echo "SwiftLint linted no files; check 'included' in .swiftlint.yml." >&2
    return 1
  fi
}

# The JDK for Gradle: JAVA_HOME if set, else java on the PATH, else the one
# Android Studio ships on macOS (which Flutter also uses).
use_jdk() {
  # `java -version` rather than `command -v java`: macOS has a placeholder
  # /usr/bin/java that only says no Java is installed.
  if [[ -n "${JAVA_HOME:-}" ]] || java -version > /dev/null 2>&1; then
    return 0
  fi
  local studio="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
  if [[ -x "$studio/bin/java" ]]; then
    export JAVA_HOME="$studio"
    return 0
  fi
  echo 'No JDK found. Set JAVA_HOME, or install Android Studio.' >&2
  return 1
}

# Runs detekt and the unchecked-cast check (both Gradle tasks in
# android/app/build.gradle.kts, which also runs them in every Android
# build), and fails if either found something.
lint_kotlin() {
  use_jdk
  local status=0
  echo '==> detekt and no_unchecked_cast'
  # detektMain analyses the app's production Kotlin with type resolution,
  # which UnsafeCallOnNullableType and ElseCaseInsteadOfExhaustiveWhen need,
  # once per build variant (debug, profile and release).
  local reports=build/app/reports/detekt
  # Deleting the reports makes Gradle rerun detekt rather than skip it as up
  # to date, so the reports checked below are always from this run.
  rm -rf "$reports"
  # Fails on any finding; the reports below are written either way.
  # --continue runs the cast check even if detekt fails, so one run reports
  # everything.
  (cd android && ./gradlew --quiet --continue :app:detektMain :app:checkUncheckedCasts) ||
    status=1

  # Guards against detekt passing because it analysed nothing, such as after
  # a change to its source paths or excludes.
  local report count checked=0
  for report in "$reports"/*.md; do
    [[ -e "$report" ]] || continue
    count=$(sed -nE 's/^\* ([0-9]+) number of kt files$/\1/p' "$report")
    if [[ -z "$count" || "$count" == 0 ]]; then
      echo "detekt analysed no Kotlin files for $(basename "$report" .md)." >&2
      return 1
    fi
    checked=$((checked + 1))
  done
  if (( checked == 0 )); then
    echo "detekt wrote no reports to $reports, so it didn't run." >&2
    return 1
  fi
  echo "detekt analysed ${count} Kotlin files in each of $checked build variants."

  return "$status"
}

case "$which" in
  swift) lint_swift ;;
  kotlin) lint_kotlin ;;
  all)
    # Both run even if the first fails, so one run reports everything.
    status=0
    lint_swift || status=1
    lint_kotlin || status=1
    exit "$status"
    ;;
  *)
    echo "Usage: $0 [swift|kotlin|all]" >&2
    exit 2
    ;;
esac
