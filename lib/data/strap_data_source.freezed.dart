// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'strap_data_source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StrapDataSourceStartResult {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapDataSourceStartResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'StrapDataSourceStartResult()';
}


}

/// @nodoc
class $StrapDataSourceStartResultCopyWith<$Res>  {
$StrapDataSourceStartResultCopyWith(StrapDataSourceStartResult _, $Res Function(StrapDataSourceStartResult) __);
}


/// Adds pattern-matching-related methods to [StrapDataSourceStartResult].
extension StrapDataSourceStartResultPatterns on StrapDataSourceStartResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StrapDataSourceStarted value)?  started,TResult Function( StrapDataSourceStartCancelled value)?  cancelled,TResult Function( StrapDataSourceStartFailed value)?  failed,TResult Function( StrapDataSourceNoStrap value)?  noStrap,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StrapDataSourceStarted() when started != null:
return started(_that);case StrapDataSourceStartCancelled() when cancelled != null:
return cancelled(_that);case StrapDataSourceStartFailed() when failed != null:
return failed(_that);case StrapDataSourceNoStrap() when noStrap != null:
return noStrap(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StrapDataSourceStarted value)  started,required TResult Function( StrapDataSourceStartCancelled value)  cancelled,required TResult Function( StrapDataSourceStartFailed value)  failed,required TResult Function( StrapDataSourceNoStrap value)  noStrap,}){
final _that = this;
switch (_that) {
case StrapDataSourceStarted():
return started(_that);case StrapDataSourceStartCancelled():
return cancelled(_that);case StrapDataSourceStartFailed():
return failed(_that);case StrapDataSourceNoStrap():
return noStrap(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StrapDataSourceStarted value)?  started,TResult? Function( StrapDataSourceStartCancelled value)?  cancelled,TResult? Function( StrapDataSourceStartFailed value)?  failed,TResult? Function( StrapDataSourceNoStrap value)?  noStrap,}){
final _that = this;
switch (_that) {
case StrapDataSourceStarted() when started != null:
return started(_that);case StrapDataSourceStartCancelled() when cancelled != null:
return cancelled(_that);case StrapDataSourceStartFailed() when failed != null:
return failed(_that);case StrapDataSourceNoStrap() when noStrap != null:
return noStrap(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function()?  cancelled,TResult Function( StrapConnectionFailure failure)?  failed,TResult Function()?  noStrap,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StrapDataSourceStarted() when started != null:
return started();case StrapDataSourceStartCancelled() when cancelled != null:
return cancelled();case StrapDataSourceStartFailed() when failed != null:
return failed(_that.failure);case StrapDataSourceNoStrap() when noStrap != null:
return noStrap();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function()  cancelled,required TResult Function( StrapConnectionFailure failure)  failed,required TResult Function()  noStrap,}) {final _that = this;
switch (_that) {
case StrapDataSourceStarted():
return started();case StrapDataSourceStartCancelled():
return cancelled();case StrapDataSourceStartFailed():
return failed(_that.failure);case StrapDataSourceNoStrap():
return noStrap();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function()?  cancelled,TResult? Function( StrapConnectionFailure failure)?  failed,TResult? Function()?  noStrap,}) {final _that = this;
switch (_that) {
case StrapDataSourceStarted() when started != null:
return started();case StrapDataSourceStartCancelled() when cancelled != null:
return cancelled();case StrapDataSourceStartFailed() when failed != null:
return failed(_that.failure);case StrapDataSourceNoStrap() when noStrap != null:
return noStrap();case _:
  return null;

}
}

}

/// @nodoc


class StrapDataSourceStarted implements StrapDataSourceStartResult {
  const StrapDataSourceStarted();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapDataSourceStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'StrapDataSourceStartResult.started()';
}


}




/// @nodoc


class StrapDataSourceStartCancelled implements StrapDataSourceStartResult {
  const StrapDataSourceStartCancelled();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapDataSourceStartCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'StrapDataSourceStartResult.cancelled()';
}


}




/// @nodoc


class StrapDataSourceStartFailed implements StrapDataSourceStartResult {
  const StrapDataSourceStartFailed(this.failure);
  

 final  StrapConnectionFailure failure;

/// Create a copy of StrapDataSourceStartResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StrapDataSourceStartFailedCopyWith<StrapDataSourceStartFailed> get copyWith => _$StrapDataSourceStartFailedCopyWithImpl<StrapDataSourceStartFailed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapDataSourceStartFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,failure);
}

@override
String toString() {
    return 'StrapDataSourceStartResult.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $StrapDataSourceStartFailedCopyWith<$Res> implements $StrapDataSourceStartResultCopyWith<$Res> {
  factory $StrapDataSourceStartFailedCopyWith(StrapDataSourceStartFailed value, $Res Function(StrapDataSourceStartFailed) _then) = _$StrapDataSourceStartFailedCopyWithImpl;
@useResult
$Res call({
 StrapConnectionFailure failure
});


$StrapConnectionFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$StrapDataSourceStartFailedCopyWithImpl<$Res>
    implements $StrapDataSourceStartFailedCopyWith<$Res> {
  _$StrapDataSourceStartFailedCopyWithImpl(this._self, this._then);

  final StrapDataSourceStartFailed _self;
  final $Res Function(StrapDataSourceStartFailed) _then;

/// Create a copy of StrapDataSourceStartResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(StrapDataSourceStartFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as StrapConnectionFailure,
  ));
}

/// Create a copy of StrapDataSourceStartResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StrapConnectionFailureCopyWith<$Res> get failure {
  
  return $StrapConnectionFailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class StrapDataSourceNoStrap implements StrapDataSourceStartResult {
  const StrapDataSourceNoStrap();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapDataSourceNoStrap);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'StrapDataSourceStartResult.noStrap()';
}


}




// dart format on
