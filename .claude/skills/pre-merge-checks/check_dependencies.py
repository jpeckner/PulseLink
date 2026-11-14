#!/usr/bin/env python3
"""List pubspec.yaml dependencies that nothing seems to use, or are in the wrong section.

Usage: check_dependencies.py [package root, default .]

- A `dependencies` entry is used if a file under lib/ imports `package:<name>/`.
  If only test/ imports it, it belongs in `dev_dependencies`.
- A `dev_dependencies` entry is used if lib/, test/, tool/ or bin/ imports it,
  or it is a tool this script knows how to recognize (code generators by their
  output files, lint packages by analysis_options.yaml).

Heuristic and informational: it reads the pubspec with a simple parser and
greps for imports. Exits 1 if it finds anything, so the caller notices.
Run from the repo root.
"""

import os
import re
import sys

# Dev tools used without being imported, and how to tell they're in use.
GENERATED_BY = {
    "build_runner": (".freezed.dart", ".g.dart"),
    "freezed": (".freezed.dart",),
    "json_serializable": (".g.dart",),
    "pigeon": (".pigeon.dart",),
}


def sections(pubspec):
    """Return {section: [package names]} for the two dependency sections."""
    result = {"dependencies": [], "dev_dependencies": []}
    current = None
    for line in pubspec.splitlines():
        if re.match(r"^\S", line):
            current = line.rstrip(":").strip() if line.rstrip().endswith(":") else None
        elif current in result and (match := re.match(r"^  ([a-z0-9_]+):", line)):
            result[current].append(match.group(1))
    return result


def dart_files(root, *directories):
    for directory in directories:
        for folder, dirnames, files in os.walk(os.path.join(root, directory)):
            dirnames[:] = [d for d in dirnames if not d.startswith(".")]
            for name in files:
                if name.endswith(".dart"):
                    yield os.path.join(folder, name)


def imported_packages(files):
    packages = set()
    for path in files:
        with open(path, encoding="utf-8") as f:
            packages.update(re.findall(r"""['"]package:([a-z0-9_]+)/""", f.read()))
    return packages


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    with open(os.path.join(root, "pubspec.yaml"), encoding="utf-8") as f:
        deps = sections(f.read())

    from_lib = imported_packages(dart_files(root, "lib"))
    from_dev = imported_packages(dart_files(root, "test", "tool", "bin", "integration_test"))
    all_files = [path for path in dart_files(root, "lib", "test")]
    analysis_options = ""
    options_path = os.path.join(root, "analysis_options.yaml")
    if os.path.exists(options_path):
        with open(options_path, encoding="utf-8") as f:
            analysis_options = f.read()

    problems = []
    for name in deps["dependencies"]:
        if name in from_lib:
            continue
        if name in from_dev:
            problems.append(f"{name}: in dependencies, but only test or tool code imports it (move to dev_dependencies?)")
        else:
            problems.append(f"{name}: in dependencies, but nothing imports it")

    for name in deps["dev_dependencies"]:
        if name in from_lib or name in from_dev:
            continue
        suffixes = GENERATED_BY.get(name)
        if suffixes and any(path.endswith(suffixes) for path in all_files):
            continue
        if f"package:{name}/" in analysis_options:
            continue
        problems.append(f"{name}: in dev_dependencies, but nothing seems to use it")

    for problem in problems:
        print(problem)
    if not problems:
        print("Every dependency is used.")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
