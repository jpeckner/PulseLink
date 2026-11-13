import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:pulselink_lints/src/closed_types.dart';

/// Flags a partial test of a closed type (an enum, `bool`, a sealed class, or
/// a nullable or record type made only of those):
///
/// - `if (x case P)`, as a statement or a collection element, when `P`
///   doesn't match every non-null value of `x`;
/// - `x is T` and `x is! T`, when `T` doesn't cover every non-null value.
///
/// Those name some cases and silently skip the rest, so a new enum value or
/// sealed subclass falls through without a compile error. A switch that lists
/// every case doesn't. A plain null check (`if (x case final y?)`, or
/// `x is Sealed` on a `Sealed?`) isn't flagged: it covers every case.
class UseSwitchOnClosedTypes extends AnalysisRule {
  new()
    : super(
        name: 'use_switch_on_closed_types',
        description:
            "Don't test an enum, bool or sealed type with `if (x case ...)` "
            'or `is`.',
      );

  static const LintCode code = LintCode(
    'use_switch_on_closed_types',
    "Don't test an enum, bool or sealed type with `if (x case ...)` or `is`.",
    correctionMessage:
        'Use a switch that lists every case, with an explicit do-nothing case '
        'where one applies, so a new value or subclass is a compile error here '
        "instead of being skipped. If it's truly needed, add a comment saying "
        "why, then '// ignore: pulselink_lints/use_switch_on_closed_types'.",
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, ClosedTypes(context.typeSystem));
    registry
      ..addIfStatement(this, visitor)
      ..addIfElement(this, visitor)
      ..addIsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  new(this.rule, this.closedTypes);

  final AnalysisRule rule;
  final ClosedTypes closedTypes;

  @override
  void visitIfStatement(IfStatement node) =>
      _checkIfCase(node.expression, node.caseClause);

  @override
  void visitIfElement(IfElement node) =>
      _checkIfCase(node.expression, node.caseClause);

  @override
  void visitIsExpression(IsExpression node) {
    final type = closedTypes.closedNonNull(node.expression.staticType);
    if (type != null && !closedTypes.covers(node.type.type, type)) {
      rule.reportAtNode(node);
    }
  }

  void _checkIfCase(Expression scrutinee, CaseClause? caseClause) {
    if (caseClause == null) {
      return;
    }
    final type = closedTypes.closedNonNull(scrutinee.staticType);
    if (type == null) {
      return;
    }
    // A guard makes even an everything-matching pattern partial.
    final guardedPattern = caseClause.guardedPattern;
    if (guardedPattern.whenClause != null ||
        !closedTypes.matchesEverything(guardedPattern.pattern, type)) {
      rule.reportAtNode(caseClause);
    }
  }
}
