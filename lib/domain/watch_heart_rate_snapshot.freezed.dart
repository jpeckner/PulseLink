// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'watch_heart_rate_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WatchHeartRateStatus {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchHeartRateStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'WatchHeartRateStatus()';
}


}

/// @nodoc
class $WatchHeartRateStatusCopyWith<$Res>  {
$WatchHeartRateStatusCopyWith(WatchHeartRateStatus _, $Res Function(WatchHeartRateStatus) __);
}


/// Adds pattern-matching-related methods to [WatchHeartRateStatus].
extension WatchHeartRateStatusPatterns on WatchHeartRateStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WatchHeartRateNoStrap value)?  noStrap,TResult Function( WatchHeartRateWaiting value)?  waiting,TResult Function( WatchHeartRateReceiving value)?  receiving,TResult Function( WatchHeartRateFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WatchHeartRateNoStrap() when noStrap != null:
return noStrap(_that);case WatchHeartRateWaiting() when waiting != null:
return waiting(_that);case WatchHeartRateReceiving() when receiving != null:
return receiving(_that);case WatchHeartRateFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WatchHeartRateNoStrap value)  noStrap,required TResult Function( WatchHeartRateWaiting value)  waiting,required TResult Function( WatchHeartRateReceiving value)  receiving,required TResult Function( WatchHeartRateFailed value)  failed,}){
final _that = this;
switch (_that) {
case WatchHeartRateNoStrap():
return noStrap(_that);case WatchHeartRateWaiting():
return waiting(_that);case WatchHeartRateReceiving():
return receiving(_that);case WatchHeartRateFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WatchHeartRateNoStrap value)?  noStrap,TResult? Function( WatchHeartRateWaiting value)?  waiting,TResult? Function( WatchHeartRateReceiving value)?  receiving,TResult? Function( WatchHeartRateFailed value)?  failed,}){
final _that = this;
switch (_that) {
case WatchHeartRateNoStrap() when noStrap != null:
return noStrap(_that);case WatchHeartRateWaiting() when waiting != null:
return waiting(_that);case WatchHeartRateReceiving() when receiving != null:
return receiving(_that);case WatchHeartRateFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  noStrap,TResult Function()?  waiting,TResult Function()?  receiving,TResult Function( StrapConnectionFailure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WatchHeartRateNoStrap() when noStrap != null:
return noStrap();case WatchHeartRateWaiting() when waiting != null:
return waiting();case WatchHeartRateReceiving() when receiving != null:
return receiving();case WatchHeartRateFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  noStrap,required TResult Function()  waiting,required TResult Function()  receiving,required TResult Function( StrapConnectionFailure failure)  failed,}) {final _that = this;
switch (_that) {
case WatchHeartRateNoStrap():
return noStrap();case WatchHeartRateWaiting():
return waiting();case WatchHeartRateReceiving():
return receiving();case WatchHeartRateFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  noStrap,TResult? Function()?  waiting,TResult? Function()?  receiving,TResult? Function( StrapConnectionFailure failure)?  failed,}) {final _that = this;
switch (_that) {
case WatchHeartRateNoStrap() when noStrap != null:
return noStrap();case WatchHeartRateWaiting() when waiting != null:
return waiting();case WatchHeartRateReceiving() when receiving != null:
return receiving();case WatchHeartRateFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class WatchHeartRateNoStrap implements WatchHeartRateStatus {
  const WatchHeartRateNoStrap();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchHeartRateNoStrap);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'WatchHeartRateStatus.noStrap()';
}


}




/// @nodoc


class WatchHeartRateWaiting implements WatchHeartRateStatus {
  const WatchHeartRateWaiting();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchHeartRateWaiting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'WatchHeartRateStatus.waiting()';
}


}




/// @nodoc


class WatchHeartRateReceiving implements WatchHeartRateStatus {
  const WatchHeartRateReceiving();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchHeartRateReceiving);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'WatchHeartRateStatus.receiving()';
}


}




/// @nodoc


class WatchHeartRateFailed implements WatchHeartRateStatus {
  const WatchHeartRateFailed(this.failure);
  

 final  StrapConnectionFailure failure;

/// Create a copy of WatchHeartRateStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchHeartRateFailedCopyWith<WatchHeartRateFailed> get copyWith => _$WatchHeartRateFailedCopyWithImpl<WatchHeartRateFailed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchHeartRateFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,failure);
}

@override
String toString() {
    return 'WatchHeartRateStatus.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $WatchHeartRateFailedCopyWith<$Res> implements $WatchHeartRateStatusCopyWith<$Res> {
  factory $WatchHeartRateFailedCopyWith(WatchHeartRateFailed value, $Res Function(WatchHeartRateFailed) _then) = _$WatchHeartRateFailedCopyWithImpl;
@useResult
$Res call({
 StrapConnectionFailure failure
});


$StrapConnectionFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$WatchHeartRateFailedCopyWithImpl<$Res>
    implements $WatchHeartRateFailedCopyWith<$Res> {
  _$WatchHeartRateFailedCopyWithImpl(this._self, this._then);

  final WatchHeartRateFailed _self;
  final $Res Function(WatchHeartRateFailed) _then;

/// Create a copy of WatchHeartRateStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(WatchHeartRateFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as StrapConnectionFailure,
  ));
}

/// Create a copy of WatchHeartRateStatus
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
mixin _$WatchHeartRateSnapshot {

/// When the phone sent it, by the phone's clock.
 DateTime get sentAt;/// True in demo mode, when the heart rate is simulated.
 bool get isSimulated; WatchHeartRateStatus get status;/// The latest sample, or null before the first one. It's kept after the
/// strap fails, so the watch can still show the last bpm and when it was
/// measured. Whether it's stale is for the watch to work out from its
/// timestamp.
 HeartRateSample? get latestReading;
/// Create a copy of WatchHeartRateSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchHeartRateSnapshotCopyWith<WatchHeartRateSnapshot> get copyWith => _$WatchHeartRateSnapshotCopyWithImpl<WatchHeartRateSnapshot>(this as WatchHeartRateSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WatchHeartRateSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchHeartRateSnapshot&&(identical(other.sentAt, _this.sentAt) || other.sentAt == _this.sentAt)&&(identical(other.isSimulated, _this.isSimulated) || other.isSimulated == _this.isSimulated)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.latestReading, _this.latestReading) || other.latestReading == _this.latestReading));
}


@override
int get hashCode {
  final _this = this as WatchHeartRateSnapshot;
  return Object.hash(runtimeType,_this.sentAt,_this.isSimulated,_this.status,_this.latestReading);
}

@override
String toString() {
  final _this = this as WatchHeartRateSnapshot;
  return 'WatchHeartRateSnapshot(sentAt: ${_this.sentAt}, isSimulated: ${_this.isSimulated}, status: ${_this.status}, latestReading: ${_this.latestReading})';
}


}

/// @nodoc
abstract mixin class $WatchHeartRateSnapshotCopyWith<$Res>  {
  factory $WatchHeartRateSnapshotCopyWith(WatchHeartRateSnapshot value, $Res Function(WatchHeartRateSnapshot) _then) = _$WatchHeartRateSnapshotCopyWithImpl;
@useResult
$Res call({
 DateTime sentAt, bool isSimulated, WatchHeartRateStatus status, HeartRateSample? latestReading
});


$WatchHeartRateStatusCopyWith<$Res> get status;$HeartRateSampleCopyWith<$Res>? get latestReading;

}
/// @nodoc
class _$WatchHeartRateSnapshotCopyWithImpl<$Res>
    implements $WatchHeartRateSnapshotCopyWith<$Res> {
  _$WatchHeartRateSnapshotCopyWithImpl(this._self, this._then);

  final WatchHeartRateSnapshot _self;
  final $Res Function(WatchHeartRateSnapshot) _then;

/// Create a copy of WatchHeartRateSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sentAt = null,Object? isSimulated = null,Object? status = null,Object? latestReading = freezed,}) {
  return _then(WatchHeartRateSnapshot(
sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,isSimulated: null == isSimulated ? _self.isSimulated : isSimulated // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WatchHeartRateStatus,latestReading: freezed == latestReading ? _self.latestReading : latestReading // ignore: cast_nullable_to_non_nullable
as HeartRateSample?,
  ));
}
/// Create a copy of WatchHeartRateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WatchHeartRateStatusCopyWith<$Res> get status {
  
  return $WatchHeartRateStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}/// Create a copy of WatchHeartRateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeartRateSampleCopyWith<$Res>? get latestReading {
    if (_self.latestReading == null) {
    return null;
  }

  return $HeartRateSampleCopyWith<$Res>(_self.latestReading!, (value) {
    return _then(_self.copyWith(latestReading: value));
  });
}
}


/// Adds pattern-matching-related methods to [WatchHeartRateSnapshot].
extension WatchHeartRateSnapshotPatterns on WatchHeartRateSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WatchHeartRateSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WatchHeartRateSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WatchHeartRateSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _WatchHeartRateSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WatchHeartRateSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _WatchHeartRateSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime sentAt,  bool isSimulated,  WatchHeartRateStatus status,  HeartRateSample? latestReading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WatchHeartRateSnapshot() when $default != null:
return $default(_that.sentAt,_that.isSimulated,_that.status,_that.latestReading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime sentAt,  bool isSimulated,  WatchHeartRateStatus status,  HeartRateSample? latestReading)  $default,) {final _that = this;
switch (_that) {
case _WatchHeartRateSnapshot():
return $default(_that.sentAt,_that.isSimulated,_that.status,_that.latestReading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime sentAt,  bool isSimulated,  WatchHeartRateStatus status,  HeartRateSample? latestReading)?  $default,) {final _that = this;
switch (_that) {
case _WatchHeartRateSnapshot() when $default != null:
return $default(_that.sentAt,_that.isSimulated,_that.status,_that.latestReading);case _:
  return null;

}
}

}

/// @nodoc


class _WatchHeartRateSnapshot implements WatchHeartRateSnapshot {
  const _WatchHeartRateSnapshot({required this.sentAt, required this.isSimulated, required this.status, required this.latestReading});
  

/// When the phone sent it, by the phone's clock.
@override final  DateTime sentAt;
/// True in demo mode, when the heart rate is simulated.
@override final  bool isSimulated;
@override final  WatchHeartRateStatus status;
/// The latest sample, or null before the first one. It's kept after the
/// strap fails, so the watch can still show the last bpm and when it was
/// measured. Whether it's stale is for the watch to work out from its
/// timestamp.
@override final  HeartRateSample? latestReading;

/// Create a copy of WatchHeartRateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WatchHeartRateSnapshotCopyWith<_WatchHeartRateSnapshot> get copyWith => __$WatchHeartRateSnapshotCopyWithImpl<_WatchHeartRateSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WatchHeartRateSnapshot&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.isSimulated, isSimulated) || other.isSimulated == isSimulated)&&(identical(other.status, status) || other.status == status)&&(identical(other.latestReading, latestReading) || other.latestReading == latestReading));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sentAt,isSimulated,status,latestReading);
}

@override
String toString() {
    return 'WatchHeartRateSnapshot(sentAt: $sentAt, isSimulated: $isSimulated, status: $status, latestReading: $latestReading)';
}


}

/// @nodoc
abstract mixin class _$WatchHeartRateSnapshotCopyWith<$Res> implements $WatchHeartRateSnapshotCopyWith<$Res> {
  factory _$WatchHeartRateSnapshotCopyWith(_WatchHeartRateSnapshot value, $Res Function(_WatchHeartRateSnapshot) _then) = __$WatchHeartRateSnapshotCopyWithImpl;
@override @useResult
$Res call({
 DateTime sentAt, bool isSimulated, WatchHeartRateStatus status, HeartRateSample? latestReading
});


@override $WatchHeartRateStatusCopyWith<$Res> get status;@override $HeartRateSampleCopyWith<$Res>? get latestReading;

}
/// @nodoc
class __$WatchHeartRateSnapshotCopyWithImpl<$Res>
    implements _$WatchHeartRateSnapshotCopyWith<$Res> {
  __$WatchHeartRateSnapshotCopyWithImpl(this._self, this._then);

  final _WatchHeartRateSnapshot _self;
  final $Res Function(_WatchHeartRateSnapshot) _then;

/// Create a copy of WatchHeartRateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sentAt = null,Object? isSimulated = null,Object? status = null,Object? latestReading = freezed,}) {
  return _then(_WatchHeartRateSnapshot(
sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,isSimulated: null == isSimulated ? _self.isSimulated : isSimulated // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WatchHeartRateStatus,latestReading: freezed == latestReading ? _self.latestReading : latestReading // ignore: cast_nullable_to_non_nullable
as HeartRateSample?,
  ));
}

/// Create a copy of WatchHeartRateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WatchHeartRateStatusCopyWith<$Res> get status {
  
  return $WatchHeartRateStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}/// Create a copy of WatchHeartRateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HeartRateSampleCopyWith<$Res>? get latestReading {
    if (_self.latestReading == null) {
    return null;
  }

  return $HeartRateSampleCopyWith<$Res>(_self.latestReading!, (value) {
    return _then(_self.copyWith(latestReading: value));
  });
}
}

// dart format on
