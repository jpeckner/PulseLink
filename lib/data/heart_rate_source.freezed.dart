// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'heart_rate_source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HeartRateSourceStartResult {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is HeartRateSourceStartResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'HeartRateSourceStartResult()';
}


}

/// @nodoc
class $HeartRateSourceStartResultCopyWith<$Res>  {
$HeartRateSourceStartResultCopyWith(HeartRateSourceStartResult _, $Res Function(HeartRateSourceStartResult) __);
}


/// Adds pattern-matching-related methods to [HeartRateSourceStartResult].
extension HeartRateSourceStartResultPatterns on HeartRateSourceStartResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HeartRateSourceStarted value)?  started,TResult Function( HeartRateSourceStartCancelled value)?  cancelled,TResult Function( HeartRateSourceStartFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HeartRateSourceStarted() when started != null:
return started(_that);case HeartRateSourceStartCancelled() when cancelled != null:
return cancelled(_that);case HeartRateSourceStartFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HeartRateSourceStarted value)  started,required TResult Function( HeartRateSourceStartCancelled value)  cancelled,required TResult Function( HeartRateSourceStartFailed value)  failed,}){
final _that = this;
switch (_that) {
case HeartRateSourceStarted():
return started(_that);case HeartRateSourceStartCancelled():
return cancelled(_that);case HeartRateSourceStartFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HeartRateSourceStarted value)?  started,TResult? Function( HeartRateSourceStartCancelled value)?  cancelled,TResult? Function( HeartRateSourceStartFailed value)?  failed,}){
final _that = this;
switch (_that) {
case HeartRateSourceStarted() when started != null:
return started(_that);case HeartRateSourceStartCancelled() when cancelled != null:
return cancelled(_that);case HeartRateSourceStartFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function()?  cancelled,TResult Function( StrapConnectionFailure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HeartRateSourceStarted() when started != null:
return started();case HeartRateSourceStartCancelled() when cancelled != null:
return cancelled();case HeartRateSourceStartFailed() when failed != null:
return failed(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function()  cancelled,required TResult Function( StrapConnectionFailure failure)  failed,}) {final _that = this;
switch (_that) {
case HeartRateSourceStarted():
return started();case HeartRateSourceStartCancelled():
return cancelled();case HeartRateSourceStartFailed():
return failed(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function()?  cancelled,TResult? Function( StrapConnectionFailure failure)?  failed,}) {final _that = this;
switch (_that) {
case HeartRateSourceStarted() when started != null:
return started();case HeartRateSourceStartCancelled() when cancelled != null:
return cancelled();case HeartRateSourceStartFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class HeartRateSourceStarted implements HeartRateSourceStartResult {
  const HeartRateSourceStarted();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is HeartRateSourceStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'HeartRateSourceStartResult.started()';
}


}




/// @nodoc


class HeartRateSourceStartCancelled implements HeartRateSourceStartResult {
  const HeartRateSourceStartCancelled();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is HeartRateSourceStartCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'HeartRateSourceStartResult.cancelled()';
}


}




/// @nodoc


class HeartRateSourceStartFailed implements HeartRateSourceStartResult {
  const HeartRateSourceStartFailed(this.failure);
  

 final  StrapConnectionFailure failure;

/// Create a copy of HeartRateSourceStartResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeartRateSourceStartFailedCopyWith<HeartRateSourceStartFailed> get copyWith => _$HeartRateSourceStartFailedCopyWithImpl<HeartRateSourceStartFailed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is HeartRateSourceStartFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,failure);
}

@override
String toString() {
    return 'HeartRateSourceStartResult.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $HeartRateSourceStartFailedCopyWith<$Res> implements $HeartRateSourceStartResultCopyWith<$Res> {
  factory $HeartRateSourceStartFailedCopyWith(HeartRateSourceStartFailed value, $Res Function(HeartRateSourceStartFailed) _then) = _$HeartRateSourceStartFailedCopyWithImpl;
@useResult
$Res call({
 StrapConnectionFailure failure
});


$StrapConnectionFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$HeartRateSourceStartFailedCopyWithImpl<$Res>
    implements $HeartRateSourceStartFailedCopyWith<$Res> {
  _$HeartRateSourceStartFailedCopyWithImpl(this._self, this._then);

  final HeartRateSourceStartFailed _self;
  final $Res Function(HeartRateSourceStartFailed) _then;

/// Create a copy of HeartRateSourceStartResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(HeartRateSourceStartFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as StrapConnectionFailure,
  ));
}

/// Create a copy of HeartRateSourceStartResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StrapConnectionFailureCopyWith<$Res> get failure {
  
  return $StrapConnectionFailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
