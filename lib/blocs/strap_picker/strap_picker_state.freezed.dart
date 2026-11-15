// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'strap_picker_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StrapPickerState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapPickerState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'StrapPickerState()';
}


}

/// @nodoc
class $StrapPickerStateCopyWith<$Res>  {
$StrapPickerStateCopyWith(StrapPickerState _, $Res Function(StrapPickerState) __);
}


/// Adds pattern-matching-related methods to [StrapPickerState].
extension StrapPickerStatePatterns on StrapPickerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StrapPickerScanning value)?  scanning,TResult Function( StrapPickerFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StrapPickerScanning() when scanning != null:
return scanning(_that);case StrapPickerFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StrapPickerScanning value)  scanning,required TResult Function( StrapPickerFailed value)  failed,}){
final _that = this;
switch (_that) {
case StrapPickerScanning():
return scanning(_that);case StrapPickerFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StrapPickerScanning value)?  scanning,TResult? Function( StrapPickerFailed value)?  failed,}){
final _that = this;
switch (_that) {
case StrapPickerScanning() when scanning != null:
return scanning(_that);case StrapPickerFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<DiscoveredStrap> straps)?  scanning,TResult Function( BluetoothProblem problem)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StrapPickerScanning() when scanning != null:
return scanning(_that.straps);case StrapPickerFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<DiscoveredStrap> straps)  scanning,required TResult Function( BluetoothProblem problem)  failed,}) {final _that = this;
switch (_that) {
case StrapPickerScanning():
return scanning(_that.straps);case StrapPickerFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<DiscoveredStrap> straps)?  scanning,TResult? Function( BluetoothProblem problem)?  failed,}) {final _that = this;
switch (_that) {
case StrapPickerScanning() when scanning != null:
return scanning(_that.straps);case StrapPickerFailed() when failed != null:
return failed(_that.problem);case _:
  return null;

}
}

}

/// @nodoc


class StrapPickerScanning implements StrapPickerState {
  const StrapPickerScanning({required  List<DiscoveredStrap> straps}): _straps = straps;
  

 final  List<DiscoveredStrap> _straps;
 List<DiscoveredStrap> get straps {
  if (_straps is EqualUnmodifiableListView) return _straps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_straps);
}


/// Create a copy of StrapPickerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StrapPickerScanningCopyWith<StrapPickerScanning> get copyWith => _$StrapPickerScanningCopyWithImpl<StrapPickerScanning>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapPickerScanning&&const DeepCollectionEquality().equals(other.straps, _straps));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_straps));
}

@override
String toString() {
    return 'StrapPickerState.scanning(straps: $straps)';
}


}

/// @nodoc
abstract mixin class $StrapPickerScanningCopyWith<$Res> implements $StrapPickerStateCopyWith<$Res> {
  factory $StrapPickerScanningCopyWith(StrapPickerScanning value, $Res Function(StrapPickerScanning) _then) = _$StrapPickerScanningCopyWithImpl;
@useResult
$Res call({
 List<DiscoveredStrap> straps
});




}
/// @nodoc
class _$StrapPickerScanningCopyWithImpl<$Res>
    implements $StrapPickerScanningCopyWith<$Res> {
  _$StrapPickerScanningCopyWithImpl(this._self, this._then);

  final StrapPickerScanning _self;
  final $Res Function(StrapPickerScanning) _then;

/// Create a copy of StrapPickerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? straps = null,}) {
  return _then(StrapPickerScanning(
straps: null == straps ? _self._straps : straps // ignore: cast_nullable_to_non_nullable
as List<DiscoveredStrap>,
  ));
}


}

/// @nodoc


class StrapPickerFailed implements StrapPickerState {
  const StrapPickerFailed(this.problem);
  

 final  BluetoothProblem problem;

/// Create a copy of StrapPickerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StrapPickerFailedCopyWith<StrapPickerFailed> get copyWith => _$StrapPickerFailedCopyWithImpl<StrapPickerFailed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is StrapPickerFailed&&(identical(other.problem, problem) || other.problem == problem));
}


@override
int get hashCode {
    return Object.hash(runtimeType,problem);
}

@override
String toString() {
    return 'StrapPickerState.failed(problem: $problem)';
}


}

/// @nodoc
abstract mixin class $StrapPickerFailedCopyWith<$Res> implements $StrapPickerStateCopyWith<$Res> {
  factory $StrapPickerFailedCopyWith(StrapPickerFailed value, $Res Function(StrapPickerFailed) _then) = _$StrapPickerFailedCopyWithImpl;
@useResult
$Res call({
 BluetoothProblem problem
});




}
/// @nodoc
class _$StrapPickerFailedCopyWithImpl<$Res>
    implements $StrapPickerFailedCopyWith<$Res> {
  _$StrapPickerFailedCopyWithImpl(this._self, this._then);

  final StrapPickerFailed _self;
  final $Res Function(StrapPickerFailed) _then;

/// Create a copy of StrapPickerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? problem = null,}) {
  return _then(StrapPickerFailed(
null == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as BluetoothProblem,
  ));
}


}

// dart format on
