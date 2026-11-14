// test_reflective_loader finds test cases by their `test_` prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:pulselink_lints/src/use_switch_on_closed_types.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseSwitchOnClosedTypesTest);
  });
}

const _declarations = '''
enum E { a, b, c }
sealed class S {}
class A extends S { int x = 0; }
class B extends S {}
abstract class Open {}
class Sub extends Open {}
void use(Object? o) {}
''';

@reflectiveTest
class UseSwitchOnClosedTypesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseSwitchOnClosedTypes();
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

  // Flagged: if-case.

  Future<void> test_ifCase_sealedSubtype() => _expectLint('''
void f(S s) {
  if (s case A()) {
    use(s);
  }
}
''', 'case A()');

  Future<void> test_ifCase_sealedSubtypeWithFields() => _expectLint('''
void f(S s) {
  if (s case A(x: 1)) {
    use(s);
  }
}
''', 'case A(x: 1)');

  Future<void> test_ifCase_boundVariable() => _expectLint('''
void f(S s) {
  if (s case final A a) {
    use(a);
  }
}
''', 'case final A a');

  Future<void> test_ifCase_enumValue() => _expectLint('''
void f(E e) {
  if (e case E.a) {
    use(e);
  }
}
''', 'case E.a');

  Future<void> test_ifCase_bool() => _expectLint('''
void f(bool b) {
  if (b case true) {
    use(b);
  }
}
''', 'case true');

  Future<void> test_ifCase_nullableSealedSubtype() => _expectLint('''
void f(S? s) {
  if (s case A()) {
    use(s);
  }
}
''', 'case A()');

  Future<void> test_ifCase_recordOfEnums() => _expectLint('''
void f(E e1, E e2) {
  if ((e1, e2) case (E.a, _)) {
    use(e1);
  }
}
''', 'case (E.a, _)');

  Future<void> test_ifCase_guardedWildcard() => _expectLint('''
void f(S s, bool b) {
  if (s case _ when b) {
    use(s);
  }
}
''', 'case _ when b');

  Future<void> test_ifCase_collectionElement() =>
      _expectLint('List<int> f(S s) => [if (s case A()) 1];\n', 'case A()');

  // Flagged: is.

  Future<void> test_is_sealedSubtype() =>
      _expectLint('bool f(S s) => s is A;\n', 's is A');

  Future<void> test_isNot_sealedSubtype() =>
      _expectLint('bool f(S s) => s is! A;\n', 's is! A');

  Future<void> test_is_nullableSealedSubtype() =>
      _expectLint('bool f(S? s) => s is A;\n', 's is A');

  // Not flagged.

  Future<void> test_switch() => _expectNoLint('''
void f(S s) {
  switch (s) {
    case A():
      use(s);
    case B():
      break;
  }
}
''');

  Future<void> test_ifCase_nullCheck() => _expectNoLint('''
void f(S? s) {
  if (s case final x?) {
    use(x);
  }
}
''');

  Future<void> test_ifCase_openType() => _expectNoLint('''
void f(Open o) {
  if (o case Sub()) {
    use(o);
  }
}
''');

  Future<void> test_ifCase_nullableInt() => _expectNoLint('''
void f(int? i) {
  if (i case final n?) {
    use(n);
  }
}
''');

  Future<void> test_plainIf() => _expectNoLint('''
void f(bool b) {
  if (b) {
    use(b);
  }
}
''');

  Future<void> test_is_nullCheckOnNullableSealed() =>
      _expectNoLint('bool f(S? s) => s is S;\n');

  Future<void> test_is_onObject() =>
      _expectNoLint('bool f(Object o) => o is A;\n');

  Future<void> test_is_onOpenType() =>
      _expectNoLint('bool f(Open o) => o is Sub;\n');
}
