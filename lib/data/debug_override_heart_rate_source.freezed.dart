// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'debug_override_heart_rate_source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReadingOverride {

 Enum get condition;



@override
bool operator ==(Object other) {
  final _this = this as ReadingOverride;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingOverride&&(identical(other.condition, _this.condition) || other.condition == _this.condition));
}


@override
int get hashCode {
  final _this = this as ReadingOverride;
  return Object.hash(runtimeType,_this.condition);
}

@override
String toString() {
  final _this = this as ReadingOverride;
  return 'ReadingOverride(condition: ${_this.condition})';
}


}

/// @nodoc
class $ReadingOverrideCopyWith<$Res>  {
$ReadingOverrideCopyWith(ReadingOverride _, $Res Function(ReadingOverride) __);
}


/// Adds pattern-matching-related methods to [ReadingOverride].
extension ReadingOverridePatterns on ReadingOverride {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DetectingStrapOverride value)?  detectingStrap,TResult Function( NonDetectingStrapOverride value)?  nonDetectingStrap,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DetectingStrapOverride() when detectingStrap != null:
return detectingStrap(_that);case NonDetectingStrapOverride() when nonDetectingStrap != null:
return nonDetectingStrap(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DetectingStrapOverride value)  detectingStrap,required TResult Function( NonDetectingStrapOverride value)  nonDetectingStrap,}){
final _that = this;
switch (_that) {
case DetectingStrapOverride():
return detectingStrap(_that);case NonDetectingStrapOverride():
return nonDetectingStrap(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DetectingStrapOverride value)?  detectingStrap,TResult? Function( NonDetectingStrapOverride value)?  nonDetectingStrap,}){
final _that = this;
switch (_that) {
case DetectingStrapOverride() when detectingStrap != null:
return detectingStrap(_that);case NonDetectingStrapOverride() when nonDetectingStrap != null:
return nonDetectingStrap(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DetectingStrapCondition condition)?  detectingStrap,TResult Function( NonDetectingStrapCondition condition)?  nonDetectingStrap,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DetectingStrapOverride() when detectingStrap != null:
return detectingStrap(_that.condition);case NonDetectingStrapOverride() when nonDetectingStrap != null:
return nonDetectingStrap(_that.condition);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DetectingStrapCondition condition)  detectingStrap,required TResult Function( NonDetectingStrapCondition condition)  nonDetectingStrap,}) {final _that = this;
switch (_that) {
case DetectingStrapOverride():
return detectingStrap(_that.condition);case NonDetectingStrapOverride():
return nonDetectingStrap(_that.condition);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DetectingStrapCondition condition)?  detectingStrap,TResult? Function( NonDetectingStrapCondition condition)?  nonDetectingStrap,}) {final _that = this;
switch (_that) {
case DetectingStrapOverride() when detectingStrap != null:
return detectingStrap(_that.condition);case NonDetectingStrapOverride() when nonDetectingStrap != null:
return nonDetectingStrap(_that.condition);case _:
  return null;

}
}

}

/// @nodoc


class DetectingStrapOverride implements ReadingOverride {
  const DetectingStrapOverride(this.condition);
  

@override final  DetectingStrapCondition condition;

/// Create a copy of ReadingOverride
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetectingStrapOverrideCopyWith<DetectingStrapOverride> get copyWith => _$DetectingStrapOverrideCopyWithImpl<DetectingStrapOverride>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DetectingStrapOverride&&(identical(other.condition, condition) || other.condition == condition));
}


@override
int get hashCode {
    return Object.hash(runtimeType,condition);
}

@override
String toString() {
    return 'ReadingOverride.detectingStrap(condition: $condition)';
}


}

/// @nodoc
abstract mixin class $DetectingStrapOverrideCopyWith<$Res> implements $ReadingOverrideCopyWith<$Res> {
  factory $DetectingStrapOverrideCopyWith(DetectingStrapOverride value, $Res Function(DetectingStrapOverride) _then) = _$DetectingStrapOverrideCopyWithImpl;
@useResult
$Res call({
 DetectingStrapCondition condition
});




}
/// @nodoc
class _$DetectingStrapOverrideCopyWithImpl<$Res>
    implements $DetectingStrapOverrideCopyWith<$Res> {
  _$DetectingStrapOverrideCopyWithImpl(this._self, this._then);

  final DetectingStrapOverride _self;
  final $Res Function(DetectingStrapOverride) _then;

/// Create a copy of ReadingOverride
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? condition = null,}) {
  return _then(DetectingStrapOverride(
null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as DetectingStrapCondition,
  ));
}


}

/// @nodoc


class NonDetectingStrapOverride implements ReadingOverride {
  const NonDetectingStrapOverride(this.condition);
  

@override final  NonDetectingStrapCondition condition;

/// Create a copy of ReadingOverride
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NonDetectingStrapOverrideCopyWith<NonDetectingStrapOverride> get copyWith => _$NonDetectingStrapOverrideCopyWithImpl<NonDetectingStrapOverride>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NonDetectingStrapOverride&&(identical(other.condition, condition) || other.condition == condition));
}


@override
int get hashCode {
    return Object.hash(runtimeType,condition);
}

@override
String toString() {
    return 'ReadingOverride.nonDetectingStrap(condition: $condition)';
}


}

/// @nodoc
abstract mixin class $NonDetectingStrapOverrideCopyWith<$Res> implements $ReadingOverrideCopyWith<$Res> {
  factory $NonDetectingStrapOverrideCopyWith(NonDetectingStrapOverride value, $Res Function(NonDetectingStrapOverride) _then) = _$NonDetectingStrapOverrideCopyWithImpl;
@useResult
$Res call({
 NonDetectingStrapCondition condition
});




}
/// @nodoc
class _$NonDetectingStrapOverrideCopyWithImpl<$Res>
    implements $NonDetectingStrapOverrideCopyWith<$Res> {
  _$NonDetectingStrapOverrideCopyWithImpl(this._self, this._then);

  final NonDetectingStrapOverride _self;
  final $Res Function(NonDetectingStrapOverride) _then;

/// Create a copy of ReadingOverride
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? condition = null,}) {
  return _then(NonDetectingStrapOverride(
null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as NonDetectingStrapCondition,
  ));
}


}

// dart format on
