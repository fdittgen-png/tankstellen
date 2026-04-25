// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reference_vehicle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReferenceVehicle {

/// Manufacturer brand, e.g. "Peugeot", "Renault".
 String get make;/// Model name as marketed in Europe, e.g. "208", "Clio".
 String get model;/// Generation label, e.g. "II (2019-)" or "V (2020-)". Free form;
/// purely informational for the user-facing picker.
 String get generation;/// First model year for this generation.
 int get yearStart;/// Last model year, or null if still in production.
 int? get yearEnd;/// Engine displacement in cubic centimetres.
 int get displacementCc;/// One of "petrol", "diesel", "hybrid", "electric". Stored as a
/// string (not enum) so adding a new fuel type is JSON-only.
 String get fuelType;/// One of "manual", "automatic". Stored as a string so the catalog
/// can grow new transmission flavours without an entity change.
 String get transmission;/// Typical volumetric efficiency for this engine. Defaults to 0.85
/// when the manufacturer doesn't publish a tuning value.
 double get volumetricEfficiency;/// Which OBD-II PID strategy unlocks the odometer for this make.
/// One of:
///
///   - "stdA6"   — generic OBD-II Service 01 PID A6 (rare, but the
///                 standards-compliant default).
///   - "psaUds"  — PSA family (Peugeot, Citroen, DS, Opel post-2017,
///                 Vauxhall) UDS-over-CAN custom PID.
///   - "bmwCan"  — BMW raw-CAN broadcast frame.
///   - "vwUds"   — VAG group (VW, Skoda, Seat, Audi) UDS PID.
///   - "unknown" — no working strategy known; consumer falls back to
///                 trip integration.
 String get odometerPidStrategy;/// Optional free-form notes (e.g. "PHEV variant uses different VE").
 String? get notes;
/// Create a copy of ReferenceVehicle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReferenceVehicleCopyWith<ReferenceVehicle> get copyWith => _$ReferenceVehicleCopyWithImpl<ReferenceVehicle>(this as ReferenceVehicle, _$identity);

  /// Serializes this ReferenceVehicle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferenceVehicle&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.yearStart, yearStart) || other.yearStart == yearStart)&&(identical(other.yearEnd, yearEnd) || other.yearEnd == yearEnd)&&(identical(other.displacementCc, displacementCc) || other.displacementCc == displacementCc)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.transmission, transmission) || other.transmission == transmission)&&(identical(other.volumetricEfficiency, volumetricEfficiency) || other.volumetricEfficiency == volumetricEfficiency)&&(identical(other.odometerPidStrategy, odometerPidStrategy) || other.odometerPidStrategy == odometerPidStrategy)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,make,model,generation,yearStart,yearEnd,displacementCc,fuelType,transmission,volumetricEfficiency,odometerPidStrategy,notes);

@override
String toString() {
  return 'ReferenceVehicle(make: $make, model: $model, generation: $generation, yearStart: $yearStart, yearEnd: $yearEnd, displacementCc: $displacementCc, fuelType: $fuelType, transmission: $transmission, volumetricEfficiency: $volumetricEfficiency, odometerPidStrategy: $odometerPidStrategy, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $ReferenceVehicleCopyWith<$Res>  {
  factory $ReferenceVehicleCopyWith(ReferenceVehicle value, $Res Function(ReferenceVehicle) _then) = _$ReferenceVehicleCopyWithImpl;
@useResult
$Res call({
 String make, String model, String generation, int yearStart, int? yearEnd, int displacementCc, String fuelType, String transmission, double volumetricEfficiency, String odometerPidStrategy, String? notes
});




}
/// @nodoc
class _$ReferenceVehicleCopyWithImpl<$Res>
    implements $ReferenceVehicleCopyWith<$Res> {
  _$ReferenceVehicleCopyWithImpl(this._self, this._then);

  final ReferenceVehicle _self;
  final $Res Function(ReferenceVehicle) _then;

/// Create a copy of ReferenceVehicle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? make = null,Object? model = null,Object? generation = null,Object? yearStart = null,Object? yearEnd = freezed,Object? displacementCc = null,Object? fuelType = null,Object? transmission = null,Object? volumetricEfficiency = null,Object? odometerPidStrategy = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
make: null == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as String,yearStart: null == yearStart ? _self.yearStart : yearStart // ignore: cast_nullable_to_non_nullable
as int,yearEnd: freezed == yearEnd ? _self.yearEnd : yearEnd // ignore: cast_nullable_to_non_nullable
as int?,displacementCc: null == displacementCc ? _self.displacementCc : displacementCc // ignore: cast_nullable_to_non_nullable
as int,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as String,transmission: null == transmission ? _self.transmission : transmission // ignore: cast_nullable_to_non_nullable
as String,volumetricEfficiency: null == volumetricEfficiency ? _self.volumetricEfficiency : volumetricEfficiency // ignore: cast_nullable_to_non_nullable
as double,odometerPidStrategy: null == odometerPidStrategy ? _self.odometerPidStrategy : odometerPidStrategy // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReferenceVehicle].
extension ReferenceVehiclePatterns on ReferenceVehicle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReferenceVehicle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReferenceVehicle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReferenceVehicle value)  $default,){
final _that = this;
switch (_that) {
case _ReferenceVehicle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReferenceVehicle value)?  $default,){
final _that = this;
switch (_that) {
case _ReferenceVehicle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String make,  String model,  String generation,  int yearStart,  int? yearEnd,  int displacementCc,  String fuelType,  String transmission,  double volumetricEfficiency,  String odometerPidStrategy,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReferenceVehicle() when $default != null:
return $default(_that.make,_that.model,_that.generation,_that.yearStart,_that.yearEnd,_that.displacementCc,_that.fuelType,_that.transmission,_that.volumetricEfficiency,_that.odometerPidStrategy,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String make,  String model,  String generation,  int yearStart,  int? yearEnd,  int displacementCc,  String fuelType,  String transmission,  double volumetricEfficiency,  String odometerPidStrategy,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _ReferenceVehicle():
return $default(_that.make,_that.model,_that.generation,_that.yearStart,_that.yearEnd,_that.displacementCc,_that.fuelType,_that.transmission,_that.volumetricEfficiency,_that.odometerPidStrategy,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String make,  String model,  String generation,  int yearStart,  int? yearEnd,  int displacementCc,  String fuelType,  String transmission,  double volumetricEfficiency,  String odometerPidStrategy,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _ReferenceVehicle() when $default != null:
return $default(_that.make,_that.model,_that.generation,_that.yearStart,_that.yearEnd,_that.displacementCc,_that.fuelType,_that.transmission,_that.volumetricEfficiency,_that.odometerPidStrategy,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReferenceVehicle extends ReferenceVehicle {
  const _ReferenceVehicle({required this.make, required this.model, required this.generation, required this.yearStart, this.yearEnd, required this.displacementCc, required this.fuelType, required this.transmission, this.volumetricEfficiency = 0.85, this.odometerPidStrategy = 'stdA6', this.notes}): super._();
  factory _ReferenceVehicle.fromJson(Map<String, dynamic> json) => _$ReferenceVehicleFromJson(json);

/// Manufacturer brand, e.g. "Peugeot", "Renault".
@override final  String make;
/// Model name as marketed in Europe, e.g. "208", "Clio".
@override final  String model;
/// Generation label, e.g. "II (2019-)" or "V (2020-)". Free form;
/// purely informational for the user-facing picker.
@override final  String generation;
/// First model year for this generation.
@override final  int yearStart;
/// Last model year, or null if still in production.
@override final  int? yearEnd;
/// Engine displacement in cubic centimetres.
@override final  int displacementCc;
/// One of "petrol", "diesel", "hybrid", "electric". Stored as a
/// string (not enum) so adding a new fuel type is JSON-only.
@override final  String fuelType;
/// One of "manual", "automatic". Stored as a string so the catalog
/// can grow new transmission flavours without an entity change.
@override final  String transmission;
/// Typical volumetric efficiency for this engine. Defaults to 0.85
/// when the manufacturer doesn't publish a tuning value.
@override@JsonKey() final  double volumetricEfficiency;
/// Which OBD-II PID strategy unlocks the odometer for this make.
/// One of:
///
///   - "stdA6"   — generic OBD-II Service 01 PID A6 (rare, but the
///                 standards-compliant default).
///   - "psaUds"  — PSA family (Peugeot, Citroen, DS, Opel post-2017,
///                 Vauxhall) UDS-over-CAN custom PID.
///   - "bmwCan"  — BMW raw-CAN broadcast frame.
///   - "vwUds"   — VAG group (VW, Skoda, Seat, Audi) UDS PID.
///   - "unknown" — no working strategy known; consumer falls back to
///                 trip integration.
@override@JsonKey() final  String odometerPidStrategy;
/// Optional free-form notes (e.g. "PHEV variant uses different VE").
@override final  String? notes;

/// Create a copy of ReferenceVehicle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReferenceVehicleCopyWith<_ReferenceVehicle> get copyWith => __$ReferenceVehicleCopyWithImpl<_ReferenceVehicle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReferenceVehicleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReferenceVehicle&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.generation, generation) || other.generation == generation)&&(identical(other.yearStart, yearStart) || other.yearStart == yearStart)&&(identical(other.yearEnd, yearEnd) || other.yearEnd == yearEnd)&&(identical(other.displacementCc, displacementCc) || other.displacementCc == displacementCc)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.transmission, transmission) || other.transmission == transmission)&&(identical(other.volumetricEfficiency, volumetricEfficiency) || other.volumetricEfficiency == volumetricEfficiency)&&(identical(other.odometerPidStrategy, odometerPidStrategy) || other.odometerPidStrategy == odometerPidStrategy)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,make,model,generation,yearStart,yearEnd,displacementCc,fuelType,transmission,volumetricEfficiency,odometerPidStrategy,notes);

@override
String toString() {
  return 'ReferenceVehicle(make: $make, model: $model, generation: $generation, yearStart: $yearStart, yearEnd: $yearEnd, displacementCc: $displacementCc, fuelType: $fuelType, transmission: $transmission, volumetricEfficiency: $volumetricEfficiency, odometerPidStrategy: $odometerPidStrategy, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$ReferenceVehicleCopyWith<$Res> implements $ReferenceVehicleCopyWith<$Res> {
  factory _$ReferenceVehicleCopyWith(_ReferenceVehicle value, $Res Function(_ReferenceVehicle) _then) = __$ReferenceVehicleCopyWithImpl;
@override @useResult
$Res call({
 String make, String model, String generation, int yearStart, int? yearEnd, int displacementCc, String fuelType, String transmission, double volumetricEfficiency, String odometerPidStrategy, String? notes
});




}
/// @nodoc
class __$ReferenceVehicleCopyWithImpl<$Res>
    implements _$ReferenceVehicleCopyWith<$Res> {
  __$ReferenceVehicleCopyWithImpl(this._self, this._then);

  final _ReferenceVehicle _self;
  final $Res Function(_ReferenceVehicle) _then;

/// Create a copy of ReferenceVehicle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? make = null,Object? model = null,Object? generation = null,Object? yearStart = null,Object? yearEnd = freezed,Object? displacementCc = null,Object? fuelType = null,Object? transmission = null,Object? volumetricEfficiency = null,Object? odometerPidStrategy = null,Object? notes = freezed,}) {
  return _then(_ReferenceVehicle(
make: null == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,generation: null == generation ? _self.generation : generation // ignore: cast_nullable_to_non_nullable
as String,yearStart: null == yearStart ? _self.yearStart : yearStart // ignore: cast_nullable_to_non_nullable
as int,yearEnd: freezed == yearEnd ? _self.yearEnd : yearEnd // ignore: cast_nullable_to_non_nullable
as int?,displacementCc: null == displacementCc ? _self.displacementCc : displacementCc // ignore: cast_nullable_to_non_nullable
as int,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as String,transmission: null == transmission ? _self.transmission : transmission // ignore: cast_nullable_to_non_nullable
as String,volumetricEfficiency: null == volumetricEfficiency ? _self.volumetricEfficiency : volumetricEfficiency // ignore: cast_nullable_to_non_nullable
as double,odometerPidStrategy: null == odometerPidStrategy ? _self.odometerPidStrategy : odometerPidStrategy // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
