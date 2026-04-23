// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'charging_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChargingLog {

 String get id;/// Vehicle that was charged. Required so per-vehicle EUR/100km
/// analytics (phase 2) always have a grouping key.
 String get vehicleId;/// Session timestamp. UTC is preferred so the phase-2 charts
/// line up across timezones, but the store persists whatever the
/// caller supplies.
 DateTime get date;/// Energy delivered during the session, in kilowatt-hours.
 double get kWh;/// Total amount paid for the session in euros. Keeping the
/// currency implicit mirrors the rest of the app — euro-only
/// until multi-currency lands.
 double get costEur;/// How long the car was plugged in, in whole minutes. Non-null
/// because "how long did that fast charge take?" is part of the
/// wheel-lens value prop — if the user genuinely doesn't know,
/// zero is the right sentinel (counts as "unreported" in
/// downstream analytics).
 int get chargeTimeMin;/// Odometer reading at the end of the session, in kilometres.
/// Drives the EUR/100km and kWh/100km calculations in
/// [ChargingCostCalculator] when paired with the previous log's
/// odometer.
 int get odometerKm;/// Free-form station label. Pre-filled when the log is opened
/// from the EV-station-detail screen in phase 2; editable
/// otherwise. Null when the user never typed one.
 String? get stationName;/// Optional link to the OCM charging station id — populated only
/// when the log was opened from the EV-station-detail screen.
/// Kept alongside [stationName] so phase-2 analytics can aggregate
/// by station without relying on free-form strings.
 String? get chargingStationId;
/// Create a copy of ChargingLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChargingLogCopyWith<ChargingLog> get copyWith => _$ChargingLogCopyWithImpl<ChargingLog>(this as ChargingLog, _$identity);

  /// Serializes this ChargingLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChargingLog&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.date, date) || other.date == date)&&(identical(other.kWh, kWh) || other.kWh == kWh)&&(identical(other.costEur, costEur) || other.costEur == costEur)&&(identical(other.chargeTimeMin, chargeTimeMin) || other.chargeTimeMin == chargeTimeMin)&&(identical(other.odometerKm, odometerKm) || other.odometerKm == odometerKm)&&(identical(other.stationName, stationName) || other.stationName == stationName)&&(identical(other.chargingStationId, chargingStationId) || other.chargingStationId == chargingStationId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,date,kWh,costEur,chargeTimeMin,odometerKm,stationName,chargingStationId);

@override
String toString() {
  return 'ChargingLog(id: $id, vehicleId: $vehicleId, date: $date, kWh: $kWh, costEur: $costEur, chargeTimeMin: $chargeTimeMin, odometerKm: $odometerKm, stationName: $stationName, chargingStationId: $chargingStationId)';
}


}

/// @nodoc
abstract mixin class $ChargingLogCopyWith<$Res>  {
  factory $ChargingLogCopyWith(ChargingLog value, $Res Function(ChargingLog) _then) = _$ChargingLogCopyWithImpl;
@useResult
$Res call({
 String id, String vehicleId, DateTime date, double kWh, double costEur, int chargeTimeMin, int odometerKm, String? stationName, String? chargingStationId
});




}
/// @nodoc
class _$ChargingLogCopyWithImpl<$Res>
    implements $ChargingLogCopyWith<$Res> {
  _$ChargingLogCopyWithImpl(this._self, this._then);

  final ChargingLog _self;
  final $Res Function(ChargingLog) _then;

/// Create a copy of ChargingLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vehicleId = null,Object? date = null,Object? kWh = null,Object? costEur = null,Object? chargeTimeMin = null,Object? odometerKm = null,Object? stationName = freezed,Object? chargingStationId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,kWh: null == kWh ? _self.kWh : kWh // ignore: cast_nullable_to_non_nullable
as double,costEur: null == costEur ? _self.costEur : costEur // ignore: cast_nullable_to_non_nullable
as double,chargeTimeMin: null == chargeTimeMin ? _self.chargeTimeMin : chargeTimeMin // ignore: cast_nullable_to_non_nullable
as int,odometerKm: null == odometerKm ? _self.odometerKm : odometerKm // ignore: cast_nullable_to_non_nullable
as int,stationName: freezed == stationName ? _self.stationName : stationName // ignore: cast_nullable_to_non_nullable
as String?,chargingStationId: freezed == chargingStationId ? _self.chargingStationId : chargingStationId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChargingLog].
extension ChargingLogPatterns on ChargingLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChargingLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChargingLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChargingLog value)  $default,){
final _that = this;
switch (_that) {
case _ChargingLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChargingLog value)?  $default,){
final _that = this;
switch (_that) {
case _ChargingLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String vehicleId,  DateTime date,  double kWh,  double costEur,  int chargeTimeMin,  int odometerKm,  String? stationName,  String? chargingStationId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChargingLog() when $default != null:
return $default(_that.id,_that.vehicleId,_that.date,_that.kWh,_that.costEur,_that.chargeTimeMin,_that.odometerKm,_that.stationName,_that.chargingStationId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String vehicleId,  DateTime date,  double kWh,  double costEur,  int chargeTimeMin,  int odometerKm,  String? stationName,  String? chargingStationId)  $default,) {final _that = this;
switch (_that) {
case _ChargingLog():
return $default(_that.id,_that.vehicleId,_that.date,_that.kWh,_that.costEur,_that.chargeTimeMin,_that.odometerKm,_that.stationName,_that.chargingStationId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String vehicleId,  DateTime date,  double kWh,  double costEur,  int chargeTimeMin,  int odometerKm,  String? stationName,  String? chargingStationId)?  $default,) {final _that = this;
switch (_that) {
case _ChargingLog() when $default != null:
return $default(_that.id,_that.vehicleId,_that.date,_that.kWh,_that.costEur,_that.chargeTimeMin,_that.odometerKm,_that.stationName,_that.chargingStationId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChargingLog implements ChargingLog {
  const _ChargingLog({required this.id, required this.vehicleId, required this.date, required this.kWh, required this.costEur, required this.chargeTimeMin, required this.odometerKm, this.stationName, this.chargingStationId});
  factory _ChargingLog.fromJson(Map<String, dynamic> json) => _$ChargingLogFromJson(json);

@override final  String id;
/// Vehicle that was charged. Required so per-vehicle EUR/100km
/// analytics (phase 2) always have a grouping key.
@override final  String vehicleId;
/// Session timestamp. UTC is preferred so the phase-2 charts
/// line up across timezones, but the store persists whatever the
/// caller supplies.
@override final  DateTime date;
/// Energy delivered during the session, in kilowatt-hours.
@override final  double kWh;
/// Total amount paid for the session in euros. Keeping the
/// currency implicit mirrors the rest of the app — euro-only
/// until multi-currency lands.
@override final  double costEur;
/// How long the car was plugged in, in whole minutes. Non-null
/// because "how long did that fast charge take?" is part of the
/// wheel-lens value prop — if the user genuinely doesn't know,
/// zero is the right sentinel (counts as "unreported" in
/// downstream analytics).
@override final  int chargeTimeMin;
/// Odometer reading at the end of the session, in kilometres.
/// Drives the EUR/100km and kWh/100km calculations in
/// [ChargingCostCalculator] when paired with the previous log's
/// odometer.
@override final  int odometerKm;
/// Free-form station label. Pre-filled when the log is opened
/// from the EV-station-detail screen in phase 2; editable
/// otherwise. Null when the user never typed one.
@override final  String? stationName;
/// Optional link to the OCM charging station id — populated only
/// when the log was opened from the EV-station-detail screen.
/// Kept alongside [stationName] so phase-2 analytics can aggregate
/// by station without relying on free-form strings.
@override final  String? chargingStationId;

/// Create a copy of ChargingLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChargingLogCopyWith<_ChargingLog> get copyWith => __$ChargingLogCopyWithImpl<_ChargingLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChargingLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChargingLog&&(identical(other.id, id) || other.id == id)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&(identical(other.date, date) || other.date == date)&&(identical(other.kWh, kWh) || other.kWh == kWh)&&(identical(other.costEur, costEur) || other.costEur == costEur)&&(identical(other.chargeTimeMin, chargeTimeMin) || other.chargeTimeMin == chargeTimeMin)&&(identical(other.odometerKm, odometerKm) || other.odometerKm == odometerKm)&&(identical(other.stationName, stationName) || other.stationName == stationName)&&(identical(other.chargingStationId, chargingStationId) || other.chargingStationId == chargingStationId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vehicleId,date,kWh,costEur,chargeTimeMin,odometerKm,stationName,chargingStationId);

@override
String toString() {
  return 'ChargingLog(id: $id, vehicleId: $vehicleId, date: $date, kWh: $kWh, costEur: $costEur, chargeTimeMin: $chargeTimeMin, odometerKm: $odometerKm, stationName: $stationName, chargingStationId: $chargingStationId)';
}


}

/// @nodoc
abstract mixin class _$ChargingLogCopyWith<$Res> implements $ChargingLogCopyWith<$Res> {
  factory _$ChargingLogCopyWith(_ChargingLog value, $Res Function(_ChargingLog) _then) = __$ChargingLogCopyWithImpl;
@override @useResult
$Res call({
 String id, String vehicleId, DateTime date, double kWh, double costEur, int chargeTimeMin, int odometerKm, String? stationName, String? chargingStationId
});




}
/// @nodoc
class __$ChargingLogCopyWithImpl<$Res>
    implements _$ChargingLogCopyWith<$Res> {
  __$ChargingLogCopyWithImpl(this._self, this._then);

  final _ChargingLog _self;
  final $Res Function(_ChargingLog) _then;

/// Create a copy of ChargingLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vehicleId = null,Object? date = null,Object? kWh = null,Object? costEur = null,Object? chargeTimeMin = null,Object? odometerKm = null,Object? stationName = freezed,Object? chargingStationId = freezed,}) {
  return _then(_ChargingLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vehicleId: null == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,kWh: null == kWh ? _self.kWh : kWh // ignore: cast_nullable_to_non_nullable
as double,costEur: null == costEur ? _self.costEur : costEur // ignore: cast_nullable_to_non_nullable
as double,chargeTimeMin: null == chargeTimeMin ? _self.chargeTimeMin : chargeTimeMin // ignore: cast_nullable_to_non_nullable
as int,odometerKm: null == odometerKm ? _self.odometerKm : odometerKm // ignore: cast_nullable_to_non_nullable
as int,stationName: freezed == stationName ? _self.stationName : stationName // ignore: cast_nullable_to_non_nullable
as String?,chargingStationId: freezed == chargingStationId ? _self.chargingStationId : chargingStationId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
