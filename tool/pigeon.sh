#!/usr/bin/env bash
# Generates the Dart, Swift and Kotlin platform-channel code from each Pigeon
# contract in pigeons/, then formats the Dart output so it passes
# `dart format --set-exit-if-changed` like the rest of lib/.
#
# Run from anywhere: tool/pigeon.sh. tool/regenerate.sh and CI run it too.

set -euo pipefail

cd "$(dirname "$0")/.."

for input in pigeons/*.dart; do
  dart run pigeon --input "$input"
done
find lib -name '*.pigeon.dart' -print0 | xargs -0 dart format > /dev/null
