// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discovered_strap.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiscoveredStrap {

/// Identifies the strap, so it can be connected to later.
 StrapBleIdentifier get id;/// The name the strap advertises, or null if it doesn't advertise one.
 StrapBleName? get name;
/// Create a copy of DiscoveredStrap
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoveredStrapCopyWith<DiscoveredStrap> get copyWith => _$DiscoveredStrapCopyWithImpl<DiscoveredStrap>(this as DiscoveredStrap, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DiscoveredStrap;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoveredStrap&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name));
}


@override
int get hashCode {
  final _this = this as DiscoveredStrap;
  return Object.hash(runtimeType,_this.id,_this.name);
}

@override
String toString() {
  final _this = this as DiscoveredStrap;
  return 'DiscoveredStrap(id: ${_this.id}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $DiscoveredStrapCopyWith<$Res>  {
  factory $DiscoveredStrapCopyWith(DiscoveredStrap value, $Res Function(DiscoveredStrap) _then) = _$DiscoveredStrapCopyWithImpl;
@useResult
$Res call({
 StrapBleIdentifier id, StrapBleName? name
});




}
/// @nodoc
class _$DiscoveredStrapCopyWithImpl<$Res>
    implements $DiscoveredStrapCopyWith<$Res> {
  _$DiscoveredStrapCopyWithImpl(this._self, this._then);

  final DiscoveredStrap _self;
  final $Res Function(DiscoveredStrap) _then;

/// Create a copy of DiscoveredStrap
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,}) {
  return _then(DiscoveredStrap(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as StrapBleIdentifier,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as StrapBleName?,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscoveredStrap].
extension DiscoveredStrapPatterns on DiscoveredStrap {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscoveredStrap value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscoveredStrap() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscoveredStrap value)  $default,){
final _that = this;
switch (_that) {
case _DiscoveredStrap():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscoveredStrap value)?  $default,){
final _that = this;
switch (_that) {
case _DiscoveredStrap() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StrapBleIdentifier id,  StrapBleName? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscoveredStrap() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StrapBleIdentifier id,  StrapBleName? name)  $default,) {final _that = this;
switch (_that) {
case _DiscoveredStrap():
return $default(_that.id,_that.name);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StrapBleIdentifier id,  StrapBleName? name)?  $default,) {final _that = this;
switch (_that) {
case _DiscoveredStrap() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _DiscoveredStrap implements DiscoveredStrap {
  const _DiscoveredStrap({required this.id, required this.name});
  

/// Identifies the strap, so it can be connected to later.
@override final  StrapBleIdentifier id;
/// The name the strap advertises, or null if it doesn't advertise one.
@override final  StrapBleName? name;

/// Create a copy of DiscoveredStrap
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscoveredStrapCopyWith<_DiscoveredStrap> get copyWith => __$DiscoveredStrapCopyWithImpl<_DiscoveredStrap>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscoveredStrap&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name);
}

@override
String toString() {
    return 'DiscoveredStrap(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$DiscoveredStrapCopyWith<$Res> implements $DiscoveredStrapCopyWith<$Res> {
  factory _$DiscoveredStrapCopyWith(_DiscoveredStrap value, $Res Function(_DiscoveredStrap) _then) = __$DiscoveredStrapCopyWithImpl;
@override @useResult
$Res call({
 StrapBleIdentifier id, StrapBleName? name
});




}
/// @nodoc
class __$DiscoveredStrapCopyWithImpl<$Res>
    implements _$DiscoveredStrapCopyWith<$Res> {
  __$DiscoveredStrapCopyWithImpl(this._self, this._then);

  final _DiscoveredStrap _self;
  final $Res Function(_DiscoveredStrap) _then;

/// Create a copy of DiscoveredStrap
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,}) {
  return _then(_DiscoveredStrap(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as StrapBleIdentifier,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as StrapBleName?,
  ));
}


}

// dart format on
