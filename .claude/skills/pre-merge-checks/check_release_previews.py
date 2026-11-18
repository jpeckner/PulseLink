#!/usr/bin/env python3
# Copyright (c) 2026 Justin Peckner
# SPDX-License-Identifier: MIT
# See the LICENSE file in the project root for the full license text.

"""Check that no SwiftUI preview made it into a release build.

Usage: check_release_previews.py <app binary> [...]

The binaries are the iOS and watch apps' executables from
`flutter build ios --release`:

- build/ios/iphoneos/Runner.app/Runner
- build/ios/iphoneos/Runner.app/Watch/PulseLinkWatch.app/PulseLinkWatch

CLAUDE.md's "SwiftUI previews" rule keeps preview code inside `#if DEBUG`,
and tool/check_swift_previews.py checks the source. This checks the result:
each `#Preview` compiles to a type conforming to `PreviewRegistry`, and an
old-style preview conforms to `PreviewProvider`, and Swift keeps those
protocol names in the binary's metadata even when it strips symbols. A
binary that mentions either has preview code in it. Exits 1 if any does,
and 2 if a binary is missing, so a wrong path can't pass.
Run from the repo root.
"""

import sys

MARKERS = (b"PreviewRegistry", b"PreviewProvider")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    found = False
    for path in sys.argv[1:]:
        try:
            with open(path, "rb") as f:
                binary = f.read()
        except OSError as error:
            print(f"Can't read {path}: {error.strerror}")
            return 2
        hits = [marker.decode() for marker in MARKERS if marker in binary]
        if hits:
            found = True
            print(f"{path}: has SwiftUI preview code ({', '.join(hits)})")
    if not found:
        print(f"No SwiftUI preview code in the {len(sys.argv) - 1} release binaries checked.")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
