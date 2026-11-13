import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;

/// Put this in a comment on the line above a declaration (after its doc
/// comment) to keep it out of the report, with a reason:
/// `// unused-code: keep, <reason>`.
const keepMarker = 'unused-code: keep';

enum Usage {
  /// Nothing outside the declaration itself refers to it.
  unused,

  /// Only code under test/ refers to it.
  testsOnly,
}

final class Finding {
  const new({
    required this.path,
    required this.line,
    required this.name,
    required this.usage,
  });

  /// Relative to the package root.
  final String path;
  final int line;
  final String name;
  final Usage usage;

  @override
  String toString() => '$path:$line $name';
}

/// Finds top-level declarations in [root]/lib that nothing uses, or that
/// only tests use.
///
/// Only top-level declarations are checked: classes, enums, mixins,
/// extensions, extension types, typedefs, functions and variables. A use of
/// any member (a constructor, method, field or enum value) counts as a use of
/// the declaration it belongs to. Unused private members are already reported
/// by `dart analyze` (`unused_element`, `unused_field`); unused public members
/// aren't checked.
///
/// Generated files (`*.freezed.dart`, `*.g.dart`) are neither checked nor
/// counted as uses, so a class used only by its own generated code is still
/// reported. `main` in lib/main.dart is the entry point and never reported.
Future<List<Finding>> findUnusedCode(String root) async {
  final packageRoot = p.normalize(p.absolute(root));
  final libDir = p.join(packageRoot, 'lib');
  final testDir = p.join(packageRoot, 'test');
  // One context for the whole package, so lib/ and test/ share one element
  // model. Separate contexts would give the same declaration two different
  // elements, and uses from tests wouldn't be matched.
  final collection = AnalysisContextCollection(includedPaths: [packageRoot]);
  try {
    final units = <ResolvedUnitResult>[];
    for (final context in collection.contexts) {
      for (final path in context.contextRoot.analyzedFiles()) {
        final inScope = p.isWithin(libDir, path) || p.isWithin(testDir, path);
        if (!inScope || !path.endsWith('.dart') || _isGenerated(path)) continue;
        final result = await context.currentSession.getResolvedUnit(path);
        if (result is ResolvedUnitResult) units.add(result);
      }
    }

    final declarations = <Element, _Declaration>{};
    for (final unit in units) {
      if (!p.isWithin(libDir, unit.path)) continue;
      for (final declaration in _declarationsIn(unit, packageRoot)) {
        declarations[declaration.element] = declaration;
      }
    }

    final collector = _ReferenceCollector(declarations, testDir);
    for (final unit in units) {
      collector.path = unit.path;
      unit.unit.accept(collector);
    }

    final findings = [
      for (final declaration in declarations.values)
        if (!declaration.usedFromLib)
          Finding(
            path: declaration.relativePath,
            line: declaration.line,
            name: declaration.name,
            usage: declaration.usedFromTest ? Usage.testsOnly : Usage.unused,
          ),
    ]..sort((a, b) => '$a'.compareTo('$b'));
    return findings;
  } finally {
    await collection.dispose();
  }
}

bool _isGenerated(String path) =>
    path.endsWith('.freezed.dart') || path.endsWith('.g.dart');

Iterable<_Declaration> _declarationsIn(
  ResolvedUnitResult unit,
  String packageRoot,
) sync* {
  final isMainFile = p.equals(unit.path, p.join(packageRoot, 'lib/main.dart'));
  for (final member in unit.unit.declarations) {
    if (_isKept(unit, member)) continue;
    // A variable declaration list declares each variable separately.
    final declared = switch (member) {
      TopLevelVariableDeclaration(:final variables) => [
        for (final variable in variables.variables)
          (variable.declaredFragment, variable.name.offset),
      ],
      _ => [
        (
          member.declaredFragment,
          member.firstTokenAfterCommentAndMetadata.offset,
        ),
      ],
    };
    for (final (fragment, offset) in declared) {
      if (fragment == null) continue;
      final element = fragment.element;
      final name = element.displayName.isEmpty
          ? '(unnamed extension)'
          : element.displayName;
      if (isMainFile && name == 'main') continue;
      yield _Declaration(
        element: element,
        name: name,
        path: unit.path,
        relativePath: p.relative(unit.path, from: packageRoot),
        line: unit.lineInfo
            .getLocation(fragment.nameOffset ?? offset)
            .lineNumber,
        start: member.offset,
        end: member.end,
      );
    }
  }
}

/// Whether the line above the declaration (after its doc comment and
/// annotations, if any) has the [keepMarker] comment.
bool _isKept(ResolvedUnitResult unit, CompilationUnitMember member) {
  final start = member.firstTokenAfterCommentAndMetadata.offset;
  // 0-based index of the line the declaration starts on.
  final line = unit.lineInfo.getLocation(start).lineNumber - 1;
  final from = unit.lineInfo.getOffsetOfLine(line == 0 ? 0 : line - 1);
  return unit.content.substring(from, start).contains(keepMarker);
}

final class _Declaration {
  new({
    required this.element,
    required this.name,
    required this.path,
    required this.relativePath,
    required this.line,
    required this.start,
    required this.end,
  });

  final Element element;
  final String name;
  final String path;
  final String relativePath;
  final int line;

  /// The declaration's own source range; references inside it don't count.
  final int start;
  final int end;

  bool usedFromLib = false;
  bool usedFromTest = false;
}

class _ReferenceCollector extends RecursiveAstVisitor<void> {
  new(this._declarations, this._testDir);

  final Map<Element, _Declaration> _declarations;
  final String _testDir;

  /// The file being visited.
  String path = '';

  void _record(Element? element, AstNode node) {
    final declaration = _declarations[_topLevel(element)];
    if (declaration == null) return;
    final isSelfReference =
        declaration.path == path &&
        node.offset >= declaration.start &&
        node.end <= declaration.end;
    if (isSelfReference) return;
    if (p.isWithin(_testDir, path)) {
      declaration.usedFromTest = true;
    } else {
      declaration.usedFromLib = true;
    }
  }

  /// The top-level declaration [element] belongs to: a class for its
  /// constructors and members, a variable for its getter and setter.
  static Element? _topLevel(Element? element) {
    var current = element is PropertyAccessorElement
        ? element.variable
        : element;
    while (current != null && current.enclosingElement is! LibraryElement) {
      current = current.enclosingElement;
    }
    return current;
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _record(node.element, node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _record(node.element, node);
    super.visitNamedType(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _record(node.element, node);
    super.visitConstructorName(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _record(node.element, node);
    super.visitBinaryExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _record(node.element, node);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _record(node.element, node);
    super.visitPostfixExpression(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _record(node.element, node);
    super.visitIndexExpression(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _record(node.element, node);
    _record(node.readElement, node);
    _record(node.writeElement, node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _record(node.element, node);
    super.visitExtensionOverride(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _record(node.element, node);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _record(node.element, node);
    super.visitRedirectingConstructorInvocation(node);
  }
}
