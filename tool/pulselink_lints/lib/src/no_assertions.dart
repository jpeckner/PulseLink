// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';

/// Flags code that fails at runtime when the programmer got something wrong,
/// which PulseLink's "No assertions" rule forbids outside tests:
///
/// - the null-assertion operator `!`, in an expression or a pattern;
/// - an `as` cast, in an expression or a pattern, that can fail: one whose
///   value's static type isn't already the target type or a subtype of it;
/// - a `late` variable without an initializer, which throws if it's read
///   before it's set (`late` with an initializer is just lazy, so it's fine);
/// - `assert`, in a statement or an initializer list, and freezed's
///   `@Assert` annotation;
/// - throwing an [Error] (`ArgumentError`, `StateError`,
///   `UnimplementedError` and the like). Dart uses errors for bugs; bad input
///   should get a typed result or null instead. Throwing an `Exception` isn't
///   flagged: the error-handling rule covers those;
/// - SDK calls that throw where Swift's equivalents return an optional:
///   `.first`, `.last`, `.single`, `.reduce` and `.elementAt` on an
///   `Iterable`, which throw on an empty one; `.firstWhere`, `.lastWhere` and
///   `.singleWhere` without `orElse`, which throw when nothing matches; and
///   `int.parse` and the other core `parse` methods, which throw on bad input.
///   Each has a version that returns null instead.
///
/// Files in a test directory are skipped, since the rule exempts tests.
class NoAssertions extends AnalysisRule {
  new()
    : super(
        name: 'no_assertions',
        description: "Don't write code that fails at runtime on a bug.",
      );

  static const LintCode code = LintCode(
    'no_assertions',
    'Avoid {0}: a bug here fails at runtime, not at compile time.',
    correctionMessage:
        "{1} If there's truly no alternative, get sign-off, add a comment "
        "saying why, then '// ignore: pulselink_lints/no_assertions'.",
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
    final visitor = _Visitor(this, context.typeSystem, context.typeProvider);
    registry
      ..addPostfixExpression(this, visitor)
      ..addNullAssertPattern(this, visitor)
      ..addAsExpression(this, visitor)
      ..addCastPattern(this, visitor)
      ..addVariableDeclarationList(this, visitor)
      ..addAssertStatement(this, visitor)
      ..addAssertInitializer(this, visitor)
      ..addAnnotation(this, visitor)
      ..addThrowExpression(this, visitor)
      ..addPrefixedIdentifier(this, visitor)
      ..addPropertyAccess(this, visitor)
      ..addMethodInvocation(this, visitor);
  }
}

/// One kind of runtime failure: what it is (completing "Avoid ..."), and
/// what to do instead.
enum _Kind {
  nullAssertion(
    'the null-assertion operator `!`',
    'Handle null instead: an if-case, `?.`, `??`, or a type that '
        "can't be null.",
  ),
  cast(
    'an `as` cast to a narrower type',
    'Match the type instead (`if (x case T t)` or a switch), so the other '
        'types are handled.',
  ),
  lateWithoutInitializer(
    'a `late` variable without an initializer',
    'Initialize it where it is declared, pass it in through the '
        'constructor, or make it nullable and handle null.',
  ),
  assertion(
    'an assertion',
    'Make the invalid state unrepresentable with a type, or return a typed '
        'result or null.',
  ),
  thrownError(
    'throwing an `Error`',
    'Return a typed result or null for bad input. An `Error` means a bug.',
  );

  new(this.what, this.instead);

  final String what;
  final String instead;
}

/// `Iterable` getters that throw on an empty collection, and what to use
/// instead.
const _throwingGetters = {
  'first': 'Use `.firstOrNull` and handle null.',
  'last': 'Use `.lastOrNull` and handle null.',
  'single': 'Use `.singleOrNull` and handle null.',
};

/// `Iterable` methods that throw on an empty collection, and what to use
/// instead.
const _throwingMethods = {
  'reduce': 'Use `.fold` with a starting value.',
  'elementAt': 'Use `.elementAtOrNull` and handle null.',
};

/// `Iterable` methods that throw when nothing matches, unless they're given
/// `orElse`, and what to use instead.
const _throwingSearches = {
  'firstWhere': 'Use `.where(...).firstOrNull` and handle null.',
  'lastWhere': 'Use `.where(...).lastOrNull` and handle null.',
  'singleWhere': 'Use `.where(...).singleOrNull` and handle null.',
};

/// dart:core types whose static `parse` throws on bad input. Each has a
/// `tryParse` that returns null instead.
const _parsingTypes = {'int', 'double', 'num', 'BigInt', 'DateTime', 'Uri'};

class _Visitor extends SimpleAstVisitor<void> {
  new(this.rule, this.typeSystem, this.typeProvider);

  final AnalysisRule rule;
  final TypeSystem typeSystem;
  final TypeProvider typeProvider;

  void _report(AstNode node, _Kind kind) =>
      _reportText(node, kind.what, kind.instead);

  void _reportText(AstNode node, String what, String instead) =>
      rule.reportAtNode(node, arguments: [what, instead]);

  void _reportToken(Token token, _Kind kind) =>
      rule.reportAtToken(token, arguments: [kind.what, kind.instead]);

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type == TokenType.BANG) {
      _reportToken(node.operator, _Kind.nullAssertion);
    }
  }

  @override
  void visitNullAssertPattern(NullAssertPattern node) =>
      _reportToken(node.operator, _Kind.nullAssertion);

  @override
  void visitAsExpression(AsExpression node) {
    if (!_alwaysSucceeds(node.expression.staticType, node.type.type)) {
      _report(node, _Kind.cast);
    }
  }

  @override
  void visitCastPattern(CastPattern node) {
    if (!_alwaysSucceeds(node.matchedValueType, node.type.type)) {
      _report(node, _Kind.cast);
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    final lateKeyword = node.lateKeyword;
    if (lateKeyword == null) {
      return;
    }
    for (final variable in node.variables) {
      if (variable.initializer == null) {
        _report(variable, _Kind.lateWithoutInitializer);
      }
    }
  }

  @override
  void visitAssertStatement(AssertStatement node) =>
      _reportToken(node.assertKeyword, _Kind.assertion);

  @override
  void visitAssertInitializer(AssertInitializer node) =>
      _reportToken(node.assertKeyword, _Kind.assertion);

  @override
  void visitAnnotation(Annotation node) {
    // Matched by name, so it's caught even where freezed_annotation isn't
    // resolved. A class of your own called Assert would be flagged too.
    if (node.name.name == 'Assert') {
      _report(node, _Kind.assertion);
    }
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (_isError(node.expression.staticType)) {
      _report(node, _Kind.thrownError);
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) =>
      _checkGetter(node, node.prefix.staticType, node.identifier.name);

  @override
  void visitPropertyAccess(PropertyAccess node) =>
      _checkGetter(node, node.realTarget.staticType, node.propertyName.name);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (_isCoreParse(node.methodName.element)) {
      final type = node.realTarget?.toSource() ?? '';
      _reportText(
        node,
        '`$type.parse`, which throws on bad input,',
        'Use `$type.tryParse` and handle null.',
      );
      return;
    }
    if (!_isIterable(node.realTarget?.staticType)) {
      return;
    }
    if (_throwingMethods[name] case final instead?) {
      _reportText(
        node,
        '`.$name`, which throws on an empty collection,',
        instead,
      );
    } else if (_throwingSearches[name] case final instead?) {
      final hasOrElse = node.argumentList.arguments.any(
        (argument) => switch (argument) {
          NamedArgument(:final name) => name.lexeme == 'orElse',
          // Argument's subtypes include the analyzer's own ArgumentImpl,
          // which can't be named outside the analyzer, so no switch here can
          // list every case.
          _ => false,
        },
      );
      if (!hasOrElse) {
        _reportText(
          node,
          '`.$name` without `orElse`, which throws when nothing matches,',
          instead,
        );
      }
    }
  }

  void _checkGetter(AstNode node, DartType? targetType, String name) {
    final instead = _throwingGetters[name];
    if (instead != null && _isIterable(targetType)) {
      _reportText(
        node,
        '`.$name`, which throws on an empty collection,',
        instead,
      );
    }
  }

  /// Whether [type], ignoring `?`, is an `Iterable`.
  bool _isIterable(DartType? type) =>
      type != null &&
      typeSystem.isSubtypeOf(
        typeSystem.promoteToNonNull(type),
        typeProvider.iterableDynamicType,
      );

  /// Whether [element] is the static `parse` of a dart:core type that has a
  /// `tryParse`.
  static bool _isCoreParse(Element? element) => switch (element) {
    final MethodElement method =>
      method.isStatic &&
          method.name == 'parse' &&
          _parsingTypes.contains(method.enclosingElement?.name) &&
          method.library.isDartCore,
    _ => false,
  };

  /// Whether casting a value of static type [from] to [to] can't fail.
  /// Unknown types count as able to fail.
  bool _alwaysSucceeds(DartType? from, DartType? to) =>
      from != null && to != null && typeSystem.isSubtypeOf(from, to);

  /// Whether [type] is `Error` from dart:core or a subclass of it.
  static bool _isError(DartType? type) => switch (type) {
    final InterfaceType interface =>
      _isCoreError(interface) || interface.allSupertypes.any(_isCoreError),
    _ => false,
  };

  static bool _isCoreError(InterfaceType type) =>
      type.element.name == 'Error' && (type.element.library.isDartCore);
}
