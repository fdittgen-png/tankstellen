// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

/// #3234 — the standalone enums + their enum-only JSON converters extracted
/// out of `vehicle_profile.dart` so the freezed entity file holds only the
/// model. Re-exported by `vehicle_profile.dart`, so the ~200 sites that import
/// these types via the model keep resolving them unchanged.

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
/// Stored as part of `VehicleProfile.supportedConnectors` so the app can
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
