// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Which fleet vehicle a record belongs to, how that was decided, and
/// how sure the app is (#4213, Epic #4211) — the *value*. The decision
/// table that produces one lives next door in
/// `vehicle_attribution_resolver.dart`.
///
/// Deliberately free of any other feature's types: the OBD2 adapter
/// identity and VIN arrive as plain strings, so this domain neither
/// imports `obd2/api.dart` nor drags the fleet feature into the app's
/// one big dependency component (`test/lint/feature_boundary_test.dart`,
/// the barrel-aware SCC gate).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

/// An automatic signal weaker than this never attributes a vehicle on
/// its own (#4213: "low-confidence attribution must not enter fleet
/// reporting as fact"). Declared here, with the value it judges, and
/// re-exposed as `VehicleAttributionResolver.minimumAutomaticConfidence`.
const double kMinimumAutomaticAttributionConfidence = 0.6;

/// How a vehicle was attributed, in the priority order #4213 fixes.
///
/// Declaration order IS the priority order (`index` = rank, lower
/// wins) — a new source must be inserted where it belongs, and the
/// resolver's table test pins the ranking.
enum VehicleAttributionSource {
  /// 1. The driver picked this vehicle. Beats every other signal,
  /// always, however confident the others are.
  explicit('explicit'),

  /// 2. A verified live OBD2 adapter identity bound to exactly one
  /// fleet vehicle. Never a MAC alone: the caller passes the stable
  /// identity it already persisted (device id + iOS peripheral UUID).
  adapterIdentity('adapter_identity'),

  /// 3. A VIN read from the connected car, matching one fleet vehicle.
  vin('vin'),

  /// 4. A fleet QR / NFC tag scanned on the vehicle.
  qr('qr'),

  /// 5. Registration or visual information. A **search aid only** —
  /// #4213 forbids it from attributing anything automatically, so the
  /// resolver never confirms on it.
  search('search');

  const VehicleAttributionSource(this.wireName);

  /// Stable persisted name — never the enum index, which would shift
  /// if a source were ever inserted.
  final String wireName;

  /// Null for a source this build does not know.
  static VehicleAttributionSource? fromWireName(String? name) {
    for (final s in values) {
      if (s.wireName == name) return s;
    }
    return null;
  }

  /// Whether this source is *machine* evidence the resolver may weigh:
  /// the adapter, the VIN and the QR tag. [explicit] is excluded
  /// because it is not weighed at all — it short-circuits the table —
  /// and [search] because #4213 forbids it from attributing anything.
  bool get isAutomaticEvidence =>
      this == adapterIdentity || this == vin || this == qr;
}

/// The attribution a creation path stamps onto the record it writes.
///
/// Immutable and write-once by contract: changing the current vehicle
/// later must never rewrite an existing attribution (#4213, "Data
/// integrity"), which is why nothing here has a setter or a `copyWith`
/// that changes the vehicle.
class VehicleAttribution {
  const VehicleAttribution({
    required this.fleetVehicleId,
    required this.source,
    required this.confidence,
    required this.at,
    this.localVehicleId,
    this.evidence = const <String>[],
  });

  final String fleetVehicleId;
  final String? localVehicleId;
  final VehicleAttributionSource source;

  /// 0..1 — 1.0 for [VehicleAttributionSource.explicit].
  final double confidence;

  /// Every piece of evidence that agreed, highest-priority source
  /// first. A corroborating VIN stays visible next to the adapter that
  /// won.
  final List<String> evidence;

  /// When the attribution was made, UTC, from the injected clock.
  final DateTime at;

  /// #4213: only an explicit pick, or corroborated high-confidence
  /// automatic evidence, may enter fleet reporting as fact.
  bool get isReportable =>
      source == VehicleAttributionSource.explicit ||
      confidence >= kMinimumAutomaticAttributionConfidence;

  static VehicleAttribution? fromJson(Map<String, dynamic> json) {
    final id = json['fleet_vehicle_id'];
    final source = VehicleAttributionSource.fromWireName(
        json['source'] as String?);
    final at = _utc(json['at']);
    if (id is! String || source == null || at == null) return null;
    final confidence = json['confidence'];
    final evidence = json['evidence'];
    return VehicleAttribution(
      fleetVehicleId: id,
      localVehicleId: json['local_vehicle_id'] as String?,
      source: source,
      confidence: confidence is num ? confidence.toDouble() : 0,
      evidence: [
        if (evidence is List)
          for (final e in evidence)
            if (e is String) e,
      ],
      at: at,
    );
  }

  Map<String, dynamic> toJson() => {
        'fleet_vehicle_id': fleetVehicleId,
        'local_vehicle_id': localVehicleId,
        'source': source.wireName,
        'confidence': confidence,
        'evidence': evidence,
        'at': at.toUtc().toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is VehicleAttribution &&
      other.fleetVehicleId == fleetVehicleId &&
      other.localVehicleId == localVehicleId &&
      other.source == source &&
      other.confidence == confidence &&
      other.at == at &&
      _sameList(other.evidence, evidence);

  @override
  int get hashCode => Object.hash(fleetVehicleId, localVehicleId, source,
      confidence, at, Object.hashAll(evidence));

  @override
  String toString() =>
      'VehicleAttribution($fleetVehicleId, ${source.wireName}, $confidence)';
}

/// Codec for the nullable `fleetAttribution` field the creation paths
/// stamp onto a record (`FillUp`, and `TripHistoryEntry` once the S2
/// lifecycle train lands).
///
/// Lenient on the way in on purpose: a blob written by a newer build —
/// or a truncated one — decodes as *no* attribution rather than as a
/// half-attribution that would enter fleet reporting. The fill-up
/// itself always survives the read.
class VehicleAttributionJsonConverter
    implements JsonConverter<VehicleAttribution?, Map<String, dynamic>?> {
  const VehicleAttributionJsonConverter();

  @override
  VehicleAttribution? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : VehicleAttribution.fromJson(json);

  @override
  Map<String, dynamic>? toJson(VehicleAttribution? object) =>
      object?.toJson();
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

DateTime? _utc(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}
