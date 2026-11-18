// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

// test_reflective_loader finds test cases by their `test_` prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:pulselink_lints/src/no_catch_all_cases.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoCatchAllCasesTest);
  });
}

const _declarations = '''
enum E { a, b, c }
sealed class S {}
class A extends S { int x = 0; }
class B extends S {}
abstract class Open {}
''';

@reflectiveTest
class NoCatchAllCasesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoCatchAllCases();
    super.setUp();
  }

  /// Expects one lint, on the first occurrence of [flagged] in [body].
  Future<void> _expectLint(String body, String flagged) {
    final code = '$_declarations$body';
    final offset = code.indexOf(flagged, _declarations.length);
    expect(offset, isNonNegative, reason: '"$flagged" not in the code');
    return assertDiagnostics(code, [lint(offset, flagged.length)]);
  }

  Future<void> _expectNoLint(String body) =>
      assertNoDiagnostics('$_declarations$body');

  // Flagged.

  Future<void> test_enum_expressionWildcard() => _expectLint('''
int f(E e) => switch (e) { E.a => 1, _ => 2 };
''', '_');

  Future<void> test_enum_statementDefault() => _expectLint('''
void f(E e) {
  switch (e) {
    case E.a:
      return;
    default:
      return;
  }
}
''', 'default');

  Future<void> test_enum_statementWildcard() => _expectLint('''
void f(E e) {
  switch (e) {
    case E.a:
      return;
    case _:
      return;
  }
}
''', '_');

  Future<void> test_sealed_untypedVariable() => _expectLint('''
int f(S s) => switch (s) { A() => 1, final other => 2 };
''', 'final other');

  Future<void> test_sealed_supertypeWildcard() => _expectLint('''
int f(S s) => switch (s) { A() => 1, Object _ => 2 };
''', 'Object _');

  Future<void> test_sealed_objectPatternOfItsOwnType() => _expectLint('''
int f(S s) => switch (s) { A() => 1, S() => 2 };
''', 'S()');

  Future<void> test_sealed_logicalOrWithWildcard() => _expectLint('''
int f(S s) => switch (s) { A() || _ => 1 };
''', 'A() || _');

  Future<void> test_bool_wildcard() => _expectLint('''
int f(bool b) => switch (b) { true => 1, _ => 2 };
''', '_');

  Future<void> test_nullableEnum_wildcard() => _expectLint('''
int f(E? e) => switch (e) { null => 0, E.a => 1, _ => 2 };
''', '_');

  Future<void> test_recordOfClosedTypes_wildcard() => _expectLint('''
int f(E e, bool b) => switch ((e, b)) { (E.a, true) => 1, _ => 2 };
''', '_');

  Future<void> test_typeParameterBoundedByEnum_wildcard() => _expectLint('''
int f<T extends E>(T e) => switch (e) { E.a => 1, _ => 2 };
''', '_');

  // Not flagged.

  Future<void> test_enum_everyCaseListed() => _expectNoLint('''
int f(E e) => switch (e) { E.a => 1, E.b => 2, E.c => 3 };
''');

  Future<void> test_sealed_destructuringWildcardField() => _expectNoLint('''
int f(S s) => switch (s) { A(x: _) => 1, B() => 2 };
''');

  Future<void> test_guardedWildcard() => _expectNoLint('''
int f(E e, bool early) => switch (e) {
  _ when early => 0,
  E.a => 1,
  E.b => 2,
  E.c => 3,
};
''');

  Future<void> test_int_wildcard() => _expectNoLint('''
int f(int i) => switch (i) { 0 => 1, _ => 2 };
''');

  Future<void> test_nonSealedClass_wildcard() => _expectNoLint('''
int f(Open o) => switch (o) { _ => 1 };
''');

  Future<void> test_recordWithOpenField_wildcard() => _expectNoLint('''
int f(E e, int i) => switch ((e, i)) { (E.a, 0) => 1, _ => 2 };
''');
}
