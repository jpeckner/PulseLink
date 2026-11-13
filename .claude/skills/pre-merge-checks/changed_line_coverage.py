#!/usr/bin/env python3
"""Report which lines the branch added or changed in lib/ that no test runs.

Usage: changed_line_coverage.py [lcov file, default coverage/lcov.info] [base-ref, default develop]

Reads the lcov file written by `flutter test --coverage` and the branch's diff
against the merge base with base-ref. Generated files are skipped. Lines lcov
doesn't list (comments, declarations, blank lines) aren't executable and
don't count.

A file the branch changed that isn't in the report at all is listed too: no
test loads it, or it has nothing executable (only declarations, as in freezed
source files), so check which.

Informational: always exits 0 unless the input is missing.
Run from the repo root.
"""

import collections
import re
import subprocess
import sys

HUNK = re.compile(r"^@@ -\S+ \+(\d+)(?:,(\d+))? @@")
GENERATED = (".freezed.dart", ".g.dart")


def changed_lines(base):
    """Map each lib/ Dart file the branch changed to the line numbers it added or changed."""
    diff = subprocess.run(
        ["git", "diff", "-U0", f"{base}...HEAD", "--", "lib/*.dart"],
        check=True, capture_output=True, text=True,
    ).stdout
    lines = collections.defaultdict(set)
    path = None
    for line in diff.splitlines():
        if line.startswith("+++ "):
            path = None if line == "+++ /dev/null" else line[len("+++ b/"):]
            if path and path.endswith(GENERATED):
                path = None
        elif path and (match := HUNK.match(line)):
            start, count = int(match.group(1)), int(match.group(2) or 1)
            lines[path].update(range(start, start + count))
    return lines


def coverage(lcov_path):
    """Map each file in the lcov report to {line: hit count}."""
    hits = collections.defaultdict(dict)
    path = None
    with open(lcov_path, encoding="utf-8") as lcov:
        for raw in lcov:
            line = raw.strip()
            if line.startswith("SF:"):
                path = line[3:]
                # flutter test writes paths relative to the package root, but
                # other tools write absolute ones.
                if "/lib/" in path and not path.startswith("lib/"):
                    path = "lib/" + path.split("/lib/", 1)[1]
            elif line.startswith("DA:") and path:
                number, count = line[3:].split(",")[:2]
                hits[path][int(number)] = int(count)
            elif line == "end_of_record":
                path = None
    return hits


def ranges(numbers):
    """Compress [1, 2, 3, 7] into '1-3, 7'."""
    out, start, prev = [], None, None
    for n in sorted(numbers):
        if start is None:
            start = prev = n
        elif n == prev + 1:
            prev = n
        else:
            out.append(f"{start}-{prev}" if start != prev else f"{start}")
            start = prev = n
    if start is not None:
        out.append(f"{start}-{prev}" if start != prev else f"{start}")
    return ", ".join(out)


def main():
    if len(sys.argv) > 3:
        print(__doc__)
        return 2
    lcov_path = sys.argv[1] if len(sys.argv) > 1 else "coverage/lcov.info"
    base = sys.argv[2] if len(sys.argv) > 2 else "develop"

    branch = changed_lines(base)
    hits = coverage(lcov_path)

    total = covered = 0
    print("== Changed lines in lib/ that no test runs")
    for path in sorted(branch):
        if path not in hits:
            print(f"{path}: not in the coverage report (no test loads it, or it has no executable lines)")
            continue
        executable = {n for n in branch[path] if n in hits[path]}
        missed = {n for n in executable if hits[path][n] == 0}
        total += len(executable)
        covered += len(executable) - len(missed)
        if missed:
            print(f"{path}: lines {ranges(missed)}")
    percent = f"{100 * covered / total:.0f}%" if total else "n/a"
    print(f"== Changed executable lines covered: {covered}/{total} ({percent})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
