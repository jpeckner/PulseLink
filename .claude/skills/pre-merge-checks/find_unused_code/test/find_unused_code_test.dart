// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'dart:io';

import 'package:find_unused_code/find_unused_code.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Writes a package named `app` with [files] (path -> source) and returns
/// its findings as `'<usage> <path>:<line> <name>'` strings.
Future<List<String>> findingsFor(Map<String, String> files) async {
  final root = await Directory.systemTemp.createTemp('find_unused_code_');
  addTearDown(() => root.delete(recursive: true));
  final allFiles = {
    'pubspec.yaml': 'name: app\nenvironment:\n  sdk: ^3.14.0\n',
    '.dart_tool/package_config.json': '''
{"configVersion": 2, "packages": [{"name": "app", "rootUri": "../",
"packageUri": "lib/", "languageVersion": "3.14"}]}
''',
    ...files,
  };
  for (final MapEntry(key: path, value: source) in allFiles.entries) {
    final file = File(p.join(root.path, path));
    await file.parent.create(recursive: true);
    await file.writeAsString(source);
  }
  final findings = await findUnusedCode(root.path);
  return [for (final f in findings) '${f.usage.name} $f'];
}

void main() {
  test('reports a class nothing uses', () async {
    expect(
      await findingsFor({
        'lib/main.dart': 'void main() {}\n',
        'lib/a.dart': 'class Unused {}\n',
      }),
      ['unused lib/a.dart:1 Unused'],
    );
  });

  test(
    'a use from lib counts, through constructors, members and values',
    () async {
      expect(
        await findingsFor({
          'lib/main.dart': '''
import 'package:app/a.dart';

void main() {
  A();
  B.make();
  C.value.toString();
  topLevel;
  final d = 1.doubled;
  print(d);
}
''',
          'lib/a.dart': '''
class A {}
class B { B.make(); }
enum C { value }
const topLevel = 1;
extension Doubled on int { int get doubled => this * 2; }
''',
        }),
        isEmpty,
      );
    },
  );

  test('a use only from test/ is reported as tests-only', () async {
    expect(
      await findingsFor({
        'lib/main.dart': 'void main() {}\n',
        'lib/a.dart': 'int helper() => 1;\n',
        'test/a_test.dart': '''
import 'package:app/a.dart';

void main() => helper();
''',
      }),
      ['testsOnly lib/a.dart:1 helper'],
    );
  });

  test("a declaration's references to itself don't count", () async {
    expect(
      await findingsFor({
        'lib/main.dart': 'void main() {}\n',
        'lib/a.dart': '''
class Node {
  Node? next;
  static Node make() => Node();
}
''',
      }),
      ['unused lib/a.dart:1 Node'],
    );
  });

  test("generated files don't count as uses", () async {
    expect(
      await findingsFor({
        'lib/main.dart': 'void main() {}\n',
        'lib/a.dart': "part 'a.g.dart';\n\nclass A {}\n",
        'lib/a.g.dart': "part of 'a.dart';\n\nA makeA() => A();\n",
      }),
      ['unused lib/a.dart:3 A'],
    );
  });

  test("Pigeon's generated libraries are neither checked nor uses", () async {
    expect(
      await findingsFor({
        'lib/main.dart': 'void main() {}\n',
        'lib/a.dart': 'class A {}\n',
        'lib/api.pigeon.dart': '''
import 'package:app/a.dart';

const pigeonCodec = 1;
A makeA() => A();
''',
      }),
      ['unused lib/a.dart:1 A'],
    );
  });

  test('each variable in a declaration list is checked', () async {
    expect(
      await findingsFor({
        'lib/main.dart': '''
import 'package:app/a.dart';

void main() => print(used);
''',
        'lib/a.dart': 'const used = 1, unused = 2;\n',
      }),
      ['unused lib/a.dart:1 unused'],
    );
  });

  test('the keep comment leaves a declaration out', () async {
    expect(
      await findingsFor({
        'lib/main.dart': 'void main() {}\n',
        'lib/a.dart':
            '''
/// Docs.
// $keepMarker, needed by Milestone 3.
class Kept {}
''',
      }),
      isEmpty,
    );
  });

  test(
    'main in lib/main.dart is the entry point, elsewhere it is not',
    () async {
      expect(
        await findingsFor({
          'lib/main.dart': 'void main() {}\n',
          'lib/other.dart': 'void main() {}\n',
        }),
        ['unused lib/other.dart:1 main'],
      );
    },
  );
}
