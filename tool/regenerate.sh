#!/usr/bin/env bash
# Cleans every build output and cache, then regenerates everything:
# packages, freezed code, Pigeon platform-channel code and (on macOS) the iOS
# project config.
#
# Run from anywhere: tool/regenerate.sh
# Use it when builds act strangely, or after switching branches or upgrading
# Flutter. For a freezed change alone, build_runner by itself is enough; for a
# Pigeon contract change, tool/pigeon.sh.

set -euo pipefail

cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$1"; }

step 'Removing build outputs and caches'
flutter clean
rm -rf coverage

step 'Getting packages'
flutter pub get
(cd tool/pulselink_lints && dart pub get)

step 'Generating freezed code'
dart run build_runner build --delete-conflicting-outputs

step 'Generating platform-channel code (Pigeon)'
tool/pigeon.sh

if [[ "$(uname)" == 'Darwin' ]]; then
  step 'Regenerating the iOS project config'
  flutter build ios --config-only
else
  step 'Skipping the iOS project config (needs macOS)'
fi

step 'Checking generated code against git'
# Only generated files, so your own uncommitted edits don't count.
generated=('*.freezed.dart' '*.pigeon.dart' '*.pigeon.swift' '*.pigeon.kt')
if [[ -n "$(git status --porcelain -- "${generated[@]}")" ]]; then
  git status --short -- "${generated[@]}"
  echo 'Generated code differs from what is committed. Review and commit it.'
else
  echo 'Generated code matches what is committed.'
fi
