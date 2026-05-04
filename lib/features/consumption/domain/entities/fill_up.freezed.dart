// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fill_up.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FillUp {

 String get id; DateTime get date; double get liters; double get totalCost; double get odometerKm;@FuelTypeJsonConverter() FuelType get fuelType; String? get stationId; String? get stationName; String? get notes;/// Optional reference to the [VehicleProfile] this fill-up belongs to
/// (#694). Null means the user logged the fill-up without attributing
/// it to a specific vehicle. Used to group per-vehicle stats and to
/// pre-fill the next log entry.
 String? get vehicleId;/// OBD2 trip-history ids that were recorded for this vehicle since
/// the previous fill-up (#888). Populated automatically by the
/// `FillUpList.add` path: trajets are first-class, standalone
/// recordings, and the link from tank-to-tank is derived on save
/// rather than baked into the trip flow. Empty when no trajets
/// were recorded in the window or when the fill-up has no bound
/// vehicle.
 List<String> get linkedTripIds;/// Whether this fill-up topped the tank up to capacity (#1195).
///
/// Default `true` matches the typical European "plein" pattern —
/// most users fill all the way up. The flag governs how the tank-
/// level estimator initialises after this fill-up: when `true`, the
/// estimator resets to the vehicle's `tankCapacityL`; when `false`,
/// it uses `previous_level + liters_added` (partial top-up).
/// Existing fill-ups deserialise with the default so historical
/// data keeps working as full-tank fills.
 bool get isFullTank;/// Whether this fill-up is an auto-generated correction entry that
/// closes the gap between OBD-recorded trip fuel and pumped liters
/// over a plein-to-plein window (#1361). Correction entries are
/// rendered orange in the fill-up list and are user-editable.
/// Defaults `false` so existing fill-ups deserialise unchanged.
 bool get isCorrection;/// Tank level in litres read from OBD2 immediately before the pump
/// started (#1401 phase 7a). Used by the upcoming reconciliation
/// flow to verify pumped litres against tank-delta and surface a
/// "verified by adapter" badge. Null when not captured — phone away
/// from the car, no adapter paired, fuel-level PID unsupported, or
/// the user logged the fill-up after the fact. Existing fill-ups
/// deserialise with null so historical data keeps working.
 double? get fuelLevelBeforeL;/// Tank level in litres read from OBD2 after the pump finished
/// (#1401 phase 7a). Paired with [fuelLevelBeforeL] to compute the
/// adapter-measured tank delta and compare it against the pumped
/// volume. Null when not captured for the same reasons as
/// [fuelLevelBeforeL]. Existing fill-ups deserialise with null so
/// historical data keeps working.
 double? get fuelLevelAfterL;
/// Create a copy of FillUp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FillUpCopyWith<FillUp> get copyWith => _$FillUpCopyWithImpl<FillUp>(this as FillUp, _$identity);

  /// Serializes this FillUp to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FillUp&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.liters, liters) || other.liters == liters)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.odometerKm, odometerKm) || other.odometerKm == odometerKm)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.stationId, stationId) || other.stationId == stationId)&&(identical(other.stationName, stationName) || other.stationName == stationName)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&const DeepCollectionEquality().equals(other.linkedTripIds, linkedTripIds)&&(identical(other.isFullTank, isFullTank) || other.isFullTank == isFullTank)&&(identical(other.isCorrection, isCorrection) || other.isCorrection == isCorrection)&&(identical(other.fuelLevelBeforeL, fuelLevelBeforeL) || other.fuelLevelBeforeL == fuelLevelBeforeL)&&(identical(other.fuelLevelAfterL, fuelLevelAfterL) || other.fuelLevelAfterL == fuelLevelAfterL));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,liters,totalCost,odometerKm,fuelType,stationId,stationName,notes,vehicleId,const DeepCollectionEquality().hash(linkedTripIds),isFullTank,isCorrection,fuelLevelBeforeL,fuelLevelAfterL);

@override
String toString() {
  return 'FillUp(id: $id, date: $date, liters: $liters, totalCost: $totalCost, odometerKm: $odometerKm, fuelType: $fuelType, stationId: $stationId, stationName: $stationName, notes: $notes, vehicleId: $vehicleId, linkedTripIds: $linkedTripIds, isFullTank: $isFullTank, isCorrection: $isCorrection, fuelLevelBeforeL: $fuelLevelBeforeL, fuelLevelAfterL: $fuelLevelAfterL)';
}


}

/// @nodoc
abstract mixin class $FillUpCopyWith<$Res>  {
  factory $FillUpCopyWith(FillUp value, $Res Function(FillUp) _then) = _$FillUpCopyWithImpl;
@useResult
$Res call({
 String id, DateTime date, double liters, double totalCost, double odometerKm,@FuelTypeJsonConverter() FuelType fuelType, String? stationId, String? stationName, String? notes, String? vehicleId, List<String> linkedTripIds, bool isFullTank, bool isCorrection, double? fuelLevelBeforeL, double? fuelLevelAfterL
});




}
/// @nodoc
class _$FillUpCopyWithImpl<$Res>
    implements $FillUpCopyWith<$Res> {
  _$FillUpCopyWithImpl(this._self, this._then);

  final FillUp _self;
  final $Res Function(FillUp) _then;

/// Create a copy of FillUp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? liters = null,Object? totalCost = null,Object? odometerKm = null,Object? fuelType = null,Object? stationId = freezed,Object? stationName = freezed,Object? notes = freezed,Object? vehicleId = freezed,Object? linkedTripIds = null,Object? isFullTank = null,Object? isCorrection = null,Object? fuelLevelBeforeL = freezed,Object? fuelLevelAfterL = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,liters: null == liters ? _self.liters : liters // ignore: cast_nullable_to_non_nullable
as double,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,odometerKm: null == odometerKm ? _self.odometerKm : odometerKm // ignore: cast_nullable_to_non_nullable
as double,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType,stationId: freezed == stationId ? _self.stationId : stationId // ignore: cast_nullable_to_non_nullable
as String?,stationName: freezed == stationName ? _self.stationName : stationName // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,vehicleId: freezed == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String?,linkedTripIds: null == linkedTripIds ? _self.linkedTripIds : linkedTripIds // ignore: cast_nullable_to_non_nullable
as List<String>,isFullTank: null == isFullTank ? _self.isFullTank : isFullTank // ignore: cast_nullable_to_non_nullable
as bool,isCorrection: null == isCorrection ? _self.isCorrection : isCorrection // ignore: cast_nullable_to_non_nullable
as bool,fuelLevelBeforeL: freezed == fuelLevelBeforeL ? _self.fuelLevelBeforeL : fuelLevelBeforeL // ignore: cast_nullable_to_non_nullable
as double?,fuelLevelAfterL: freezed == fuelLevelAfterL ? _self.fuelLevelAfterL : fuelLevelAfterL // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [FillUp].
extension FillUpPatterns on FillUp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FillUp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FillUp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FillUp value)  $default,){
final _that = this;
switch (_that) {
case _FillUp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FillUp value)?  $default,){
final _that = this;
switch (_that) {
case _FillUp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime date,  double liters,  double totalCost,  double odometerKm, @FuelTypeJsonConverter()  FuelType fuelType,  String? stationId,  String? stationName,  String? notes,  String? vehicleId,  List<String> linkedTripIds,  bool isFullTank,  bool isCorrection,  double? fuelLevelBeforeL,  double? fuelLevelAfterL)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FillUp() when $default != null:
return $default(_that.id,_that.date,_that.liters,_that.totalCost,_that.odometerKm,_that.fuelType,_that.stationId,_that.stationName,_that.notes,_that.vehicleId,_that.linkedTripIds,_that.isFullTank,_that.isCorrection,_that.fuelLevelBeforeL,_that.fuelLevelAfterL);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime date,  double liters,  double totalCost,  double odometerKm, @FuelTypeJsonConverter()  FuelType fuelType,  String? stationId,  String? stationName,  String? notes,  String? vehicleId,  List<String> linkedTripIds,  bool isFullTank,  bool isCorrection,  double? fuelLevelBeforeL,  double? fuelLevelAfterL)  $default,) {final _that = this;
switch (_that) {
case _FillUp():
return $default(_that.id,_that.date,_that.liters,_that.totalCost,_that.odometerKm,_that.fuelType,_that.stationId,_that.stationName,_that.notes,_that.vehicleId,_that.linkedTripIds,_that.isFullTank,_that.isCorrection,_that.fuelLevelBeforeL,_that.fuelLevelAfterL);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime date,  double liters,  double totalCost,  double odometerKm, @FuelTypeJsonConverter()  FuelType fuelType,  String? stationId,  String? stationName,  String? notes,  String? vehicleId,  List<String> linkedTripIds,  bool isFullTank,  bool isCorrection,  double? fuelLevelBeforeL,  double? fuelLevelAfterL)?  $default,) {final _that = this;
switch (_that) {
case _FillUp() when $default != null:
return $default(_that.id,_that.date,_that.liters,_that.totalCost,_that.odometerKm,_that.fuelType,_that.stationId,_that.stationName,_that.notes,_that.vehicleId,_that.linkedTripIds,_that.isFullTank,_that.isCorrection,_that.fuelLevelBeforeL,_that.fuelLevelAfterL);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FillUp implements FillUp {
  const _FillUp({required this.id, required this.date, required this.liters, required this.totalCost, required this.odometerKm, @FuelTypeJsonConverter() required this.fuelType, this.stationId, this.stationName, this.notes, this.vehicleId, final  List<String> linkedTripIds = const <String>[], this.isFullTank = true, this.isCorrection = false, this.fuelLevelBeforeL, this.fuelLevelAfterL}): _linkedTripIds = linkedTripIds;
  factory _FillUp.fromJson(Map<String, dynamic> json) => _$FillUpFromJson(json);

@override final  String id;
@override final  DateTime date;
@override final  double liters;
@override final  double totalCost;
@override final  double odometerKm;
@override@FuelTypeJsonConverter() final  FuelType fuelType;
@override final  String? stationId;
@override final  String? stationName;
@override final  String? notes;
/// Optional reference to the [VehicleProfile] this fill-up belongs to
/// (#694). Null means the user logged the fill-up without attributing
/// it to a specific vehicle. Used to group per-vehicle stats and to
/// pre-fill the next log entry.
@override final  String? vehicleId;
/// OBD2 trip-history ids that were recorded for this vehicle since
/// the previous fill-up (#888). Populated automatically by the
/// `FillUpList.add` path: trajets are first-class, standalone
/// recordings, and the link from tank-to-tank is derived on save
/// rather than baked into the trip flow. Empty when no trajets
/// were recorded in the window or when the fill-up has no bound
/// vehicle.
 final  List<String> _linkedTripIds;
/// OBD2 trip-history ids that were recorded for this vehicle since
/// the previous fill-up (#888). Populated automatically by the
/// `FillUpList.add` path: trajets are first-class, standalone
/// recordings, and the link from tank-to-tank is derived on save
/// rather than baked into the trip flow. Empty when no trajets
/// were recorded in the window or when the fill-up has no bound
/// vehicle.
@override@JsonKey() List<String> get linkedTripIds {
  if (_linkedTripIds is EqualUnmodifiableListView) return _linkedTripIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_linkedTripIds);
}

/// Whether this fill-up topped the tank up to capacity (#1195).
///
/// Default `true` matches the typical European "plein" pattern —
/// most users fill all the way up. The flag governs how the tank-
/// level estimator initialises after this fill-up: when `true`, the
/// estimator resets to the vehicle's `tankCapacityL`; when `false`,
/// it uses `previous_level + liters_added` (partial top-up).
/// Existing fill-ups deserialise with the default so historical
/// data keeps working as full-tank fills.
@override@JsonKey() final  bool isFullTank;
/// Whether this fill-up is an auto-generated correction entry that
/// closes the gap between OBD-recorded trip fuel and pumped liters
/// over a plein-to-plein window (#1361). Correction entries are
/// rendered orange in the fill-up list and are user-editable.
/// Defaults `false` so existing fill-ups deserialise unchanged.
@override@JsonKey() final  bool isCorrection;
/// Tank level in litres read from OBD2 immediately before the pump
/// started (#1401 phase 7a). Used by the upcoming reconciliation
/// flow to verify pumped litres against tank-delta and surface a
/// "verified by adapter" badge. Null when not captured — phone away
/// from the car, no adapter paired, fuel-level PID unsupported, or
/// the user logged the fill-up after the fact. Existing fill-ups
/// deserialise with null so historical data keeps working.
@override final  double? fuelLevelBeforeL;
/// Tank level in litres read from OBD2 after the pump finished
/// (#1401 phase 7a). Paired with [fuelLevelBeforeL] to compute the
/// adapter-measured tank delta and compare it against the pumped
/// volume. Null when not captured for the same reasons as
/// [fuelLevelBeforeL]. Existing fill-ups deserialise with null so
/// historical data keeps working.
@override final  double? fuelLevelAfterL;

/// Create a copy of FillUp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FillUpCopyWith<_FillUp> get copyWith => __$FillUpCopyWithImpl<_FillUp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FillUpToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FillUp&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.liters, liters) || other.liters == liters)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.odometerKm, odometerKm) || other.odometerKm == odometerKm)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.stationId, stationId) || other.stationId == stationId)&&(identical(other.stationName, stationName) || other.stationName == stationName)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.vehicleId, vehicleId) || other.vehicleId == vehicleId)&&const DeepCollectionEquality().equals(other._linkedTripIds, _linkedTripIds)&&(identical(other.isFullTank, isFullTank) || other.isFullTank == isFullTank)&&(identical(other.isCorrection, isCorrection) || other.isCorrection == isCorrection)&&(identical(other.fuelLevelBeforeL, fuelLevelBeforeL) || other.fuelLevelBeforeL == fuelLevelBeforeL)&&(identical(other.fuelLevelAfterL, fuelLevelAfterL) || other.fuelLevelAfterL == fuelLevelAfterL));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,liters,totalCost,odometerKm,fuelType,stationId,stationName,notes,vehicleId,const DeepCollectionEquality().hash(_linkedTripIds),isFullTank,isCorrection,fuelLevelBeforeL,fuelLevelAfterL);

@override
String toString() {
  return 'FillUp(id: $id, date: $date, liters: $liters, totalCost: $totalCost, odometerKm: $odometerKm, fuelType: $fuelType, stationId: $stationId, stationName: $stationName, notes: $notes, vehicleId: $vehicleId, linkedTripIds: $linkedTripIds, isFullTank: $isFullTank, isCorrection: $isCorrection, fuelLevelBeforeL: $fuelLevelBeforeL, fuelLevelAfterL: $fuelLevelAfterL)';
}


}

/// @nodoc
abstract mixin class _$FillUpCopyWith<$Res> implements $FillUpCopyWith<$Res> {
  factory _$FillUpCopyWith(_FillUp value, $Res Function(_FillUp) _then) = __$FillUpCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime date, double liters, double totalCost, double odometerKm,@FuelTypeJsonConverter() FuelType fuelType, String? stationId, String? stationName, String? notes, String? vehicleId, List<String> linkedTripIds, bool isFullTank, bool isCorrection, double? fuelLevelBeforeL, double? fuelLevelAfterL
});




}
/// @nodoc
class __$FillUpCopyWithImpl<$Res>
    implements _$FillUpCopyWith<$Res> {
  __$FillUpCopyWithImpl(this._self, this._then);

  final _FillUp _self;
  final $Res Function(_FillUp) _then;

/// Create a copy of FillUp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? liters = null,Object? totalCost = null,Object? odometerKm = null,Object? fuelType = null,Object? stationId = freezed,Object? stationName = freezed,Object? notes = freezed,Object? vehicleId = freezed,Object? linkedTripIds = null,Object? isFullTank = null,Object? isCorrection = null,Object? fuelLevelBeforeL = freezed,Object? fuelLevelAfterL = freezed,}) {
  return _then(_FillUp(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,liters: null == liters ? _self.liters : liters // ignore: cast_nullable_to_non_nullable
as double,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,odometerKm: null == odometerKm ? _self.odometerKm : odometerKm // ignore: cast_nullable_to_non_nullable
as double,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType,stationId: freezed == stationId ? _self.stationId : stationId // ignore: cast_nullable_to_non_nullable
as String?,stationName: freezed == stationName ? _self.stationName : stationName // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,vehicleId: freezed == vehicleId ? _self.vehicleId : vehicleId // ignore: cast_nullable_to_non_nullable
as String?,linkedTripIds: null == linkedTripIds ? _self._linkedTripIds : linkedTripIds // ignore: cast_nullable_to_non_nullable
as List<String>,isFullTank: null == isFullTank ? _self.isFullTank : isFullTank // ignore: cast_nullable_to_non_nullable
as bool,isCorrection: null == isCorrection ? _self.isCorrection : isCorrection // ignore: cast_nullable_to_non_nullable
as bool,fuelLevelBeforeL: freezed == fuelLevelBeforeL ? _self.fuelLevelBeforeL : fuelLevelBeforeL // ignore: cast_nullable_to_non_nullable
as double?,fuelLevelAfterL: freezed == fuelLevelAfterL ? _self.fuelLevelAfterL : fuelLevelAfterL // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
