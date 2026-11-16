import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Flags a string literal shown to the user: the text of a `Text` or
/// `SelectableText`, or a named argument that's user-facing text by
/// convention, such as `tooltip:`, `semanticLabel:`, `label:` or `title:`.
/// Interpolated and adjacent strings count, and so does a literal used as a
/// fallback (`name ?? 'Unnamed'`) or as either branch of a `? :`.
///
/// User-facing text goes in lib/l10n/app_en.arb, and the UI reads it through
/// the generated, typed AppLocalizations (`context.l10n.tryAgain`), so a
/// missing string is a compile error and the app can be translated later.
///
/// Skipped: tests, and debug-only code (files named `debug_*.dart` or in a
/// `debug` folder), which the release build drops. An empty string isn't
/// flagged.
class NoHardcodedUiStrings extends AnalysisRule {
  new()
    : super(
        name: 'no_hardcoded_ui_strings',
        description: "Don't hard-code text shown to the user.",
      );

  static const LintCode code = LintCode(
    'no_hardcoded_ui_strings',
    "Don't hard-code text shown to the user.",
    correctionMessage:
        'Add it to lib/l10n/app_en.arb and use `context.l10n`. If it truly '
        "isn't text for the user, add a comment saying why, then "
        "'// ignore: pulselink_lints/no_hardcoded_ui_strings'.",
  );

  /// Named arguments that hold user-facing text in Flutter's widgets.
  static const userFacingArguments = {
    'tooltip',
    'semanticLabel',
    'semanticsLabel',
    'semanticsValue',
    'label',
    'labelText',
    'hintText',
    'helperText',
    'errorText',
    'counterText',
    'prefixText',
    'suffixText',
    'title',
    'message',
    'text',
  };

  /// Widgets whose first positional argument is the text they show.
  static const textWidgets = {'Text', 'SelectableText'};

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (context.isInTestDirectory ||
        _isDebugOnly(context.definingUnit.file.path)) {
      return;
    }
    final visitor = _Visitor(this);
    registry
      ..addSimpleStringLiteral(this, visitor)
      ..addStringInterpolation(this, visitor)
      ..addAdjacentStrings(this, visitor);
  }

  static bool _isDebugOnly(String path) {
    final segments = path.split(RegExp(r'[/\\]'));
    return segments.contains('debug') ||
        (segments.lastOrNull?.startsWith('debug_') ?? false);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  new(this.rule);

  final AnalysisRule rule;

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.value.isNotEmpty) {
      _check(node);
    }
  }

  @override
  void visitStringInterpolation(StringInterpolation node) => _check(node);

  @override
  void visitAdjacentStrings(AdjacentStrings node) => _check(node);

  void _check(StringLiteral node) {
    // Only the outermost string: the parts of 'a' 'b', and a string inside
    // an interpolation, are checked as part of it.
    final parent = node.parent;
    if (parent is AdjacentStrings || parent is InterpolationExpression) {
      return;
    }
    final argument = _argumentHolding(node);
    if (argument != null && _isUserFacing(argument)) {
      rule.reportAtNode(node);
    }
  }

  /// The argument [node] is the value of, looking through parentheses,
  /// `??` and `? :`; null if it isn't an argument's value.
  static Argument? _argumentHolding(Expression node) {
    var current = node;
    while (true) {
      final parent = current.parent;
      switch (parent) {
        case ParenthesizedExpression():
          current = parent;
        case BinaryExpression(
          operator: Token(type: TokenType.QUESTION_QUESTION),
        ):
          current = parent;
        case ConditionalExpression(:final condition)
            when !identical(condition, current):
          current = parent;
        case NamedArgument():
          return parent;
        case ArgumentList():
          return current;
        default:
          return null;
      }
    }
  }

  static bool _isUserFacing(Argument argument) {
    if (argument is NamedArgument) {
      return NoHardcodedUiStrings.userFacingArguments.contains(
        argument.name.lexeme,
      );
    }
    // A positional argument: the first one of a Text or SelectableText.
    final arguments = argument.parent;
    final creation = arguments?.parent;
    if (arguments is! ArgumentList ||
        creation is! InstanceCreationExpression ||
        !identical(arguments.arguments.firstOrNull, argument)) {
      return false;
    }
    return NoHardcodedUiStrings.textWidgets.contains(
      creation.constructorName.type.name.lexeme,
    );
  }
}
