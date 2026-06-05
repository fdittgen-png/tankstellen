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
mixin _$FuelTypeEfficiencyStats {

/// The fuel this row aggregates (grouped by [FuelType.apiValue]).
 FuelType get fuelType;/// Average litres / 100 km over this fuel's dominant-attributed
/// intervals. `null` when [attributedIntervalCount] is 0 — the fuel
/// never dominated a closed interval (only a minority in mixed tanks,
/// or only present in the opening fill / open tail).
 double? get avgL100km;/// Average cost per km (store currency) over this fuel's
/// dominant-attributed intervals. `null` under the same condition as
/// [avgL100km].
 double? get avgCostPerKm;/// Σ `totalCost` of EVERY non-correction fill of this fuel, across all
/// intervals (incl. the opening fill and the open tail). A per-fill
/// fact, independent of interval attribution — "how much I have spent
/// on this fuel in total".
 double get totalSpent;/// Count of all non-correction fills of this fuel.
 int get fillCount;/// Number of closed plein-to-plein intervals attributed to this fuel
/// under the dominant-fuel rule. 0 ⇒ [avgL100km] / [avgCostPerKm] null.
 int get attributedIntervalCount;/// Of [attributedIntervalCount], how many intervals actually contained
/// more than one fuel among their contributing non-correction fills.
/// Drives the "N of M tanks were mixed" transparency footnote.
 int get mixedIntervalCount;
/// Create a copy of FuelTypeEfficiencyStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FuelTypeEfficiencyStatsCopyWith<FuelTypeEfficiencyStats> get copyWith => _$FuelTypeEfficiencyStatsCopyWithImpl<FuelTypeEfficiencyStats>(this as FuelTypeEfficiencyStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FuelTypeEfficiencyStats&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.avgL100km, avgL100km) || other.avgL100km == avgL100km)&&(identical(other.avgCostPerKm, avgCostPerKm) || other.avgCostPerKm == avgCostPerKm)&&(identical(other.totalSpent, totalSpent) || other.totalSpent == totalSpent)&&(identical(other.fillCount, fillCount) || other.fillCount == fillCount)&&(identical(other.attributedIntervalCount, attributedIntervalCount) || other.attributedIntervalCount == attributedIntervalCount)&&(identical(other.mixedIntervalCount, mixedIntervalCount) || other.mixedIntervalCount == mixedIntervalCount));
}


@override
int get hashCode => Object.hash(runtimeType,fuelType,avgL100km,avgCostPerKm,totalSpent,fillCount,attributedIntervalCount,mixedIntervalCount);

@override
String toString() {
  return 'FuelTypeEfficiencyStats(fuelType: $fuelType, avgL100km: $avgL100km, avgCostPerKm: $avgCostPerKm, totalSpent: $totalSpent, fillCount: $fillCount, attributedIntervalCount: $attributedIntervalCount, mixedIntervalCount: $mixedIntervalCount)';
}


}

/// @nodoc
abstract mixin class $FuelTypeEfficiencyStatsCopyWith<$Res>  {
  factory $FuelTypeEfficiencyStatsCopyWith(FuelTypeEfficiencyStats value, $Res Function(FuelTypeEfficiencyStats) _then) = _$FuelTypeEfficiencyStatsCopyWithImpl;
@useResult
$Res call({
 FuelType fuelType, double? avgL100km, double? avgCostPerKm, double totalSpent, int fillCount, int attributedIntervalCount, int mixedIntervalCount
});




}
/// @nodoc
class _$FuelTypeEfficiencyStatsCopyWithImpl<$Res>
    implements $FuelTypeEfficiencyStatsCopyWith<$Res> {
  _$FuelTypeEfficiencyStatsCopyWithImpl(this._self, this._then);

  final FuelTypeEfficiencyStats _self;
  final $Res Function(FuelTypeEfficiencyStats) _then;

/// Create a copy of FuelTypeEfficiencyStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fuelType = null,Object? avgL100km = freezed,Object? avgCostPerKm = freezed,Object? totalSpent = null,Object? fillCount = null,Object? attributedIntervalCount = null,Object? mixedIntervalCount = null,}) {
  return _then(_self.copyWith(
fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType,avgL100km: freezed == avgL100km ? _self.avgL100km : avgL100km // ignore: cast_nullable_to_non_nullable
as double?,avgCostPerKm: freezed == avgCostPerKm ? _self.avgCostPerKm : avgCostPerKm // ignore: cast_nullable_to_non_nullable
as double?,totalSpent: null == totalSpent ? _self.totalSpent : totalSpent // ignore: cast_nullable_to_non_nullable
as double,fillCount: null == fillCount ? _self.fillCount : fillCount // ignore: cast_nullable_to_non_nullable
as int,attributedIntervalCount: null == attributedIntervalCount ? _self.attributedIntervalCount : attributedIntervalCount // ignore: cast_nullable_to_non_nullable
as int,mixedIntervalCount: null == mixedIntervalCount ? _self.mixedIntervalCount : mixedIntervalCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FuelType fuelType,  double? avgL100km,  double? avgCostPerKm,  double totalSpent,  int fillCount,  int attributedIntervalCount,  int mixedIntervalCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FuelTypeEfficiencyStats() when $default != null:
return $default(_that.fuelType,_that.avgL100km,_that.avgCostPerKm,_that.totalSpent,_that.fillCount,_that.attributedIntervalCount,_that.mixedIntervalCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FuelType fuelType,  double? avgL100km,  double? avgCostPerKm,  double totalSpent,  int fillCount,  int attributedIntervalCount,  int mixedIntervalCount)  $default,) {final _that = this;
switch (_that) {
case _FuelTypeEfficiencyStats():
return $default(_that.fuelType,_that.avgL100km,_that.avgCostPerKm,_that.totalSpent,_that.fillCount,_that.attributedIntervalCount,_that.mixedIntervalCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FuelType fuelType,  double? avgL100km,  double? avgCostPerKm,  double totalSpent,  int fillCount,  int attributedIntervalCount,  int mixedIntervalCount)?  $default,) {final _that = this;
switch (_that) {
case _FuelTypeEfficiencyStats() when $default != null:
return $default(_that.fuelType,_that.avgL100km,_that.avgCostPerKm,_that.totalSpent,_that.fillCount,_that.attributedIntervalCount,_that.mixedIntervalCount);case _:
  return null;

}
}

}

/// @nodoc


class _FuelTypeEfficiencyStats implements FuelTypeEfficiencyStats {
  const _FuelTypeEfficiencyStats({required this.fuelType, this.avgL100km, this.avgCostPerKm, required this.totalSpent, required this.fillCount, required this.attributedIntervalCount, required this.mixedIntervalCount});
  

/// The fuel this row aggregates (grouped by [FuelType.apiValue]).
@override final  FuelType fuelType;
/// Average litres / 100 km over this fuel's dominant-attributed
/// intervals. `null` when [attributedIntervalCount] is 0 — the fuel
/// never dominated a closed interval (only a minority in mixed tanks,
/// or only present in the opening fill / open tail).
@override final  double? avgL100km;
/// Average cost per km (store currency) over this fuel's
/// dominant-attributed intervals. `null` under the same condition as
/// [avgL100km].
@override final  double? avgCostPerKm;
/// Σ `totalCost` of EVERY non-correction fill of this fuel, across all
/// intervals (incl. the opening fill and the open tail). A per-fill
/// fact, independent of interval attribution — "how much I have spent
/// on this fuel in total".
@override final  double totalSpent;
/// Count of all non-correction fills of this fuel.
@override final  int fillCount;
/// Number of closed plein-to-plein intervals attributed to this fuel
/// under the dominant-fuel rule. 0 ⇒ [avgL100km] / [avgCostPerKm] null.
@override final  int attributedIntervalCount;
/// Of [attributedIntervalCount], how many intervals actually contained
/// more than one fuel among their contributing non-correction fills.
/// Drives the "N of M tanks were mixed" transparency footnote.
@override final  int mixedIntervalCount;

/// Create a copy of FuelTypeEfficiencyStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FuelTypeEfficiencyStatsCopyWith<_FuelTypeEfficiencyStats> get copyWith => __$FuelTypeEfficiencyStatsCopyWithImpl<_FuelTypeEfficiencyStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FuelTypeEfficiencyStats&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.avgL100km, avgL100km) || other.avgL100km == avgL100km)&&(identical(other.avgCostPerKm, avgCostPerKm) || other.avgCostPerKm == avgCostPerKm)&&(identical(other.totalSpent, totalSpent) || other.totalSpent == totalSpent)&&(identical(other.fillCount, fillCount) || other.fillCount == fillCount)&&(identical(other.attributedIntervalCount, attributedIntervalCount) || other.attributedIntervalCount == attributedIntervalCount)&&(identical(other.mixedIntervalCount, mixedIntervalCount) || other.mixedIntervalCount == mixedIntervalCount));
}


@override
int get hashCode => Object.hash(runtimeType,fuelType,avgL100km,avgCostPerKm,totalSpent,fillCount,attributedIntervalCount,mixedIntervalCount);

@override
String toString() {
  return 'FuelTypeEfficiencyStats(fuelType: $fuelType, avgL100km: $avgL100km, avgCostPerKm: $avgCostPerKm, totalSpent: $totalSpent, fillCount: $fillCount, attributedIntervalCount: $attributedIntervalCount, mixedIntervalCount: $mixedIntervalCount)';
}


}

/// @nodoc
abstract mixin class _$FuelTypeEfficiencyStatsCopyWith<$Res> implements $FuelTypeEfficiencyStatsCopyWith<$Res> {
  factory _$FuelTypeEfficiencyStatsCopyWith(_FuelTypeEfficiencyStats value, $Res Function(_FuelTypeEfficiencyStats) _then) = __$FuelTypeEfficiencyStatsCopyWithImpl;
@override @useResult
$Res call({
 FuelType fuelType, double? avgL100km, double? avgCostPerKm, double totalSpent, int fillCount, int attributedIntervalCount, int mixedIntervalCount
});




}
/// @nodoc
class __$FuelTypeEfficiencyStatsCopyWithImpl<$Res>
    implements _$FuelTypeEfficiencyStatsCopyWith<$Res> {
  __$FuelTypeEfficiencyStatsCopyWithImpl(this._self, this._then);

  final _FuelTypeEfficiencyStats _self;
  final $Res Function(_FuelTypeEfficiencyStats) _then;

/// Create a copy of FuelTypeEfficiencyStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fuelType = null,Object? avgL100km = freezed,Object? avgCostPerKm = freezed,Object? totalSpent = null,Object? fillCount = null,Object? attributedIntervalCount = null,Object? mixedIntervalCount = null,}) {
  return _then(_FuelTypeEfficiencyStats(
fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType,avgL100km: freezed == avgL100km ? _self.avgL100km : avgL100km // ignore: cast_nullable_to_non_nullable
as double?,avgCostPerKm: freezed == avgCostPerKm ? _self.avgCostPerKm : avgCostPerKm // ignore: cast_nullable_to_non_nullable
as double?,totalSpent: null == totalSpent ? _self.totalSpent : totalSpent // ignore: cast_nullable_to_non_nullable
as double,fillCount: null == fillCount ? _self.fillCount : fillCount // ignore: cast_nullable_to_non_nullable
as int,attributedIntervalCount: null == attributedIntervalCount ? _self.attributedIntervalCount : attributedIntervalCount // ignore: cast_nullable_to_non_nullable
as int,mixedIntervalCount: null == mixedIntervalCount ? _self.mixedIntervalCount : mixedIntervalCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
