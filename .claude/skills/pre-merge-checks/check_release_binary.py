#!/usr/bin/env python3
"""Check that debug-only Dart code didn't make it into a release build.

Usage: check_release_binary.py <binary or .apk> [...]

Debug-only code is every Dart file under lib/ that is named `debug_*.dart` or
sits in a `debug/` folder. It must be reachable only from the
`if (!kReleaseMode)` branch of main(), so the release compiler drops it. This
script collects markers from those files (the names of the types they declare,
and their string literals of 8 or more characters that no other file uses)
and searches the compiled Dart code for them:

- iOS: build/ios/iphoneos/Runner.app/Frameworks/App.framework/App
- Android: build/app/outputs/flutter-apk/app-release.apk (its lib/*/libapp.so)

Dart's AOT compiler keeps the names of the classes it compiles in (unless the
build uses --obfuscate), so a marker found in the binary means debug code was
compiled into the release build. Exits 1 if any marker is found.
Run from the repo root.
"""

import os
import re
import sys
import zipfile

TYPE = re.compile(r"^\s*(?:abstract |sealed |final |base |interface |mixin )*(?:class|enum|mixin|extension type|extension)\s+([A-Za-z_]\w*)", re.M)
LITERAL = re.compile(r"""'([^'\\$\n]{8,})'|"([^"\\$\n]{8,})\"""")


def dart_files():
    """Yield (path, is_debug_only) for each hand-written Dart file under lib/."""
    for folder, _, files in os.walk("lib"):
        in_debug_folder = "debug" in folder.split(os.sep)
        for name in files:
            if name.endswith(".dart") and not name.endswith((".freezed.dart", ".g.dart")):
                yield os.path.join(folder, name), in_debug_folder or name.startswith("debug_")


def strings_and_types(path):
    """The type names a file declares and the string literals in its code."""
    with open(path, encoding="utf-8") as f:
        # Comments aren't compiled in, and their apostrophes confuse the
        # string pattern.
        source = re.sub(r"//.*", "", f.read())
    # Imports, exports and parts name files, not code that's compiled in.
    source = re.sub(r"^\s*(import|export|part)\b.*$", "", source, flags=re.M)
    literals = {single or double for single, double in LITERAL.findall(source)}
    return set(TYPE.findall(source)), literals


def markers():
    """Names and strings found only in debug-only files."""
    debug, shared = set(), set()
    for path, is_debug_only in dart_files():
        types, literals = strings_and_types(path)
        if is_debug_only:
            debug |= types | literals
        else:
            shared |= types | literals
    return sorted(debug - shared)


def binaries(path):
    """Yield (label, bytes) for each compiled Dart library in path."""
    if path.endswith(".apk"):
        with zipfile.ZipFile(path) as apk:
            for name in apk.namelist():
                if name.endswith("/libapp.so"):
                    yield f"{path}!{name}", apk.read(name)
    else:
        with open(path, "rb") as f:
            yield path, f.read()


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    wanted = markers()
    if not wanted:
        print("No debug-only Dart files under lib/, so nothing to check.")
        return 0
    print(f"Markers from debug-only code: {', '.join(wanted)}")

    leaks = []
    checked = 0
    for path in sys.argv[1:]:
        for label, data in binaries(path):
            checked += 1
            for marker in wanted:
                if marker.encode("utf-8") in data:
                    leaks.append(f"{label}: {marker}")
    if checked == 0:
        print("No compiled Dart code found in the given files.")
        return 2
    for leak in leaks:
        print(f"Debug-only code in a release build: {leak}")
    if not leaks:
        print(f"None of them are in the {checked} release binaries checked.")
    return 1 if leaks else 0


if __name__ == "__main__":
    sys.exit(main())
