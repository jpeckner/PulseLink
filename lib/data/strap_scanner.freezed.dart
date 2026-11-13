// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'strap_scanner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StrapScanEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapScanEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'StrapScanEvent()';
}


}

/// @nodoc
class $StrapScanEventCopyWith<$Res>  {
$StrapScanEventCopyWith(StrapScanEvent _, $Res Function(StrapScanEvent) __);
}


/// Adds pattern-matching-related methods to [StrapScanEvent].
extension StrapScanEventPatterns on StrapScanEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StrapScanScanning value)?  scanning,TResult Function( StrapFound value)?  found,TResult Function( StrapScanFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StrapScanScanning() when scanning != null:
return scanning(_that);case StrapFound() when found != null:
return found(_that);case StrapScanFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StrapScanScanning value)  scanning,required TResult Function( StrapFound value)  found,required TResult Function( StrapScanFailed value)  failed,}){
final _that = this;
switch (_that) {
case StrapScanScanning():
return scanning(_that);case StrapFound():
return found(_that);case StrapScanFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StrapScanScanning value)?  scanning,TResult? Function( StrapFound value)?  found,TResult? Function( StrapScanFailed value)?  failed,}){
final _that = this;
switch (_that) {
case StrapScanScanning() when scanning != null:
return scanning(_that);case StrapFound() when found != null:
return found(_that);case StrapScanFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  scanning,TResult Function( DiscoveredStrap strap)?  found,TResult Function( BluetoothProblem problem)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StrapScanScanning() when scanning != null:
return scanning();case StrapFound() when found != null:
return found(_that.strap);case StrapScanFailed() when failed != null:
return failed(_that.problem);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  scanning,required TResult Function( DiscoveredStrap strap)  found,required TResult Function( BluetoothProblem problem)  failed,}) {final _that = this;
switch (_that) {
case StrapScanScanning():
return scanning();case StrapFound():
return found(_that.strap);case StrapScanFailed():
return failed(_that.problem);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  scanning,TResult? Function( DiscoveredStrap strap)?  found,TResult? Function( BluetoothProblem problem)?  failed,}) {final _that = this;
switch (_that) {
case StrapScanScanning() when scanning != null:
return scanning();case StrapFound() when found != null:
return found(_that.strap);case StrapScanFailed() when failed != null:
return failed(_that.problem);case _:
  return null;

}
}

}

/// @nodoc


class StrapScanScanning implements StrapScanEvent {
  const StrapScanScanning();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapScanScanning);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'StrapScanEvent.scanning()';
}


}




/// @nodoc


class StrapFound implements StrapScanEvent {
  const StrapFound(this.strap);
  

 final  DiscoveredStrap strap;

/// Create a copy of StrapScanEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StrapFoundCopyWith<StrapFound> get copyWith => _$StrapFoundCopyWithImpl<StrapFound>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapFound&&(identical(other.strap, strap) || other.strap == strap));
}


@override
int get hashCode {
    return Object.hash(runtimeType,strap);
}

@override
String toString() {
    return 'StrapScanEvent.found(strap: $strap)';
}


}

/// @nodoc
abstract mixin class $StrapFoundCopyWith<$Res> implements $StrapScanEventCopyWith<$Res> {
  factory $StrapFoundCopyWith(StrapFound value, $Res Function(StrapFound) _then) = _$StrapFoundCopyWithImpl;
@useResult
$Res call({
 DiscoveredStrap strap
});


$DiscoveredStrapCopyWith<$Res> get strap;

}
/// @nodoc
class _$StrapFoundCopyWithImpl<$Res>
    implements $StrapFoundCopyWith<$Res> {
  _$StrapFoundCopyWithImpl(this._self, this._then);

  final StrapFound _self;
  final $Res Function(StrapFound) _then;

/// Create a copy of StrapScanEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? strap = null,}) {
  return _then(StrapFound(
null == strap ? _self.strap : strap // ignore: cast_nullable_to_non_nullable
as DiscoveredStrap,
  ));
}

/// Create a copy of StrapScanEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiscoveredStrapCopyWith<$Res> get strap {
  
  return $DiscoveredStrapCopyWith<$Res>(_self.strap, (value) {
    return _then(_self.copyWith(strap: value));
  });
}
}

/// @nodoc


class StrapScanFailed implements StrapScanEvent {
  const StrapScanFailed(this.problem);
  

 final  BluetoothProblem problem;

/// Create a copy of StrapScanEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StrapScanFailedCopyWith<StrapScanFailed> get copyWith => _$StrapScanFailedCopyWithImpl<StrapScanFailed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapScanFailed&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode {
    return Object.hash(runtimeType,problem);
}

@override
String toString() {
    return 'StrapScanEvent.failed(problem: $problem)';
}


}

/// @nodoc
abstract mixin class $StrapScanFailedCopyWith<$Res> implements $StrapScanEventCopyWith<$Res> {
  factory $StrapScanFailedCopyWith(StrapScanFailed value, $Res Function(StrapScanFailed) _then) = _$StrapScanFailedCopyWithImpl;
@useResult
$Res call({
 BluetoothProblem problem
});




}
/// @nodoc
class _$StrapScanFailedCopyWithImpl<$Res>
    implements $StrapScanFailedCopyWith<$Res> {
  _$StrapScanFailedCopyWithImpl(this._self, this._then);

  final StrapScanFailed _self;
  final $Res Function(StrapScanFailed) _then;

/// Create a copy of StrapScanEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? problem = null,}) {
  return _then(StrapScanFailed(
null == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as BluetoothProblem,
  ));
}


}

// dart format on
