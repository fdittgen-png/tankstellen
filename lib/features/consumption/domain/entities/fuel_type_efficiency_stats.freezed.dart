// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fuel_type_efficiency_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FuelEfficiencyBucket {

/// The interval's largest-share fuel — the only fuel for a PURE bucket,
/// the first half of an `A/B` mix label otherwise.
 FuelType get dominant;/// The interval's second-largest-share fuel, present only for a MIX
/// bucket. `null` ⇒ this is a PURE bucket.
 FuelType? get secondary;
/// Create a copy of FuelEfficiencyBucket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FuelEfficiencyBucketCopyWith<FuelEfficiencyBucket> get copyWith => _$FuelEfficiencyBucketCopyWithImpl<FuelEfficiencyBucket>(this as FuelEfficiencyBucket, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FuelEfficiencyBucket&&(identical(other.dominant, dominant) || other.dominant == dominant)&&(identical(other.secondary, secondary) || other.secondary == secondary));
}


@override
int get hashCode => Object.hash(runtimeType,dominant,secondary);

@override
String toString() {
  return 'FuelEfficiencyBucket(dominant: $dominant, secondary: $secondary)';
}


}

/// @nodoc
abstract mixin class $FuelEfficiencyBucketCopyWith<$Res>  {
  factory $FuelEfficiencyBucketCopyWith(FuelEfficiencyBucket value, $Res Function(FuelEfficiencyBucket) _then) = _$FuelEfficiencyBucketCopyWithImpl;
@useResult
$Res call({
 FuelType dominant, FuelType? secondary
});




}
/// @nodoc
class _$FuelEfficiencyBucketCopyWithImpl<$Res>
    implements $FuelEfficiencyBucketCopyWith<$Res> {
  _$FuelEfficiencyBucketCopyWithImpl(this._self, this._then);

  final FuelEfficiencyBucket _self;
  final $Res Function(FuelEfficiencyBucket) _then;

/// Create a copy of FuelEfficiencyBucket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dominant = null,Object? secondary = freezed,}) {
  return _then(_self.copyWith(
dominant: null == dominant ? _self.dominant : dominant // ignore: cast_nullable_to_non_nullable
as FuelType,secondary: freezed == secondary ? _self.secondary : secondary // ignore: cast_nullable_to_non_nullable
as FuelType?,
  ));
}

}


/// Adds pattern-matching-related methods to [FuelEfficiencyBucket].
extension FuelEfficiencyBucketPatterns on FuelEfficiencyBucket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FuelEfficiencyBucket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FuelEfficiencyBucket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FuelEfficiencyBucket value)  $default,){
final _that = this;
switch (_that) {
case _FuelEfficiencyBucket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FuelEfficiencyBucket value)?  $default,){
final _that = this;
switch (_that) {
case _FuelEfficiencyBucket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FuelType dominant,  FuelType? secondary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FuelEfficiencyBucket() when $default != null:
return $default(_that.dominant,_that.secondary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FuelType dominant,  FuelType? secondary)  $default,) {final _that = this;
switch (_that) {
case _FuelEfficiencyBucket():
return $default(_that.dominant,_that.secondary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FuelType dominant,  FuelType? secondary)?  $default,) {final _that = this;
switch (_that) {
case _FuelEfficiencyBucket() when $default != null:
return $default(_that.dominant,_that.secondary);case _:
  return null;

}
}

}

/// @nodoc


class _FuelEfficiencyBucket extends FuelEfficiencyBucket {
  const _FuelEfficiencyBucket({required this.dominant, this.secondary}): super._();
  

/// The interval's largest-share fuel — the only fuel for a PURE bucket,
/// the first half of an `A/B` mix label otherwise.
@override final  FuelType dominant;
/// The interval's second-largest-share fuel, present only for a MIX
/// bucket. `null` ⇒ this is a PURE bucket.
@override final  FuelType? secondary;

/// Create a copy of FuelEfficiencyBucket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FuelEfficiencyBucketCopyWith<_FuelEfficiencyBucket> get copyWith => __$FuelEfficiencyBucketCopyWithImpl<_FuelEfficiencyBucket>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FuelEfficiencyBucket&&(identical(other.dominant, dominant) || other.dominant == dominant)&&(identical(other.secondary, secondary) || other.secondary == secondary));
}


@override
int get hashCode => Object.hash(runtimeType,dominant,secondary);

@override
String toString() {
  return 'FuelEfficiencyBucket(dominant: $dominant, secondary: $secondary)';
}


}

/// @nodoc
abstract mixin class _$FuelEfficiencyBucketCopyWith<$Res> implements $FuelEfficiencyBucketCopyWith<$Res> {
  factory _$FuelEfficiencyBucketCopyWith(_FuelEfficiencyBucket value, $Res Function(_FuelEfficiencyBucket) _then) = __$FuelEfficiencyBucketCopyWithImpl;
@override @useResult
$Res call({
 FuelType dominant, FuelType? secondary
});




}
/// @nodoc
class __$FuelEfficiencyBucketCopyWithImpl<$Res>
    implements _$FuelEfficiencyBucketCopyWith<$Res> {
  __$FuelEfficiencyBucketCopyWithImpl(this._self, this._then);

  final _FuelEfficiencyBucket _self;
  final $Res Function(_FuelEfficiencyBucket) _then;

/// Create a copy of FuelEfficiencyBucket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dominant = null,Object? secondary = freezed,}) {
  return _then(_FuelEfficiencyBucket(
dominant: null == dominant ? _self.dominant : dominant // ignore: cast_nullable_to_non_nullable
as FuelType,secondary: freezed == secondary ? _self.secondary : secondary // ignore: cast_nullable_to_non_nullable
as FuelType?,
  ));
}


}

/// @nodoc
mixin _$FuelTypeEfficiencyStats {

/// The composition bucket this row aggregates (pure or mix — ADR 0015).
 FuelEfficiencyBucket get bucket;/// Average litres / 100 km over the closed intervals classified into this
/// bucket. `null` when [attributedIntervalCount] is 0 or every such
/// interval had zero usable distance (odometer reset / open tail only).
 double? get avgL100km;/// Average cost per km (store currency) over this bucket's intervals.
/// `null` under the same condition as [avgL100km].
 double? get avgCostPerKm;/// Σ `totalCost` of every non-correction fill folded into this bucket's
/// intervals — "how much the tanks of this composition cost in total".
 double get totalSpent;/// Count of non-correction fills folded into this bucket's intervals.
 int get fillCount;/// Number of closed plein-to-plein intervals classified into this bucket.
/// 0 ⇒ [avgL100km] / [avgCostPerKm] null.
 int get attributedIntervalCount;
/// Create a copy of FuelTypeEfficiencyStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FuelTypeEfficiencyStatsCopyWith<FuelTypeEfficiencyStats> get copyWith => _$FuelTypeEfficiencyStatsCopyWithImpl<FuelTypeEfficiencyStats>(this as FuelTypeEfficiencyStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FuelTypeEfficiencyStats&&(identical(other.bucket, bucket) || other.bucket == bucket)&&(identical(other.avgL100km, avgL100km) || other.avgL100km == avgL100km)&&(identical(other.avgCostPerKm, avgCostPerKm) || other.avgCostPerKm == avgCostPerKm)&&(identical(other.totalSpent, totalSpent) || other.totalSpent == totalSpent)&&(identical(other.fillCount, fillCount) || other.fillCount == fillCount)&&(identical(other.attributedIntervalCount, attributedIntervalCount) || other.attributedIntervalCount == attributedIntervalCount));
}


@override
int get hashCode => Object.hash(runtimeType,bucket,avgL100km,avgCostPerKm,totalSpent,fillCount,attributedIntervalCount);

@override
String toString() {
  return 'FuelTypeEfficiencyStats(bucket: $bucket, avgL100km: $avgL100km, avgCostPerKm: $avgCostPerKm, totalSpent: $totalSpent, fillCount: $fillCount, attributedIntervalCount: $attributedIntervalCount)';
}


}

/// @nodoc
abstract mixin class $FuelTypeEfficiencyStatsCopyWith<$Res>  {
  factory $FuelTypeEfficiencyStatsCopyWith(FuelTypeEfficiencyStats value, $Res Function(FuelTypeEfficiencyStats) _then) = _$FuelTypeEfficiencyStatsCopyWithImpl;
@useResult
$Res call({
 FuelEfficiencyBucket bucket, double? avgL100km, double? avgCostPerKm, double totalSpent, int fillCount, int attributedIntervalCount
});


$FuelEfficiencyBucketCopyWith<$Res> get bucket;

}
/// @nodoc
class _$FuelTypeEfficiencyStatsCopyWithImpl<$Res>
    implements $FuelTypeEfficiencyStatsCopyWith<$Res> {
  _$FuelTypeEfficiencyStatsCopyWithImpl(this._self, this._then);

  final FuelTypeEfficiencyStats _self;
  final $Res Function(FuelTypeEfficiencyStats) _then;

/// Create a copy of FuelTypeEfficiencyStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bucket = null,Object? avgL100km = freezed,Object? avgCostPerKm = freezed,Object? totalSpent = null,Object? fillCount = null,Object? attributedIntervalCount = null,}) {
  return _then(_self.copyWith(
bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as FuelEfficiencyBucket,avgL100km: freezed == avgL100km ? _self.avgL100km : avgL100km // ignore: cast_nullable_to_non_nullable
as double?,avgCostPerKm: freezed == avgCostPerKm ? _self.avgCostPerKm : avgCostPerKm // ignore: cast_nullable_to_non_nullable
as double?,totalSpent: null == totalSpent ? _self.totalSpent : totalSpent // ignore: cast_nullable_to_non_nullable
as double,fillCount: null == fillCount ? _self.fillCount : fillCount // ignore: cast_nullable_to_non_nullable
as int,attributedIntervalCount: null == attributedIntervalCount ? _self.attributedIntervalCount : attributedIntervalCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of FuelTypeEfficiencyStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FuelEfficiencyBucketCopyWith<$Res> get bucket {
  
  return $FuelEfficiencyBucketCopyWith<$Res>(_self.bucket, (value) {
    return _then(_self.copyWith(bucket: value));
  });
}
}


/// Adds pattern-matching-related methods to [FuelTypeEfficiencyStats].
extension FuelTypeEfficiencyStatsPatterns on FuelTypeEfficiencyStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FuelTypeEfficiencyStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FuelTypeEfficiencyStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FuelTypeEfficiencyStats value)  $default,){
final _that = this;
switch (_that) {
case _FuelTypeEfficiencyStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FuelTypeEfficiencyStats value)?  $default,){
final _that = this;
switch (_that) {
case _FuelTypeEfficiencyStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FuelEfficiencyBucket bucket,  double? avgL100km,  double? avgCostPerKm,  double totalSpent,  int fillCount,  int attributedIntervalCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FuelTypeEfficiencyStats() when $default != null:
return $default(_that.bucket,_that.avgL100km,_that.avgCostPerKm,_that.totalSpent,_that.fillCount,_that.attributedIntervalCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FuelEfficiencyBucket bucket,  double? avgL100km,  double? avgCostPerKm,  double totalSpent,  int fillCount,  int attributedIntervalCount)  $default,) {final _that = this;
switch (_that) {
case _FuelTypeEfficiencyStats():
return $default(_that.bucket,_that.avgL100km,_that.avgCostPerKm,_that.totalSpent,_that.fillCount,_that.attributedIntervalCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FuelEfficiencyBucket bucket,  double? avgL100km,  double? avgCostPerKm,  double totalSpent,  int fillCount,  int attributedIntervalCount)?  $default,) {final _that = this;
switch (_that) {
case _FuelTypeEfficiencyStats() when $default != null:
return $default(_that.bucket,_that.avgL100km,_that.avgCostPerKm,_that.totalSpent,_that.fillCount,_that.attributedIntervalCount);case _:
  return null;

}
}

}

/// @nodoc


class _FuelTypeEfficiencyStats extends FuelTypeEfficiencyStats {
  const _FuelTypeEfficiencyStats({required this.bucket, this.avgL100km, this.avgCostPerKm, required this.totalSpent, required this.fillCount, required this.attributedIntervalCount}): super._();
  

/// The composition bucket this row aggregates (pure or mix — ADR 0015).
@override final  FuelEfficiencyBucket bucket;
/// Average litres / 100 km over the closed intervals classified into this
/// bucket. `null` when [attributedIntervalCount] is 0 or every such
/// interval had zero usable distance (odometer reset / open tail only).
@override final  double? avgL100km;
/// Average cost per km (store currency) over this bucket's intervals.
/// `null` under the same condition as [avgL100km].
@override final  double? avgCostPerKm;
/// Σ `totalCost` of every non-correction fill folded into this bucket's
/// intervals — "how much the tanks of this composition cost in total".
@override final  double totalSpent;
/// Count of non-correction fills folded into this bucket's intervals.
@override final  int fillCount;
/// Number of closed plein-to-plein intervals classified into this bucket.
/// 0 ⇒ [avgL100km] / [avgCostPerKm] null.
@override final  int attributedIntervalCount;

/// Create a copy of FuelTypeEfficiencyStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FuelTypeEfficiencyStatsCopyWith<_FuelTypeEfficiencyStats> get copyWith => __$FuelTypeEfficiencyStatsCopyWithImpl<_FuelTypeEfficiencyStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FuelTypeEfficiencyStats&&(identical(other.bucket, bucket) || other.bucket == bucket)&&(identical(other.avgL100km, avgL100km) || other.avgL100km == avgL100km)&&(identical(other.avgCostPerKm, avgCostPerKm) || other.avgCostPerKm == avgCostPerKm)&&(identical(other.totalSpent, totalSpent) || other.totalSpent == totalSpent)&&(identical(other.fillCount, fillCount) || other.fillCount == fillCount)&&(identical(other.attributedIntervalCount, attributedIntervalCount) || other.attributedIntervalCount == attributedIntervalCount));
}


@override
int get hashCode => Object.hash(runtimeType,bucket,avgL100km,avgCostPerKm,totalSpent,fillCount,attributedIntervalCount);

@override
String toString() {
  return 'FuelTypeEfficiencyStats(bucket: $bucket, avgL100km: $avgL100km, avgCostPerKm: $avgCostPerKm, totalSpent: $totalSpent, fillCount: $fillCount, attributedIntervalCount: $attributedIntervalCount)';
}


}

/// @nodoc
abstract mixin class _$FuelTypeEfficiencyStatsCopyWith<$Res> implements $FuelTypeEfficiencyStatsCopyWith<$Res> {
  factory _$FuelTypeEfficiencyStatsCopyWith(_FuelTypeEfficiencyStats value, $Res Function(_FuelTypeEfficiencyStats) _then) = __$FuelTypeEfficiencyStatsCopyWithImpl;
@override @useResult
$Res call({
 FuelEfficiencyBucket bucket, double? avgL100km, double? avgCostPerKm, double totalSpent, int fillCount, int attributedIntervalCount
});


@override $FuelEfficiencyBucketCopyWith<$Res> get bucket;

}
/// @nodoc
class __$FuelTypeEfficiencyStatsCopyWithImpl<$Res>
    implements _$FuelTypeEfficiencyStatsCopyWith<$Res> {
  __$FuelTypeEfficiencyStatsCopyWithImpl(this._self, this._then);

  final _FuelTypeEfficiencyStats _self;
  final $Res Function(_FuelTypeEfficiencyStats) _then;

/// Create a copy of FuelTypeEfficiencyStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bucket = null,Object? avgL100km = freezed,Object? avgCostPerKm = freezed,Object? totalSpent = null,Object? fillCount = null,Object? attributedIntervalCount = null,}) {
  return _then(_FuelTypeEfficiencyStats(
bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as FuelEfficiencyBucket,avgL100km: freezed == avgL100km ? _self.avgL100km : avgL100km // ignore: cast_nullable_to_non_nullable
as double?,avgCostPerKm: freezed == avgCostPerKm ? _self.avgCostPerKm : avgCostPerKm // ignore: cast_nullable_to_non_nullable
as double?,totalSpent: null == totalSpent ? _self.totalSpent : totalSpent // ignore: cast_nullable_to_non_nullable
as double,fillCount: null == fillCount ? _self.fillCount : fillCount // ignore: cast_nullable_to_non_nullable
as int,attributedIntervalCount: null == attributedIntervalCount ? _self.attributedIntervalCount : attributedIntervalCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of FuelTypeEfficiencyStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FuelEfficiencyBucketCopyWith<$Res> get bucket {
  
  return $FuelEfficiencyBucketCopyWith<$Res>(_self.bucket, (value) {
    return _then(_self.copyWith(bucket: value));
  });
}
}

// dart format on
