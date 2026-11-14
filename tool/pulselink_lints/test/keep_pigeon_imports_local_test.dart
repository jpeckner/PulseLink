// test_reflective_loader finds test cases by their `test_` prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:pulselink_lints/src/keep_pigeon_imports_local.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(KeepPigeonImportsLocalTest);
  });
}

@reflectiveTest
class KeepPigeonImportsLocalTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = KeepPigeonImportsLocal();
    super.setUp();
    newFile('$testPackageLibPath/data/ble/api.pigeon.dart', 'class Event {}\n');
    newFile('$testPackageLibPath/data/ble/source.dart', 'class Source {}\n');
  }

  /// Writes [code] at [path] under lib/ and expects no lint in it.
  Future<void> _expectNoLintsAt(String path, String code) {
    final fullPath = '$testPackageLibPath/$path';
    newFile(fullPath, code);
    return assertNoDiagnosticsInFile(fullPath);
  }

  // Flagged.

  Future<void> test_importFromOutsideTheFolder() async {
    const directive = "import 'package:test/data/ble/api.pigeon.dart';";
    await assertDiagnostics('$directive\n\nEvent? e;\n', [
      lint(0, directive.length),
    ]);
  }

  Future<void> test_importFromAParentFolder() async {
    const directive = "import 'ble/api.pigeon.dart';";
    final path = '$testPackageLibPath/data/repository.dart';
    newFile(path, '$directive\n\nEvent? e;\n');
    await assertDiagnosticsInFile(path, [lint(0, directive.length)]);
  }

  Future<void> test_importFromASiblingFolder() async {
    const directive = "import '../ble/api.pigeon.dart';";
    final path = '$testPackageLibPath/data/watch/source.dart';
    newFile(path, '$directive\n\nEvent? e;\n');
    await assertDiagnosticsInFile(path, [lint(0, directive.length)]);
  }

  Future<void> test_importWithShow() async {
    const directive =
        "import 'package:test/data/ble/api.pigeon.dart' show Event;";
    await assertDiagnostics('$directive\n\nEvent? e;\n', [
      lint(0, directive.length),
    ]);
  }

  Future<void> test_exportFromOutsideTheFolder() async {
    const directive = "export 'package:test/data/ble/api.pigeon.dart';";
    await assertDiagnostics('$directive\n', [lint(0, directive.length)]);
  }

  Future<void> test_exportFromTheSameFolder() async {
    const directive = "export 'api.pigeon.dart';";
    final path = '$testPackageLibPath/data/ble/all.dart';
    newFile(path, '$directive\n');
    await assertDiagnosticsInFile(path, [lint(0, directive.length)]);
  }

  // Not flagged.

  Future<void> test_importFromTheSameFolder() => _expectNoLintsAt(
    'data/ble/strap.dart',
    "import 'api.pigeon.dart';\n\nEvent? e;\n",
  );

  Future<void> test_packageImportFromTheSameFolder() => _expectNoLintsAt(
    'data/ble/strap.dart',
    "import 'package:test/data/ble/api.pigeon.dart';\n\nEvent? e;\n",
  );

  Future<void> test_importFromASubfolder() => _expectNoLintsAt(
    'data/ble/scan/scanner.dart',
    "import '../api.pigeon.dart';\n\nEvent? e;\n",
  );

  Future<void> test_otherImportFromOutsideTheFolder() => assertNoDiagnostics(
    "import 'package:test/data/ble/source.dart';\n\nSource? s;\n",
  );

  Future<void> test_testDirectoryIsExempt() async {
    final path = '$testPackageTestPath/a_test.dart';
    newFile(path, '''
import 'package:test/data/ble/api.pigeon.dart';
export 'package:test/data/ble/api.pigeon.dart';

Event? e;
''');
    await assertNoDiagnosticsInFile(path);
  }
}
