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

 String get id; DateTime get date; double get kwh; double get totalCost; double get odometerKm;/// Optional charging duration in minutes. Some users log every
/// session, others only track kWh + cost. Null when unrecorded.
 int? get chargeTimeMin; String? get stationId; String? get stationName;/// Operator / network (Ionity, Shell Recharge, Tesla, etc.).
/// Optional because OCM doesn't always carry one.
 String? get operator; String? get notes;/// Reference to the vehicle that was charged (#694). Null means
/// the user logged the session without attributing it.
 String? get vehicleId;
/// Create a copy of ChargingLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChargingLogCopyWith<ChargingLog> get copyWith => _$ChargingLogCopyWithImpl<ChargingLog>(this as ChargingLog, _$identity);

  /// Serializes this ChargingLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChargingLog&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.kwh, kwh) || other.kwh == kwh)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.odometerKm, odometerKm) || other.odometerKm == odometerKm)&&(identical(other.chargeTimeMin, chargeTimeMin) || other.chargeTimeMin == chargeTimeMin)&&(identical(other.stationId, stationId) || other.stationId == stationId)&&(identical(other.stationName, stationName) || other.stationName == stationName)&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,kwh,totalCost,odometerKm,chargeTimeMin,stationId,stationName,operator,notes,vehicleId);

@override
String toString() {
  return 'ChargingLog(id: $id, date: $date, kwh: $kwh, totalCost: $totalCost, odometerKm: $odometerKm, chargeTimeMin: $chargeTimeMin, stationId: $stationId, stationName: $stationName, operator: $operator, notes: $notes, vehicleId: $vehicleId)';
}


}

/// @nodoc
abstract mixin class $ChargingLogCopyWith<$Res>  {
  factory $ChargingLogCopyWith(ChargingLog value, $Res Function(ChargingLog) _then) = _$ChargingLogCopyWithImpl;
@useResult
$Res call({
 String id, DateTime date, double kwh, double totalCost, double odometerKm, int? chargeTimeMin, String? stationId, String? stationName, String? operator, String? notes, String? vehicleId
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? kwh = null,Object? totalCost = null,Object? odometerKm = null,Object? chargeTimeMin = freezed,Object? stationId = freezed,Object? stationName = freezed,Object? operator = freezed,Object? notes = freezed,Object? vehicleId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,kwh: null == kwh ? _self.kwh : kwh // ignore: cast_nullable_to_non_nullable
as double,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,odometerKm: null == odometerKm ? _self.odometerKm : odometerKm // ignore: cast_nullable_to_non_nullable
as double,chargeTimeMin: freezed == chargeTimeMin ? _self.chargeTimeMin : chargeTimeMin // ignore: cast_nullable_to_non_nullable
as int?,stationId: freezed == stationId ? _self.stationId : stationId // ignore: cast_nullable_to_non_nullable
as String?,stationName: freezed == stationName ? _self.stationName : stationName // ignore: cast_nullable_to_non_nullable
as String?,operator: freezed == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,vehicleId: freezed == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime date,  double kwh,  double totalCost,  double odometerKm,  int? chargeTimeMin,  String? stationId,  String? stationName,  String? operator,  String? notes,  String? vehicleId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChargingLog() when $default != null:
return $default(_that.id,_that.date,_that.kwh,_that.totalCost,_that.odometerKm,_that.chargeTimeMin,_that.stationId,_that.stationName,_that.operator,_that.notes,_that.vehicleId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime date,  double kwh,  double totalCost,  double odometerKm,  int? chargeTimeMin,  String? stationId,  String? stationName,  String? operator,  String? notes,  String? vehicleId)  $default,) {final _that = this;
switch (_that) {
case _ChargingLog():
return $default(_that.id,_that.date,_that.kwh,_that.totalCost,_that.odometerKm,_that.chargeTimeMin,_that.stationId,_that.stationName,_that.operator,_that.notes,_that.vehicleId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime date,  double kwh,  double totalCost,  double odometerKm,  int? chargeTimeMin,  String? stationId,  String? stationName,  String? operator,  String? notes,  String? vehicleId)?  $default,) {final _that = this;
switch (_that) {
case _ChargingLog() when $default != null:
return $default(_that.id,_that.date,_that.kwh,_that.totalCost,_that.odometerKm,_that.chargeTimeMin,_that.stationId,_that.stationName,_that.operator,_that.notes,_that.vehicleId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChargingLog extends ChargingLog {
  const _ChargingLog({required this.id, required this.date, required this.kwh, required this.totalCost, required this.odometerKm, this.chargeTimeMin, this.stationId, this.stationName, this.operator, this.notes, this.vehicleId}): super._();
  factory _ChargingLog.fromJson(Map<String, dynamic> json) => _$ChargingLogFromJson(json);

@override final  String id;
@override final  DateTime date;
@override final  double kwh;
@override final  double totalCost;
@override final  double odometerKm;
/// Optional charging duration in minutes. Some users log every
/// session, others only track kWh + cost. Null when unrecorded.
@override final  int? chargeTimeMin;
@override final  String? stationId;
@override final  String? stationName;
/// Operator / network (Ionity, Shell Recharge, Tesla, etc.).
/// Optional because OCM doesn't always carry one.
@override final  String? operator;
@override final  String? notes;
/// Reference to the vehicle that was charged (#694). Null means
/// the user logged the session without attributing it.
@override final  String? vehicleId;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChargingLog&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.kwh, kwh) || other.kwh == kwh)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.odometerKm, odometerKm) || other.odometerKm == odometerKm)&&(identical(other.chargeTimeMin, chargeTimeMin) || other.chargeTimeMin == chargeTimeMin)&&(identical(other.stationId, stationId) || other.stationId == stationId)&&(identical(other.stationName, stationName) || other.stationName == stationName)&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,kwh,totalCost,odometerKm,chargeTimeMin,stationId,stationName,operator,notes,vehicleId);

@override
String toString() {
  return 'ChargingLog(id: $id, date: $date, kwh: $kwh, totalCost: $totalCost, odometerKm: $odometerKm, chargeTimeMin: $chargeTimeMin, stationId: $stationId, stationName: $stationName, operator: $operator, notes: $notes, vehicleId: $vehicleId)';
}


}

/// @nodoc
abstract mixin class _$ChargingLogCopyWith<$Res> implements $ChargingLogCopyWith<$Res> {
  factory _$ChargingLogCopyWith(_ChargingLog value, $Res Function(_ChargingLog) _then) = __$ChargingLogCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime date, double kwh, double totalCost, double odometerKm, int? chargeTimeMin, String? stationId, String? stationName, String? operator, String? notes, String? vehicleId
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? kwh = null,Object? totalCost = null,Object? odometerKm = null,Object? chargeTimeMin = freezed,Object? stationId = freezed,Object? stationName = freezed,Object? operator = freezed,Object? notes = freezed,Object? vehicleId = freezed,}) {
  return _then(_ChargingLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,kwh: null == kwh ? _self.kwh : kwh // ignore: cast_nullable_to_non_nullable
as double,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,odometerKm: null == odometerKm ? _self.odometerKm : odometerKm // ignore: cast_nullable_to_non_nullable
as double,chargeTimeMin: freezed == chargeTimeMin ? _self.chargeTimeMin : chargeTimeMin // ignore: cast_nullable_to_non_nullable
as int?,stationId: freezed == stationId ? _self.stationId : stationId // ignore: cast_nullable_to_non_nullable
as String?,stationName: freezed == stationName ? _self.stationName : stationName // ignore: cast_nullable_to_non_nullable
as String?,operator: freezed == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,vehicleId: freezed == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
