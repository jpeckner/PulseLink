// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'strap_connection_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StrapConnectionFailure {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapConnectionFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'StrapConnectionFailure()';
}


}

/// @nodoc
class $StrapConnectionFailureCopyWith<$Res>  {
$StrapConnectionFailureCopyWith(StrapConnectionFailure _, $Res Function(StrapConnectionFailure) __);
}


/// Adds pattern-matching-related methods to [StrapConnectionFailure].
extension StrapConnectionFailurePatterns on StrapConnectionFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BluetoothFailure value)?  bluetooth,TResult Function( StrapUnreachable value)?  strapUnreachable,TResult Function( NotAHeartRateStrap value)?  notAHeartRateStrap,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BluetoothFailure() when bluetooth != null:
return bluetooth(_that);case StrapUnreachable() when strapUnreachable != null:
return strapUnreachable(_that);case NotAHeartRateStrap() when notAHeartRateStrap != null:
return notAHeartRateStrap(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BluetoothFailure value)  bluetooth,required TResult Function( StrapUnreachable value)  strapUnreachable,required TResult Function( NotAHeartRateStrap value)  notAHeartRateStrap,}){
final _that = this;
switch (_that) {
case BluetoothFailure():
return bluetooth(_that);case StrapUnreachable():
return strapUnreachable(_that);case NotAHeartRateStrap():
return notAHeartRateStrap(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BluetoothFailure value)?  bluetooth,TResult? Function( StrapUnreachable value)?  strapUnreachable,TResult? Function( NotAHeartRateStrap value)?  notAHeartRateStrap,}){
final _that = this;
switch (_that) {
case BluetoothFailure() when bluetooth != null:
return bluetooth(_that);case StrapUnreachable() when strapUnreachable != null:
return strapUnreachable(_that);case NotAHeartRateStrap() when notAHeartRateStrap != null:
return notAHeartRateStrap(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( BluetoothProblem problem)?  bluetooth,TResult Function()?  strapUnreachable,TResult Function()?  notAHeartRateStrap,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BluetoothFailure() when bluetooth != null:
return bluetooth(_that.problem);case StrapUnreachable() when strapUnreachable != null:
return strapUnreachable();case NotAHeartRateStrap() when notAHeartRateStrap != null:
return notAHeartRateStrap();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( BluetoothProblem problem)  bluetooth,required TResult Function()  strapUnreachable,required TResult Function()  notAHeartRateStrap,}) {final _that = this;
switch (_that) {
case BluetoothFailure():
return bluetooth(_that.problem);case StrapUnreachable():
return strapUnreachable();case NotAHeartRateStrap():
return notAHeartRateStrap();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( BluetoothProblem problem)?  bluetooth,TResult? Function()?  strapUnreachable,TResult? Function()?  notAHeartRateStrap,}) {final _that = this;
switch (_that) {
case BluetoothFailure() when bluetooth != null:
return bluetooth(_that.problem);case StrapUnreachable() when strapUnreachable != null:
return strapUnreachable();case NotAHeartRateStrap() when notAHeartRateStrap != null:
return notAHeartRateStrap();case _:
  return null;

}
}

}

/// @nodoc


class BluetoothFailure implements StrapConnectionFailure {
  const BluetoothFailure(this.problem);
  

 final  BluetoothProblem problem;

/// Create a copy of StrapConnectionFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BluetoothFailureCopyWith<BluetoothFailure> get copyWith => _$BluetoothFailureCopyWithImpl<BluetoothFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BluetoothFailure&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode {
    return Object.hash(runtimeType,problem);
}

@override
String toString() {
    return 'StrapConnectionFailure.bluetooth(problem: $problem)';
}


}

/// @nodoc
abstract mixin class $BluetoothFailureCopyWith<$Res> implements $StrapConnectionFailureCopyWith<$Res> {
  factory $BluetoothFailureCopyWith(BluetoothFailure value, $Res Function(BluetoothFailure) _then) = _$BluetoothFailureCopyWithImpl;
@useResult
$Res call({
 BluetoothProblem problem
});




}
/// @nodoc
class _$BluetoothFailureCopyWithImpl<$Res>
    implements $BluetoothFailureCopyWith<$Res> {
  _$BluetoothFailureCopyWithImpl(this._self, this._then);

  final BluetoothFailure _self;
  final $Res Function(BluetoothFailure) _then;

/// Create a copy of StrapConnectionFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? problem = null,}) {
  return _then(BluetoothFailure(
null == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as BluetoothProblem,
  ));
}


}

/// @nodoc


class StrapUnreachable implements StrapConnectionFailure {
  const StrapUnreachable();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapUnreachable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'StrapConnectionFailure.strapUnreachable()';
}


}




/// @nodoc


class NotAHeartRateStrap implements StrapConnectionFailure {
  const NotAHeartRateStrap();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NotAHeartRateStrap);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'StrapConnectionFailure.notAHeartRateStrap()';
}


}




// dart format on
