import 'package:freezed_annotation/freezed_annotation.dart';

import 'speed_consumption_histogram.dart';
import 'trip_length_breakdown.dart';

part 'vehicle_profile.freezed.dart';
part 'vehicle_profile.g.dart';

/// Powertrain type for a stored vehicle.
enum VehicleType {
  combustion('combustion'),
  hybrid('hybrid'),
  ev('ev');

  final String key;
  const VehicleType(this.key);

  static VehicleType fromKey(String? value) {
    if (value == null) return VehicleType.combustion;
    for (final v in VehicleType.values) {
      if (v.key == value) return v;
    }
    return VehicleType.combustion;
  }
}

/// How the per-vehicle baseline calibration (#779) should classify
/// driving samples (#894).
///
/// * [rule] — the original winner-take-all classifier from #768:
///   every sample is assigned to exactly one [DrivingSituation] and
///   the Welford accumulator for that situation is bumped by one.
/// * [fuzzy] — phase 2 from the #773 investigation: every sample
///   contributes to ALL accumulators proportional to its membership
///   in each situation. Smoother at borderline speeds (around
///   60 km/h urban/highway) and at mode transitions, at the cost of
///   a slightly longer cold-start (each bucket grows more slowly).
///
/// Default is [rule] so existing profiles keep their behaviour
/// without migration.
enum VehicleCalibrationMode {
  rule('rule'),
  fuzzy('fuzzy');

  final String key;
  const VehicleCalibrationMode(this.key);

  static VehicleCalibrationMode fromKey(String? value) {
    if (value == null) return VehicleCalibrationMode.rule;
    for (final m in VehicleCalibrationMode.values) {
      if (m.key == value) return m;
    }
    return VehicleCalibrationMode.rule;
  }
}

/// Common EV connector standards used in Europe.
///
/// Stored as part of [VehicleProfile.supportedConnectors] so the app can
/// filter charging stations by compatibility with the user's vehicle.
enum ConnectorType {
  type2('type2', 'Type 2'),
  ccs('ccs', 'CCS'),
  chademo('chademo', 'CHAdeMO'),
  tesla('tesla', 'Tesla'),
  schuko('schuko', 'Schuko'),
  type1('type1', 'Type 1'),
  threePin('three_pin', '3-pin');

  final String key;
  final String label;
  const ConnectorType(this.key, this.label);

  static ConnectorType? fromKey(String? value) {
    if (value == null) return null;
    for (final c in ConnectorType.values) {
      if (c.key == value) return c;
    }
    return null;
  }
}

/// User preferences for how a vehicle should be charged.
///
/// Independent of the [VehicleProfile] model because the values are
/// relevant only for EVs / hybrids and may be edited separately.
@freezed
abstract class ChargingPreferences with _$ChargingPreferences {
  const factory ChargingPreferences({
    @Default(20) int minSocPercent,
    @Default(80) int maxSocPercent,
    @Default(<String>[]) List<String> preferredNetworks,
  }) = _ChargingPreferences;

  factory ChargingPreferences.fromJson(Map<String, dynamic> json) =>
      _$ChargingPreferencesFromJson(json);
}

/// Persistent data for one of the user's vehicles.
///
/// A single profile may describe a combustion car (tank capacity, preferred
/// fuel) or an EV (battery, supported connectors, charging preferences).
/// Hybrids may carry either or both sets of fields.
@freezed
abstract class VehicleProfile with _$VehicleProfile {
  const VehicleProfile._();

  const factory VehicleProfile({
    required String id,
    required String name,
    @Default(VehicleType.combustion)
    @VehicleTypeJsonConverter()
    VehicleType type,

    // EV fields
    double? batteryKwh,
    double? maxChargingKw,
    @Default(<ConnectorType>{})
    @ConnectorTypeSetConverter()
    Set<ConnectorType> supportedConnectors,
    @Default(ChargingPreferences())
    @ChargingPreferencesJsonConverter()
    ChargingPreferences chargingPreferences,

    // Combustion fields
    double? tankCapacityL,
    String? preferredFuelType,

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
    int? engineDisplacementCc,
    int? engineCylinders,
    @Default(0.85) double volumetricEfficiency,
    @Default(0) int volumetricEfficiencySamples,

    // User-editable calibration overrides (#1397). Each is null until
    // the user types a value into the "Advanced calibration" section
    // of the edit-vehicle screen; non-null values take precedence over
    // every other source in the resolution chain
    //   manualOverride → vehicle.<field> → referenceVehicle.<field> → kDefault
    // wired through `lib/features/consumption/data/obd2/obd2_service.dart`
    // and `trip_recording_controller.dart`. The "Reset to detected"
    // button in the calibration card simply nulls the matching field.
    //
    //   manualEngineDisplacementCcOverride: cubic centimetres, free-text
    //     input. Stored as `double?` (not `int?`) so the user can enter
    //     fractional values that the form parser turns into a clean
    //     double; the OBD2 callers `.round().toInt()` it before
    //     forwarding to the int-typed estimator.
    //   manualVolumetricEfficiencyOverride: 0.50–1.00 — same physical
    //     range the [VeLearner] enforces.
    //   manualAfrOverride: stoichiometric AFR in kg/kg. ~14.7 for petrol,
    //     ~14.5 for diesel; users with LPG conversions / E85 can override.
    //   manualFuelDensityGPerLOverride: density in g/L at ~15 °C. Petrol
    //     ~740, diesel ~832; for unusual blends the user can override.
    double? manualEngineDisplacementCcOverride,
    double? manualVolumetricEfficiencyOverride,
    double? manualAfrOverride,
    double? manualFuelDensityGPerLOverride,

    // Curb weight in kilograms (#812). Populated by the VIN decoder
    // phase 2 onboarding flow (GVWR-minus-payload on the NHTSA side,
    // or manufacturer spec sheets via a future secondary lookup).
    // Null means "unknown" — consumers like the rolling-resistance
    // estimator fall back to a 1500 kg reference, so the field being
    // null is not fatal.
    int? curbWeightKg,

    // OBD2 adapter pairing (#784). Persisted so the app can
    // transparently reconnect on launch without prompting the user
    // again. Both fields are nullable — unpaired vehicles carry
    // null. The MAC is the stable key; the name is the label shown
    // to the user ("vLinker FS").
    String? obd2AdapterMac,
    String? obd2AdapterName,

    // Vehicle Identification Number (#812 phase 2). Optional — the
    // VIN decoder may pre-fill engine fields when present, and the
    // value is persisted so a subsequent edit still shows what the
    // user entered. No format validation at the model level — the
    // UI rejects clearly-invalid input via the decoder, but users
    // should be free to save a stub profile with a partial VIN.
    String? vin,

    // Baseline calibration mode (#894). `rule` keeps the original
    // winner-take-all classifier from #779; `fuzzy` re-weights each
    // sample across all situations via [FuzzyClassifier]. Default
    // stays on `rule` so existing profiles deserialize without a
    // migration — users opt in from the vehicle edit screen.
    @Default(VehicleCalibrationMode.rule)
    @VehicleCalibrationModeJsonConverter()
    VehicleCalibrationMode calibrationMode,

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
    @Default(false) bool autoRecord,
    String? pairedAdapterMac,
    @Default(5.0) double movementStartThresholdKmh,
    @Default(60) int disconnectSaveDelaySec,
    @Default(false) bool backgroundLocationConsent,

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
    String? make,
    String? model,
    int? year,
    String? referenceVehicleId,

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
    TripLengthBreakdown? tripLengthAggregates,
    SpeedConsumptionHistogram? speedConsumptionAggregates,
    DateTime? aggregatesUpdatedAt,
    int? aggregatesTripCount,

    // Gear-inference per-vehicle calibration (#1263 phase 2). The
    // pure-logic clusterer in [gear_inference.dart] needs the driven-
    // wheel circumference to derive the engine-RPM / wheel-RPM ratio
    // it clusters on; persisted centroids let the next trip seed
    // k-means with the previous trip's converged values instead of
    // cold-starting from this trip's percentiles.
    //
    //   tireCircumferenceMeters: circumference in metres of the driven
    //     wheel — used by gear-inference (#1263). 1.95 m is the default
    //     for a typical 195/65R15, the most common factory size on the
    //     European compact-car class this app targets. Users can
    //     override from the vehicle edit screen (phase 3) if their car
    //     runs a different tyre.
    //   gearCentroids: persisted cluster centroids from the most
    //     recent trip (sorted ascending). Null when no trip has run
    //     yet — the clusterer cold-starts in that case. Phase 3 wires
    //     the centroid-write side of this field; this phase ships the
    //     storage so the read path is ready when it lands.
    @Default(1.95) double tireCircumferenceMeters,
    List<double>? gearCentroids,

    // VIN-driven auto-population fields (#1399). Stored separately from
    // the user-entered fields above so the UI can:
    //   1. Render a "(detected)" badge next to any user field whose
    //      value matches the corresponding `detectedX` field.
    //   2. Decide whether to auto-fill empty user fields on adapter
    //      pair (yes when user field is null and detected is non-null).
    //   3. Surface a "differs from detected — apply?" snackbar when
    //      the user has manually entered a value that contradicts the
    //      decoded one (no silent overwrite).
    //
    // `lastReadVin` / `lastVinReadAt` capture the timestamp of the
    // most recent Mode 09 PID 02 read; the rest are the decoded fields
    // from the offline WMI table + (optional) NHTSA vPIC response.
    String? lastReadVin,
    DateTime? lastVinReadAt,
    String? detectedMake,
    String? detectedModel,
    int? detectedYear,
    int? detectedEngineDisplacementCc,
    String? detectedFuelType,
  }) = _VehicleProfile;

  factory VehicleProfile.fromJson(Map<String, dynamic> json) =>
      _$VehicleProfileFromJson(json);

  bool get isEv => type == VehicleType.ev || type == VehicleType.hybrid;
  bool get isCombustion =>
      type == VehicleType.combustion || type == VehicleType.hybrid;
}

/// Serializes [VehicleType] as its string key.
class VehicleTypeJsonConverter
    implements JsonConverter<VehicleType, String> {
  const VehicleTypeJsonConverter();

  @override
  VehicleType fromJson(String json) => VehicleType.fromKey(json);

  @override
  String toJson(VehicleType object) => object.key;
}

/// Serializes [VehicleCalibrationMode] as its string key. Accepts
/// `null` / unknown values as [VehicleCalibrationMode.rule] so
/// pre-#894 profiles (which simply omit the field) deserialize with
/// the existing rule-based behaviour.
class VehicleCalibrationModeJsonConverter
    implements JsonConverter<VehicleCalibrationMode, String?> {
  const VehicleCalibrationModeJsonConverter();

  @override
  VehicleCalibrationMode fromJson(String? json) =>
      VehicleCalibrationMode.fromKey(json);

  @override
  String toJson(VehicleCalibrationMode object) => object.key;
}

/// Serializes [ChargingPreferences] as a plain map so json_serializable
/// does not store the nested object instance directly in the parent's
/// `toJson` output (which would break round-trips through Hive).
class ChargingPreferencesJsonConverter
    implements JsonConverter<ChargingPreferences, Map<String, dynamic>> {
  const ChargingPreferencesJsonConverter();

  @override
  ChargingPreferences fromJson(Map<String, dynamic> json) =>
      ChargingPreferences.fromJson(json);

  @override
  Map<String, dynamic> toJson(ChargingPreferences object) => object.toJson();
}

/// Serializes a `Set<ConnectorType>` as a list of string keys so it
/// survives Hive's `Map<String, dynamic>` storage.
class ConnectorTypeSetConverter
    implements JsonConverter<Set<ConnectorType>, List<dynamic>> {
  const ConnectorTypeSetConverter();

  @override
  Set<ConnectorType> fromJson(List<dynamic> json) {
    final result = <ConnectorType>{};
    for (final value in json) {
      final c = ConnectorType.fromKey(value?.toString());
      if (c != null) result.add(c);
    }
    return result;
  }

  @override
  List<String> toJson(Set<ConnectorType> object) =>
      object.map((c) => c.key).toList();
}
