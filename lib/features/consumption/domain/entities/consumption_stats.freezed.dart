// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'consumption_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConsumptionStats {

 int get fillUpCount; double get totalLiters; double get totalSpent; double get totalDistanceKm; double? get avgConsumptionL100km; double? get avgCostPerKm; double? get avgPricePerLiter; DateTime? get periodStart; DateTime? get periodEnd;
/// Create a copy of ConsumptionStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsumptionStatsCopyWith<ConsumptionStats> get copyWith => _$ConsumptionStatsCopyWithImpl<ConsumptionStats>(this as ConsumptionStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsumptionStats&&(identical(other.fillUpCount, fillUpCount) || other.fillUpCount == fillUpCount)&&(identical(other.totalLiters, totalLiters) || other.totalLiters == totalLiters)&&(identical(other.totalSpent, totalSpent) || other.totalSpent == totalSpent)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.avgConsumptionL100km, avgConsumptionL100km) || other.avgConsumptionL100km == avgConsumptionL100km)&&(identical(other.avgCostPerKm, avgCostPerKm) || other.avgCostPerKm == avgCostPerKm)&&(identical(other.avgPricePerLiter, avgPricePerLiter) || other.avgPricePerLiter == avgPricePerLiter)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd));
}


@override
int get hashCode => Object.hash(runtimeType,fillUpCount,totalLiters,totalSpent,totalDistanceKm,avgConsumptionL100km,avgCostPerKm,avgPricePerLiter,periodStart,periodEnd);

@override
String toString() {
  return 'ConsumptionStats(fillUpCount: $fillUpCount, totalLiters: $totalLiters, totalSpent: $totalSpent, totalDistanceKm: $totalDistanceKm, avgConsumptionL100km: $avgConsumptionL100km, avgCostPerKm: $avgCostPerKm, avgPricePerLiter: $avgPricePerLiter, periodStart: $periodStart, periodEnd: $periodEnd)';
}


}

/// @nodoc
abstract mixin class $ConsumptionStatsCopyWith<$Res>  {
  factory $ConsumptionStatsCopyWith(ConsumptionStats value, $Res Function(ConsumptionStats) _then) = _$ConsumptionStatsCopyWithImpl;
@useResult
$Res call({
 int fillUpCount, double totalLiters, double totalSpent, double totalDistanceKm, double? avgConsumptionL100km, double? avgCostPerKm, double? avgPricePerLiter, DateTime? periodStart, DateTime? periodEnd
});




}
/// @nodoc
class _$ConsumptionStatsCopyWithImpl<$Res>
    implements $ConsumptionStatsCopyWith<$Res> {
  _$ConsumptionStatsCopyWithImpl(this._self, this._then);

  final ConsumptionStats _self;
  final $Res Function(ConsumptionStats) _then;

/// Create a copy of ConsumptionStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fillUpCount = null,Object? totalLiters = null,Object? totalSpent = null,Object? totalDistanceKm = null,Object? avgConsumptionL100km = freezed,Object? avgCostPerKm = freezed,Object? avgPricePerLiter = freezed,Object? periodStart = freezed,Object? periodEnd = freezed,}) {
  return _then(_self.copyWith(
fillUpCount: null == fillUpCount ? _self.fillUpCount : fillUpCount // ignore: cast_nullable_to_non_nullable
as int,totalLiters: null == totalLiters ? _self.totalLiters : totalLiters // ignore: cast_nullable_to_non_nullable
as double,totalSpent: null == totalSpent ? _self.totalSpent : totalSpent // ignore: cast_nullable_to_non_nullable
as double,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,avgConsumptionL100km: freezed == avgConsumptionL100km ? _self.avgConsumptionL100km : avgConsumptionL100km // ignore: cast_nullable_to_non_nullable
as double?,avgCostPerKm: freezed == avgCostPerKm ? _self.avgCostPerKm : avgCostPerKm // ignore: cast_nullable_to_non_nullable
as double?,avgPricePerLiter: freezed == avgPricePerLiter ? _self.avgPricePerLiter : avgPricePerLiter // ignore: cast_nullable_to_non_nullable
as double?,periodStart: freezed == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime?,periodEnd: freezed == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConsumptionStats].
extension ConsumptionStatsPatterns on ConsumptionStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsumptionStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsumptionStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsumptionStats value)  $default,){
final _that = this;
switch (_that) {
case _ConsumptionStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsumptionStats value)?  $default,){
final _that = this;
switch (_that) {
case _ConsumptionStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int fillUpCount,  double totalLiters,  double totalSpent,  double totalDistanceKm,  double? avgConsumptionL100km,  double? avgCostPerKm,  double? avgPricePerLiter,  DateTime? periodStart,  DateTime? periodEnd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsumptionStats() when $default != null:
return $default(_that.fillUpCount,_that.totalLiters,_that.totalSpent,_that.totalDistanceKm,_that.avgConsumptionL100km,_that.avgCostPerKm,_that.avgPricePerLiter,_that.periodStart,_that.periodEnd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int fillUpCount,  double totalLiters,  double totalSpent,  double totalDistanceKm,  double? avgConsumptionL100km,  double? avgCostPerKm,  double? avgPricePerLiter,  DateTime? periodStart,  DateTime? periodEnd)  $default,) {final _that = this;
switch (_that) {
case _ConsumptionStats():
return $default(_that.fillUpCount,_that.totalLiters,_that.totalSpent,_that.totalDistanceKm,_that.avgConsumptionL100km,_that.avgCostPerKm,_that.avgPricePerLiter,_that.periodStart,_that.periodEnd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int fillUpCount,  double totalLiters,  double totalSpent,  double totalDistanceKm,  double? avgConsumptionL100km,  double? avgCostPerKm,  double? avgPricePerLiter,  DateTime? periodStart,  DateTime? periodEnd)?  $default,) {final _that = this;
switch (_that) {
case _ConsumptionStats() when $default != null:
return $default(_that.fillUpCount,_that.totalLiters,_that.totalSpent,_that.totalDistanceKm,_that.avgConsumptionL100km,_that.avgCostPerKm,_that.avgPricePerLiter,_that.periodStart,_that.periodEnd);case _:
  return null;

}
}

}

/// @nodoc


class _ConsumptionStats extends ConsumptionStats {
  const _ConsumptionStats({required this.fillUpCount, required this.totalLiters, required this.totalSpent, required this.totalDistanceKm, this.avgConsumptionL100km, this.avgCostPerKm, this.avgPricePerLiter, this.periodStart, this.periodEnd}): super._();
  

@override final  int fillUpCount;
@override final  double totalLiters;
@override final  double totalSpent;
@override final  double totalDistanceKm;
@override final  double? avgConsumptionL100km;
@override final  double? avgCostPerKm;
@override final  double? avgPricePerLiter;
@override final  DateTime? periodStart;
@override final  DateTime? periodEnd;

/// Create a copy of ConsumptionStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsumptionStatsCopyWith<_ConsumptionStats> get copyWith => __$ConsumptionStatsCopyWithImpl<_ConsumptionStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsumptionStats&&(identical(other.fillUpCount, fillUpCount) || other.fillUpCount == fillUpCount)&&(identical(other.totalLiters, totalLiters) || other.totalLiters == totalLiters)&&(identical(other.totalSpent, totalSpent) || other.totalSpent == totalSpent)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.avgConsumptionL100km, avgConsumptionL100km) || other.avgConsumptionL100km == avgConsumptionL100km)&&(identical(other.avgCostPerKm, avgCostPerKm) || other.avgCostPerKm == avgCostPerKm)&&(identical(other.avgPricePerLiter, avgPricePerLiter) || other.avgPricePerLiter == avgPricePerLiter)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd));
}


@override
int get hashCode => Object.hash(runtimeType,fillUpCount,totalLiters,totalSpent,totalDistanceKm,avgConsumptionL100km,avgCostPerKm,avgPricePerLiter,periodStart,periodEnd);

@override
String toString() {
  return 'ConsumptionStats(fillUpCount: $fillUpCount, totalLiters: $totalLiters, totalSpent: $totalSpent, totalDistanceKm: $totalDistanceKm, avgConsumptionL100km: $avgConsumptionL100km, avgCostPerKm: $avgCostPerKm, avgPricePerLiter: $avgPricePerLiter, periodStart: $periodStart, periodEnd: $periodEnd)';
}


}

/// @nodoc
abstract mixin class _$ConsumptionStatsCopyWith<$Res> implements $ConsumptionStatsCopyWith<$Res> {
  factory _$ConsumptionStatsCopyWith(_ConsumptionStats value, $Res Function(_ConsumptionStats) _then) = __$ConsumptionStatsCopyWithImpl;
@override @useResult
$Res call({
 int fillUpCount, double totalLiters, double totalSpent, double totalDistanceKm, double? avgConsumptionL100km, double? avgCostPerKm, double? avgPricePerLiter, DateTime? periodStart, DateTime? periodEnd
});




}
/// @nodoc
class __$ConsumptionStatsCopyWithImpl<$Res>
    implements _$ConsumptionStatsCopyWith<$Res> {
  __$ConsumptionStatsCopyWithImpl(this._self, this._then);

  final _ConsumptionStats _self;
  final $Res Function(_ConsumptionStats) _then;

/// Create a copy of ConsumptionStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fillUpCount = null,Object? totalLiters = null,Object? totalSpent = null,Object? totalDistanceKm = null,Object? avgConsumptionL100km = freezed,Object? avgCostPerKm = freezed,Object? avgPricePerLiter = freezed,Object? periodStart = freezed,Object? periodEnd = freezed,}) {
  return _then(_ConsumptionStats(
fillUpCount: null == fillUpCount ? _self.fillUpCount : fillUpCount // ignore: cast_nullable_to_non_nullable
as int,totalLiters: null == totalLiters ? _self.totalLiters : totalLiters // ignore: cast_nullable_to_non_nullable
as double,totalSpent: null == totalSpent ? _self.totalSpent : totalSpent // ignore: cast_nullable_to_non_nullable
as double,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,avgConsumptionL100km: freezed == avgConsumptionL100km ? _self.avgConsumptionL100km : avgConsumptionL100km // ignore: cast_nullable_to_non_nullable
as double?,avgCostPerKm: freezed == avgCostPerKm ? _self.avgCostPerKm : avgCostPerKm // ignore: cast_nullable_to_non_nullable
as double?,avgPricePerLiter: freezed == avgPricePerLiter ? _self.avgPricePerLiter : avgPricePerLiter // ignore: cast_nullable_to_non_nullable
as double?,periodStart: freezed == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime?,periodEnd: freezed == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
