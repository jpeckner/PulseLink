// test_reflective_loader finds test cases by their `test_` prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:pulselink_lints/src/no_assertions.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoAssertionsTest);
  });
}

@reflectiveTest
class NoAssertionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoAssertions();
    super.setUp();
  }

  /// Expects one lint, on the first occurrence of [flagged] in [code].
  Future<void> _expectLint(String code, String flagged) {
    final offset = code.indexOf(flagged);
    expect(offset, isNonNegative, reason: '"$flagged" not in the code');
    return assertDiagnostics(code, [lint(offset, flagged.length)]);
  }

  // Flagged.

  Future<void> test_nullAssertion_expression() =>
      _expectLint('int f(int? x) => x!;\n', '!');

  Future<void> test_nullAssertion_pattern() => _expectLint('''
int f(int? x) {
  final (y!, _) = (x, 0);
  return y;
}
''', '!');

  Future<void> test_cast_downcast() =>
      _expectLint('int f(Object o) => o as int;\n', 'o as int');

  Future<void> test_cast_fromDynamic() =>
      _expectLint('int f(dynamic o) => o as int;\n', 'o as int');

  Future<void> test_cast_pattern() => _expectLint('''
int f(Object o) {
  final (x as int, _) = (o, 0);
  return x;
}
''', 'x as int');

  Future<void> test_late_fieldWithoutInitializer() => _expectLint('''
class C {
  late int value;
}
''', 'value');

  Future<void> test_late_localWithoutInitializer() => _expectLint('''
int f() {
  late int count;
  count = 1;
  return count;
}
''', 'count');

  Future<void> test_assert_statement() => _expectLint('''
void f(int x) {
  assert(x > 0);
}
''', 'assert');

  Future<void> test_assert_initializer() => _expectLint('''
class C {
  C(int x) : assert(x > 0);
}
''', 'assert');

  Future<void> test_assert_freezedAnnotation() => _expectLint('''
class Assert {
  const Assert(this.condition);
  final String condition;
}

@Assert('x > 0')
class C {}
''', "@Assert('x > 0')");

  Future<void> test_throw_argumentError() => _expectLint('''
void f() {
  throw ArgumentError('bad');
}
''', "throw ArgumentError('bad')");

  Future<void> test_throw_errorInExpression() => _expectLint(
    "int f() => throw ArgumentError('bad');\n",
    "throw ArgumentError('bad')",
  );

  Future<void> test_throw_errorSubclass() => _expectLint('''
class MyError extends Error {}

void f() {
  throw MyError();
}
''', 'throw MyError()');

  Future<void> test_sdk_firstOnList() =>
      _expectLint('int f(List<int> l) => l.first;\n', 'l.first');

  Future<void> test_sdk_firstOnIterable() =>
      _expectLint('int f(Iterable<int> i) => i.first;\n', 'i.first');

  Future<void> test_sdk_firstOnPropertyAccess() =>
      _expectLint('int f(List<List<int>> l) => l[0].first;\n', 'l[0].first');

  Future<void> test_sdk_firstNullAware() =>
      _expectLint('int? f(List<int>? l) => l?.first;\n', 'l?.first');

  Future<void> test_sdk_elementAt() => _expectLint(
    'int f(Iterable<int> i) => i.elementAt(1);\n',
    'i.elementAt(1)',
  );

  Future<void> test_sdk_firstWhereWithoutOrElse() => _expectLint(
    'int f(List<int> l) => l.firstWhere((x) => x > 1);\n',
    'l.firstWhere((x) => x > 1)',
  );

  Future<void> test_sdk_intParse() =>
      _expectLint('int f(String s) => int.parse(s);\n', 'int.parse(s)');

  Future<void> test_sdk_doubleParse() => _expectLint(
    'double f(String s) => double.parse(s);\n',
    'double.parse(s)',
  );

  // Not flagged.
  Future<void> test_sdk_firstWhereWithOrElse() => assertNoDiagnostics(
    'int f(List<int> l) => l.firstWhere((x) => x > 1, orElse: () => 0);\n',
  );

  Future<void> test_sdk_tryParse() =>
      assertNoDiagnostics('int? f(String s) => int.tryParse(s);\n');

  Future<void> test_sdk_firstOnNonIterable() => assertNoDiagnostics('''
class Pair {
  int get first => 1;
}

int f(Pair p) => p.first;
''');

  Future<void> test_sdk_ownStaticParse() => assertNoDiagnostics('''
class Code {
  static int parse(String s) => s.length;
}

int f(String s) => Code.parse(s);
''');

  Future<void> test_notNullAssertion_prefixNot() =>
      assertNoDiagnostics('bool f(bool b) => !b;\n');

  Future<void> test_notNullAssertion_notEquals() =>
      assertNoDiagnostics('bool f(int? x) => x != null;\n');

  Future<void> test_typeCheckPattern() => assertNoDiagnostics('''
int f(Object o) => switch (o) {
  final int i => i,
  _ => 0,
};
''');

  Future<void> test_late_withInitializer() => assertNoDiagnostics('''
int compute() => 1;

class C {
  late final int value = compute();
}
''');

  Future<void> test_importPrefix() => assertNoDiagnostics(
    "import 'dart:math' as math;\n\nnum f() => math.pi;\n",
  );

  Future<void> test_throw_exception() => assertNoDiagnostics('''
class MyException implements Exception {}

void f() {
  throw MyException();
}
''');

  Future<void> test_rethrow() => assertNoDiagnostics('''
void f(void Function() g) {
  try {
    g();
  } on Exception {
    rethrow;
  }
}
''');

  Future<void> test_testDirectoryIsExempt() async {
    final path = '$testPackageTestPath/a_test.dart';
    newFile(path, '''
int f(int? x, Object o) {
  assert(x != null);
  return x! + (o as int);
}
''');
    await assertNoDiagnosticsInFile(path);
  }
}
