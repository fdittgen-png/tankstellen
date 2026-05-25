// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gps_calibration_matrix.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GpsCalibrationMatrix {

/// Constant L/100 km term. Seeded from the vehicle's declared
/// WLTP at cold start, refined per fill-up. Default matches
/// [defaultBaselineLPer100Km] (literal here because freezed's
/// generator can't resolve static-const names in `@Default`).
 double get baseline;/// L/100 km penalty per share-of-idle (idle_seconds / total).
/// Default matches [defaultIdleCost].
 double get idleCost;/// L/100 km penalty per share-of-≥110-km/h. Default matches
/// [defaultHighSpeedPenalty].
 double get highSpeedPenalty;/// L/100 km penalty per accel-event-per-km. Default matches
/// [defaultAccelEventCost].
 double get accelEventCost;// ─── Reserved 7-coef expansion slots — null in the lean model ───
/// Brake event cost (proxy for missed regen / coasting
/// opportunity). Null until the expand-on-demand trigger fires
/// (cold maturity + variance > threshold after 8 fill-ups).
 double? get brakeEventCost;/// Grade-climb cost per 100 m climbed. Null until expansion.
 double? get gradeClimbCost;/// Corner-load cost per integral unit. Null until expansion.
 double? get cornerLoadCost;// ─── Reconciliation bookkeeping ───
/// How many fill-ups have contributed an LSQ update to this
/// matrix. Drives the maturity tier (cold < 3, warming 3–7,
/// converged ≥ 8 per ADR 0010).
 int get fillUpReconciliationCount;/// Mean squared residual over the last 5 fill-up windows
/// in (L/100 km)². Drives the maturity tier alongside the count.
 double get residualVariance;/// Wall-clock timestamp of the most recent reconciliation, or
/// null when the matrix has never been refined.
 DateTime? get lastReconciledAt;
/// Create a copy of GpsCalibrationMatrix
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GpsCalibrationMatrixCopyWith<GpsCalibrationMatrix> get copyWith => _$GpsCalibrationMatrixCopyWithImpl<GpsCalibrationMatrix>(this as GpsCalibrationMatrix, _$identity);

  /// Serializes this GpsCalibrationMatrix to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GpsCalibrationMatrix&&(identical(other.baseline, baseline) || other.baseline == baseline)&&(identical(other.idleCost, idleCost) || other.idleCost == idleCost)&&(identical(other.highSpeedPenalty, highSpeedPenalty) || other.highSpeedPenalty == highSpeedPenalty)&&(identical(other.accelEventCost, accelEventCost) || other.accelEventCost == accelEventCost)&&(identical(other.brakeEventCost, brakeEventCost) || other.brakeEventCost == brakeEventCost)&&(identical(other.gradeClimbCost, gradeClimbCost) || other.gradeClimbCost == gradeClimbCost)&&(identical(other.cornerLoadCost, cornerLoadCost) || other.cornerLoadCost == cornerLoadCost)&&(identical(other.fillUpReconciliationCount, fillUpReconciliationCount) || other.fillUpReconciliationCount == fillUpReconciliationCount)&&(identical(other.residualVariance, residualVariance) || other.residualVariance == residualVariance)&&(identical(other.lastReconciledAt, lastReconciledAt) || other.lastReconciledAt == lastReconciledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,baseline,idleCost,highSpeedPenalty,accelEventCost,brakeEventCost,gradeClimbCost,cornerLoadCost,fillUpReconciliationCount,residualVariance,lastReconciledAt);

@override
String toString() {
  return 'GpsCalibrationMatrix(baseline: $baseline, idleCost: $idleCost, highSpeedPenalty: $highSpeedPenalty, accelEventCost: $accelEventCost, brakeEventCost: $brakeEventCost, gradeClimbCost: $gradeClimbCost, cornerLoadCost: $cornerLoadCost, fillUpReconciliationCount: $fillUpReconciliationCount, residualVariance: $residualVariance, lastReconciledAt: $lastReconciledAt)';
}


}

/// @nodoc
abstract mixin class $GpsCalibrationMatrixCopyWith<$Res>  {
  factory $GpsCalibrationMatrixCopyWith(GpsCalibrationMatrix value, $Res Function(GpsCalibrationMatrix) _then) = _$GpsCalibrationMatrixCopyWithImpl;
@useResult
$Res call({
 double baseline, double idleCost, double highSpeedPenalty, double accelEventCost, double? brakeEventCost, double? gradeClimbCost, double? cornerLoadCost, int fillUpReconciliationCount, double residualVariance, DateTime? lastReconciledAt
});




}
/// @nodoc
class _$GpsCalibrationMatrixCopyWithImpl<$Res>
    implements $GpsCalibrationMatrixCopyWith<$Res> {
  _$GpsCalibrationMatrixCopyWithImpl(this._self, this._then);

  final GpsCalibrationMatrix _self;
  final $Res Function(GpsCalibrationMatrix) _then;

/// Create a copy of GpsCalibrationMatrix
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? baseline = null,Object? idleCost = null,Object? highSpeedPenalty = null,Object? accelEventCost = null,Object? brakeEventCost = freezed,Object? gradeClimbCost = freezed,Object? cornerLoadCost = freezed,Object? fillUpReconciliationCount = null,Object? residualVariance = null,Object? lastReconciledAt = freezed,}) {
  return _then(_self.copyWith(
baseline: null == baseline ? _self.baseline : baseline // ignore: cast_nullable_to_non_nullable
as double,idleCost: null == idleCost ? _self.idleCost : idleCost // ignore: cast_nullable_to_non_nullable
as double,highSpeedPenalty: null == highSpeedPenalty ? _self.highSpeedPenalty : highSpeedPenalty // ignore: cast_nullable_to_non_nullable
as double,accelEventCost: null == accelEventCost ? _self.accelEventCost : accelEventCost // ignore: cast_nullable_to_non_nullable
as double,brakeEventCost: freezed == brakeEventCost ? _self.brakeEventCost : brakeEventCost // ignore: cast_nullable_to_non_nullable
as double?,gradeClimbCost: freezed == gradeClimbCost ? _self.gradeClimbCost : gradeClimbCost // ignore: cast_nullable_to_non_nullable
as double?,cornerLoadCost: freezed == cornerLoadCost ? _self.cornerLoadCost : cornerLoadCost // ignore: cast_nullable_to_non_nullable
as double?,fillUpReconciliationCount: null == fillUpReconciliationCount ? _self.fillUpReconciliationCount : fillUpReconciliationCount // ignore: cast_nullable_to_non_nullable
as int,residualVariance: null == residualVariance ? _self.residualVariance : residualVariance // ignore: cast_nullable_to_non_nullable
as double,lastReconciledAt: freezed == lastReconciledAt ? _self.lastReconciledAt : lastReconciledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GpsCalibrationMatrix].
extension GpsCalibrationMatrixPatterns on GpsCalibrationMatrix {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GpsCalibrationMatrix value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GpsCalibrationMatrix() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GpsCalibrationMatrix value)  $default,){
final _that = this;
switch (_that) {
case _GpsCalibrationMatrix():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GpsCalibrationMatrix value)?  $default,){
final _that = this;
switch (_that) {
case _GpsCalibrationMatrix() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double baseline,  double idleCost,  double highSpeedPenalty,  double accelEventCost,  double? brakeEventCost,  double? gradeClimbCost,  double? cornerLoadCost,  int fillUpReconciliationCount,  double residualVariance,  DateTime? lastReconciledAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GpsCalibrationMatrix() when $default != null:
return $default(_that.baseline,_that.idleCost,_that.highSpeedPenalty,_that.accelEventCost,_that.brakeEventCost,_that.gradeClimbCost,_that.cornerLoadCost,_that.fillUpReconciliationCount,_that.residualVariance,_that.lastReconciledAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double baseline,  double idleCost,  double highSpeedPenalty,  double accelEventCost,  double? brakeEventCost,  double? gradeClimbCost,  double? cornerLoadCost,  int fillUpReconciliationCount,  double residualVariance,  DateTime? lastReconciledAt)  $default,) {final _that = this;
switch (_that) {
case _GpsCalibrationMatrix():
return $default(_that.baseline,_that.idleCost,_that.highSpeedPenalty,_that.accelEventCost,_that.brakeEventCost,_that.gradeClimbCost,_that.cornerLoadCost,_that.fillUpReconciliationCount,_that.residualVariance,_that.lastReconciledAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double baseline,  double idleCost,  double highSpeedPenalty,  double accelEventCost,  double? brakeEventCost,  double? gradeClimbCost,  double? cornerLoadCost,  int fillUpReconciliationCount,  double residualVariance,  DateTime? lastReconciledAt)?  $default,) {final _that = this;
switch (_that) {
case _GpsCalibrationMatrix() when $default != null:
return $default(_that.baseline,_that.idleCost,_that.highSpeedPenalty,_that.accelEventCost,_that.brakeEventCost,_that.gradeClimbCost,_that.cornerLoadCost,_that.fillUpReconciliationCount,_that.residualVariance,_that.lastReconciledAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GpsCalibrationMatrix extends GpsCalibrationMatrix {
  const _GpsCalibrationMatrix({this.baseline = 6.5, this.idleCost = 1.2, this.highSpeedPenalty = 2.0, this.accelEventCost = 0.5, this.brakeEventCost, this.gradeClimbCost, this.cornerLoadCost, this.fillUpReconciliationCount = 0, this.residualVariance = 0.0, this.lastReconciledAt}): super._();
  factory _GpsCalibrationMatrix.fromJson(Map<String, dynamic> json) => _$GpsCalibrationMatrixFromJson(json);

/// Constant L/100 km term. Seeded from the vehicle's declared
/// WLTP at cold start, refined per fill-up. Default matches
/// [defaultBaselineLPer100Km] (literal here because freezed's
/// generator can't resolve static-const names in `@Default`).
@override@JsonKey() final  double baseline;
/// L/100 km penalty per share-of-idle (idle_seconds / total).
/// Default matches [defaultIdleCost].
@override@JsonKey() final  double idleCost;
/// L/100 km penalty per share-of-≥110-km/h. Default matches
/// [defaultHighSpeedPenalty].
@override@JsonKey() final  double highSpeedPenalty;
/// L/100 km penalty per accel-event-per-km. Default matches
/// [defaultAccelEventCost].
@override@JsonKey() final  double accelEventCost;
// ─── Reserved 7-coef expansion slots — null in the lean model ───
/// Brake event cost (proxy for missed regen / coasting
/// opportunity). Null until the expand-on-demand trigger fires
/// (cold maturity + variance > threshold after 8 fill-ups).
@override final  double? brakeEventCost;
/// Grade-climb cost per 100 m climbed. Null until expansion.
@override final  double? gradeClimbCost;
/// Corner-load cost per integral unit. Null until expansion.
@override final  double? cornerLoadCost;
// ─── Reconciliation bookkeeping ───
/// How many fill-ups have contributed an LSQ update to this
/// matrix. Drives the maturity tier (cold < 3, warming 3–7,
/// converged ≥ 8 per ADR 0010).
@override@JsonKey() final  int fillUpReconciliationCount;
/// Mean squared residual over the last 5 fill-up windows
/// in (L/100 km)². Drives the maturity tier alongside the count.
@override@JsonKey() final  double residualVariance;
/// Wall-clock timestamp of the most recent reconciliation, or
/// null when the matrix has never been refined.
@override final  DateTime? lastReconciledAt;

/// Create a copy of GpsCalibrationMatrix
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GpsCalibrationMatrixCopyWith<_GpsCalibrationMatrix> get copyWith => __$GpsCalibrationMatrixCopyWithImpl<_GpsCalibrationMatrix>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GpsCalibrationMatrixToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GpsCalibrationMatrix&&(identical(other.baseline, baseline) || other.baseline == baseline)&&(identical(other.idleCost, idleCost) || other.idleCost == idleCost)&&(identical(other.highSpeedPenalty, highSpeedPenalty) || other.highSpeedPenalty == highSpeedPenalty)&&(identical(other.accelEventCost, accelEventCost) || other.accelEventCost == accelEventCost)&&(identical(other.brakeEventCost, brakeEventCost) || other.brakeEventCost == brakeEventCost)&&(identical(other.gradeClimbCost, gradeClimbCost) || other.gradeClimbCost == gradeClimbCost)&&(identical(other.cornerLoadCost, cornerLoadCost) || other.cornerLoadCost == cornerLoadCost)&&(identical(other.fillUpReconciliationCount, fillUpReconciliationCount) || other.fillUpReconciliationCount == fillUpReconciliationCount)&&(identical(other.residualVariance, residualVariance) || other.residualVariance == residualVariance)&&(identical(other.lastReconciledAt, lastReconciledAt) || other.lastReconciledAt == lastReconciledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,baseline,idleCost,highSpeedPenalty,accelEventCost,brakeEventCost,gradeClimbCost,cornerLoadCost,fillUpReconciliationCount,residualVariance,lastReconciledAt);

@override
String toString() {
  return 'GpsCalibrationMatrix(baseline: $baseline, idleCost: $idleCost, highSpeedPenalty: $highSpeedPenalty, accelEventCost: $accelEventCost, brakeEventCost: $brakeEventCost, gradeClimbCost: $gradeClimbCost, cornerLoadCost: $cornerLoadCost, fillUpReconciliationCount: $fillUpReconciliationCount, residualVariance: $residualVariance, lastReconciledAt: $lastReconciledAt)';
}


}

/// @nodoc
abstract mixin class _$GpsCalibrationMatrixCopyWith<$Res> implements $GpsCalibrationMatrixCopyWith<$Res> {
  factory _$GpsCalibrationMatrixCopyWith(_GpsCalibrationMatrix value, $Res Function(_GpsCalibrationMatrix) _then) = __$GpsCalibrationMatrixCopyWithImpl;
@override @useResult
$Res call({
 double baseline, double idleCost, double highSpeedPenalty, double accelEventCost, double? brakeEventCost, double? gradeClimbCost, double? cornerLoadCost, int fillUpReconciliationCount, double residualVariance, DateTime? lastReconciledAt
});




}
/// @nodoc
class __$GpsCalibrationMatrixCopyWithImpl<$Res>
    implements _$GpsCalibrationMatrixCopyWith<$Res> {
  __$GpsCalibrationMatrixCopyWithImpl(this._self, this._then);

  final _GpsCalibrationMatrix _self;
  final $Res Function(_GpsCalibrationMatrix) _then;

/// Create a copy of GpsCalibrationMatrix
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? baseline = null,Object? idleCost = null,Object? highSpeedPenalty = null,Object? accelEventCost = null,Object? brakeEventCost = freezed,Object? gradeClimbCost = freezed,Object? cornerLoadCost = freezed,Object? fillUpReconciliationCount = null,Object? residualVariance = null,Object? lastReconciledAt = freezed,}) {
  return _then(_GpsCalibrationMatrix(
baseline: null == baseline ? _self.baseline : baseline // ignore: cast_nullable_to_non_nullable
as double,idleCost: null == idleCost ? _self.idleCost : idleCost // ignore: cast_nullable_to_non_nullable
as double,highSpeedPenalty: null == highSpeedPenalty ? _self.highSpeedPenalty : highSpeedPenalty // ignore: cast_nullable_to_non_nullable
as double,accelEventCost: null == accelEventCost ? _self.accelEventCost : accelEventCost // ignore: cast_nullable_to_non_nullable
as double,brakeEventCost: freezed == brakeEventCost ? _self.brakeEventCost : brakeEventCost // ignore: cast_nullable_to_non_nullable
as double?,gradeClimbCost: freezed == gradeClimbCost ? _self.gradeClimbCost : gradeClimbCost // ignore: cast_nullable_to_non_nullable
as double?,cornerLoadCost: freezed == cornerLoadCost ? _self.cornerLoadCost : cornerLoadCost // ignore: cast_nullable_to_non_nullable
as double?,fillUpReconciliationCount: null == fillUpReconciliationCount ? _self.fillUpReconciliationCount : fillUpReconciliationCount // ignore: cast_nullable_to_non_nullable
as int,residualVariance: null == residualVariance ? _self.residualVariance : residualVariance // ignore: cast_nullable_to_non_nullable
as double,lastReconciledAt: freezed == lastReconciledAt ? _self.lastReconciledAt : lastReconciledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
