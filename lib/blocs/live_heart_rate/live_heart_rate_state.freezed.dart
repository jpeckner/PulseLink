// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_heart_rate_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LiveHeartRateState {

 bool get isSimulated;
/// Create a copy of LiveHeartRateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveHeartRateStateCopyWith<LiveHeartRateState> get copyWith => _$LiveHeartRateStateCopyWithImpl<LiveHeartRateState>(this as LiveHeartRateState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LiveHeartRateState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveHeartRateState&&(identical(other.isSimulated, _this.isSimulated) || other.isSimulated == _this.isSimulated));
}


@override
int get hashCode {
  final _this = this as LiveHeartRateState;
  return Object.hash(runtimeType,_this.isSimulated);
}

@override
String toString() {
  final _this = this as LiveHeartRateState;
  return 'LiveHeartRateState(isSimulated: ${_this.isSimulated})';
}


}

/// @nodoc
abstract mixin class $LiveHeartRateStateCopyWith<$Res>  {
  factory $LiveHeartRateStateCopyWith(LiveHeartRateState value, $Res Function(LiveHeartRateState) _then) = _$LiveHeartRateStateCopyWithImpl;
@useResult
$Res call({
 bool isSimulated
});




}
/// @nodoc
class _$LiveHeartRateStateCopyWithImpl<$Res>
    implements $LiveHeartRateStateCopyWith<$Res> {
  _$LiveHeartRateStateCopyWithImpl(this._self, this._then);

  final LiveHeartRateState _self;
  final $Res Function(LiveHeartRateState) _then;

/// Create a copy of LiveHeartRateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isSimulated = null,}) {
  return _then(_self.copyWith(
isSimulated: null == isSimulated ? _self.isSimulated : isSimulated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveHeartRateState].
extension LiveHeartRateStatePatterns on LiveHeartRateState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LiveHeartRateWaiting value)?  waiting,TResult Function( LiveHeartRateReading value)?  reading,TResult Function( LiveHeartRateConnectionFailed value)?  connectionFailed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LiveHeartRateWaiting() when waiting != null:
return waiting(_that);case LiveHeartRateReading() when reading != null:
return reading(_that);case LiveHeartRateConnectionFailed() when connectionFailed != null:
return connectionFailed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LiveHeartRateWaiting value)  waiting,required TResult Function( LiveHeartRateReading value)  reading,required TResult Function( LiveHeartRateConnectionFailed value)  connectionFailed,}){
final _that = this;
switch (_that) {
case LiveHeartRateWaiting():
return waiting(_that);case LiveHeartRateReading():
return reading(_that);case LiveHeartRateConnectionFailed():
return connectionFailed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LiveHeartRateWaiting value)?  waiting,TResult? Function( LiveHeartRateReading value)?  reading,TResult? Function( LiveHeartRateConnectionFailed value)?  connectionFailed,}){
final _that = this;
switch (_that) {
case LiveHeartRateWaiting() when waiting != null:
return waiting(_that);case LiveHeartRateReading() when reading != null:
return reading(_that);case LiveHeartRateConnectionFailed() when connectionFailed != null:
return connectionFailed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool isSimulated)?  waiting,TResult Function( HeartRateSample sample,  bool isStale,  bool isSimulated)?  reading,TResult Function( StrapConnectionFailure failure,  bool isSimulated)?  connectionFailed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LiveHeartRateWaiting() when waiting != null:
return waiting(_that.isSimulated);case LiveHeartRateReading() when reading != null:
return reading(_that.sample,_that.isStale,_that.isSimulated);case LiveHeartRateConnectionFailed() when connectionFailed != null:
return connectionFailed(_that.failure,_that.isSimulated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool isSimulated)  waiting,required TResult Function( HeartRateSample sample,  bool isStale,  bool isSimulated)  reading,required TResult Function( StrapConnectionFailure failure,  bool isSimulated)  connectionFailed,}) {final _that = this;
switch (_that) {
case LiveHeartRateWaiting():
return waiting(_that.isSimulated);case LiveHeartRateReading():
return reading(_that.sample,_that.isStale,_that.isSimulated);case LiveHeartRateConnectionFailed():
return connectionFailed(_that.failure,_that.isSimulated);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool isSimulated)?  waiting,TResult? Function( HeartRateSample sample,  bool isStale,  bool isSimulated)?  reading,TResult? Function( StrapConnectionFailure failure,  bool isSimulated)?  connectionFailed,}) {final _that = this;
switch (_that) {
case LiveHeartRateWaiting() when waiting != null:
return waiting(_that.isSimulated);case LiveHeartRateReading() when reading != null:
return reading(_that.sample,_that.isStale,_that.isSimulated);case LiveHeartRateConnectionFailed() when connectionFailed != null:
return connectionFailed(_that.failure,_that.isSimulated);case _:
  return null;

}
}

}

/// @nodoc


class LiveHeartRateWaiting implements LiveHeartRateState {
  const LiveHeartRateWaiting({required this.isSimulated});
  

@override final  bool isSimulated;

/// Create a copy of LiveHeartRateState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveHeartRateWaitingCopyWith<LiveHeartRateWaiting> get copyWith => _$LiveHeartRateWaitingCopyWithImpl<LiveHeartRateWaiting>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveHeartRateWaiting&&(identical(other.isSimulated, isSimulated) || other.isSimulated == isSimulated));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isSimulated);
}

@override
String toString() {
    return 'LiveHeartRateState.waiting(isSimulated: $isSimulated)';
}


}

/// @nodoc
abstract mixin class $LiveHeartRateWaitingCopyWith<$Res> implements $LiveHeartRateStateCopyWith<$Res> {
  factory $LiveHeartRateWaitingCopyWith(LiveHeartRateWaiting value, $Res Function(LiveHeartRateWaiting) _then) = _$LiveHeartRateWaitingCopyWithImpl;
@override @useResult
$Res call({
 bool isSimulated
});




}
/// @nodoc
class _$LiveHeartRateWaitingCopyWithImpl<$Res>
    implements $LiveHeartRateWaitingCopyWith<$Res> {
  _$LiveHeartRateWaitingCopyWithImpl(this._self, this._then);

  final LiveHeartRateWaiting _self;
  final $Res Function(LiveHeartRateWaiting) _then;

/// Create a copy of LiveHeartRateState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isSimulated = null,}) {
  return _then(LiveHeartRateWaiting(
isSimulated: null == isSimulated ? _self.isSimulated : isSimulated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class LiveHeartRateReading implements LiveHeartRateState {
  const LiveHeartRateReading({required this.sample, required this.isStale, required this.isSimulated});
  

 final  HeartRateSample sample;
 final  bool isStale;
@override final  bool isSimulated;

/// Create a copy of LiveHeartRateState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveHeartRateReadingCopyWith<LiveHeartRateReading> get copyWith => _$LiveHeartRateReadingCopyWithImpl<LiveHeartRateReading>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveHeartRateReading&&(identical(other.sample, sample) || other.sample == sample)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&(identical(other.isSimulated, isSimulated) || other.isSimulated == isSimulated));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sample,isStale,isSimulated);
}

@override
String toString() {
    return 'LiveHeartRateState.reading(sample: $sample, isStale: $isStale, isSimulated: $isSimulated)';
}


}

/// @nodoc
abstract mixin class $LiveHeartRateReadingCopyWith<$Res> implements $LiveHeartRateStateCopyWith<$Res> {
  factory $LiveHeartRateReadingCopyWith(LiveHeartRateReading value, $Res Function(LiveHeartRateReading) _then) = _$LiveHeartRateReadingCopyWithImpl;
@override @useResult
$Res call({
 HeartRateSample sample, bool isStale, bool isSimulated
});


$HeartRateSampleCopyWith<$Res> get sample;

}
/// @nodoc
class _$LiveHeartRateReadingCopyWithImpl<$Res>
    implements $LiveHeartRateReadingCopyWith<$Res> {
  _$LiveHeartRateReadingCopyWithImpl(this._self, this._then);

  final LiveHeartRateReading _self;
  final $Res Function(LiveHeartRateReading) _then;

/// Create a copy of LiveHeartRateState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sample = null,Object? isStale = null,Object? isSimulated = null,}) {
  return _then(LiveHeartRateReading(
sample: null == sample ? _self.sample : sample // ignore: cast_nullable_to_non_nullable
as HeartRateSample,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,isSimulated: null == isSimulated ? _self.isSimulated : isSimulated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of LiveHeartRateState
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


class LiveHeartRateConnectionFailed implements LiveHeartRateState {
  const LiveHeartRateConnectionFailed({required this.failure, required this.isSimulated});
  

 final  StrapConnectionFailure failure;
@override final  bool isSimulated;

/// Create a copy of LiveHeartRateState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveHeartRateConnectionFailedCopyWith<LiveHeartRateConnectionFailed> get copyWith => _$LiveHeartRateConnectionFailedCopyWithImpl<LiveHeartRateConnectionFailed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveHeartRateConnectionFailed&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.isSimulated, isSimulated) || other.isSimulated == isSimulated));
}


@override
int get hashCode {
    return Object.hash(runtimeType,failure,isSimulated);
}

@override
String toString() {
    return 'LiveHeartRateState.connectionFailed(failure: $failure, isSimulated: $isSimulated)';
}


}

/// @nodoc
abstract mixin class $LiveHeartRateConnectionFailedCopyWith<$Res> implements $LiveHeartRateStateCopyWith<$Res> {
  factory $LiveHeartRateConnectionFailedCopyWith(LiveHeartRateConnectionFailed value, $Res Function(LiveHeartRateConnectionFailed) _then) = _$LiveHeartRateConnectionFailedCopyWithImpl;
@override @useResult
$Res call({
 StrapConnectionFailure failure, bool isSimulated
});


$StrapConnectionFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$LiveHeartRateConnectionFailedCopyWithImpl<$Res>
    implements $LiveHeartRateConnectionFailedCopyWith<$Res> {
  _$LiveHeartRateConnectionFailedCopyWithImpl(this._self, this._then);

  final LiveHeartRateConnectionFailed _self;
  final $Res Function(LiveHeartRateConnectionFailed) _then;

/// Create a copy of LiveHeartRateState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? isSimulated = null,}) {
  return _then(LiveHeartRateConnectionFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as StrapConnectionFailure,isSimulated: null == isSimulated ? _self.isSimulated : isSimulated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of LiveHeartRateState
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
