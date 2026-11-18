// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'dart:io';

import 'package:find_unused_code/find_unused_code.dart';

const _usage = '''
Usage: dart run bin/find_unused_code.dart <package root>

Lists top-level declarations in <package root>/lib that nothing uses, and
those only tests use. Exits 1 if anything is unused.''';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(_usage);
    exitCode = 2;
    return;
  }
  final findings = await findUnusedCode(args.single);
  final unused = [
    for (final f in findings)
      if (f.usage == Usage.unused) f,
  ];
  final testsOnly = [
    for (final f in findings)
      if (f.usage == Usage.testsOnly) f,
  ];

  stdout.writeln('== Unused: ${unused.length}');
  unused.forEach(stdout.writeln);
  stdout.writeln('== Used only by tests: ${testsOnly.length}');
  testsOnly.forEach(stdout.writeln);
  if (unused.isNotEmpty) {
    exitCode = 1;
  }
}
