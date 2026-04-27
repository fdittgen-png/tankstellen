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
 String? get vin;// Baseline calibration mode (#894). `rule` keeps the original
// winner-take-all classifier from #779; `fuzzy` re-weights each
// sample across all situations via [FuzzyClassifier]. Default
// stays on `rule` so existing profiles deserialize without a
// migration — users opt in from the vehicle edit screen.
@VehicleCalibrationModeJsonConverter() VehicleCalibrationMode get calibrationMode;// Hands-free auto-record configuration (#1004 phase 1). All
// fields default to "off" or to safe values so pre-#1004 Hive
// profiles deserialize cleanly via freezed's `@Default`. Phases
// 2-6 layer the background service, movement-detection,
// disconnect-save, badge counter and UI on top of these fields
// — phase 1 ships the data layer only.
//
//   autoRecord: master toggle. Off by default — every user must
//     opt in explicitly from the vehicle edit screen.
//   pairedAdapterMac: MAC address of the ELM327 adapter that
//     belongs to this vehicle. Distinct from
//     [obd2AdapterMac] (the "currently connected" adapter from
//     #784 / #816); pairedAdapterMac is the long-lived "this
//     adapter belongs to this car" marker that the BLE auto-
//     connect listener watches for. Null when the user hasn't
//     paired one yet.
//   movementStartThresholdKmh: speed (OBD2 PID 0x0D OR phone
//     GPS, whichever fires first) above which auto-record fires
//     `startTrip()`. Default 5 km/h — low enough to catch
//     pulling out of a parking spot, high enough to ignore the
//     adapter waking up while the car is stationary.
//   disconnectSaveDelaySec: debounce window in seconds before a
//     BT disconnect triggers `stopAndSave`. Default 60 s — long
//     enough to absorb a tunnel or a parking-garage lift, short
//     enough that the user sees a saved trip when they walk
//     into the kitchen.
//   backgroundLocationConsent: separate from runtime location
//     permission — this is the user's stored answer to "may we
//     record GPS while the screen is off?" Without it, the
//     auto-flow runs BT-only and skips GPS-based trip metadata.
 bool get autoRecord; String? get pairedAdapterMac; double get movementStartThresholdKmh; int get disconnectSaveDelaySec; bool get backgroundLocationConsent;// Reference catalog identification (#950 phase 4). Optional fields
// populated during onboarding (VIN decoder pre-fill or manual user
// entry) so the migrator and the OBD-II layer can resolve the
// vehicle to a [ReferenceVehicle]. All three default to null so
// pre-#950 profiles deserialize without losing data — the migrator
// fills them in on first launch.
//
//   make: marketing brand name, e.g. "Peugeot", "Renault".
//   model: model name as marketed in Europe, e.g. "208", "Clio".
//   year: model year (4-digit), used to disambiguate generations.
//   referenceVehicleId: slug of the matching catalog entry, e.g.
//     "peugeot-208-ii-2019-". Format is `<make>-<model>-<generation>`
//     lowercased with non-alphanumerics collapsed to dashes. The
//     consumer side (obd2_service) resolves the slug back to a
//     [ReferenceVehicle] via the catalog provider.
 String? get make; String? get model; int? get year; String? get referenceVehicleId;// Rolling per-vehicle driving aggregates (#1193 phase 1). All four
// fields are nullable; they remain null until the first trip
// aggregator pass writes them, and a null bucket entry inside the
// populated [TripLengthBreakdown] / [SpeedConsumptionHistogram]
// means the vehicle has trips overall but not yet enough in that
// specific bucket to clear the per-bucket min-sample threshold.
//
// The phase-1 PR ships these storage fields and the value-object
// schemas only — the aggregator service that fills them lives in
// `lib/features/vehicle/data/vehicle_aggregate_updater.dart`
// (#1193 phase 2), and the vehicle-profile UI section that reads
// them lives in the edit/view screens (#1193 phase 3).
//
//   tripLengthAggregates:    short / medium / long bucket stats.
//   speedConsumptionAggregates: per-speed-band L/100 km histogram.
//   aggregatesUpdatedAt:     wall-clock time of the last refresh.
//   aggregatesTripCount:     # trips folded into the current pass
//                            (used by the UI to gate the section
//                            below a min-trips threshold).
 TripLengthBreakdown? get tripLengthAggregates; SpeedConsumptionHistogram? get speedConsumptionAggregates; DateTime? get aggregatesUpdatedAt; int? get aggregatesTripCount;
/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleProfileCopyWith<VehicleProfile> get copyWith => _$VehicleProfileCopyWithImpl<VehicleProfile>(this as VehicleProfile, _$identity);

  /// Serializes this VehicleProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.batteryKwh, batteryKwh) || other.batteryKwh == batteryKwh)&&(identical(other.maxChargingKw, maxChargingKw) || other.maxChargingKw == maxChargingKw)&&const DeepCollectionEquality().equals(other.supportedConnectors, supportedConnectors)&&(identical(other.chargingPreferences, chargingPreferences) || other.chargingPreferences == chargingPreferences)&&(identical(other.tankCapacityL, tankCapacityL) || other.tankCapacityL == tankCapacityL)&&(identical(other.preferredFuelType, preferredFuelType) || other.preferredFuelType == preferredFuelType)&&(identical(other.engineDisplacementCc, engineDisplacementCc) || other.engineDisplacementCc == engineDisplacementCc)&&(identical(other.engineCylinders, engineCylinders) || other.engineCylinders == engineCylinders)&&(identical(other.volumetricEfficiency, volumetricEfficiency) || other.volumetricEfficiency == volumetricEfficiency)&&(identical(other.volumetricEfficiencySamples, volumetricEfficiencySamples) || other.volumetricEfficiencySamples == volumetricEfficiencySamples)&&(identical(other.curbWeightKg, curbWeightKg) || other.curbWeightKg == curbWeightKg)&&(identical(other.obd2AdapterMac, obd2AdapterMac) || other.obd2AdapterMac == obd2AdapterMac)&&(identical(other.obd2AdapterName, obd2AdapterName) || other.obd2AdapterName == obd2AdapterName)&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.calibrationMode, calibrationMode) || other.calibrationMode == calibrationMode)&&(identical(other.autoRecord, autoRecord) || other.autoRecord == autoRecord)&&(identical(other.pairedAdapterMac, pairedAdapterMac) || other.pairedAdapterMac == pairedAdapterMac)&&(identical(other.movementStartThresholdKmh, movementStartThresholdKmh) || other.movementStartThresholdKmh == movementStartThresholdKmh)&&(identical(other.disconnectSaveDelaySec, disconnectSaveDelaySec) || other.disconnectSaveDelaySec == disconnectSaveDelaySec)&&(identical(other.backgroundLocationConsent, backgroundLocationConsent) || other.backgroundLocationConsent == backgroundLocationConsent)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year)&&(identical(other.referenceVehicleId, referenceVehicleId) || other.referenceVehicleId == referenceVehicleId)&&(identical(other.tripLengthAggregates, tripLengthAggregates) || other.tripLengthAggregates == tripLengthAggregates)&&(identical(other.speedConsumptionAggregates, speedConsumptionAggregates) || other.speedConsumptionAggregates == speedConsumptionAggregates)&&(identical(other.aggregatesUpdatedAt, aggregatesUpdatedAt) || other.aggregatesUpdatedAt == aggregatesUpdatedAt)&&(identical(other.aggregatesTripCount, aggregatesTripCount) || other.aggregatesTripCount == aggregatesTripCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,type,batteryKwh,maxChargingKw,const DeepCollectionEquality().hash(supportedConnectors),chargingPreferences,tankCapacityL,preferredFuelType,engineDisplacementCc,engineCylinders,volumetricEfficiency,volumetricEfficiencySamples,curbWeightKg,obd2AdapterMac,obd2AdapterName,vin,calibrationMode,autoRecord,pairedAdapterMac,movementStartThresholdKmh,disconnectSaveDelaySec,backgroundLocationConsent,make,model,year,referenceVehicleId,tripLengthAggregates,speedConsumptionAggregates,aggregatesUpdatedAt,aggregatesTripCount]);

@override
String toString() {
  return 'VehicleProfile(id: $id, name: $name, type: $type, batteryKwh: $batteryKwh, maxChargingKw: $maxChargingKw, supportedConnectors: $supportedConnectors, chargingPreferences: $chargingPreferences, tankCapacityL: $tankCapacityL, preferredFuelType: $preferredFuelType, engineDisplacementCc: $engineDisplacementCc, engineCylinders: $engineCylinders, volumetricEfficiency: $volumetricEfficiency, volumetricEfficiencySamples: $volumetricEfficiencySamples, curbWeightKg: $curbWeightKg, obd2AdapterMac: $obd2AdapterMac, obd2AdapterName: $obd2AdapterName, vin: $vin, calibrationMode: $calibrationMode, autoRecord: $autoRecord, pairedAdapterMac: $pairedAdapterMac, movementStartThresholdKmh: $movementStartThresholdKmh, disconnectSaveDelaySec: $disconnectSaveDelaySec, backgroundLocationConsent: $backgroundLocationConsent, make: $make, model: $model, year: $year, referenceVehicleId: $referenceVehicleId, tripLengthAggregates: $tripLengthAggregates, speedConsumptionAggregates: $speedConsumptionAggregates, aggregatesUpdatedAt: $aggregatesUpdatedAt, aggregatesTripCount: $aggregatesTripCount)';
}


}

/// @nodoc
abstract mixin class $VehicleProfileCopyWith<$Res>  {
  factory $VehicleProfileCopyWith(VehicleProfile value, $Res Function(VehicleProfile) _then) = _$VehicleProfileCopyWithImpl;
@useResult
$Res call({
 String id, String name,@VehicleTypeJsonConverter() VehicleType type, double? batteryKwh, double? maxChargingKw,@ConnectorTypeSetConverter() Set<ConnectorType> supportedConnectors,@ChargingPreferencesJsonConverter() ChargingPreferences chargingPreferences, double? tankCapacityL, String? preferredFuelType, int? engineDisplacementCc, int? engineCylinders, double volumetricEfficiency, int volumetricEfficiencySamples, int? curbWeightKg, String? obd2AdapterMac, String? obd2AdapterName, String? vin,@VehicleCalibrationModeJsonConverter() VehicleCalibrationMode calibrationMode, bool autoRecord, String? pairedAdapterMac, double movementStartThresholdKmh, int disconnectSaveDelaySec, bool backgroundLocationConsent, String? make, String? model, int? year, String? referenceVehicleId, TripLengthBreakdown? tripLengthAggregates, SpeedConsumptionHistogram? speedConsumptionAggregates, DateTime? aggregatesUpdatedAt, int? aggregatesTripCount
});


$ChargingPreferencesCopyWith<$Res> get chargingPreferences;$TripLengthBreakdownCopyWith<$Res>? get tripLengthAggregates;$SpeedConsumptionHistogramCopyWith<$Res>? get speedConsumptionAggregates;

}
/// @nodoc
class _$VehicleProfileCopyWithImpl<$Res>
    implements $VehicleProfileCopyWith<$Res> {
  _$VehicleProfileCopyWithImpl(this._self, this._then);

  final VehicleProfile _self;
  final $Res Function(VehicleProfile) _then;

/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? batteryKwh = freezed,Object? maxChargingKw = freezed,Object? supportedConnectors = null,Object? chargingPreferences = null,Object? tankCapacityL = freezed,Object? preferredFuelType = freezed,Object? engineDisplacementCc = freezed,Object? engineCylinders = freezed,Object? volumetricEfficiency = null,Object? volumetricEfficiencySamples = null,Object? curbWeightKg = freezed,Object? obd2AdapterMac = freezed,Object? obd2AdapterName = freezed,Object? vin = freezed,Object? calibrationMode = null,Object? autoRecord = null,Object? pairedAdapterMac = freezed,Object? movementStartThresholdKmh = null,Object? disconnectSaveDelaySec = null,Object? backgroundLocationConsent = null,Object? make = freezed,Object? model = freezed,Object? year = freezed,Object? referenceVehicleId = freezed,Object? tripLengthAggregates = freezed,Object? speedConsumptionAggregates = freezed,Object? aggregatesUpdatedAt = freezed,Object? aggregatesTripCount = freezed,}) {
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
as String?,calibrationMode: null == calibrationMode ? _self.calibrationMode : calibrationMode // ignore: cast_nullable_to_non_nullable
as VehicleCalibrationMode,autoRecord: null == autoRecord ? _self.autoRecord : autoRecord // ignore: cast_nullable_to_non_nullable
as bool,pairedAdapterMac: freezed == pairedAdapterMac ? _self.pairedAdapterMac : pairedAdapterMac // ignore: cast_nullable_to_non_nullable
as String?,movementStartThresholdKmh: null == movementStartThresholdKmh ? _self.movementStartThresholdKmh : movementStartThresholdKmh // ignore: cast_nullable_to_non_nullable
as double,disconnectSaveDelaySec: null == disconnectSaveDelaySec ? _self.disconnectSaveDelaySec : disconnectSaveDelaySec // ignore: cast_nullable_to_non_nullable
as int,backgroundLocationConsent: null == backgroundLocationConsent ? _self.backgroundLocationConsent : backgroundLocationConsent // ignore: cast_nullable_to_non_nullable
as bool,make: freezed == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,referenceVehicleId: freezed == referenceVehicleId ? _self.referenceVehicleId : referenceVehicleId // ignore: cast_nullable_to_non_nullable
as String?,tripLengthAggregates: freezed == tripLengthAggregates ? _self.tripLengthAggregates : tripLengthAggregates // ignore: cast_nullable_to_non_nullable
as TripLengthBreakdown?,speedConsumptionAggregates: freezed == speedConsumptionAggregates ? _self.speedConsumptionAggregates : speedConsumptionAggregates // ignore: cast_nullable_to_non_nullable
as SpeedConsumptionHistogram?,aggregatesUpdatedAt: freezed == aggregatesUpdatedAt ? _self.aggregatesUpdatedAt : aggregatesUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,aggregatesTripCount: freezed == aggregatesTripCount ? _self.aggregatesTripCount : aggregatesTripCount // ignore: cast_nullable_to_non_nullable
as int?,
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
}/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripLengthBreakdownCopyWith<$Res>? get tripLengthAggregates {
    if (_self.tripLengthAggregates == null) {
    return null;
  }

  return $TripLengthBreakdownCopyWith<$Res>(_self.tripLengthAggregates!, (value) {
    return _then(_self.copyWith(tripLengthAggregates: value));
  });
}/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedConsumptionHistogramCopyWith<$Res>? get speedConsumptionAggregates {
    if (_self.speedConsumptionAggregates == null) {
    return null;
  }

  return $SpeedConsumptionHistogramCopyWith<$Res>(_self.speedConsumptionAggregates!, (value) {
    return _then(_self.copyWith(speedConsumptionAggregates: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @VehicleTypeJsonConverter()  VehicleType type,  double? batteryKwh,  double? maxChargingKw, @ConnectorTypeSetConverter()  Set<ConnectorType> supportedConnectors, @ChargingPreferencesJsonConverter()  ChargingPreferences chargingPreferences,  double? tankCapacityL,  String? preferredFuelType,  int? engineDisplacementCc,  int? engineCylinders,  double volumetricEfficiency,  int volumetricEfficiencySamples,  int? curbWeightKg,  String? obd2AdapterMac,  String? obd2AdapterName,  String? vin, @VehicleCalibrationModeJsonConverter()  VehicleCalibrationMode calibrationMode,  bool autoRecord,  String? pairedAdapterMac,  double movementStartThresholdKmh,  int disconnectSaveDelaySec,  bool backgroundLocationConsent,  String? make,  String? model,  int? year,  String? referenceVehicleId,  TripLengthBreakdown? tripLengthAggregates,  SpeedConsumptionHistogram? speedConsumptionAggregates,  DateTime? aggregatesUpdatedAt,  int? aggregatesTripCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleProfile() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.batteryKwh,_that.maxChargingKw,_that.supportedConnectors,_that.chargingPreferences,_that.tankCapacityL,_that.preferredFuelType,_that.engineDisplacementCc,_that.engineCylinders,_that.volumetricEfficiency,_that.volumetricEfficiencySamples,_that.curbWeightKg,_that.obd2AdapterMac,_that.obd2AdapterName,_that.vin,_that.calibrationMode,_that.autoRecord,_that.pairedAdapterMac,_that.movementStartThresholdKmh,_that.disconnectSaveDelaySec,_that.backgroundLocationConsent,_that.make,_that.model,_that.year,_that.referenceVehicleId,_that.tripLengthAggregates,_that.speedConsumptionAggregates,_that.aggregatesUpdatedAt,_that.aggregatesTripCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @VehicleTypeJsonConverter()  VehicleType type,  double? batteryKwh,  double? maxChargingKw, @ConnectorTypeSetConverter()  Set<ConnectorType> supportedConnectors, @ChargingPreferencesJsonConverter()  ChargingPreferences chargingPreferences,  double? tankCapacityL,  String? preferredFuelType,  int? engineDisplacementCc,  int? engineCylinders,  double volumetricEfficiency,  int volumetricEfficiencySamples,  int? curbWeightKg,  String? obd2AdapterMac,  String? obd2AdapterName,  String? vin, @VehicleCalibrationModeJsonConverter()  VehicleCalibrationMode calibrationMode,  bool autoRecord,  String? pairedAdapterMac,  double movementStartThresholdKmh,  int disconnectSaveDelaySec,  bool backgroundLocationConsent,  String? make,  String? model,  int? year,  String? referenceVehicleId,  TripLengthBreakdown? tripLengthAggregates,  SpeedConsumptionHistogram? speedConsumptionAggregates,  DateTime? aggregatesUpdatedAt,  int? aggregatesTripCount)  $default,) {final _that = this;
switch (_that) {
case _VehicleProfile():
return $default(_that.id,_that.name,_that.type,_that.batteryKwh,_that.maxChargingKw,_that.supportedConnectors,_that.chargingPreferences,_that.tankCapacityL,_that.preferredFuelType,_that.engineDisplacementCc,_that.engineCylinders,_that.volumetricEfficiency,_that.volumetricEfficiencySamples,_that.curbWeightKg,_that.obd2AdapterMac,_that.obd2AdapterName,_that.vin,_that.calibrationMode,_that.autoRecord,_that.pairedAdapterMac,_that.movementStartThresholdKmh,_that.disconnectSaveDelaySec,_that.backgroundLocationConsent,_that.make,_that.model,_that.year,_that.referenceVehicleId,_that.tripLengthAggregates,_that.speedConsumptionAggregates,_that.aggregatesUpdatedAt,_that.aggregatesTripCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @VehicleTypeJsonConverter()  VehicleType type,  double? batteryKwh,  double? maxChargingKw, @ConnectorTypeSetConverter()  Set<ConnectorType> supportedConnectors, @ChargingPreferencesJsonConverter()  ChargingPreferences chargingPreferences,  double? tankCapacityL,  String? preferredFuelType,  int? engineDisplacementCc,  int? engineCylinders,  double volumetricEfficiency,  int volumetricEfficiencySamples,  int? curbWeightKg,  String? obd2AdapterMac,  String? obd2AdapterName,  String? vin, @VehicleCalibrationModeJsonConverter()  VehicleCalibrationMode calibrationMode,  bool autoRecord,  String? pairedAdapterMac,  double movementStartThresholdKmh,  int disconnectSaveDelaySec,  bool backgroundLocationConsent,  String? make,  String? model,  int? year,  String? referenceVehicleId,  TripLengthBreakdown? tripLengthAggregates,  SpeedConsumptionHistogram? speedConsumptionAggregates,  DateTime? aggregatesUpdatedAt,  int? aggregatesTripCount)?  $default,) {final _that = this;
switch (_that) {
case _VehicleProfile() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.batteryKwh,_that.maxChargingKw,_that.supportedConnectors,_that.chargingPreferences,_that.tankCapacityL,_that.preferredFuelType,_that.engineDisplacementCc,_that.engineCylinders,_that.volumetricEfficiency,_that.volumetricEfficiencySamples,_that.curbWeightKg,_that.obd2AdapterMac,_that.obd2AdapterName,_that.vin,_that.calibrationMode,_that.autoRecord,_that.pairedAdapterMac,_that.movementStartThresholdKmh,_that.disconnectSaveDelaySec,_that.backgroundLocationConsent,_that.make,_that.model,_that.year,_that.referenceVehicleId,_that.tripLengthAggregates,_that.speedConsumptionAggregates,_that.aggregatesUpdatedAt,_that.aggregatesTripCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehicleProfile extends VehicleProfile {
  const _VehicleProfile({required this.id, required this.name, @VehicleTypeJsonConverter() this.type = VehicleType.combustion, this.batteryKwh, this.maxChargingKw, @ConnectorTypeSetConverter() final  Set<ConnectorType> supportedConnectors = const <ConnectorType>{}, @ChargingPreferencesJsonConverter() this.chargingPreferences = const ChargingPreferences(), this.tankCapacityL, this.preferredFuelType, this.engineDisplacementCc, this.engineCylinders, this.volumetricEfficiency = 0.85, this.volumetricEfficiencySamples = 0, this.curbWeightKg, this.obd2AdapterMac, this.obd2AdapterName, this.vin, @VehicleCalibrationModeJsonConverter() this.calibrationMode = VehicleCalibrationMode.rule, this.autoRecord = false, this.pairedAdapterMac, this.movementStartThresholdKmh = 5.0, this.disconnectSaveDelaySec = 60, this.backgroundLocationConsent = false, this.make, this.model, this.year, this.referenceVehicleId, this.tripLengthAggregates, this.speedConsumptionAggregates, this.aggregatesUpdatedAt, this.aggregatesTripCount}): _supportedConnectors = supportedConnectors,super._();
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
// Baseline calibration mode (#894). `rule` keeps the original
// winner-take-all classifier from #779; `fuzzy` re-weights each
// sample across all situations via [FuzzyClassifier]. Default
// stays on `rule` so existing profiles deserialize without a
// migration — users opt in from the vehicle edit screen.
@override@JsonKey()@VehicleCalibrationModeJsonConverter() final  VehicleCalibrationMode calibrationMode;
// Hands-free auto-record configuration (#1004 phase 1). All
// fields default to "off" or to safe values so pre-#1004 Hive
// profiles deserialize cleanly via freezed's `@Default`. Phases
// 2-6 layer the background service, movement-detection,
// disconnect-save, badge counter and UI on top of these fields
// — phase 1 ships the data layer only.
//
//   autoRecord: master toggle. Off by default — every user must
//     opt in explicitly from the vehicle edit screen.
//   pairedAdapterMac: MAC address of the ELM327 adapter that
//     belongs to this vehicle. Distinct from
//     [obd2AdapterMac] (the "currently connected" adapter from
//     #784 / #816); pairedAdapterMac is the long-lived "this
//     adapter belongs to this car" marker that the BLE auto-
//     connect listener watches for. Null when the user hasn't
//     paired one yet.
//   movementStartThresholdKmh: speed (OBD2 PID 0x0D OR phone
//     GPS, whichever fires first) above which auto-record fires
//     `startTrip()`. Default 5 km/h — low enough to catch
//     pulling out of a parking spot, high enough to ignore the
//     adapter waking up while the car is stationary.
//   disconnectSaveDelaySec: debounce window in seconds before a
//     BT disconnect triggers `stopAndSave`. Default 60 s — long
//     enough to absorb a tunnel or a parking-garage lift, short
//     enough that the user sees a saved trip when they walk
//     into the kitchen.
//   backgroundLocationConsent: separate from runtime location
//     permission — this is the user's stored answer to "may we
//     record GPS while the screen is off?" Without it, the
//     auto-flow runs BT-only and skips GPS-based trip metadata.
@override@JsonKey() final  bool autoRecord;
@override final  String? pairedAdapterMac;
@override@JsonKey() final  double movementStartThresholdKmh;
@override@JsonKey() final  int disconnectSaveDelaySec;
@override@JsonKey() final  bool backgroundLocationConsent;
// Reference catalog identification (#950 phase 4). Optional fields
// populated during onboarding (VIN decoder pre-fill or manual user
// entry) so the migrator and the OBD-II layer can resolve the
// vehicle to a [ReferenceVehicle]. All three default to null so
// pre-#950 profiles deserialize without losing data — the migrator
// fills them in on first launch.
//
//   make: marketing brand name, e.g. "Peugeot", "Renault".
//   model: model name as marketed in Europe, e.g. "208", "Clio".
//   year: model year (4-digit), used to disambiguate generations.
//   referenceVehicleId: slug of the matching catalog entry, e.g.
//     "peugeot-208-ii-2019-". Format is `<make>-<model>-<generation>`
//     lowercased with non-alphanumerics collapsed to dashes. The
//     consumer side (obd2_service) resolves the slug back to a
//     [ReferenceVehicle] via the catalog provider.
@override final  String? make;
@override final  String? model;
@override final  int? year;
@override final  String? referenceVehicleId;
// Rolling per-vehicle driving aggregates (#1193 phase 1). All four
// fields are nullable; they remain null until the first trip
// aggregator pass writes them, and a null bucket entry inside the
// populated [TripLengthBreakdown] / [SpeedConsumptionHistogram]
// means the vehicle has trips overall but not yet enough in that
// specific bucket to clear the per-bucket min-sample threshold.
//
// The phase-1 PR ships these storage fields and the value-object
// schemas only — the aggregator service that fills them lives in
// `lib/features/vehicle/data/vehicle_aggregate_updater.dart`
// (#1193 phase 2), and the vehicle-profile UI section that reads
// them lives in the edit/view screens (#1193 phase 3).
//
//   tripLengthAggregates:    short / medium / long bucket stats.
//   speedConsumptionAggregates: per-speed-band L/100 km histogram.
//   aggregatesUpdatedAt:     wall-clock time of the last refresh.
//   aggregatesTripCount:     # trips folded into the current pass
//                            (used by the UI to gate the section
//                            below a min-trips threshold).
@override final  TripLengthBreakdown? tripLengthAggregates;
@override final  SpeedConsumptionHistogram? speedConsumptionAggregates;
@override final  DateTime? aggregatesUpdatedAt;
@override final  int? aggregatesTripCount;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.batteryKwh, batteryKwh) || other.batteryKwh == batteryKwh)&&(identical(other.maxChargingKw, maxChargingKw) || other.maxChargingKw == maxChargingKw)&&const DeepCollectionEquality().equals(other._supportedConnectors, _supportedConnectors)&&(identical(other.chargingPreferences, chargingPreferences) || other.chargingPreferences == chargingPreferences)&&(identical(other.tankCapacityL, tankCapacityL) || other.tankCapacityL == tankCapacityL)&&(identical(other.preferredFuelType, preferredFuelType) || other.preferredFuelType == preferredFuelType)&&(identical(other.engineDisplacementCc, engineDisplacementCc) || other.engineDisplacementCc == engineDisplacementCc)&&(identical(other.engineCylinders, engineCylinders) || other.engineCylinders == engineCylinders)&&(identical(other.volumetricEfficiency, volumetricEfficiency) || other.volumetricEfficiency == volumetricEfficiency)&&(identical(other.volumetricEfficiencySamples, volumetricEfficiencySamples) || other.volumetricEfficiencySamples == volumetricEfficiencySamples)&&(identical(other.curbWeightKg, curbWeightKg) || other.curbWeightKg == curbWeightKg)&&(identical(other.obd2AdapterMac, obd2AdapterMac) || other.obd2AdapterMac == obd2AdapterMac)&&(identical(other.obd2AdapterName, obd2AdapterName) || other.obd2AdapterName == obd2AdapterName)&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.calibrationMode, calibrationMode) || other.calibrationMode == calibrationMode)&&(identical(other.autoRecord, autoRecord) || other.autoRecord == autoRecord)&&(identical(other.pairedAdapterMac, pairedAdapterMac) || other.pairedAdapterMac == pairedAdapterMac)&&(identical(other.movementStartThresholdKmh, movementStartThresholdKmh) || other.movementStartThresholdKmh == movementStartThresholdKmh)&&(identical(other.disconnectSaveDelaySec, disconnectSaveDelaySec) || other.disconnectSaveDelaySec == disconnectSaveDelaySec)&&(identical(other.backgroundLocationConsent, backgroundLocationConsent) || other.backgroundLocationConsent == backgroundLocationConsent)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year)&&(identical(other.referenceVehicleId, referenceVehicleId) || other.referenceVehicleId == referenceVehicleId)&&(identical(other.tripLengthAggregates, tripLengthAggregates) || other.tripLengthAggregates == tripLengthAggregates)&&(identical(other.speedConsumptionAggregates, speedConsumptionAggregates) || other.speedConsumptionAggregates == speedConsumptionAggregates)&&(identical(other.aggregatesUpdatedAt, aggregatesUpdatedAt) || other.aggregatesUpdatedAt == aggregatesUpdatedAt)&&(identical(other.aggregatesTripCount, aggregatesTripCount) || other.aggregatesTripCount == aggregatesTripCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,type,batteryKwh,maxChargingKw,const DeepCollectionEquality().hash(_supportedConnectors),chargingPreferences,tankCapacityL,preferredFuelType,engineDisplacementCc,engineCylinders,volumetricEfficiency,volumetricEfficiencySamples,curbWeightKg,obd2AdapterMac,obd2AdapterName,vin,calibrationMode,autoRecord,pairedAdapterMac,movementStartThresholdKmh,disconnectSaveDelaySec,backgroundLocationConsent,make,model,year,referenceVehicleId,tripLengthAggregates,speedConsumptionAggregates,aggregatesUpdatedAt,aggregatesTripCount]);

@override
String toString() {
  return 'VehicleProfile(id: $id, name: $name, type: $type, batteryKwh: $batteryKwh, maxChargingKw: $maxChargingKw, supportedConnectors: $supportedConnectors, chargingPreferences: $chargingPreferences, tankCapacityL: $tankCapacityL, preferredFuelType: $preferredFuelType, engineDisplacementCc: $engineDisplacementCc, engineCylinders: $engineCylinders, volumetricEfficiency: $volumetricEfficiency, volumetricEfficiencySamples: $volumetricEfficiencySamples, curbWeightKg: $curbWeightKg, obd2AdapterMac: $obd2AdapterMac, obd2AdapterName: $obd2AdapterName, vin: $vin, calibrationMode: $calibrationMode, autoRecord: $autoRecord, pairedAdapterMac: $pairedAdapterMac, movementStartThresholdKmh: $movementStartThresholdKmh, disconnectSaveDelaySec: $disconnectSaveDelaySec, backgroundLocationConsent: $backgroundLocationConsent, make: $make, model: $model, year: $year, referenceVehicleId: $referenceVehicleId, tripLengthAggregates: $tripLengthAggregates, speedConsumptionAggregates: $speedConsumptionAggregates, aggregatesUpdatedAt: $aggregatesUpdatedAt, aggregatesTripCount: $aggregatesTripCount)';
}


}

/// @nodoc
abstract mixin class _$VehicleProfileCopyWith<$Res> implements $VehicleProfileCopyWith<$Res> {
  factory _$VehicleProfileCopyWith(_VehicleProfile value, $Res Function(_VehicleProfile) _then) = __$VehicleProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@VehicleTypeJsonConverter() VehicleType type, double? batteryKwh, double? maxChargingKw,@ConnectorTypeSetConverter() Set<ConnectorType> supportedConnectors,@ChargingPreferencesJsonConverter() ChargingPreferences chargingPreferences, double? tankCapacityL, String? preferredFuelType, int? engineDisplacementCc, int? engineCylinders, double volumetricEfficiency, int volumetricEfficiencySamples, int? curbWeightKg, String? obd2AdapterMac, String? obd2AdapterName, String? vin,@VehicleCalibrationModeJsonConverter() VehicleCalibrationMode calibrationMode, bool autoRecord, String? pairedAdapterMac, double movementStartThresholdKmh, int disconnectSaveDelaySec, bool backgroundLocationConsent, String? make, String? model, int? year, String? referenceVehicleId, TripLengthBreakdown? tripLengthAggregates, SpeedConsumptionHistogram? speedConsumptionAggregates, DateTime? aggregatesUpdatedAt, int? aggregatesTripCount
});


@override $ChargingPreferencesCopyWith<$Res> get chargingPreferences;@override $TripLengthBreakdownCopyWith<$Res>? get tripLengthAggregates;@override $SpeedConsumptionHistogramCopyWith<$Res>? get speedConsumptionAggregates;

}
/// @nodoc
class __$VehicleProfileCopyWithImpl<$Res>
    implements _$VehicleProfileCopyWith<$Res> {
  __$VehicleProfileCopyWithImpl(this._self, this._then);

  final _VehicleProfile _self;
  final $Res Function(_VehicleProfile) _then;

/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? batteryKwh = freezed,Object? maxChargingKw = freezed,Object? supportedConnectors = null,Object? chargingPreferences = null,Object? tankCapacityL = freezed,Object? preferredFuelType = freezed,Object? engineDisplacementCc = freezed,Object? engineCylinders = freezed,Object? volumetricEfficiency = null,Object? volumetricEfficiencySamples = null,Object? curbWeightKg = freezed,Object? obd2AdapterMac = freezed,Object? obd2AdapterName = freezed,Object? vin = freezed,Object? calibrationMode = null,Object? autoRecord = null,Object? pairedAdapterMac = freezed,Object? movementStartThresholdKmh = null,Object? disconnectSaveDelaySec = null,Object? backgroundLocationConsent = null,Object? make = freezed,Object? model = freezed,Object? year = freezed,Object? referenceVehicleId = freezed,Object? tripLengthAggregates = freezed,Object? speedConsumptionAggregates = freezed,Object? aggregatesUpdatedAt = freezed,Object? aggregatesTripCount = freezed,}) {
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
as String?,calibrationMode: null == calibrationMode ? _self.calibrationMode : calibrationMode // ignore: cast_nullable_to_non_nullable
as VehicleCalibrationMode,autoRecord: null == autoRecord ? _self.autoRecord : autoRecord // ignore: cast_nullable_to_non_nullable
as bool,pairedAdapterMac: freezed == pairedAdapterMac ? _self.pairedAdapterMac : pairedAdapterMac // ignore: cast_nullable_to_non_nullable
as String?,movementStartThresholdKmh: null == movementStartThresholdKmh ? _self.movementStartThresholdKmh : movementStartThresholdKmh // ignore: cast_nullable_to_non_nullable
as double,disconnectSaveDelaySec: null == disconnectSaveDelaySec ? _self.disconnectSaveDelaySec : disconnectSaveDelaySec // ignore: cast_nullable_to_non_nullable
as int,backgroundLocationConsent: null == backgroundLocationConsent ? _self.backgroundLocationConsent : backgroundLocationConsent // ignore: cast_nullable_to_non_nullable
as bool,make: freezed == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,referenceVehicleId: freezed == referenceVehicleId ? _self.referenceVehicleId : referenceVehicleId // ignore: cast_nullable_to_non_nullable
as String?,tripLengthAggregates: freezed == tripLengthAggregates ? _self.tripLengthAggregates : tripLengthAggregates // ignore: cast_nullable_to_non_nullable
as TripLengthBreakdown?,speedConsumptionAggregates: freezed == speedConsumptionAggregates ? _self.speedConsumptionAggregates : speedConsumptionAggregates // ignore: cast_nullable_to_non_nullable
as SpeedConsumptionHistogram?,aggregatesUpdatedAt: freezed == aggregatesUpdatedAt ? _self.aggregatesUpdatedAt : aggregatesUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,aggregatesTripCount: freezed == aggregatesTripCount ? _self.aggregatesTripCount : aggregatesTripCount // ignore: cast_nullable_to_non_nullable
as int?,
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
}/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripLengthBreakdownCopyWith<$Res>? get tripLengthAggregates {
    if (_self.tripLengthAggregates == null) {
    return null;
  }

  return $TripLengthBreakdownCopyWith<$Res>(_self.tripLengthAggregates!, (value) {
    return _then(_self.copyWith(tripLengthAggregates: value));
  });
}/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpeedConsumptionHistogramCopyWith<$Res>? get speedConsumptionAggregates {
    if (_self.speedConsumptionAggregates == null) {
    return null;
  }

  return $SpeedConsumptionHistogramCopyWith<$Res>(_self.speedConsumptionAggregates!, (value) {
    return _then(_self.copyWith(speedConsumptionAggregates: value));
  });
}
}

// dart format on
