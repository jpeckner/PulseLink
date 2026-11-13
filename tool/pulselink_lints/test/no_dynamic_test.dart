// test_reflective_loader finds test cases by their `test_` prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:pulselink_lints/src/no_dynamic.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDynamicTest);
  });
}

@reflectiveTest
class NoDynamicTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoDynamic();
    super.setUp();
  }

  /// Expects a lint on each occurrence of `dynamic` in [code].
  Future<void> _expectLints(String code) {
    final offsets = RegExp(r'\bdynamic\b').allMatches(code).map((m) => m.start);
    expect(offsets, isNotEmpty);
    return assertDiagnostics(code, [
      for (final offset in offsets) lint(offset, 'dynamic'.length),
    ]);
  }

  // Flagged.

  Future<void> test_parameter() => _expectLints('void f(dynamic d) {}\n');

  Future<void> test_returnType() => _expectLints('dynamic f() => 1;\n');

  Future<void> test_local() => _expectLints('''
void f() {
  final dynamic d = 1;
  print(d);
}
''');

  Future<void> test_field() => _expectLints('''
class C {
  dynamic d = 1;
}
''');

  Future<void> test_typeArgument() =>
      _expectLints('Map<String, dynamic> f() => {};\n');

  Future<void> test_listLiteralTypeArgument() =>
      _expectLints('List<Object?> f() => <dynamic>[];\n');

  Future<void> test_nestedTypeArgument() =>
      _expectLints('List<Map<String, dynamic>> f() => [];\n');

  Future<void> test_typedef() =>
      _expectLints('typedef Json = Map<String, dynamic>;\n');

  Future<void> test_functionTypeParameter() =>
      _expectLints('void f(void Function(dynamic) g) {}\n');

  Future<void> test_cast() =>
      _expectLints('Object? f(Object? o) => o as dynamic;\n');

  // Not flagged.

  Future<void> test_objectQuestion() => assertNoDiagnostics('''
Map<String, Object?> f(Object? o) => {'o': o};
''');

  Future<void> test_inferred() => assertNoDiagnostics('''
void f() {
  final values = [1, 2];
  print(values);
}
''');
}
