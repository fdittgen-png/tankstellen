// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChargingPreferences {

 int get minSocPercent; int get maxSocPercent; List<String> get preferredNetworks;
/// Create a copy of ChargingPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChargingPreferencesCopyWith<ChargingPreferences> get copyWith => _$ChargingPreferencesCopyWithImpl<ChargingPreferences>(this as ChargingPreferences, _$identity);

  /// Serializes this ChargingPreferences to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChargingPreferences&&(identical(other.minSocPercent, minSocPercent) || other.minSocPercent == minSocPercent)&&(identical(other.maxSocPercent, maxSocPercent) || other.maxSocPercent == maxSocPercent)&&const DeepCollectionEquality().equals(other.preferredNetworks, preferredNetworks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minSocPercent,maxSocPercent,const DeepCollectionEquality().hash(preferredNetworks));

@override
String toString() {
  return 'ChargingPreferences(minSocPercent: $minSocPercent, maxSocPercent: $maxSocPercent, preferredNetworks: $preferredNetworks)';
}


}

/// @nodoc
abstract mixin class $ChargingPreferencesCopyWith<$Res>  {
  factory $ChargingPreferencesCopyWith(ChargingPreferences value, $Res Function(ChargingPreferences) _then) = _$ChargingPreferencesCopyWithImpl;
@useResult
$Res call({
 int minSocPercent, int maxSocPercent, List<String> preferredNetworks
});




}
/// @nodoc
class _$ChargingPreferencesCopyWithImpl<$Res>
    implements $ChargingPreferencesCopyWith<$Res> {
  _$ChargingPreferencesCopyWithImpl(this._self, this._then);

  final ChargingPreferences _self;
  final $Res Function(ChargingPreferences) _then;

/// Create a copy of ChargingPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minSocPercent = null,Object? maxSocPercent = null,Object? preferredNetworks = null,}) {
  return _then(_self.copyWith(
minSocPercent: null == minSocPercent ? _self.minSocPercent : minSocPercent // ignore: cast_nullable_to_non_nullable
as int,maxSocPercent: null == maxSocPercent ? _self.maxSocPercent : maxSocPercent // ignore: cast_nullable_to_non_nullable
as int,preferredNetworks: null == preferredNetworks ? _self.preferredNetworks : preferredNetworks // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChargingPreferences].
extension ChargingPreferencesPatterns on ChargingPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChargingPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChargingPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChargingPreferences value)  $default,){
final _that = this;
switch (_that) {
case _ChargingPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChargingPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _ChargingPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int minSocPercent,  int maxSocPercent,  List<String> preferredNetworks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChargingPreferences() when $default != null:
return $default(_that.minSocPercent,_that.maxSocPercent,_that.preferredNetworks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int minSocPercent,  int maxSocPercent,  List<String> preferredNetworks)  $default,) {final _that = this;
switch (_that) {
case _ChargingPreferences():
return $default(_that.minSocPercent,_that.maxSocPercent,_that.preferredNetworks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int minSocPercent,  int maxSocPercent,  List<String> preferredNetworks)?  $default,) {final _that = this;
switch (_that) {
case _ChargingPreferences() when $default != null:
return $default(_that.minSocPercent,_that.maxSocPercent,_that.preferredNetworks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChargingPreferences implements ChargingPreferences {
  const _ChargingPreferences({this.minSocPercent = 20, this.maxSocPercent = 80, final  List<String> preferredNetworks = const <String>[]}): _preferredNetworks = preferredNetworks;
  factory _ChargingPreferences.fromJson(Map<String, dynamic> json) => _$ChargingPreferencesFromJson(json);

@override@JsonKey() final  int minSocPercent;
@override@JsonKey() final  int maxSocPercent;
 final  List<String> _preferredNetworks;
@override@JsonKey() List<String> get preferredNetworks {
  if (_preferredNetworks is EqualUnmodifiableListView) return _preferredNetworks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preferredNetworks);
}


/// Create a copy of ChargingPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChargingPreferencesCopyWith<_ChargingPreferences> get copyWith => __$ChargingPreferencesCopyWithImpl<_ChargingPreferences>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChargingPreferencesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChargingPreferences&&(identical(other.minSocPercent, minSocPercent) || other.minSocPercent == minSocPercent)&&(identical(other.maxSocPercent, maxSocPercent) || other.maxSocPercent == maxSocPercent)&&const DeepCollectionEquality().equals(other._preferredNetworks, _preferredNetworks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minSocPercent,maxSocPercent,const DeepCollectionEquality().hash(_preferredNetworks));

@override
String toString() {
  return 'ChargingPreferences(minSocPercent: $minSocPercent, maxSocPercent: $maxSocPercent, preferredNetworks: $preferredNetworks)';
}


}

/// @nodoc
abstract mixin class _$ChargingPreferencesCopyWith<$Res> implements $ChargingPreferencesCopyWith<$Res> {
  factory _$ChargingPreferencesCopyWith(_ChargingPreferences value, $Res Function(_ChargingPreferences) _then) = __$ChargingPreferencesCopyWithImpl;
@override @useResult
$Res call({
 int minSocPercent, int maxSocPercent, List<String> preferredNetworks
});




}
/// @nodoc
class __$ChargingPreferencesCopyWithImpl<$Res>
    implements _$ChargingPreferencesCopyWith<$Res> {
  __$ChargingPreferencesCopyWithImpl(this._self, this._then);

  final _ChargingPreferences _self;
  final $Res Function(_ChargingPreferences) _then;

/// Create a copy of ChargingPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minSocPercent = null,Object? maxSocPercent = null,Object? preferredNetworks = null,}) {
  return _then(_ChargingPreferences(
minSocPercent: null == minSocPercent ? _self.minSocPercent : minSocPercent // ignore: cast_nullable_to_non_nullable
as int,maxSocPercent: null == maxSocPercent ? _self.maxSocPercent : maxSocPercent // ignore: cast_nullable_to_non_nullable
as int,preferredNetworks: null == preferredNetworks ? _self._preferredNetworks : preferredNetworks // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$VehicleProfile {

 String get id; String get name;@VehicleTypeJsonConverter() VehicleType get type;// EV fields
 double? get batteryKwh; double? get maxChargingKw;@ConnectorTypeSetConverter() Set<ConnectorType> get supportedConnectors;@ChargingPreferencesJsonConverter() ChargingPreferences get chargingPreferences;// Combustion fields
 double? get tankCapacityL; String? get preferredFuelType;// Engine parameters for the speed-density fuel-rate fallback
// (#812). Only populated when the VIN decoder or the user's
// manual onboarding entry provides them. `readFuelRateLPerHour`
// on a vehicle without these falls back to its generic 1.0 L /
// η_v 0.85 defaults — still better than the NO DATA blanks the
// Peugeot 107 class was producing before #810.
//
//   engineDisplacementCc: total swept volume in cubic
//     centimetres (e.g. 998 for a 1.0 L 1KR-FE). Null when
//     unknown — the math falls back to 1000 cc.
//   engineCylinders: used by future features (firing-event-
//     based fuel estimation, engine-stress indicators). No
//     default — null is honest.
//   volumetricEfficiency: 0.60–0.95 range. Default 0.85 is
//     reasonable for a typical NA petrol engine at cruise.
//     Adaptive calibration (#815) narrows this per vehicle
//     from tankful reconciliation — see [VeLearner].
//   volumetricEfficiencySamples: EWMA sample counter for η_v
//     (#815). 0 at first fill-up; bumps by 1 every time the
//     reconciliation pipeline accepts a pumped/integrated pair.
//     Used for debugging and UX — e.g. "calibrated from 3
//     tankfuls" — and as a future ramp for the EWMA alpha if
//     the fixed 0.3 blend ever needs to soften during early
//     samples.
 int? get engineDisplacementCc; int? get engineCylinders; double get volumetricEfficiency; int get volumetricEfficiencySamples;// Curb weight in kilograms (#812). Populated by the VIN decoder
// phase 2 onboarding flow (GVWR-minus-payload on the NHTSA side,
// or manufacturer spec sheets via a future secondary lookup).
// Null means "unknown" — consumers like the rolling-resistance
// estimator fall back to a 1500 kg reference, so the field being
// null is not fatal.
 int? get curbWeightKg;// OBD2 adapter pairing (#784). Persisted so the app can
// transparently reconnect on launch without prompting the user
// again. Both fields are nullable — unpaired vehicles carry
// null. The MAC is the stable key; the name is the label shown
// to the user ("vLinker FS").
 String? get obd2AdapterMac; String? get obd2AdapterName;// Vehicle Identification Number (#812 phase 2). Optional — the
// VIN decoder may pre-fill engine fields when present, and the
// value is persisted so a subsequent edit still shows what the
// user entered. No format validation at the model level — the
// UI rejects clearly-invalid input via the decoder, but users
// should be free to save a stub profile with a partial VIN.
 String? get vin;
/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleProfileCopyWith<VehicleProfile> get copyWith => _$VehicleProfileCopyWithImpl<VehicleProfile>(this as VehicleProfile, _$identity);

  /// Serializes this VehicleProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.batteryKwh, batteryKwh) || other.batteryKwh == batteryKwh)&&(identical(other.maxChargingKw, maxChargingKw) || other.maxChargingKw == maxChargingKw)&&const DeepCollectionEquality().equals(other.supportedConnectors, supportedConnectors)&&(identical(other.chargingPreferences, chargingPreferences) || other.chargingPreferences == chargingPreferences)&&(identical(other.tankCapacityL, tankCapacityL) || other.tankCapacityL == tankCapacityL)&&(identical(other.preferredFuelType, preferredFuelType) || other.preferredFuelType == preferredFuelType)&&(identical(other.engineDisplacementCc, engineDisplacementCc) || other.engineDisplacementCc == engineDisplacementCc)&&(identical(other.engineCylinders, engineCylinders) || other.engineCylinders == engineCylinders)&&(identical(other.volumetricEfficiency, volumetricEfficiency) || other.volumetricEfficiency == volumetricEfficiency)&&(identical(other.volumetricEfficiencySamples, volumetricEfficiencySamples) || other.volumetricEfficiencySamples == volumetricEfficiencySamples)&&(identical(other.curbWeightKg, curbWeightKg) || other.curbWeightKg == curbWeightKg)&&(identical(other.obd2AdapterMac, obd2AdapterMac) || other.obd2AdapterMac == obd2AdapterMac)&&(identical(other.obd2AdapterName, obd2AdapterName) || other.obd2AdapterName == obd2AdapterName)&&(identical(other.vin, vin) || other.vin == vin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,batteryKwh,maxChargingKw,const DeepCollectionEquality().hash(supportedConnectors),chargingPreferences,tankCapacityL,preferredFuelType,engineDisplacementCc,engineCylinders,volumetricEfficiency,volumetricEfficiencySamples,curbWeightKg,obd2AdapterMac,obd2AdapterName,vin);

@override
String toString() {
  return 'VehicleProfile(id: $id, name: $name, type: $type, batteryKwh: $batteryKwh, maxChargingKw: $maxChargingKw, supportedConnectors: $supportedConnectors, chargingPreferences: $chargingPreferences, tankCapacityL: $tankCapacityL, preferredFuelType: $preferredFuelType, engineDisplacementCc: $engineDisplacementCc, engineCylinders: $engineCylinders, volumetricEfficiency: $volumetricEfficiency, volumetricEfficiencySamples: $volumetricEfficiencySamples, curbWeightKg: $curbWeightKg, obd2AdapterMac: $obd2AdapterMac, obd2AdapterName: $obd2AdapterName, vin: $vin)';
}


}

/// @nodoc
abstract mixin class $VehicleProfileCopyWith<$Res>  {
  factory $VehicleProfileCopyWith(VehicleProfile value, $Res Function(VehicleProfile) _then) = _$VehicleProfileCopyWithImpl;
@useResult
$Res call({
 String id, String name,@VehicleTypeJsonConverter() VehicleType type, double? batteryKwh, double? maxChargingKw,@ConnectorTypeSetConverter() Set<ConnectorType> supportedConnectors,@ChargingPreferencesJsonConverter() ChargingPreferences chargingPreferences, double? tankCapacityL, String? preferredFuelType, int? engineDisplacementCc, int? engineCylinders, double volumetricEfficiency, int volumetricEfficiencySamples, int? curbWeightKg, String? obd2AdapterMac, String? obd2AdapterName, String? vin
});


$ChargingPreferencesCopyWith<$Res> get chargingPreferences;

}
/// @nodoc
class _$VehicleProfileCopyWithImpl<$Res>
    implements $VehicleProfileCopyWith<$Res> {
  _$VehicleProfileCopyWithImpl(this._self, this._then);

  final VehicleProfile _self;
  final $Res Function(VehicleProfile) _then;

/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? batteryKwh = freezed,Object? maxChargingKw = freezed,Object? supportedConnectors = null,Object? chargingPreferences = null,Object? tankCapacityL = freezed,Object? preferredFuelType = freezed,Object? engineDisplacementCc = freezed,Object? engineCylinders = freezed,Object? volumetricEfficiency = null,Object? volumetricEfficiencySamples = null,Object? curbWeightKg = freezed,Object? obd2AdapterMac = freezed,Object? obd2AdapterName = freezed,Object? vin = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as VehicleType,batteryKwh: freezed == batteryKwh ? _self.batteryKwh : batteryKwh // ignore: cast_nullable_to_non_nullable
as double?,maxChargingKw: freezed == maxChargingKw ? _self.maxChargingKw : maxChargingKw // ignore: cast_nullable_to_non_nullable
as double?,supportedConnectors: null == supportedConnectors ? _self.supportedConnectors : supportedConnectors // ignore: cast_nullable_to_non_nullable
as Set<ConnectorType>,chargingPreferences: null == chargingPreferences ? _self.chargingPreferences : chargingPreferences // ignore: cast_nullable_to_non_nullable
as ChargingPreferences,tankCapacityL: freezed == tankCapacityL ? _self.tankCapacityL : tankCapacityL // ignore: cast_nullable_to_non_nullable
as double?,preferredFuelType: freezed == preferredFuelType ? _self.preferredFuelType : preferredFuelType // ignore: cast_nullable_to_non_nullable
as String?,engineDisplacementCc: freezed == engineDisplacementCc ? _self.engineDisplacementCc : engineDisplacementCc // ignore: cast_nullable_to_non_nullable
as int?,engineCylinders: freezed == engineCylinders ? _self.engineCylinders : engineCylinders // ignore: cast_nullable_to_non_nullable
as int?,volumetricEfficiency: null == volumetricEfficiency ? _self.volumetricEfficiency : volumetricEfficiency // ignore: cast_nullable_to_non_nullable
as double,volumetricEfficiencySamples: null == volumetricEfficiencySamples ? _self.volumetricEfficiencySamples : volumetricEfficiencySamples // ignore: cast_nullable_to_non_nullable
as int,curbWeightKg: freezed == curbWeightKg ? _self.curbWeightKg : curbWeightKg // ignore: cast_nullable_to_non_nullable
as int?,obd2AdapterMac: freezed == obd2AdapterMac ? _self.obd2AdapterMac : obd2AdapterMac // ignore: cast_nullable_to_non_nullable
as String?,obd2AdapterName: freezed == obd2AdapterName ? _self.obd2AdapterName : obd2AdapterName // ignore: cast_nullable_to_non_nullable
as String?,vin: freezed == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChargingPreferencesCopyWith<$Res> get chargingPreferences {
  
  return $ChargingPreferencesCopyWith<$Res>(_self.chargingPreferences, (value) {
    return _then(_self.copyWith(chargingPreferences: value));
  });
}
}


/// Adds pattern-matching-related methods to [VehicleProfile].
extension VehicleProfilePatterns on VehicleProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehicleProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehicleProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehicleProfile value)  $default,){
final _that = this;
switch (_that) {
case _VehicleProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehicleProfile value)?  $default,){
final _that = this;
switch (_that) {
case _VehicleProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @VehicleTypeJsonConverter()  VehicleType type,  double? batteryKwh,  double? maxChargingKw, @ConnectorTypeSetConverter()  Set<ConnectorType> supportedConnectors, @ChargingPreferencesJsonConverter()  ChargingPreferences chargingPreferences,  double? tankCapacityL,  String? preferredFuelType,  int? engineDisplacementCc,  int? engineCylinders,  double volumetricEfficiency,  int volumetricEfficiencySamples,  int? curbWeightKg,  String? obd2AdapterMac,  String? obd2AdapterName,  String? vin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleProfile() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.batteryKwh,_that.maxChargingKw,_that.supportedConnectors,_that.chargingPreferences,_that.tankCapacityL,_that.preferredFuelType,_that.engineDisplacementCc,_that.engineCylinders,_that.volumetricEfficiency,_that.volumetricEfficiencySamples,_that.curbWeightKg,_that.obd2AdapterMac,_that.obd2AdapterName,_that.vin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @VehicleTypeJsonConverter()  VehicleType type,  double? batteryKwh,  double? maxChargingKw, @ConnectorTypeSetConverter()  Set<ConnectorType> supportedConnectors, @ChargingPreferencesJsonConverter()  ChargingPreferences chargingPreferences,  double? tankCapacityL,  String? preferredFuelType,  int? engineDisplacementCc,  int? engineCylinders,  double volumetricEfficiency,  int volumetricEfficiencySamples,  int? curbWeightKg,  String? obd2AdapterMac,  String? obd2AdapterName,  String? vin)  $default,) {final _that = this;
switch (_that) {
case _VehicleProfile():
return $default(_that.id,_that.name,_that.type,_that.batteryKwh,_that.maxChargingKw,_that.supportedConnectors,_that.chargingPreferences,_that.tankCapacityL,_that.preferredFuelType,_that.engineDisplacementCc,_that.engineCylinders,_that.volumetricEfficiency,_that.volumetricEfficiencySamples,_that.curbWeightKg,_that.obd2AdapterMac,_that.obd2AdapterName,_that.vin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @VehicleTypeJsonConverter()  VehicleType type,  double? batteryKwh,  double? maxChargingKw, @ConnectorTypeSetConverter()  Set<ConnectorType> supportedConnectors, @ChargingPreferencesJsonConverter()  ChargingPreferences chargingPreferences,  double? tankCapacityL,  String? preferredFuelType,  int? engineDisplacementCc,  int? engineCylinders,  double volumetricEfficiency,  int volumetricEfficiencySamples,  int? curbWeightKg,  String? obd2AdapterMac,  String? obd2AdapterName,  String? vin)?  $default,) {final _that = this;
switch (_that) {
case _VehicleProfile() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.batteryKwh,_that.maxChargingKw,_that.supportedConnectors,_that.chargingPreferences,_that.tankCapacityL,_that.preferredFuelType,_that.engineDisplacementCc,_that.engineCylinders,_that.volumetricEfficiency,_that.volumetricEfficiencySamples,_that.curbWeightKg,_that.obd2AdapterMac,_that.obd2AdapterName,_that.vin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehicleProfile extends VehicleProfile {
  const _VehicleProfile({required this.id, required this.name, @VehicleTypeJsonConverter() this.type = VehicleType.combustion, this.batteryKwh, this.maxChargingKw, @ConnectorTypeSetConverter() final  Set<ConnectorType> supportedConnectors = const <ConnectorType>{}, @ChargingPreferencesJsonConverter() this.chargingPreferences = const ChargingPreferences(), this.tankCapacityL, this.preferredFuelType, this.engineDisplacementCc, this.engineCylinders, this.volumetricEfficiency = 0.85, this.volumetricEfficiencySamples = 0, this.curbWeightKg, this.obd2AdapterMac, this.obd2AdapterName, this.vin}): _supportedConnectors = supportedConnectors,super._();
  factory _VehicleProfile.fromJson(Map<String, dynamic> json) => _$VehicleProfileFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey()@VehicleTypeJsonConverter() final  VehicleType type;
// EV fields
@override final  double? batteryKwh;
@override final  double? maxChargingKw;
 final  Set<ConnectorType> _supportedConnectors;
@override@JsonKey()@ConnectorTypeSetConverter() Set<ConnectorType> get supportedConnectors {
  if (_supportedConnectors is EqualUnmodifiableSetView) return _supportedConnectors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_supportedConnectors);
}

@override@JsonKey()@ChargingPreferencesJsonConverter() final  ChargingPreferences chargingPreferences;
// Combustion fields
@override final  double? tankCapacityL;
@override final  String? preferredFuelType;
// Engine parameters for the speed-density fuel-rate fallback
// (#812). Only populated when the VIN decoder or the user's
// manual onboarding entry provides them. `readFuelRateLPerHour`
// on a vehicle without these falls back to its generic 1.0 L /
// η_v 0.85 defaults — still better than the NO DATA blanks the
// Peugeot 107 class was producing before #810.
//
//   engineDisplacementCc: total swept volume in cubic
//     centimetres (e.g. 998 for a 1.0 L 1KR-FE). Null when
//     unknown — the math falls back to 1000 cc.
//   engineCylinders: used by future features (firing-event-
//     based fuel estimation, engine-stress indicators). No
//     default — null is honest.
//   volumetricEfficiency: 0.60–0.95 range. Default 0.85 is
//     reasonable for a typical NA petrol engine at cruise.
//     Adaptive calibration (#815) narrows this per vehicle
//     from tankful reconciliation — see [VeLearner].
//   volumetricEfficiencySamples: EWMA sample counter for η_v
//     (#815). 0 at first fill-up; bumps by 1 every time the
//     reconciliation pipeline accepts a pumped/integrated pair.
//     Used for debugging and UX — e.g. "calibrated from 3
//     tankfuls" — and as a future ramp for the EWMA alpha if
//     the fixed 0.3 blend ever needs to soften during early
//     samples.
@override final  int? engineDisplacementCc;
@override final  int? engineCylinders;
@override@JsonKey() final  double volumetricEfficiency;
@override@JsonKey() final  int volumetricEfficiencySamples;
// Curb weight in kilograms (#812). Populated by the VIN decoder
// phase 2 onboarding flow (GVWR-minus-payload on the NHTSA side,
// or manufacturer spec sheets via a future secondary lookup).
// Null means "unknown" — consumers like the rolling-resistance
// estimator fall back to a 1500 kg reference, so the field being
// null is not fatal.
@override final  int? curbWeightKg;
// OBD2 adapter pairing (#784). Persisted so the app can
// transparently reconnect on launch without prompting the user
// again. Both fields are nullable — unpaired vehicles carry
// null. The MAC is the stable key; the name is the label shown
// to the user ("vLinker FS").
@override final  String? obd2AdapterMac;
@override final  String? obd2AdapterName;
// Vehicle Identification Number (#812 phase 2). Optional — the
// VIN decoder may pre-fill engine fields when present, and the
// value is persisted so a subsequent edit still shows what the
// user entered. No format validation at the model level — the
// UI rejects clearly-invalid input via the decoder, but users
// should be free to save a stub profile with a partial VIN.
@override final  String? vin;

/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleProfileCopyWith<_VehicleProfile> get copyWith => __$VehicleProfileCopyWithImpl<_VehicleProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.batteryKwh, batteryKwh) || other.batteryKwh == batteryKwh)&&(identical(other.maxChargingKw, maxChargingKw) || other.maxChargingKw == maxChargingKw)&&const DeepCollectionEquality().equals(other._supportedConnectors, _supportedConnectors)&&(identical(other.chargingPreferences, chargingPreferences) || other.chargingPreferences == chargingPreferences)&&(identical(other.tankCapacityL, tankCapacityL) || other.tankCapacityL == tankCapacityL)&&(identical(other.preferredFuelType, preferredFuelType) || other.preferredFuelType == preferredFuelType)&&(identical(other.engineDisplacementCc, engineDisplacementCc) || other.engineDisplacementCc == engineDisplacementCc)&&(identical(other.engineCylinders, engineCylinders) || other.engineCylinders == engineCylinders)&&(identical(other.volumetricEfficiency, volumetricEfficiency) || other.volumetricEfficiency == volumetricEfficiency)&&(identical(other.volumetricEfficiencySamples, volumetricEfficiencySamples) || other.volumetricEfficiencySamples == volumetricEfficiencySamples)&&(identical(other.curbWeightKg, curbWeightKg) || other.curbWeightKg == curbWeightKg)&&(identical(other.obd2AdapterMac, obd2AdapterMac) || other.obd2AdapterMac == obd2AdapterMac)&&(identical(other.obd2AdapterName, obd2AdapterName) || other.obd2AdapterName == obd2AdapterName)&&(identical(other.vin, vin) || other.vin == vin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,batteryKwh,maxChargingKw,const DeepCollectionEquality().hash(_supportedConnectors),chargingPreferences,tankCapacityL,preferredFuelType,engineDisplacementCc,engineCylinders,volumetricEfficiency,volumetricEfficiencySamples,curbWeightKg,obd2AdapterMac,obd2AdapterName,vin);

@override
String toString() {
  return 'VehicleProfile(id: $id, name: $name, type: $type, batteryKwh: $batteryKwh, maxChargingKw: $maxChargingKw, supportedConnectors: $supportedConnectors, chargingPreferences: $chargingPreferences, tankCapacityL: $tankCapacityL, preferredFuelType: $preferredFuelType, engineDisplacementCc: $engineDisplacementCc, engineCylinders: $engineCylinders, volumetricEfficiency: $volumetricEfficiency, volumetricEfficiencySamples: $volumetricEfficiencySamples, curbWeightKg: $curbWeightKg, obd2AdapterMac: $obd2AdapterMac, obd2AdapterName: $obd2AdapterName, vin: $vin)';
}


}

/// @nodoc
abstract mixin class _$VehicleProfileCopyWith<$Res> implements $VehicleProfileCopyWith<$Res> {
  factory _$VehicleProfileCopyWith(_VehicleProfile value, $Res Function(_VehicleProfile) _then) = __$VehicleProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@VehicleTypeJsonConverter() VehicleType type, double? batteryKwh, double? maxChargingKw,@ConnectorTypeSetConverter() Set<ConnectorType> supportedConnectors,@ChargingPreferencesJsonConverter() ChargingPreferences chargingPreferences, double? tankCapacityL, String? preferredFuelType, int? engineDisplacementCc, int? engineCylinders, double volumetricEfficiency, int volumetricEfficiencySamples, int? curbWeightKg, String? obd2AdapterMac, String? obd2AdapterName, String? vin
});


@override $ChargingPreferencesCopyWith<$Res> get chargingPreferences;

}
/// @nodoc
class __$VehicleProfileCopyWithImpl<$Res>
    implements _$VehicleProfileCopyWith<$Res> {
  __$VehicleProfileCopyWithImpl(this._self, this._then);

  final _VehicleProfile _self;
  final $Res Function(_VehicleProfile) _then;

/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? batteryKwh = freezed,Object? maxChargingKw = freezed,Object? supportedConnectors = null,Object? chargingPreferences = null,Object? tankCapacityL = freezed,Object? preferredFuelType = freezed,Object? engineDisplacementCc = freezed,Object? engineCylinders = freezed,Object? volumetricEfficiency = null,Object? volumetricEfficiencySamples = null,Object? curbWeightKg = freezed,Object? obd2AdapterMac = freezed,Object? obd2AdapterName = freezed,Object? vin = freezed,}) {
  return _then(_VehicleProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as VehicleType,batteryKwh: freezed == batteryKwh ? _self.batteryKwh : batteryKwh // ignore: cast_nullable_to_non_nullable
as double?,maxChargingKw: freezed == maxChargingKw ? _self.maxChargingKw : maxChargingKw // ignore: cast_nullable_to_non_nullable
as double?,supportedConnectors: null == supportedConnectors ? _self._supportedConnectors : supportedConnectors // ignore: cast_nullable_to_non_nullable
as Set<ConnectorType>,chargingPreferences: null == chargingPreferences ? _self.chargingPreferences : chargingPreferences // ignore: cast_nullable_to_non_nullable
as ChargingPreferences,tankCapacityL: freezed == tankCapacityL ? _self.tankCapacityL : tankCapacityL // ignore: cast_nullable_to_non_nullable
as double?,preferredFuelType: freezed == preferredFuelType ? _self.preferredFuelType : preferredFuelType // ignore: cast_nullable_to_non_nullable
as String?,engineDisplacementCc: freezed == engineDisplacementCc ? _self.engineDisplacementCc : engineDisplacementCc // ignore: cast_nullable_to_non_nullable
as int?,engineCylinders: freezed == engineCylinders ? _self.engineCylinders : engineCylinders // ignore: cast_nullable_to_non_nullable
as int?,volumetricEfficiency: null == volumetricEfficiency ? _self.volumetricEfficiency : volumetricEfficiency // ignore: cast_nullable_to_non_nullable
as double,volumetricEfficiencySamples: null == volumetricEfficiencySamples ? _self.volumetricEfficiencySamples : volumetricEfficiencySamples // ignore: cast_nullable_to_non_nullable
as int,curbWeightKg: freezed == curbWeightKg ? _self.curbWeightKg : curbWeightKg // ignore: cast_nullable_to_non_nullable
as int?,obd2AdapterMac: freezed == obd2AdapterMac ? _self.obd2AdapterMac : obd2AdapterMac // ignore: cast_nullable_to_non_nullable
as String?,obd2AdapterName: freezed == obd2AdapterName ? _self.obd2AdapterName : obd2AdapterName // ignore: cast_nullable_to_non_nullable
as String?,vin: freezed == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChargingPreferencesCopyWith<$Res> get chargingPreferences {
  
  return $ChargingPreferencesCopyWith<$Res>(_self.chargingPreferences, (value) {
    return _then(_self.copyWith(chargingPreferences: value));
  });
}
}

// dart format on
