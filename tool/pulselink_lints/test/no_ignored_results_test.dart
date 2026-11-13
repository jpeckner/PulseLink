// test_reflective_loader finds test cases by their `test_` prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:pulselink_lints/src/no_ignored_results.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoIgnoredResultsTest);
  });
}

const _declarations = '''
import 'dart:async';

enum E { a, b }
sealed class S {}
final class A extends S {}
final class B extends S {}
E enumResult() => E.a;
S sealedResult() => A();
S? nullableResult() => null;
Future<S> futureResult() async => A();
bool boolResult() => true;
int intResult() => 1;
void use(Object? o) {}
class C {
  E method() => E.a;
}
''';

@reflectiveTest
class NoIgnoredResultsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoIgnoredResults();
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

  Future<void> test_statement_enum() => _expectLint('''
void f() {
  enumResult();
}
''', 'enumResult()');

  Future<void> test_statement_sealed() => _expectLint('''
void f() {
  sealedResult();
}
''', 'sealedResult()');

  Future<void> test_statement_nullableSealed() => _expectLint('''
void f() {
  nullableResult();
}
''', 'nullableResult()');

  Future<void> test_statement_method() => _expectLint('''
void f(C c) {
  c.method();
}
''', 'c.method()');

  Future<void> test_statement_await() => _expectLint('''
Future<void> f() async {
  await futureResult();
}
''', 'await futureResult()');

  Future<void> test_voidArrowFunction() =>
      _expectLint('void f() => sealedResult();\n', 'sealedResult()');

  Future<void> test_voidArrowMethod() => _expectLint('''
class D {
  void f() => enumResult();
}
''', 'enumResult()');

  Future<void> test_unawaited() => _expectLint('''
void f() {
  unawaited(futureResult());
}
''', 'unawaited(futureResult())');

  // Not flagged.

  Future<void> test_used() => _expectNoLint('''
void f() {
  use(sealedResult());
}
''');

  Future<void> test_discardedToWildcard() => _expectNoLint('''
void f() {
  final _ = sealedResult();
}
''');

  Future<void> test_assignment() => _expectNoLint('''
void f() {
  var e = E.b;
  e = enumResult();
  use(e);
}
''');

  Future<void> test_bool() => _expectNoLint('''
void f() {
  boolResult();
}
''');

  Future<void> test_int() => _expectNoLint('''
void f() {
  intResult();
}
''');

  Future<void> test_returningArrowFunction() =>
      _expectNoLint('S f() => sealedResult();\n');

  Future<void> test_unawaitedVoidFuture() => _expectNoLint('''
Future<void> g() async {}

void f() {
  unawaited(g());
}
''');
}
