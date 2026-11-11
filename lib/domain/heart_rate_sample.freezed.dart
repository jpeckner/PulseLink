// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'heart_rate_sample.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HeartRateSample {

 DateTime get timestamp;
/// Create a copy of HeartRateSample
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeartRateSampleCopyWith<HeartRateSample> get copyWith => _$HeartRateSampleCopyWithImpl<HeartRateSample>(this as HeartRateSample, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HeartRateSample;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeartRateSample&&(identical(other.timestamp, _this.timestamp) || other.timestamp == _this.timestamp));
}


@override
int get hashCode {
  final _this = this as HeartRateSample;
  return Object.hash(runtimeType,_this.timestamp);
}

@override
String toString() {
  final _this = this as HeartRateSample;
  return 'HeartRateSample(timestamp: ${_this.timestamp})';
}


}

/// @nodoc
abstract mixin class $HeartRateSampleCopyWith<$Res>  {
  factory $HeartRateSampleCopyWith(HeartRateSample value, $Res Function(HeartRateSample) _then) = _$HeartRateSampleCopyWithImpl;
@useResult
$Res call({
 DateTime timestamp
});




}
/// @nodoc
class _$HeartRateSampleCopyWithImpl<$Res>
    implements $HeartRateSampleCopyWith<$Res> {
  _$HeartRateSampleCopyWithImpl(this._self, this._then);

  final HeartRateSample _self;
  final $Res Function(HeartRateSample) _then;

/// Create a copy of HeartRateSample
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,}) {
  return _then(_self.copyWith(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [HeartRateSample].
extension HeartRateSamplePatterns on HeartRateSample {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MeasuredHeartRateSample value)?  measured,TResult Function( UnavailableHeartRateSample value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MeasuredHeartRateSample() when measured != null:
return measured(_that);case UnavailableHeartRateSample() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MeasuredHeartRateSample value)  measured,required TResult Function( UnavailableHeartRateSample value)  unavailable,}){
final _that = this;
switch (_that) {
case MeasuredHeartRateSample():
return measured(_that);case UnavailableHeartRateSample():
return unavailable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MeasuredHeartRateSample value)?  measured,TResult? Function( UnavailableHeartRateSample value)?  unavailable,}){
final _that = this;
switch (_that) {
case MeasuredHeartRateSample() when measured != null:
return measured(_that);case UnavailableHeartRateSample() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int bpm,  DateTime timestamp,  SensorContact contact,  List<Duration> rrIntervals)?  measured,TResult Function( DateTime timestamp,  HeartRateUnavailableReason reason)?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MeasuredHeartRateSample() when measured != null:
return measured(_that.bpm,_that.timestamp,_that.contact,_that.rrIntervals);case UnavailableHeartRateSample() when unavailable != null:
return unavailable(_that.timestamp,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int bpm,  DateTime timestamp,  SensorContact contact,  List<Duration> rrIntervals)  measured,required TResult Function( DateTime timestamp,  HeartRateUnavailableReason reason)  unavailable,}) {final _that = this;
switch (_that) {
case MeasuredHeartRateSample():
return measured(_that.bpm,_that.timestamp,_that.contact,_that.rrIntervals);case UnavailableHeartRateSample():
return unavailable(_that.timestamp,_that.reason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int bpm,  DateTime timestamp,  SensorContact contact,  List<Duration> rrIntervals)?  measured,TResult? Function( DateTime timestamp,  HeartRateUnavailableReason reason)?  unavailable,}) {final _that = this;
switch (_that) {
case MeasuredHeartRateSample() when measured != null:
return measured(_that.bpm,_that.timestamp,_that.contact,_that.rrIntervals);case UnavailableHeartRateSample() when unavailable != null:
return unavailable(_that.timestamp,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class MeasuredHeartRateSample implements HeartRateSample {
  const MeasuredHeartRateSample({required this.bpm, required this.timestamp, required this.contact,  List<Duration> rrIntervals = const <Duration>[]}): assert(bpm > 0, 'A measured sample needs a bpm above 0'),assert(contact != SensorContact.notDetected, 'A sample without skin contact must be unavailable'),_rrIntervals = rrIntervals;
  

 final  int bpm;
@override final  DateTime timestamp;
 final  SensorContact contact;
 final  List<Duration> _rrIntervals;
@JsonKey() List<Duration> get rrIntervals {
  if (_rrIntervals is EqualUnmodifiableListView) return _rrIntervals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rrIntervals);
}


/// Create a copy of HeartRateSample
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeasuredHeartRateSampleCopyWith<MeasuredHeartRateSample> get copyWith => _$MeasuredHeartRateSampleCopyWithImpl<MeasuredHeartRateSample>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MeasuredHeartRateSample&&(identical(other.bpm, bpm) || other.bpm == bpm)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.contact, contact) || other.contact == contact)&&const DeepCollectionEquality().equals(other.rrIntervals, _rrIntervals));
}


@override
int get hashCode {
    return Object.hash(runtimeType,bpm,timestamp,contact,const DeepCollectionEquality().hash(_rrIntervals));
}

@override
String toString() {
    return 'HeartRateSample.measured(bpm: $bpm, timestamp: $timestamp, contact: $contact, rrIntervals: $rrIntervals)';
}


}

/// @nodoc
abstract mixin class $MeasuredHeartRateSampleCopyWith<$Res> implements $HeartRateSampleCopyWith<$Res> {
  factory $MeasuredHeartRateSampleCopyWith(MeasuredHeartRateSample value, $Res Function(MeasuredHeartRateSample) _then) = _$MeasuredHeartRateSampleCopyWithImpl;
@override @useResult
$Res call({
 int bpm, DateTime timestamp, SensorContact contact, List<Duration> rrIntervals
});




}
/// @nodoc
class _$MeasuredHeartRateSampleCopyWithImpl<$Res>
    implements $MeasuredHeartRateSampleCopyWith<$Res> {
  _$MeasuredHeartRateSampleCopyWithImpl(this._self, this._then);

  final MeasuredHeartRateSample _self;
  final $Res Function(MeasuredHeartRateSample) _then;

/// Create a copy of HeartRateSample
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bpm = null,Object? timestamp = null,Object? contact = null,Object? rrIntervals = null,}) {
  return _then(MeasuredHeartRateSample(
bpm: null == bpm ? _self.bpm : bpm // ignore: cast_nullable_to_non_nullable
as int,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,contact: null == contact ? _self.contact : contact // ignore: cast_nullable_to_non_nullable
as SensorContact,rrIntervals: null == rrIntervals ? _self._rrIntervals : rrIntervals // ignore: cast_nullable_to_non_nullable
as List<Duration>,
  ));
}


}

/// @nodoc


class UnavailableHeartRateSample implements HeartRateSample {
  const UnavailableHeartRateSample({required this.timestamp, required this.reason});
  

@override final  DateTime timestamp;
 final  HeartRateUnavailableReason reason;

/// Create a copy of HeartRateSample
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnavailableHeartRateSampleCopyWith<UnavailableHeartRateSample> get copyWith => _$UnavailableHeartRateSampleCopyWithImpl<UnavailableHeartRateSample>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnavailableHeartRateSample&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,timestamp,reason);
}

@override
String toString() {
    return 'HeartRateSample.unavailable(timestamp: $timestamp, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $UnavailableHeartRateSampleCopyWith<$Res> implements $HeartRateSampleCopyWith<$Res> {
  factory $UnavailableHeartRateSampleCopyWith(UnavailableHeartRateSample value, $Res Function(UnavailableHeartRateSample) _then) = _$UnavailableHeartRateSampleCopyWithImpl;
@override @useResult
$Res call({
 DateTime timestamp, HeartRateUnavailableReason reason
});




}
/// @nodoc
class _$UnavailableHeartRateSampleCopyWithImpl<$Res>
    implements $UnavailableHeartRateSampleCopyWith<$Res> {
  _$UnavailableHeartRateSampleCopyWithImpl(this._self, this._then);

  final UnavailableHeartRateSample _self;
  final $Res Function(UnavailableHeartRateSample) _then;

/// Create a copy of HeartRateSample
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? reason = null,}) {
  return _then(UnavailableHeartRateSample(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as HeartRateUnavailableReason,
  ));
}


}

// dart format on
