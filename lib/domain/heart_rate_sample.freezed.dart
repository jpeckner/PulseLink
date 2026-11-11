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


/// Create a copy of HeartRateSample
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeartRateSampleCopyWith<HeartRateSample> get copyWith => _$HeartRateSampleCopyWithImpl<HeartRateSample>(this as HeartRateSample, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HeartRateSample;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeartRateSample&&(identical(other.bpm, _this.bpm) || other.bpm == _this.bpm)&&(identical(other.timestamp, _this.timestamp) || other.timestamp == _this.timestamp)&&(identical(other.contact, _this.contact) || other.contact == _this.contact)&&const DeepCollectionEquality().equals(other.rrIntervals, _this.rrIntervals));
}


@override
int get hashCode {
  final _this = this as HeartRateSample;
  return Object.hash(runtimeType,_this.bpm,_this.timestamp,_this.contact,const DeepCollectionEquality().hash(_this.rrIntervals));
}

@override
String toString() {
  final _this = this as HeartRateSample;
  return 'HeartRateSample(bpm: ${_this.bpm}, timestamp: ${_this.timestamp}, contact: ${_this.contact}, rrIntervals: ${_this.rrIntervals})';
}


}

/// @nodoc
abstract mixin class $HeartRateSampleCopyWith<$Res>  {
  factory $HeartRateSampleCopyWith(HeartRateSample value, $Res Function(HeartRateSample) _then) = _$HeartRateSampleCopyWithImpl;
@useResult
$Res call({
 int bpm, DateTime timestamp, SensorContact contact, List<Duration> rrIntervals
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
@pragma('vm:prefer-inline') @override $Res call({Object? bpm = null,Object? timestamp = null,Object? contact = null,Object? rrIntervals = null,}) {
  return _then(HeartRateSample(
bpm: null == bpm ? _self.bpm : bpm // ignore: cast_nullable_to_non_nullable
as int,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,contact: null == contact ? _self.contact : contact // ignore: cast_nullable_to_non_nullable
as SensorContact,rrIntervals: null == rrIntervals ? _self.rrIntervals : rrIntervals // ignore: cast_nullable_to_non_nullable
as List<Duration>,
  ));
}

}



// dart format on
