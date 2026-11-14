import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Flags an import of a Pigeon-generated library (`*.pigeon.dart`) from
/// outside its own folder, and any export of one.
///
/// Pigeon can't make a field private: every field it generates is public and
/// mutable, such as `BleBatteryLevel.percent`, a raw `int`. So the generated
/// types stay in the folder that holds them (and its subfolders), where a
/// data source converts them into domain types such as `BatteryLevel`, and
/// the rest of the app only sees those. Re-exporting one would hand its types
/// to every importer, so exports are flagged wherever they are.
///
/// Files in a test directory are skipped: tests drive the platform channels
/// with Pigeon's types.
class KeepPigeonImportsLocal extends AnalysisRule {
  new()
    : super(
        name: 'keep_pigeon_imports_local',
        description:
            "Use Pigeon's generated types only in the folder that holds them.",
      );

  static const LintCode code = LintCode(
    'keep_pigeon_imports_local',
    "Don't {0} `{1}` here: Pigeon's generated types stay in `{2}`.",
    correctionMessage:
        "Convert them to domain types in that folder's data source, and use "
        'those here.',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (context.isInTestDirectory) {
      return;
    }
    final importer = context.libraryElement?.uri;
    if (importer == null) {
      return;
    }
    final visitor = _Visitor(this, importer);
    registry
      ..addImportDirective(this, visitor)
      ..addExportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  new(this.rule, this.importer);

  final AnalysisRule rule;

  /// The library being analyzed.
  final Uri importer;

  @override
  void visitImportDirective(ImportDirective node) {
    // Null when the URI doesn't resolve, which the analyzer reports itself.
    final imported = node.libraryImport?.importedLibrary?.uri;
    if (imported == null || !_isPigeon(imported)) {
      return;
    }
    final folder = imported.resolve('.');
    if (!importer.toString().startsWith(folder.toString())) {
      _report(node, 'import', imported, folder);
    }
  }

  @override
  void visitExportDirective(ExportDirective node) {
    final exported = node.libraryExport?.exportedLibrary?.uri;
    if (exported != null && _isPigeon(exported)) {
      _report(node, 'export', exported, exported.resolve('.'));
    }
  }

  static bool _isPigeon(Uri library) => library.path.endsWith('.pigeon.dart');

  void _report(Directive node, String verb, Uri library, Uri folder) {
    rule.reportAtNode(
      node,
      arguments: [
        verb,
        library.pathSegments.lastOrNull ?? '$library',
        '$folder',
      ],
    );
  }
}
