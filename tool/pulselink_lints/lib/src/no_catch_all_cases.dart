import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';

/// Flags a catch-all case (`default:`, `_`, `final x`, `Object()` and the
/// like) in a switch on a closed type: an enum, `bool`, a sealed class, or a
/// nullable or record type made only of those.
///
/// The compiler already makes those switches cover every case. A catch-all
/// defeats that: when a new enum value or sealed subclass is added later, it
/// falls into the catch-all silently instead of being a compile error at
/// every switch that needs to handle it.
///
/// A case with a `when` guard isn't a catch-all: the compiler doesn't count
/// guarded cases towards covering every case.
class NoCatchAllCases extends AnalysisRule {
  new()
    : super(
        name: 'no_catch_all_cases',
        description:
            "Don't use a catch-all case when switching on an enum, bool or "
            'sealed type.',
      );

  static const LintCode code = LintCode(
    'no_catch_all_cases',
    "Don't use a catch-all case when switching on an enum, bool or sealed "
        'type.',
    correctionMessage:
        'List each case, so a new value or subclass is a compile error here '
        "instead of falling into the catch-all. If it's truly needed, add a "
        "comment saying why, then '// ignore: pulselink_lints/no_catch_all_cases'.",
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context.typeSystem);
    registry
      ..addSwitchStatement(this, visitor)
      ..addSwitchExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  new(this.rule, this.typeSystem);

  final AnalysisRule rule;
  final TypeSystem typeSystem;

  @override
  void visitSwitchStatement(SwitchStatement node) {
    final scrutineeType = _closedScrutineeType(node.expression);
    if (scrutineeType == null) {
      return;
    }
    for (final member in node.members) {
      switch (member) {
        case SwitchDefault():
          rule.reportAtToken(member.keyword);
        case SwitchPatternCase(:final guardedPattern):
          _checkCase(guardedPattern, scrutineeType);
        case SwitchCase():
          // A constant case (pre-patterns syntax) never matches everything.
          break;
      }
    }
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    final scrutineeType = _closedScrutineeType(node.expression);
    if (scrutineeType == null) {
      return;
    }
    for (final switchCase in node.cases) {
      _checkCase(switchCase.guardedPattern, scrutineeType);
    }
  }

  void _checkCase(GuardedPattern guardedPattern, DartType scrutineeType) {
    if (guardedPattern.whenClause != null) {
      return;
    }
    final pattern = guardedPattern.pattern;
    if (_matchesEverything(pattern, scrutineeType)) {
      rule.reportAtNode(pattern);
    }
  }

  /// The scrutinee's type without `?`, if it's closed; otherwise null.
  DartType? _closedScrutineeType(Expression scrutinee) {
    final type = scrutinee.staticType;
    if (type == null) {
      return null;
    }
    final nonNull = typeSystem.promoteToNonNull(
      typeSystem.resolveToBound(type),
    );
    return _isClosed(nonNull) ? nonNull : null;
  }

  bool _isClosed(DartType type) {
    if (type.isDartCoreBool) {
      return true;
    }
    return switch (type) {
      InterfaceType(:final element) =>
        element is EnumElement || (element is ClassElement && element.isSealed),
      RecordType(:final positionalFields, :final namedFields) =>
        positionalFields.every((field) => _isClosedField(field.type)) &&
            namedFields.every((field) => _isClosedField(field.type)),
      _ => false,
    };
  }

  bool _isClosedField(DartType type) =>
      _isClosed(typeSystem.promoteToNonNull(typeSystem.resolveToBound(type)));

  /// Whether [pattern] matches every non-null value of [scrutineeType].
  ///
  /// Only top-level forms count: a pattern that destructures fields, such as
  /// `Reading(isStale: _)`, still names one case.
  bool _matchesEverything(DartPattern pattern, DartType scrutineeType) {
    return switch (pattern) {
      WildcardPattern(:final type) || DeclaredVariablePattern(:final type) =>
        _covers(type?.type, scrutineeType),
      ObjectPattern(:final type, :final fields) =>
        fields.isEmpty && _covers(type.type, scrutineeType),
      ParenthesizedPattern(:final pattern) ||
      NullCheckPattern(:final pattern) ||
      NullAssertPattern(
        :final pattern,
      ) => _matchesEverything(pattern, scrutineeType),
      LogicalOrPattern(:final leftOperand, :final rightOperand) =>
        _matchesEverything(leftOperand, scrutineeType) ||
            _matchesEverything(rightOperand, scrutineeType),
      _ => false,
    };
  }

  /// Whether a pattern typed [patternType] (null when untyped) matches every
  /// non-null value of [scrutineeType].
  bool _covers(DartType? patternType, DartType scrutineeType) =>
      patternType == null || typeSystem.isSubtypeOf(scrutineeType, patternType);
}
