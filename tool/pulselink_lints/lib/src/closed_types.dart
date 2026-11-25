// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';

/// Type questions the rules share. A closed type is one whose every value
/// the compiler knows: an enum, `bool`, a sealed class, or a record made only
/// of those. A switch on one must cover every case, so adding a value or
/// subclass is a compile error at every switch that must handle it.
final class ClosedTypes {
  new(this._typeSystem);

  final TypeSystem _typeSystem;

  /// [type] without `?` (and type parameters resolved to their bound), if
  /// that's closed; otherwise null.
  DartType? closedNonNull(DartType? type) {
    if (type == null) {
      return null;
    }
    final nonNull = _nonNull(type);
    return _isClosed(nonNull) ? nonNull : null;
  }

  /// Whether [pattern] matches every non-null value of [type].
  ///
  /// Only top-level forms count: a pattern that destructures fields, such as
  /// `Reading(isStale: _)`, still names one case.
  bool matchesEverything(DartPattern pattern, DartType type) {
    return switch (pattern) {
      WildcardPattern(type: final patternType) ||
      DeclaredVariablePattern(
        type: final patternType,
      ) => covers(patternType?.type, type),
      ObjectPattern(type: final patternType, :final fields) =>
        fields.isEmpty && covers(patternType.type, type),
      ParenthesizedPattern(:final pattern) ||
      NullCheckPattern(:final pattern) ||
      NullAssertPattern(:final pattern) => matchesEverything(pattern, type),
      LogicalOrPattern(:final leftOperand, :final rightOperand) =>
        matchesEverything(leftOperand, type) ||
            matchesEverything(rightOperand, type),
      _ => false,
    };
  }

  /// Whether a pattern or test typed [testedType] (null when untyped)
  /// matches every non-null value of [type].
  bool covers(DartType? testedType, DartType type) =>
      testedType == null || _typeSystem.isSubtypeOf(type, testedType);

  DartType _nonNull(DartType type) =>
      _typeSystem.promoteToNonNull(_typeSystem.resolveToBound(type));

  bool _isClosed(DartType type) {
    if (type.isDartCoreBool) {
      return true;
    }
    return switch (type) {
      InterfaceType(:final element) =>
        element is EnumElement || (element is ClassElement && element.isSealed),
      RecordType(:final positionalFields, :final namedFields) =>
        positionalFields.every((field) => _isClosed(_nonNull(field.type))) &&
            namedFields.every((field) => _isClosed(_nonNull(field.type))),
      _ => false,
    };
  }
}
