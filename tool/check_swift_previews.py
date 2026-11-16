#!/usr/bin/env python3
"""Checks that every SwiftUI preview is compiled into debug builds only.

Usage: check_swift_previews.py <folder or .swift file> [...]

CLAUDE.md's "SwiftUI previews" rule: preview code goes inside `#if DEBUG`,
which only the Debug build configuration defines, so none of it ships in a
release build. This reports each `#Preview`, `PreviewProvider` and
`PreviewModifier` that isn't inside an `#if DEBUG` branch, in SwiftLint's
format, so Xcode shows it inline. Exits 1 if it reports anything.

SwiftLint's regex rules can't tell whether code is inside an `#if`, hence
this script. tool/lint_native.sh runs it with SwiftLint, on the same
folders, and tool/check_native_lints.sh proves it reports. Pigeon's
generated `*.pigeon.swift` files are skipped.

Preview-only helpers (sample data, wrapper views) belong in the same
`#if DEBUG` block, but nothing marks them as preview code, so reviews
check those.
"""

import os
import re
import sys

RULE = "swiftui_previews_debug_only"
PREVIEW = re.compile(r"#Preview\b|\bPreviewProvider\b|\bPreviewModifier\b")
DIRECTIVE = re.compile(r"^\s*#(if|elseif|else|endif)\b(.*)$")


def swift_files(paths):
    for path in paths:
        if os.path.isfile(path):
            yield path
            continue
        for folder, _, names in os.walk(path):
            for name in sorted(names):
                if name.endswith(".swift") and not name.endswith(".pigeon.swift"):
                    yield os.path.join(folder, name)


def code_lines(source):
    """Yield (line number, line) with comments blanked out. Block comments
    are tracked across lines; string literals aren't parsed, which is fine
    for the names searched for."""
    in_block = False
    for number, line in enumerate(source.splitlines(), 1):
        code = []
        i = 0
        while i < len(line):
            if in_block:
                end = line.find("*/", i)
                if end == -1:
                    break
                in_block = False
                i = end + 2
            elif line.startswith("/*", i):
                in_block = True
                i += 2
            elif line.startswith("//", i):
                break
            else:
                code.append(line[i])
                i += 1
        yield number, "".join(code)


def findings(path):
    with open(path, encoding="utf-8") as f:
        source = f.read()
    # One entry per open #if: whether the branch being read is DEBUG.
    branches = []
    for number, line in code_lines(source):
        directive = DIRECTIVE.match(line)
        if directive:
            keyword, condition = directive[1], directive[2].strip()
            if keyword == "if":
                branches.append(condition == "DEBUG")
            elif keyword == "elseif" and branches:
                branches[-1] = condition == "DEBUG"
            elif keyword == "else" and branches:
                branches[-1] = False
            elif keyword == "endif" and branches:
                branches.pop()
            continue
        match = PREVIEW.search(line)
        if match and not any(branches):
            yield (
                f"{path}:{number}:{match.start() + 1}: error: SwiftUI preview code must be "
                f"inside #if DEBUG, so it never ships in a release build ({RULE})"
            )


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    reported = [line for path in swift_files(sys.argv[1:]) for line in findings(path)]
    for line in reported:
        print(line)
    return 1 if reported else 0


if __name__ == "__main__":
    sys.exit(main())
