// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pump_gain_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PumpGainEntry {

 double get gain; int get samples; DateTime? get updatedAt;
/// Create a copy of PumpGainEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PumpGainEntryCopyWith<PumpGainEntry> get copyWith => _$PumpGainEntryCopyWithImpl<PumpGainEntry>(this as PumpGainEntry, _$identity);

  /// Serializes this PumpGainEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PumpGainEntry&&(identical(other.gain, gain) || other.gain == gain)&&(identical(other.samples, samples) || other.samples == samples)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gain,samples,updatedAt);

@override
String toString() {
  return 'PumpGainEntry(gain: $gain, samples: $samples, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PumpGainEntryCopyWith<$Res>  {
  factory $PumpGainEntryCopyWith(PumpGainEntry value, $Res Function(PumpGainEntry) _then) = _$PumpGainEntryCopyWithImpl;
@useResult
$Res call({
 double gain, int samples, DateTime? updatedAt
});




}
/// @nodoc
class _$PumpGainEntryCopyWithImpl<$Res>
    implements $PumpGainEntryCopyWith<$Res> {
  _$PumpGainEntryCopyWithImpl(this._self, this._then);

  final PumpGainEntry _self;
  final $Res Function(PumpGainEntry) _then;

/// Create a copy of PumpGainEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gain = null,Object? samples = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
gain: null == gain ? _self.gain : gain // ignore: cast_nullable_to_non_nullable
as double,samples: null == samples ? _self.samples : samples // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PumpGainEntry].
extension PumpGainEntryPatterns on PumpGainEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PumpGainEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PumpGainEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PumpGainEntry value)  $default,){
final _that = this;
switch (_that) {
case _PumpGainEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PumpGainEntry value)?  $default,){
final _that = this;
switch (_that) {
case _PumpGainEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double gain,  int samples,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PumpGainEntry() when $default != null:
return $default(_that.gain,_that.samples,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double gain,  int samples,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PumpGainEntry():
return $default(_that.gain,_that.samples,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double gain,  int samples,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PumpGainEntry() when $default != null:
return $default(_that.gain,_that.samples,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PumpGainEntry implements PumpGainEntry {
  const _PumpGainEntry({this.gain = 1.0, this.samples = 0, this.updatedAt});
  factory _PumpGainEntry.fromJson(Map<String, dynamic> json) => _$PumpGainEntryFromJson(json);

@override@JsonKey() final  double gain;
@override@JsonKey() final  int samples;
@override final  DateTime? updatedAt;

/// Create a copy of PumpGainEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PumpGainEntryCopyWith<_PumpGainEntry> get copyWith => __$PumpGainEntryCopyWithImpl<_PumpGainEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PumpGainEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PumpGainEntry&&(identical(other.gain, gain) || other.gain == gain)&&(identical(other.samples, samples) || other.samples == samples)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gain,samples,updatedAt);

@override
String toString() {
  return 'PumpGainEntry(gain: $gain, samples: $samples, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PumpGainEntryCopyWith<$Res> implements $PumpGainEntryCopyWith<$Res> {
  factory _$PumpGainEntryCopyWith(_PumpGainEntry value, $Res Function(_PumpGainEntry) _then) = __$PumpGainEntryCopyWithImpl;
@override @useResult
$Res call({
 double gain, int samples, DateTime? updatedAt
});




}
/// @nodoc
class __$PumpGainEntryCopyWithImpl<$Res>
    implements _$PumpGainEntryCopyWith<$Res> {
  __$PumpGainEntryCopyWithImpl(this._self, this._then);

  final _PumpGainEntry _self;
  final $Res Function(_PumpGainEntry) _then;

/// Create a copy of PumpGainEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gain = null,Object? samples = null,Object? updatedAt = freezed,}) {
  return _then(_PumpGainEntry(
gain: null == gain ? _self.gain : gain // ignore: cast_nullable_to_non_nullable
as double,samples: null == samples ? _self.samples : samples // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
