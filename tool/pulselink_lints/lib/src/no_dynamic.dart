// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Flags every written `dynamic`: on a parameter, a return type, a variable,
/// a type argument (`Map<String, dynamic>`), a typedef, a cast or a type
/// test.
///
/// `dynamic` turns off type checking: any member can be called on it and
/// any value assigned from it, and mistakes surface at runtime. Swift has no
/// equivalent. `Object?` accepts the same values but needs a type check
/// before use, like Swift's `Any`, and the type checker treats the two the
/// same, so an override written with `dynamic` can use `Object?` instead.
///
/// The built-in `avoid_annotating_with_dynamic` lint only covers parameters.
/// Implicit `dynamic` (an untyped declaration that infers it) is caught by
/// the `strict-inference` and `strict-raw-types` language modes instead.
class NoDynamic extends AnalysisRule {
  new() : super(name: 'no_dynamic', description: "Don't write `dynamic`.");

  static const LintCode code = LintCode(
    'no_dynamic',
    "Don't write `dynamic`: it turns off type checking.",
    correctionMessage:
        'Use `Object?` or a precise type, so every use needs a type check '
        "first, as with Swift's `Any`. If it's truly needed, add a comment "
        "saying why, then '// ignore: pulselink_lints/no_dynamic'.",
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addNamedType(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  new(this.rule);

  final AnalysisRule rule;

  @override
  void visitNamedType(NamedType node) {
    // Checked by type, not just by name, so a class of your own that's
    // somehow called `dynamic` wouldn't count.
    if (node.name.lexeme == 'dynamic' && node.type is DynamicType) {
      rule.reportAtNode(node);
    }
  }
}
