// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'speed_consumption_histogram.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SpeedBand {

/// Lower bound of the band (km/h, inclusive).
 int get minKmh;/// Upper bound of the band (km/h, exclusive). `null` for the
/// open-ended top band — speeds at or above [minKmh] without an
/// upper cutoff (autobahn / motorway "everything else" tail).
 int? get maxKmh;/// Number of speed-consumption samples folded into this band.
/// Aggregator-side this is the count of `TripDetailSample`s whose
/// instantaneous speed fell inside the half-open interval; phase 2
/// owns that classification.
 int get sampleCount;/// Mean fuel consumption across samples in this band, in litres
/// per 100 km. Computed by the phase-2 aggregator from the stored
/// totals; persisted directly so the UI doesn't have to re-derive.
 double get meanLPer100km;/// Fraction of total observed driving time that fell into this
/// band, in `[0, 1]`. Across every band in a populated
/// [SpeedConsumptionHistogram] the share rolls up to `1.0`
/// (modulo float rounding). Useful for "you spend 40 % of your
/// driving in 50–80 km/h" callouts on the vehicle profile screen.
 double get timeShareFraction;
/// Create a copy of SpeedBand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedBandCopyWith<SpeedBand> get copyWith => _$SpeedBandCopyWithImpl<SpeedBand>(this as SpeedBand, _$identity);

  /// Serializes this SpeedBand to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedBand&&(identical(other.minKmh, minKmh) || other.minKmh == minKmh)&&(identical(other.maxKmh, maxKmh) || other.maxKmh == maxKmh)&&(identical(other.sampleCount, sampleCount) || other.sampleCount == sampleCount)&&(identical(other.meanLPer100km, meanLPer100km) || other.meanLPer100km == meanLPer100km)&&(identical(other.timeShareFraction, timeShareFraction) || other.timeShareFraction == timeShareFraction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minKmh,maxKmh,sampleCount,meanLPer100km,timeShareFraction);

@override
String toString() {
  return 'SpeedBand(minKmh: $minKmh, maxKmh: $maxKmh, sampleCount: $sampleCount, meanLPer100km: $meanLPer100km, timeShareFraction: $timeShareFraction)';
}


}

/// @nodoc
abstract mixin class $SpeedBandCopyWith<$Res>  {
  factory $SpeedBandCopyWith(SpeedBand value, $Res Function(SpeedBand) _then) = _$SpeedBandCopyWithImpl;
@useResult
$Res call({
 int minKmh, int? maxKmh, int sampleCount, double meanLPer100km, double timeShareFraction
});




}
/// @nodoc
class _$SpeedBandCopyWithImpl<$Res>
    implements $SpeedBandCopyWith<$Res> {
  _$SpeedBandCopyWithImpl(this._self, this._then);

  final SpeedBand _self;
  final $Res Function(SpeedBand) _then;

/// Create a copy of SpeedBand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minKmh = null,Object? maxKmh = freezed,Object? sampleCount = null,Object? meanLPer100km = null,Object? timeShareFraction = null,}) {
  return _then(_self.copyWith(
minKmh: null == minKmh ? _self.minKmh : minKmh // ignore: cast_nullable_to_non_nullable
as int,maxKmh: freezed == maxKmh ? _self.maxKmh : maxKmh // ignore: cast_nullable_to_non_nullable
as int?,sampleCount: null == sampleCount ? _self.sampleCount : sampleCount // ignore: cast_nullable_to_non_nullable
as int,meanLPer100km: null == meanLPer100km ? _self.meanLPer100km : meanLPer100km // ignore: cast_nullable_to_non_nullable
as double,timeShareFraction: null == timeShareFraction ? _self.timeShareFraction : timeShareFraction // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SpeedBand].
extension SpeedBandPatterns on SpeedBand {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeedBand value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeedBand() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeedBand value)  $default,){
final _that = this;
switch (_that) {
case _SpeedBand():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeedBand value)?  $default,){
final _that = this;
switch (_that) {
case _SpeedBand() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int minKmh,  int? maxKmh,  int sampleCount,  double meanLPer100km,  double timeShareFraction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedBand() when $default != null:
return $default(_that.minKmh,_that.maxKmh,_that.sampleCount,_that.meanLPer100km,_that.timeShareFraction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int minKmh,  int? maxKmh,  int sampleCount,  double meanLPer100km,  double timeShareFraction)  $default,) {final _that = this;
switch (_that) {
case _SpeedBand():
return $default(_that.minKmh,_that.maxKmh,_that.sampleCount,_that.meanLPer100km,_that.timeShareFraction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int minKmh,  int? maxKmh,  int sampleCount,  double meanLPer100km,  double timeShareFraction)?  $default,) {final _that = this;
switch (_that) {
case _SpeedBand() when $default != null:
return $default(_that.minKmh,_that.maxKmh,_that.sampleCount,_that.meanLPer100km,_that.timeShareFraction);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpeedBand implements SpeedBand {
  const _SpeedBand({required this.minKmh, required this.maxKmh, required this.sampleCount, required this.meanLPer100km, required this.timeShareFraction});
  factory _SpeedBand.fromJson(Map<String, dynamic> json) => _$SpeedBandFromJson(json);

/// Lower bound of the band (km/h, inclusive).
@override final  int minKmh;
/// Upper bound of the band (km/h, exclusive). `null` for the
/// open-ended top band — speeds at or above [minKmh] without an
/// upper cutoff (autobahn / motorway "everything else" tail).
@override final  int? maxKmh;
/// Number of speed-consumption samples folded into this band.
/// Aggregator-side this is the count of `TripDetailSample`s whose
/// instantaneous speed fell inside the half-open interval; phase 2
/// owns that classification.
@override final  int sampleCount;
/// Mean fuel consumption across samples in this band, in litres
/// per 100 km. Computed by the phase-2 aggregator from the stored
/// totals; persisted directly so the UI doesn't have to re-derive.
@override final  double meanLPer100km;
/// Fraction of total observed driving time that fell into this
/// band, in `[0, 1]`. Across every band in a populated
/// [SpeedConsumptionHistogram] the share rolls up to `1.0`
/// (modulo float rounding). Useful for "you spend 40 % of your
/// driving in 50–80 km/h" callouts on the vehicle profile screen.
@override final  double timeShareFraction;

/// Create a copy of SpeedBand
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedBandCopyWith<_SpeedBand> get copyWith => __$SpeedBandCopyWithImpl<_SpeedBand>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpeedBandToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedBand&&(identical(other.minKmh, minKmh) || other.minKmh == minKmh)&&(identical(other.maxKmh, maxKmh) || other.maxKmh == maxKmh)&&(identical(other.sampleCount, sampleCount) || other.sampleCount == sampleCount)&&(identical(other.meanLPer100km, meanLPer100km) || other.meanLPer100km == meanLPer100km)&&(identical(other.timeShareFraction, timeShareFraction) || other.timeShareFraction == timeShareFraction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minKmh,maxKmh,sampleCount,meanLPer100km,timeShareFraction);

@override
String toString() {
  return 'SpeedBand(minKmh: $minKmh, maxKmh: $maxKmh, sampleCount: $sampleCount, meanLPer100km: $meanLPer100km, timeShareFraction: $timeShareFraction)';
}


}

/// @nodoc
abstract mixin class _$SpeedBandCopyWith<$Res> implements $SpeedBandCopyWith<$Res> {
  factory _$SpeedBandCopyWith(_SpeedBand value, $Res Function(_SpeedBand) _then) = __$SpeedBandCopyWithImpl;
@override @useResult
$Res call({
 int minKmh, int? maxKmh, int sampleCount, double meanLPer100km, double timeShareFraction
});




}
/// @nodoc
class __$SpeedBandCopyWithImpl<$Res>
    implements _$SpeedBandCopyWith<$Res> {
  __$SpeedBandCopyWithImpl(this._self, this._then);

  final _SpeedBand _self;
  final $Res Function(_SpeedBand) _then;

/// Create a copy of SpeedBand
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minKmh = null,Object? maxKmh = freezed,Object? sampleCount = null,Object? meanLPer100km = null,Object? timeShareFraction = null,}) {
  return _then(_SpeedBand(
minKmh: null == minKmh ? _self.minKmh : minKmh // ignore: cast_nullable_to_non_nullable
as int,maxKmh: freezed == maxKmh ? _self.maxKmh : maxKmh // ignore: cast_nullable_to_non_nullable
as int?,sampleCount: null == sampleCount ? _self.sampleCount : sampleCount // ignore: cast_nullable_to_non_nullable
as int,meanLPer100km: null == meanLPer100km ? _self.meanLPer100km : meanLPer100km // ignore: cast_nullable_to_non_nullable
as double,timeShareFraction: null == timeShareFraction ? _self.timeShareFraction : timeShareFraction // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$SpeedConsumptionHistogram {

 List<SpeedBand> get bands;
/// Create a copy of SpeedConsumptionHistogram
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedConsumptionHistogramCopyWith<SpeedConsumptionHistogram> get copyWith => _$SpeedConsumptionHistogramCopyWithImpl<SpeedConsumptionHistogram>(this as SpeedConsumptionHistogram, _$identity);

  /// Serializes this SpeedConsumptionHistogram to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedConsumptionHistogram&&const DeepCollectionEquality().equals(other.bands, bands));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(bands));

@override
String toString() {
  return 'SpeedConsumptionHistogram(bands: $bands)';
}


}

/// @nodoc
abstract mixin class $SpeedConsumptionHistogramCopyWith<$Res>  {
  factory $SpeedConsumptionHistogramCopyWith(SpeedConsumptionHistogram value, $Res Function(SpeedConsumptionHistogram) _then) = _$SpeedConsumptionHistogramCopyWithImpl;
@useResult
$Res call({
 List<SpeedBand> bands
});




}
/// @nodoc
class _$SpeedConsumptionHistogramCopyWithImpl<$Res>
    implements $SpeedConsumptionHistogramCopyWith<$Res> {
  _$SpeedConsumptionHistogramCopyWithImpl(this._self, this._then);

  final SpeedConsumptionHistogram _self;
  final $Res Function(SpeedConsumptionHistogram) _then;

/// Create a copy of SpeedConsumptionHistogram
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bands = null,}) {
  return _then(_self.copyWith(
bands: null == bands ? _self.bands : bands // ignore: cast_nullable_to_non_nullable
as List<SpeedBand>,
  ));
}

}


/// Adds pattern-matching-related methods to [SpeedConsumptionHistogram].
extension SpeedConsumptionHistogramPatterns on SpeedConsumptionHistogram {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpeedConsumptionHistogram value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpeedConsumptionHistogram() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpeedConsumptionHistogram value)  $default,){
final _that = this;
switch (_that) {
case _SpeedConsumptionHistogram():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpeedConsumptionHistogram value)?  $default,){
final _that = this;
switch (_that) {
case _SpeedConsumptionHistogram() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SpeedBand> bands)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpeedConsumptionHistogram() when $default != null:
return $default(_that.bands);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SpeedBand> bands)  $default,) {final _that = this;
switch (_that) {
case _SpeedConsumptionHistogram():
return $default(_that.bands);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SpeedBand> bands)?  $default,) {final _that = this;
switch (_that) {
case _SpeedConsumptionHistogram() when $default != null:
return $default(_that.bands);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpeedConsumptionHistogram implements SpeedConsumptionHistogram {
  const _SpeedConsumptionHistogram({final  List<SpeedBand> bands = const <SpeedBand>[]}): _bands = bands;
  factory _SpeedConsumptionHistogram.fromJson(Map<String, dynamic> json) => _$SpeedConsumptionHistogramFromJson(json);

 final  List<SpeedBand> _bands;
@override@JsonKey() List<SpeedBand> get bands {
  if (_bands is EqualUnmodifiableListView) return _bands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bands);
}


/// Create a copy of SpeedConsumptionHistogram
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpeedConsumptionHistogramCopyWith<_SpeedConsumptionHistogram> get copyWith => __$SpeedConsumptionHistogramCopyWithImpl<_SpeedConsumptionHistogram>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpeedConsumptionHistogramToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpeedConsumptionHistogram&&const DeepCollectionEquality().equals(other._bands, _bands));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_bands));

@override
String toString() {
  return 'SpeedConsumptionHistogram(bands: $bands)';
}


}

/// @nodoc
abstract mixin class _$SpeedConsumptionHistogramCopyWith<$Res> implements $SpeedConsumptionHistogramCopyWith<$Res> {
  factory _$SpeedConsumptionHistogramCopyWith(_SpeedConsumptionHistogram value, $Res Function(_SpeedConsumptionHistogram) _then) = __$SpeedConsumptionHistogramCopyWithImpl;
@override @useResult
$Res call({
 List<SpeedBand> bands
});




}
/// @nodoc
class __$SpeedConsumptionHistogramCopyWithImpl<$Res>
    implements _$SpeedConsumptionHistogramCopyWith<$Res> {
  __$SpeedConsumptionHistogramCopyWithImpl(this._self, this._then);

  final _SpeedConsumptionHistogram _self;
  final $Res Function(_SpeedConsumptionHistogram) _then;

/// Create a copy of SpeedConsumptionHistogram
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bands = null,}) {
  return _then(_SpeedConsumptionHistogram(
bands: null == bands ? _self._bands : bands // ignore: cast_nullable_to_non_nullable
as List<SpeedBand>,
  ));
}


}

// dart format on
