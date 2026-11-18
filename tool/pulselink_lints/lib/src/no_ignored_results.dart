// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:pulselink_lints/src/closed_types.dart';

/// Flags a value of an enum or sealed type (or a nullable or record type made
/// only of those) that's thrown away:
///
/// - an expression statement, such as `source.start();` or
///   `await source.start();`;
/// - the body of a `void` arrow function, such as `void f() => g();`;
/// - the future passed to `unawaited`, which discards the value it completes
///   with.
///
/// Swift warns about any unused result unless the function opts out. Dart
/// only does for functions marked `@useResult`, so a typed result, such as
/// "Bluetooth is off", could be dropped without anyone noticing.
///
/// `bool` isn't counted, since results like `set.add(x)` are routinely
/// ignored. To discard a result on purpose, assign it to `_`
/// (`final _ = f();`) with a comment saying why.
class NoIgnoredResults extends AnalysisRule {
  new()
    : super(
        name: 'no_ignored_results',
        description:
            "Don't throw away a value of an enum or sealed type, such as a "
            'typed result.',
      );

  static const LintCode code = LintCode(
    'no_ignored_results',
    'This {0} is thrown away.',
    correctionMessage:
        'Handle every case with a switch. To discard it on purpose, write '
        "`final _ = ...;` with a comment saying why. If it's truly needed, "
        "add a comment, then '// ignore: pulselink_lints/no_ignored_results'.",
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
      ..addExpressionStatement(this, visitor)
      ..addExpressionFunctionBody(this, visitor)
      ..addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  new(this.rule, this.closedTypes);

  final AnalysisRule rule;
  final ClosedTypes closedTypes;

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    final expression = node.expression;
    // An assignment's value is the one just stored, and a cascade's is its
    // target; neither is a result being dropped.
    if (expression case AssignmentExpression() || CascadeExpression()) {
      return;
    }
    _check(expression, expression.staticType);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    final returnType = switch (node.parent) {
      MethodDeclaration(:final declaredFragment) ||
      FunctionExpression(
        :final declaredFragment,
      ) => declaredFragment?.element.returnType,
      _ => null,
    };
    if (returnType is VoidType) {
      _check(node.expression, node.expression.staticType);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final element = node.methodName.element;
    final isUnawaited =
        element is TopLevelFunctionElement &&
        element.name == 'unawaited' &&
        element.library.isDartAsync;
    if (!isUnawaited) {
      return;
    }
    final arguments = node.argumentList.arguments;
    if (arguments.isEmpty) {
      return;
    }
    // unawaited takes one positional argument. Argument's other subtypes
    // include the analyzer's own ArgumentImpl, which can't be named outside
    // the analyzer, hence the catch-all.
    final futureType = switch (arguments.first) {
      Expression(:final staticType) => staticType,
      _ => null,
    };
    if (futureType case InterfaceType(
      isDartAsyncFuture: true,
      typeArguments: [final valueType],
    )) {
      _check(node, valueType);
    }
  }

  void _check(AstNode node, DartType? type) {
    final closed = closedTypes.closedNonNull(type);
    if (closed != null && !closed.isDartCoreBool) {
      rule.reportAtNode(node, arguments: [closed.getDisplayString()]);
    }
  }
}
