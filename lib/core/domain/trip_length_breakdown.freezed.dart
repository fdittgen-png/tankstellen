// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_length_breakdown.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripLengthBucket {

/// Number of completed trips folded into this bucket.
 int get tripCount;/// Mean fuel consumption across the bucket, in litres per 100 km.
/// Aggregator-side this is computed as `totalLitres / totalDistanceKm * 100`,
/// or via Welford-style incremental update when folding a single trip
/// into the existing bucket — phase 2 owns that math.
 double get meanLPer100km;/// Sum of distance (km) across every trip in this bucket. Useful
/// for the UI "you drove X km on long trips this month" line and
/// as the denominator if a consumer needs to recompute the mean
/// at higher precision than [meanLPer100km] preserved.
 double get totalDistanceKm;/// Sum of fuel used (litres) across every trip in this bucket.
/// Same role as [totalDistanceKm] — kept so the mean can be
/// rederived without information loss.
 double get totalLitres;
/// Create a copy of TripLengthBucket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripLengthBucketCopyWith<TripLengthBucket> get copyWith => _$TripLengthBucketCopyWithImpl<TripLengthBucket>(this as TripLengthBucket, _$identity);

  /// Serializes this TripLengthBucket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripLengthBucket&&(identical(other.tripCount, tripCount) || other.tripCount == tripCount)&&(identical(other.meanLPer100km, meanLPer100km) || other.meanLPer100km == meanLPer100km)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.totalLitres, totalLitres) || other.totalLitres == totalLitres));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tripCount,meanLPer100km,totalDistanceKm,totalLitres);

@override
String toString() {
  return 'TripLengthBucket(tripCount: $tripCount, meanLPer100km: $meanLPer100km, totalDistanceKm: $totalDistanceKm, totalLitres: $totalLitres)';
}


}

/// @nodoc
abstract mixin class $TripLengthBucketCopyWith<$Res>  {
  factory $TripLengthBucketCopyWith(TripLengthBucket value, $Res Function(TripLengthBucket) _then) = _$TripLengthBucketCopyWithImpl;
@useResult
$Res call({
 int tripCount, double meanLPer100km, double totalDistanceKm, double totalLitres
});




}
/// @nodoc
class _$TripLengthBucketCopyWithImpl<$Res>
    implements $TripLengthBucketCopyWith<$Res> {
  _$TripLengthBucketCopyWithImpl(this._self, this._then);

  final TripLengthBucket _self;
  final $Res Function(TripLengthBucket) _then;

/// Create a copy of TripLengthBucket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tripCount = null,Object? meanLPer100km = null,Object? totalDistanceKm = null,Object? totalLitres = null,}) {
  return _then(_self.copyWith(
tripCount: null == tripCount ? _self.tripCount : tripCount // ignore: cast_nullable_to_non_nullable
as int,meanLPer100km: null == meanLPer100km ? _self.meanLPer100km : meanLPer100km // ignore: cast_nullable_to_non_nullable
as double,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,totalLitres: null == totalLitres ? _self.totalLitres : totalLitres // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TripLengthBucket].
extension TripLengthBucketPatterns on TripLengthBucket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripLengthBucket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripLengthBucket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripLengthBucket value)  $default,){
final _that = this;
switch (_that) {
case _TripLengthBucket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripLengthBucket value)?  $default,){
final _that = this;
switch (_that) {
case _TripLengthBucket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int tripCount,  double meanLPer100km,  double totalDistanceKm,  double totalLitres)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripLengthBucket() when $default != null:
return $default(_that.tripCount,_that.meanLPer100km,_that.totalDistanceKm,_that.totalLitres);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int tripCount,  double meanLPer100km,  double totalDistanceKm,  double totalLitres)  $default,) {final _that = this;
switch (_that) {
case _TripLengthBucket():
return $default(_that.tripCount,_that.meanLPer100km,_that.totalDistanceKm,_that.totalLitres);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int tripCount,  double meanLPer100km,  double totalDistanceKm,  double totalLitres)?  $default,) {final _that = this;
switch (_that) {
case _TripLengthBucket() when $default != null:
return $default(_that.tripCount,_that.meanLPer100km,_that.totalDistanceKm,_that.totalLitres);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripLengthBucket implements TripLengthBucket {
  const _TripLengthBucket({required this.tripCount, required this.meanLPer100km, required this.totalDistanceKm, required this.totalLitres});
  factory _TripLengthBucket.fromJson(Map<String, dynamic> json) => _$TripLengthBucketFromJson(json);

/// Number of completed trips folded into this bucket.
@override final  int tripCount;
/// Mean fuel consumption across the bucket, in litres per 100 km.
/// Aggregator-side this is computed as `totalLitres / totalDistanceKm * 100`,
/// or via Welford-style incremental update when folding a single trip
/// into the existing bucket — phase 2 owns that math.
@override final  double meanLPer100km;
/// Sum of distance (km) across every trip in this bucket. Useful
/// for the UI "you drove X km on long trips this month" line and
/// as the denominator if a consumer needs to recompute the mean
/// at higher precision than [meanLPer100km] preserved.
@override final  double totalDistanceKm;
/// Sum of fuel used (litres) across every trip in this bucket.
/// Same role as [totalDistanceKm] — kept so the mean can be
/// rederived without information loss.
@override final  double totalLitres;

/// Create a copy of TripLengthBucket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripLengthBucketCopyWith<_TripLengthBucket> get copyWith => __$TripLengthBucketCopyWithImpl<_TripLengthBucket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripLengthBucketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripLengthBucket&&(identical(other.tripCount, tripCount) || other.tripCount == tripCount)&&(identical(other.meanLPer100km, meanLPer100km) || other.meanLPer100km == meanLPer100km)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.totalLitres, totalLitres) || other.totalLitres == totalLitres));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tripCount,meanLPer100km,totalDistanceKm,totalLitres);

@override
String toString() {
  return 'TripLengthBucket(tripCount: $tripCount, meanLPer100km: $meanLPer100km, totalDistanceKm: $totalDistanceKm, totalLitres: $totalLitres)';
}


}

/// @nodoc
abstract mixin class _$TripLengthBucketCopyWith<$Res> implements $TripLengthBucketCopyWith<$Res> {
  factory _$TripLengthBucketCopyWith(_TripLengthBucket value, $Res Function(_TripLengthBucket) _then) = __$TripLengthBucketCopyWithImpl;
@override @useResult
$Res call({
 int tripCount, double meanLPer100km, double totalDistanceKm, double totalLitres
});




}
/// @nodoc
class __$TripLengthBucketCopyWithImpl<$Res>
    implements _$TripLengthBucketCopyWith<$Res> {
  __$TripLengthBucketCopyWithImpl(this._self, this._then);

  final _TripLengthBucket _self;
  final $Res Function(_TripLengthBucket) _then;

/// Create a copy of TripLengthBucket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tripCount = null,Object? meanLPer100km = null,Object? totalDistanceKm = null,Object? totalLitres = null,}) {
  return _then(_TripLengthBucket(
tripCount: null == tripCount ? _self.tripCount : tripCount // ignore: cast_nullable_to_non_nullable
as int,meanLPer100km: null == meanLPer100km ? _self.meanLPer100km : meanLPer100km // ignore: cast_nullable_to_non_nullable
as double,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,totalLitres: null == totalLitres ? _self.totalLitres : totalLitres // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$TripLengthBreakdown {

 TripLengthBucket? get short; TripLengthBucket? get medium; TripLengthBucket? get long;
/// Create a copy of TripLengthBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripLengthBreakdownCopyWith<TripLengthBreakdown> get copyWith => _$TripLengthBreakdownCopyWithImpl<TripLengthBreakdown>(this as TripLengthBreakdown, _$identity);

  /// Serializes this TripLengthBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripLengthBreakdown&&(identical(other.short, short) || other.short == short)&&(identical(other.medium, medium) || other.medium == medium)&&(identical(other.long, long) || other.long == long));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,short,medium,long);

@override
String toString() {
  return 'TripLengthBreakdown(short: $short, medium: $medium, long: $long)';
}


}

/// @nodoc
abstract mixin class $TripLengthBreakdownCopyWith<$Res>  {
  factory $TripLengthBreakdownCopyWith(TripLengthBreakdown value, $Res Function(TripLengthBreakdown) _then) = _$TripLengthBreakdownCopyWithImpl;
@useResult
$Res call({
 TripLengthBucket? short, TripLengthBucket? medium, TripLengthBucket? long
});


$TripLengthBucketCopyWith<$Res>? get short;$TripLengthBucketCopyWith<$Res>? get medium;$TripLengthBucketCopyWith<$Res>? get long;

}
/// @nodoc
class _$TripLengthBreakdownCopyWithImpl<$Res>
    implements $TripLengthBreakdownCopyWith<$Res> {
  _$TripLengthBreakdownCopyWithImpl(this._self, this._then);

  final TripLengthBreakdown _self;
  final $Res Function(TripLengthBreakdown) _then;

/// Create a copy of TripLengthBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? short = freezed,Object? medium = freezed,Object? long = freezed,}) {
  return _then(_self.copyWith(
short: freezed == short ? _self.short : short // ignore: cast_nullable_to_non_nullable
as TripLengthBucket?,medium: freezed == medium ? _self.medium : medium // ignore: cast_nullable_to_non_nullable
as TripLengthBucket?,long: freezed == long ? _self.long : long // ignore: cast_nullable_to_non_nullable
as TripLengthBucket?,
  ));
}
/// Create a copy of TripLengthBreakdown
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripLengthBucketCopyWith<$Res>? get short {
    if (_self.short == null) {
    return null;
  }

  return $TripLengthBucketCopyWith<$Res>(_self.short!, (value) {
    return _then(_self.copyWith(short: value));
  });
}/// Create a copy of TripLengthBreakdown
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripLengthBucketCopyWith<$Res>? get medium {
    if (_self.medium == null) {
    return null;
  }

  return $TripLengthBucketCopyWith<$Res>(_self.medium!, (value) {
    return _then(_self.copyWith(medium: value));
  });
}/// Create a copy of TripLengthBreakdown
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripLengthBucketCopyWith<$Res>? get long {
    if (_self.long == null) {
    return null;
  }

  return $TripLengthBucketCopyWith<$Res>(_self.long!, (value) {
    return _then(_self.copyWith(long: value));
  });
}
}


/// Adds pattern-matching-related methods to [TripLengthBreakdown].
extension TripLengthBreakdownPatterns on TripLengthBreakdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripLengthBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripLengthBreakdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripLengthBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _TripLengthBreakdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripLengthBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _TripLengthBreakdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TripLengthBucket? short,  TripLengthBucket? medium,  TripLengthBucket? long)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripLengthBreakdown() when $default != null:
return $default(_that.short,_that.medium,_that.long);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TripLengthBucket? short,  TripLengthBucket? medium,  TripLengthBucket? long)  $default,) {final _that = this;
switch (_that) {
case _TripLengthBreakdown():
return $default(_that.short,_that.medium,_that.long);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TripLengthBucket? short,  TripLengthBucket? medium,  TripLengthBucket? long)?  $default,) {final _that = this;
switch (_that) {
case _TripLengthBreakdown() when $default != null:
return $default(_that.short,_that.medium,_that.long);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripLengthBreakdown implements TripLengthBreakdown {
  const _TripLengthBreakdown({this.short, this.medium, this.long});
  factory _TripLengthBreakdown.fromJson(Map<String, dynamic> json) => _$TripLengthBreakdownFromJson(json);

@override final  TripLengthBucket? short;
@override final  TripLengthBucket? medium;
@override final  TripLengthBucket? long;

/// Create a copy of TripLengthBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripLengthBreakdownCopyWith<_TripLengthBreakdown> get copyWith => __$TripLengthBreakdownCopyWithImpl<_TripLengthBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripLengthBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripLengthBreakdown&&(identical(other.short, short) || other.short == short)&&(identical(other.medium, medium) || other.medium == medium)&&(identical(other.long, long) || other.long == long));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,short,medium,long);

@override
String toString() {
  return 'TripLengthBreakdown(short: $short, medium: $medium, long: $long)';
}


}

/// @nodoc
abstract mixin class _$TripLengthBreakdownCopyWith<$Res> implements $TripLengthBreakdownCopyWith<$Res> {
  factory _$TripLengthBreakdownCopyWith(_TripLengthBreakdown value, $Res Function(_TripLengthBreakdown) _then) = __$TripLengthBreakdownCopyWithImpl;
@override @useResult
$Res call({
 TripLengthBucket? short, TripLengthBucket? medium, TripLengthBucket? long
});


@override $TripLengthBucketCopyWith<$Res>? get short;@override $TripLengthBucketCopyWith<$Res>? get medium;@override $TripLengthBucketCopyWith<$Res>? get long;

}
/// @nodoc
class __$TripLengthBreakdownCopyWithImpl<$Res>
    implements _$TripLengthBreakdownCopyWith<$Res> {
  __$TripLengthBreakdownCopyWithImpl(this._self, this._then);

  final _TripLengthBreakdown _self;
  final $Res Function(_TripLengthBreakdown) _then;

/// Create a copy of TripLengthBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? short = freezed,Object? medium = freezed,Object? long = freezed,}) {
  return _then(_TripLengthBreakdown(
short: freezed == short ? _self.short : short // ignore: cast_nullable_to_non_nullable
as TripLengthBucket?,medium: freezed == medium ? _self.medium : medium // ignore: cast_nullable_to_non_nullable
as TripLengthBucket?,long: freezed == long ? _self.long : long // ignore: cast_nullable_to_non_nullable
as TripLengthBucket?,
  ));
}

/// Create a copy of TripLengthBreakdown
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripLengthBucketCopyWith<$Res>? get short {
    if (_self.short == null) {
    return null;
  }

  return $TripLengthBucketCopyWith<$Res>(_self.short!, (value) {
    return _then(_self.copyWith(short: value));
  });
}/// Create a copy of TripLengthBreakdown
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripLengthBucketCopyWith<$Res>? get medium {
    if (_self.medium == null) {
    return null;
  }

  return $TripLengthBucketCopyWith<$Res>(_self.medium!, (value) {
    return _then(_self.copyWith(medium: value));
  });
}/// Create a copy of TripLengthBreakdown
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripLengthBucketCopyWith<$Res>? get long {
    if (_self.long == null) {
    return null;
  }

  return $TripLengthBucketCopyWith<$Res>(_self.long!, (value) {
    return _then(_self.copyWith(long: value));
  });
}
}

// dart format on
