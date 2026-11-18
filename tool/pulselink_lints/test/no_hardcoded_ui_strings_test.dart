// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

// test_reflective_loader finds test cases by their `test_` prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:pulselink_lints/src/no_hardcoded_ui_strings.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoHardcodedUiStringsTest);
  });
}

/// Stand-ins for Flutter's widgets, which the test package doesn't have.
const _widgets = '''
class Text {
  const Text(String data, {String? semanticsLabel});
}

class Icon {
  const Icon(Object icon, {String? semanticLabel, String? key});
}

class Strings {
  String get title => 'from the ARB';
}
''';

@reflectiveTest
class NoHardcodedUiStringsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoHardcodedUiStrings();
    super.setUp();
  }

  /// Expects one lint, on [literal], in [code] (which follows the widgets).
  Future<void> _expectLintOn(String code, String literal) async {
    final source = '$_widgets\n$code\n';
    await assertDiagnostics(source, [
      lint(source.indexOf(literal), literal.length),
    ]);
  }

  /// Writes [code] (which follows the widgets) at [path] under lib/ and
  /// expects no lint in it.
  Future<void> _expectNoLintsAt(String path, String code) {
    final fullPath = '$testPackageLibPath/$path';
    newFile(fullPath, '$_widgets\n$code\n');
    return assertNoDiagnosticsInFile(fullPath);
  }

  // Flagged.

  Future<void> test_textData() =>
      _expectLintOn("const t = Text('Hello');", "'Hello'");

  Future<void> test_interpolatedTextData() =>
      _expectLintOn(r"Text f(int n) => Text('$n bpm');", r"'$n bpm'");

  Future<void> test_adjacentStrings() => _expectLintOn(
    "const t = Text('Hello, '\n    'world');",
    "'Hello, '\n    'world'",
  );

  Future<void> test_userFacingNamedArgument() => _expectLintOn(
    "Text f(String s) => Text(s, semanticsLabel: 'Heart rate');",
    "'Heart rate'",
  );

  Future<void> test_fallbackAfterQuestionQuestion() =>
      _expectLintOn("Text f(String? s) => Text(s ?? 'Unnamed');", "'Unnamed'");

  Future<void> test_branchOfAConditional() => _expectLintOn(
    "Icon f(bool b, String s) => Icon(1, semanticLabel: b ? s : 'Off');",
    "'Off'",
  );

  Future<void> test_parenthesized() =>
      _expectLintOn("const t = Text(('Hello'));", "'Hello'");

  // Not flagged.

  Future<void> test_textFromStrings() =>
      _expectNoLintsAt('ui/screen.dart', 'Text f(Strings s) => Text(s.title);');

  Future<void> test_otherNamedArgument() => _expectNoLintsAt(
    'ui/screen.dart',
    "Icon f() => Icon(1, key: 'battery');",
  );

  Future<void> test_emptyString() =>
      _expectNoLintsAt('ui/screen.dart', "const t = Text('');");

  Future<void> test_conditionIsNotText() => _expectNoLintsAt(
    'ui/screen.dart',
    "Text f(String s, String t) => Text(s == 'a' ? s : t);",
  );

  Future<void> test_notAnArgument() =>
      _expectNoLintsAt('ui/screen.dart', "const name = 'PulseLink';");

  Future<void> test_debugFolder() =>
      _expectNoLintsAt('ui/debug/buttons.dart', "const t = Text('Override');");

  Future<void> test_debugFile() =>
      _expectNoLintsAt('data/debug_source.dart', "const t = Text('Override');");

  Future<void> test_testDirectory() async {
    final path = '$testPackageRootPath/test/screen_test.dart';
    newFile(path, "$_widgets\nconst t = Text('Hello');\n");
    await assertNoDiagnosticsInFile(path);
  }
}
