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
/// bucket. `null` when [attributedIntervalCount] is 0, every such
/// interval had zero usable distance (odometer reset / open tail only),
/// or the bucket's fuel is not sold by the litre (#4364 — a kg or kWh
/// quantity does not become litres by relabelling the suffix).
 double? get avgL100km;/// Average cost per km over this bucket's intervals, in
/// [recordedSpend]'s single denomination. `null` under the same
/// conditions as [avgL100km], and also whenever the bucket's money
/// spans more than one currency or a contributing fill carried no
/// price at all (#4364).
///
/// Its valuation basis is [MoneyValuationBasis.modelledConsumedFuel] —
/// see [intervalCost]. It is an OBSERVED cost, not the vehicle's
/// intrinsic efficiency and not a total cost of ownership.
 double? get avgCostPerKm;/// What the fills folded into this bucket ACTUALLY cost at the pump
/// (#4364) — [MoneyValuationBasis.recordedPurchaseSpend].
///
/// This is the field that answers "how much did the tanks of this
/// composition cost". It is NOT [intervalCost]: that one values the
/// fuel the engine burned, which a fuel switch makes a visibly
/// different number. `null` when the bucket's fills span more than
/// one denomination — 30 EUR and 225 DKK have no common total.
 double? get recordedPurchaseSpend;/// [recordedPurchaseSpend] segregated by the currency each fill
/// recorded, unknown currencies in their own bucket (#4364).
 MoneyTally get recordedSpend;/// Non-correction fills folded into this bucket that carried no
/// recorded cost (#4364). Non-zero withholds every money figure: a
/// missing price shrinks a numerator while its distance stays in the
/// denominator, which manufactures a cheaper fuel.
 int get unpricedFillCount;/// The unit this bucket's quantities are measured in (#4364).
/// Litre-based buckets get consumption figures; kg (CNG, hydrogen)
/// and kWh (electric) buckets keep their native spend and report no
/// L/100 km at all.
 FuelQuantityUnit get quantityUnit;/// Count of non-correction fills folded into this bucket's intervals.
 int get fillCount;/// Number of closed plein-to-plein intervals classified into this bucket.
/// 0 ⇒ [avgL100km] / [avgCostPerKm] null.
 int get attributedIntervalCount;/// Of [attributedIntervalCount], how many were classified WITHOUT the
/// carried-over opening tank content — the v2 contributing-fills-only
/// fallback used when the opening content is unknowable (tank capacity
/// not set, or the interval opened on a non-plein first fill / a
/// synthetic correction). 0 ⇒ every interval used the full v3
/// carried-content composition (#3764, ADR 0015 v3).
 int get legacyAttributedIntervalCount;/// Σ litres over this bucket's attributed intervals (#3828).
///
/// The aggregator has always summed this to derive [avgL100km] and then
/// discarded it, which cost the screen its most comparable number: with
/// litres AND [intervalCost] we can state the **price per litre** each
/// fuel was actually bought at, instead of leaving the reader to infer
/// why one fuel costs more per km while burning fewer litres.
 double get totalLitres;/// Σ distance (km) over this bucket's attributed intervals (#3828).
/// Says how much driving a row's verdict rests on.
 double get totalDistanceKm;/// The MODELLED value of the fuel this bucket's intervals burned
/// ([MoneyValuationBasis.modelledConsumedFuel]) — the burned volume
/// split over the interval's composition and priced at what each
/// grade cost (#3846).
///
/// NOT recorded purchase spend (#4364): that is
/// [recordedPurchaseSpend]. A field named `totalSpent` used to carry
/// exactly this number, which made a reconstruction read as a bank
/// statement. Only prices from fills inside the counted closed
/// windows feed it, so appending a later expensive purchase cannot
/// retroactively revalue an earlier period.
///
/// `null` when the money is not denominable (mixed currencies, or a
/// contributing fill with no price).
 double? get intervalCost;
/// Create a copy of FuelTypeEfficiencyStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FuelTypeEfficiencyStatsCopyWith<FuelTypeEfficiencyStats> get copyWith => _$FuelTypeEfficiencyStatsCopyWithImpl<FuelTypeEfficiencyStats>(this as FuelTypeEfficiencyStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FuelTypeEfficiencyStats&&(identical(other.bucket, bucket) || other.bucket == bucket)&&(identical(other.avgL100km, avgL100km) || other.avgL100km == avgL100km)&&(identical(other.avgCostPerKm, avgCostPerKm) || other.avgCostPerKm == avgCostPerKm)&&(identical(other.recordedPurchaseSpend, recordedPurchaseSpend) || other.recordedPurchaseSpend == recordedPurchaseSpend)&&(identical(other.recordedSpend, recordedSpend) || other.recordedSpend == recordedSpend)&&(identical(other.unpricedFillCount, unpricedFillCount) || other.unpricedFillCount == unpricedFillCount)&&(identical(other.quantityUnit, quantityUnit) || other.quantityUnit == quantityUnit)&&(identical(other.fillCount, fillCount) || other.fillCount == fillCount)&&(identical(other.attributedIntervalCount, attributedIntervalCount) || other.attributedIntervalCount == attributedIntervalCount)&&(identical(other.legacyAttributedIntervalCount, legacyAttributedIntervalCount) || other.legacyAttributedIntervalCount == legacyAttributedIntervalCount)&&(identical(other.totalLitres, totalLitres) || other.totalLitres == totalLitres)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.intervalCost, intervalCost) || other.intervalCost == intervalCost));
}


@override
int get hashCode => Object.hash(runtimeType,bucket,avgL100km,avgCostPerKm,recordedPurchaseSpend,recordedSpend,unpricedFillCount,quantityUnit,fillCount,attributedIntervalCount,legacyAttributedIntervalCount,totalLitres,totalDistanceKm,intervalCost);

@override
String toString() {
  return 'FuelTypeEfficiencyStats(bucket: $bucket, avgL100km: $avgL100km, avgCostPerKm: $avgCostPerKm, recordedPurchaseSpend: $recordedPurchaseSpend, recordedSpend: $recordedSpend, unpricedFillCount: $unpricedFillCount, quantityUnit: $quantityUnit, fillCount: $fillCount, attributedIntervalCount: $attributedIntervalCount, legacyAttributedIntervalCount: $legacyAttributedIntervalCount, totalLitres: $totalLitres, totalDistanceKm: $totalDistanceKm, intervalCost: $intervalCost)';
}


}

/// @nodoc
abstract mixin class $FuelTypeEfficiencyStatsCopyWith<$Res>  {
  factory $FuelTypeEfficiencyStatsCopyWith(FuelTypeEfficiencyStats value, $Res Function(FuelTypeEfficiencyStats) _then) = _$FuelTypeEfficiencyStatsCopyWithImpl;
@useResult
$Res call({
 FuelEfficiencyBucket bucket, double? avgL100km, double? avgCostPerKm, double? recordedPurchaseSpend, MoneyTally recordedSpend, int unpricedFillCount, FuelQuantityUnit quantityUnit, int fillCount, int attributedIntervalCount, int legacyAttributedIntervalCount, double totalLitres, double totalDistanceKm, double? intervalCost
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
@pragma('vm:prefer-inline') @override $Res call({Object? bucket = null,Object? avgL100km = freezed,Object? avgCostPerKm = freezed,Object? recordedPurchaseSpend = freezed,Object? recordedSpend = null,Object? unpricedFillCount = null,Object? quantityUnit = null,Object? fillCount = null,Object? attributedIntervalCount = null,Object? legacyAttributedIntervalCount = null,Object? totalLitres = null,Object? totalDistanceKm = null,Object? intervalCost = freezed,}) {
  return _then(_self.copyWith(
bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as FuelEfficiencyBucket,avgL100km: freezed == avgL100km ? _self.avgL100km : avgL100km // ignore: cast_nullable_to_non_nullable
as double?,avgCostPerKm: freezed == avgCostPerKm ? _self.avgCostPerKm : avgCostPerKm // ignore: cast_nullable_to_non_nullable
as double?,recordedPurchaseSpend: freezed == recordedPurchaseSpend ? _self.recordedPurchaseSpend : recordedPurchaseSpend // ignore: cast_nullable_to_non_nullable
as double?,recordedSpend: null == recordedSpend ? _self.recordedSpend : recordedSpend // ignore: cast_nullable_to_non_nullable
as MoneyTally,unpricedFillCount: null == unpricedFillCount ? _self.unpricedFillCount : unpricedFillCount // ignore: cast_nullable_to_non_nullable
as int,quantityUnit: null == quantityUnit ? _self.quantityUnit : quantityUnit // ignore: cast_nullable_to_non_nullable
as FuelQuantityUnit,fillCount: null == fillCount ? _self.fillCount : fillCount // ignore: cast_nullable_to_non_nullable
as int,attributedIntervalCount: null == attributedIntervalCount ? _self.attributedIntervalCount : attributedIntervalCount // ignore: cast_nullable_to_non_nullable
as int,legacyAttributedIntervalCount: null == legacyAttributedIntervalCount ? _self.legacyAttributedIntervalCount : legacyAttributedIntervalCount // ignore: cast_nullable_to_non_nullable
as int,totalLitres: null == totalLitres ? _self.totalLitres : totalLitres // ignore: cast_nullable_to_non_nullable
as double,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,intervalCost: freezed == intervalCost ? _self.intervalCost : intervalCost // ignore: cast_nullable_to_non_nullable
as double?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FuelEfficiencyBucket bucket,  double? avgL100km,  double? avgCostPerKm,  double? recordedPurchaseSpend,  MoneyTally recordedSpend,  int unpricedFillCount,  FuelQuantityUnit quantityUnit,  int fillCount,  int attributedIntervalCount,  int legacyAttributedIntervalCount,  double totalLitres,  double totalDistanceKm,  double? intervalCost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FuelTypeEfficiencyStats() when $default != null:
return $default(_that.bucket,_that.avgL100km,_that.avgCostPerKm,_that.recordedPurchaseSpend,_that.recordedSpend,_that.unpricedFillCount,_that.quantityUnit,_that.fillCount,_that.attributedIntervalCount,_that.legacyAttributedIntervalCount,_that.totalLitres,_that.totalDistanceKm,_that.intervalCost);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FuelEfficiencyBucket bucket,  double? avgL100km,  double? avgCostPerKm,  double? recordedPurchaseSpend,  MoneyTally recordedSpend,  int unpricedFillCount,  FuelQuantityUnit quantityUnit,  int fillCount,  int attributedIntervalCount,  int legacyAttributedIntervalCount,  double totalLitres,  double totalDistanceKm,  double? intervalCost)  $default,) {final _that = this;
switch (_that) {
case _FuelTypeEfficiencyStats():
return $default(_that.bucket,_that.avgL100km,_that.avgCostPerKm,_that.recordedPurchaseSpend,_that.recordedSpend,_that.unpricedFillCount,_that.quantityUnit,_that.fillCount,_that.attributedIntervalCount,_that.legacyAttributedIntervalCount,_that.totalLitres,_that.totalDistanceKm,_that.intervalCost);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FuelEfficiencyBucket bucket,  double? avgL100km,  double? avgCostPerKm,  double? recordedPurchaseSpend,  MoneyTally recordedSpend,  int unpricedFillCount,  FuelQuantityUnit quantityUnit,  int fillCount,  int attributedIntervalCount,  int legacyAttributedIntervalCount,  double totalLitres,  double totalDistanceKm,  double? intervalCost)?  $default,) {final _that = this;
switch (_that) {
case _FuelTypeEfficiencyStats() when $default != null:
return $default(_that.bucket,_that.avgL100km,_that.avgCostPerKm,_that.recordedPurchaseSpend,_that.recordedSpend,_that.unpricedFillCount,_that.quantityUnit,_that.fillCount,_that.attributedIntervalCount,_that.legacyAttributedIntervalCount,_that.totalLitres,_that.totalDistanceKm,_that.intervalCost);case _:
  return null;

}
}

}

/// @nodoc


class _FuelTypeEfficiencyStats extends FuelTypeEfficiencyStats {
  const _FuelTypeEfficiencyStats({required this.bucket, this.avgL100km, this.avgCostPerKm, this.recordedPurchaseSpend, this.recordedSpend = MoneyTally.empty, this.unpricedFillCount = 0, this.quantityUnit = FuelQuantityUnit.litre, required this.fillCount, required this.attributedIntervalCount, this.legacyAttributedIntervalCount = 0, this.totalLitres = 0, this.totalDistanceKm = 0, this.intervalCost}): super._();
  

/// The composition bucket this row aggregates (pure or mix — ADR 0015).
@override final  FuelEfficiencyBucket bucket;
/// Average litres / 100 km over the closed intervals classified into this
/// bucket. `null` when [attributedIntervalCount] is 0, every such
/// interval had zero usable distance (odometer reset / open tail only),
/// or the bucket's fuel is not sold by the litre (#4364 — a kg or kWh
/// quantity does not become litres by relabelling the suffix).
@override final  double? avgL100km;
/// Average cost per km over this bucket's intervals, in
/// [recordedSpend]'s single denomination. `null` under the same
/// conditions as [avgL100km], and also whenever the bucket's money
/// spans more than one currency or a contributing fill carried no
/// price at all (#4364).
///
/// Its valuation basis is [MoneyValuationBasis.modelledConsumedFuel] —
/// see [intervalCost]. It is an OBSERVED cost, not the vehicle's
/// intrinsic efficiency and not a total cost of ownership.
@override final  double? avgCostPerKm;
/// What the fills folded into this bucket ACTUALLY cost at the pump
/// (#4364) — [MoneyValuationBasis.recordedPurchaseSpend].
///
/// This is the field that answers "how much did the tanks of this
/// composition cost". It is NOT [intervalCost]: that one values the
/// fuel the engine burned, which a fuel switch makes a visibly
/// different number. `null` when the bucket's fills span more than
/// one denomination — 30 EUR and 225 DKK have no common total.
@override final  double? recordedPurchaseSpend;
/// [recordedPurchaseSpend] segregated by the currency each fill
/// recorded, unknown currencies in their own bucket (#4364).
@override@JsonKey() final  MoneyTally recordedSpend;
/// Non-correction fills folded into this bucket that carried no
/// recorded cost (#4364). Non-zero withholds every money figure: a
/// missing price shrinks a numerator while its distance stays in the
/// denominator, which manufactures a cheaper fuel.
@override@JsonKey() final  int unpricedFillCount;
/// The unit this bucket's quantities are measured in (#4364).
/// Litre-based buckets get consumption figures; kg (CNG, hydrogen)
/// and kWh (electric) buckets keep their native spend and report no
/// L/100 km at all.
@override@JsonKey() final  FuelQuantityUnit quantityUnit;
/// Count of non-correction fills folded into this bucket's intervals.
@override final  int fillCount;
/// Number of closed plein-to-plein intervals classified into this bucket.
/// 0 ⇒ [avgL100km] / [avgCostPerKm] null.
@override final  int attributedIntervalCount;
/// Of [attributedIntervalCount], how many were classified WITHOUT the
/// carried-over opening tank content — the v2 contributing-fills-only
/// fallback used when the opening content is unknowable (tank capacity
/// not set, or the interval opened on a non-plein first fill / a
/// synthetic correction). 0 ⇒ every interval used the full v3
/// carried-content composition (#3764, ADR 0015 v3).
@override@JsonKey() final  int legacyAttributedIntervalCount;
/// Σ litres over this bucket's attributed intervals (#3828).
///
/// The aggregator has always summed this to derive [avgL100km] and then
/// discarded it, which cost the screen its most comparable number: with
/// litres AND [intervalCost] we can state the **price per litre** each
/// fuel was actually bought at, instead of leaving the reader to infer
/// why one fuel costs more per km while burning fewer litres.
@override@JsonKey() final  double totalLitres;
/// Σ distance (km) over this bucket's attributed intervals (#3828).
/// Says how much driving a row's verdict rests on.
@override@JsonKey() final  double totalDistanceKm;
/// The MODELLED value of the fuel this bucket's intervals burned
/// ([MoneyValuationBasis.modelledConsumedFuel]) — the burned volume
/// split over the interval's composition and priced at what each
/// grade cost (#3846).
///
/// NOT recorded purchase spend (#4364): that is
/// [recordedPurchaseSpend]. A field named `totalSpent` used to carry
/// exactly this number, which made a reconstruction read as a bank
/// statement. Only prices from fills inside the counted closed
/// windows feed it, so appending a later expensive purchase cannot
/// retroactively revalue an earlier period.
///
/// `null` when the money is not denominable (mixed currencies, or a
/// contributing fill with no price).
@override final  double? intervalCost;

/// Create a copy of FuelTypeEfficiencyStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FuelTypeEfficiencyStatsCopyWith<_FuelTypeEfficiencyStats> get copyWith => __$FuelTypeEfficiencyStatsCopyWithImpl<_FuelTypeEfficiencyStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FuelTypeEfficiencyStats&&(identical(other.bucket, bucket) || other.bucket == bucket)&&(identical(other.avgL100km, avgL100km) || other.avgL100km == avgL100km)&&(identical(other.avgCostPerKm, avgCostPerKm) || other.avgCostPerKm == avgCostPerKm)&&(identical(other.recordedPurchaseSpend, recordedPurchaseSpend) || other.recordedPurchaseSpend == recordedPurchaseSpend)&&(identical(other.recordedSpend, recordedSpend) || other.recordedSpend == recordedSpend)&&(identical(other.unpricedFillCount, unpricedFillCount) || other.unpricedFillCount == unpricedFillCount)&&(identical(other.quantityUnit, quantityUnit) || other.quantityUnit == quantityUnit)&&(identical(other.fillCount, fillCount) || other.fillCount == fillCount)&&(identical(other.attributedIntervalCount, attributedIntervalCount) || other.attributedIntervalCount == attributedIntervalCount)&&(identical(other.legacyAttributedIntervalCount, legacyAttributedIntervalCount) || other.legacyAttributedIntervalCount == legacyAttributedIntervalCount)&&(identical(other.totalLitres, totalLitres) || other.totalLitres == totalLitres)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.intervalCost, intervalCost) || other.intervalCost == intervalCost));
}


@override
int get hashCode => Object.hash(runtimeType,bucket,avgL100km,avgCostPerKm,recordedPurchaseSpend,recordedSpend,unpricedFillCount,quantityUnit,fillCount,attributedIntervalCount,legacyAttributedIntervalCount,totalLitres,totalDistanceKm,intervalCost);

@override
String toString() {
  return 'FuelTypeEfficiencyStats(bucket: $bucket, avgL100km: $avgL100km, avgCostPerKm: $avgCostPerKm, recordedPurchaseSpend: $recordedPurchaseSpend, recordedSpend: $recordedSpend, unpricedFillCount: $unpricedFillCount, quantityUnit: $quantityUnit, fillCount: $fillCount, attributedIntervalCount: $attributedIntervalCount, legacyAttributedIntervalCount: $legacyAttributedIntervalCount, totalLitres: $totalLitres, totalDistanceKm: $totalDistanceKm, intervalCost: $intervalCost)';
}


}

/// @nodoc
abstract mixin class _$FuelTypeEfficiencyStatsCopyWith<$Res> implements $FuelTypeEfficiencyStatsCopyWith<$Res> {
  factory _$FuelTypeEfficiencyStatsCopyWith(_FuelTypeEfficiencyStats value, $Res Function(_FuelTypeEfficiencyStats) _then) = __$FuelTypeEfficiencyStatsCopyWithImpl;
@override @useResult
$Res call({
 FuelEfficiencyBucket bucket, double? avgL100km, double? avgCostPerKm, double? recordedPurchaseSpend, MoneyTally recordedSpend, int unpricedFillCount, FuelQuantityUnit quantityUnit, int fillCount, int attributedIntervalCount, int legacyAttributedIntervalCount, double totalLitres, double totalDistanceKm, double? intervalCost
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
@override @pragma('vm:prefer-inline') $Res call({Object? bucket = null,Object? avgL100km = freezed,Object? avgCostPerKm = freezed,Object? recordedPurchaseSpend = freezed,Object? recordedSpend = null,Object? unpricedFillCount = null,Object? quantityUnit = null,Object? fillCount = null,Object? attributedIntervalCount = null,Object? legacyAttributedIntervalCount = null,Object? totalLitres = null,Object? totalDistanceKm = null,Object? intervalCost = freezed,}) {
  return _then(_FuelTypeEfficiencyStats(
bucket: null == bucket ? _self.bucket : bucket // ignore: cast_nullable_to_non_nullable
as FuelEfficiencyBucket,avgL100km: freezed == avgL100km ? _self.avgL100km : avgL100km // ignore: cast_nullable_to_non_nullable
as double?,avgCostPerKm: freezed == avgCostPerKm ? _self.avgCostPerKm : avgCostPerKm // ignore: cast_nullable_to_non_nullable
as double?,recordedPurchaseSpend: freezed == recordedPurchaseSpend ? _self.recordedPurchaseSpend : recordedPurchaseSpend // ignore: cast_nullable_to_non_nullable
as double?,recordedSpend: null == recordedSpend ? _self.recordedSpend : recordedSpend // ignore: cast_nullable_to_non_nullable
as MoneyTally,unpricedFillCount: null == unpricedFillCount ? _self.unpricedFillCount : unpricedFillCount // ignore: cast_nullable_to_non_nullable
as int,quantityUnit: null == quantityUnit ? _self.quantityUnit : quantityUnit // ignore: cast_nullable_to_non_nullable
as FuelQuantityUnit,fillCount: null == fillCount ? _self.fillCount : fillCount // ignore: cast_nullable_to_non_nullable
as int,attributedIntervalCount: null == attributedIntervalCount ? _self.attributedIntervalCount : attributedIntervalCount // ignore: cast_nullable_to_non_nullable
as int,legacyAttributedIntervalCount: null == legacyAttributedIntervalCount ? _self.legacyAttributedIntervalCount : legacyAttributedIntervalCount // ignore: cast_nullable_to_non_nullable
as int,totalLitres: null == totalLitres ? _self.totalLitres : totalLitres // ignore: cast_nullable_to_non_nullable
as double,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,intervalCost: freezed == intervalCost ? _self.intervalCost : intervalCost // ignore: cast_nullable_to_non_nullable
as double?,
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
