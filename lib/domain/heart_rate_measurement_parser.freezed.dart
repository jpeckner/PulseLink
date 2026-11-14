// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'heart_rate_measurement_parser.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HeartRateParseResult {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is HeartRateParseResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'HeartRateParseResult()';
}


}

/// @nodoc
class $HeartRateParseResultCopyWith<$Res>  {
$HeartRateParseResultCopyWith(HeartRateParseResult _, $Res Function(HeartRateParseResult) __);
}


/// Adds pattern-matching-related methods to [HeartRateParseResult].
extension HeartRateParseResultPatterns on HeartRateParseResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HeartRateParseSuccess value)?  success,TResult Function( HeartRateParseFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HeartRateParseSuccess() when success != null:
return success(_that);case HeartRateParseFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HeartRateParseSuccess value)  success,required TResult Function( HeartRateParseFailure value)  failure,}){
final _that = this;
switch (_that) {
case HeartRateParseSuccess():
return success(_that);case HeartRateParseFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HeartRateParseSuccess value)?  success,TResult? Function( HeartRateParseFailure value)?  failure,}){
final _that = this;
switch (_that) {
case HeartRateParseSuccess() when success != null:
return success(_that);case HeartRateParseFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( HeartRateSample sample)?  success,TResult Function( HeartRateParseError error)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HeartRateParseSuccess() when success != null:
return success(_that.sample);case HeartRateParseFailure() when failure != null:
return failure(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( HeartRateSample sample)  success,required TResult Function( HeartRateParseError error)  failure,}) {final _that = this;
switch (_that) {
case HeartRateParseSuccess():
return success(_that.sample);case HeartRateParseFailure():
return failure(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( HeartRateSample sample)?  success,TResult? Function( HeartRateParseError error)?  failure,}) {final _that = this;
switch (_that) {
case HeartRateParseSuccess() when success != null:
return success(_that.sample);case HeartRateParseFailure() when failure != null:
return failure(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class HeartRateParseSuccess implements HeartRateParseResult {
  const HeartRateParseSuccess(this.sample);
  

 final  HeartRateSample sample;

/// Create a copy of HeartRateParseResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeartRateParseSuccessCopyWith<HeartRateParseSuccess> get copyWith => _$HeartRateParseSuccessCopyWithImpl<HeartRateParseSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is HeartRateParseSuccess&&(identical(other.sample, sample) || other.sample == sample));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sample);
}

@override
String toString() {
    return 'HeartRateParseResult.success(sample: $sample)';
}


}

/// @nodoc
abstract mixin class $HeartRateParseSuccessCopyWith<$Res> implements $HeartRateParseResultCopyWith<$Res> {
  factory $HeartRateParseSuccessCopyWith(HeartRateParseSuccess value, $Res Function(HeartRateParseSuccess) _then) = _$HeartRateParseSuccessCopyWithImpl;
@useResult
$Res call({
 HeartRateSample sample
});


$HeartRateSampleCopyWith<$Res> get sample;

}
/// @nodoc
class _$HeartRateParseSuccessCopyWithImpl<$Res>
    implements $HeartRateParseSuccessCopyWith<$Res> {
  _$HeartRateParseSuccessCopyWithImpl(this._self, this._then);

  final HeartRateParseSuccess _self;
  final $Res Function(HeartRateParseSuccess) _then;

/// Create a copy of HeartRateParseResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sample = null,}) {
  return _then(HeartRateParseSuccess(
null == sample ? _self.sample : sample // ignore: cast_nullable_to_non_nullable
as HeartRateSample,
  ));
}

/// Create a copy of HeartRateParseResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeartRateSampleCopyWith<$Res> get sample {
  
  return $HeartRateSampleCopyWith<$Res>(_self.sample, (value) {
    return _then(_self.copyWith(sample: value));
  });
}
}

/// @nodoc


class HeartRateParseFailure implements HeartRateParseResult {
  const HeartRateParseFailure(this.error);
  

 final  HeartRateParseError error;

/// Create a copy of HeartRateParseResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeartRateParseFailureCopyWith<HeartRateParseFailure> get copyWith => _$HeartRateParseFailureCopyWithImpl<HeartRateParseFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is HeartRateParseFailure&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode {
    return Object.hash(runtimeType,error);
}

@override
String toString() {
    return 'HeartRateParseResult.failure(error: $error)';
}


}

/// @nodoc
abstract mixin class $HeartRateParseFailureCopyWith<$Res> implements $HeartRateParseResultCopyWith<$Res> {
  factory $HeartRateParseFailureCopyWith(HeartRateParseFailure value, $Res Function(HeartRateParseFailure) _then) = _$HeartRateParseFailureCopyWithImpl;
@useResult
$Res call({
 HeartRateParseError error
});




}
/// @nodoc
class _$HeartRateParseFailureCopyWithImpl<$Res>
    implements $HeartRateParseFailureCopyWith<$Res> {
  _$HeartRateParseFailureCopyWithImpl(this._self, this._then);

  final HeartRateParseFailure _self;
  final $Res Function(HeartRateParseFailure) _then;

/// Create a copy of HeartRateParseResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(HeartRateParseFailure(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as HeartRateParseError,
  ));
}


}

// dart format on
