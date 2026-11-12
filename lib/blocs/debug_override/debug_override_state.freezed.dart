// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'debug_override_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DebugOverrideState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DebugOverrideState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DebugOverrideState()';
}


}

/// @nodoc
class $DebugOverrideStateCopyWith<$Res>  {
$DebugOverrideStateCopyWith(DebugOverrideState _, $Res Function(DebugOverrideState) __);
}


/// Adds pattern-matching-related methods to [DebugOverrideState].
extension DebugOverrideStatePatterns on DebugOverrideState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DebugOverrideHidden value)?  hidden,TResult Function( DebugOverrideShown value)?  shown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DebugOverrideHidden() when hidden != null:
return hidden(_that);case DebugOverrideShown() when shown != null:
return shown(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DebugOverrideHidden value)  hidden,required TResult Function( DebugOverrideShown value)  shown,}){
final _that = this;
switch (_that) {
case DebugOverrideHidden():
return hidden(_that);case DebugOverrideShown():
return shown(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DebugOverrideHidden value)?  hidden,TResult? Function( DebugOverrideShown value)?  shown,}){
final _that = this;
switch (_that) {
case DebugOverrideHidden() when hidden != null:
return hidden(_that);case DebugOverrideShown() when shown != null:
return shown(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  hidden,TResult Function( ReadingOverride mode)?  shown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DebugOverrideHidden() when hidden != null:
return hidden();case DebugOverrideShown() when shown != null:
return shown(_that.mode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  hidden,required TResult Function( ReadingOverride mode)  shown,}) {final _that = this;
switch (_that) {
case DebugOverrideHidden():
return hidden();case DebugOverrideShown():
return shown(_that.mode);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  hidden,TResult? Function( ReadingOverride mode)?  shown,}) {final _that = this;
switch (_that) {
case DebugOverrideHidden() when hidden != null:
return hidden();case DebugOverrideShown() when shown != null:
return shown(_that.mode);case _:
  return null;

}
}

}

/// @nodoc


class DebugOverrideHidden implements DebugOverrideState {
  const DebugOverrideHidden();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DebugOverrideHidden);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DebugOverrideState.hidden()';
}


}




/// @nodoc


class DebugOverrideShown implements DebugOverrideState {
  const DebugOverrideShown(this.mode);
  

 final  ReadingOverride mode;

/// Create a copy of DebugOverrideState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebugOverrideShownCopyWith<DebugOverrideShown> get copyWith => _$DebugOverrideShownCopyWithImpl<DebugOverrideShown>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DebugOverrideShown&&(identical(other.mode, mode) || other.mode == mode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,mode);
}

@override
String toString() {
    return 'DebugOverrideState.shown(mode: $mode)';
}


}

/// @nodoc
abstract mixin class $DebugOverrideShownCopyWith<$Res> implements $DebugOverrideStateCopyWith<$Res> {
  factory $DebugOverrideShownCopyWith(DebugOverrideShown value, $Res Function(DebugOverrideShown) _then) = _$DebugOverrideShownCopyWithImpl;
@useResult
$Res call({
 ReadingOverride mode
});




}
/// @nodoc
class _$DebugOverrideShownCopyWithImpl<$Res>
    implements $DebugOverrideShownCopyWith<$Res> {
  _$DebugOverrideShownCopyWithImpl(this._self, this._then);

  final DebugOverrideShown _self;
  final $Res Function(DebugOverrideShown) _then;

/// Create a copy of DebugOverrideState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mode = null,}) {
  return _then(DebugOverrideShown(
null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ReadingOverride,
  ));
}


}

// dart format on
