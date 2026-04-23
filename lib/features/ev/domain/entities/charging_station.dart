import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;
import 'opening_hours.dart';

part 'charging_station.freezed.dart';
part 'charging_station.g.dart';

/// Real-time status of an individual [EvConnector].
enum ConnectorStatus {
  available('available'),
  occupied('occupied'),
  outOfOrder('out_of_order'),
  unknown('unknown');

  final String key;
  const ConnectorStatus(this.key);

  static ConnectorStatus fromKey(String? value) {
    if (value == null) return ConnectorStatus.unknown;
    for (final v in ConnectorStatus.values) {
      if (v.key == value) return v;
    }
    return ConnectorStatus.unknown;
  }

  /// Best-effort heuristic mapping from the human-readable labels that
  /// OpenChargeMap returns ("Currently Available", "In Use", "Not
  /// Operational", …) into the canonical [ConnectorStatus]. Used by the
  /// legacy-format [EvConnector.fromJson] path so data persisted before
  /// the #560 consolidation still rehydrates correctly.
  static ConnectorStatus fromLabel(String? label) {
    if (label == null) return ConnectorStatus.unknown;
    final lower = label.toLowerCase();
    if (lower.contains('available') || lower == 'operational') {
      return ConnectorStatus.available;
    }
    if (lower.contains('in use') || lower.contains('occupied')) {
      return ConnectorStatus.occupied;
    }
    if (lower.contains('not operational') ||
        lower.contains('out of order') ||
        lower.contains('unavailable') ||
        lower.contains('removed')) {
      return ConnectorStatus.outOfOrder;
    }
    return ConnectorStatus.unknown;
  }
}

/// Heuristic mapping from OpenChargeMap-style connector labels to the
/// canonical [ConnectorType]. Exported so services can produce
/// [EvConnector] instances directly without round-tripping through
/// JSON.
ConnectorType connectorTypeFromLabel(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('ccs')) return ConnectorType.ccs;
  if (lower.contains('chademo')) return ConnectorType.chademo;
  if (lower.contains('tesla')) return ConnectorType.tesla;
  if (lower.contains('type 2')) return ConnectorType.type2;
  if (lower.contains('type 1')) return ConnectorType.type1;
  if (lower.contains('schuko')) return ConnectorType.schuko;
  if (lower.contains('3-pin') || lower.contains('three pin')) {
    return ConnectorType.threePin;
  }
  return ConnectorType.type2;
}

/// Normalizes a JSON payload from either the pre-#560 search-side
/// [Connector] shape (`powerKW` / free-form `type` / free-form
/// `status`) or the canonical ev-side [EvConnector] shape so
/// [EvConnector.fromJson] can consume either.
Map<String, dynamic> _normalizeConnectorJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);

  // Legacy power key
  if (!normalized.containsKey('maxPowerKw') &&
      normalized.containsKey('powerKW')) {
    normalized['maxPowerKw'] = normalized['powerKW'];
  }

  // Type: accept enum key ("ccs") or free-form label ("CCS Type 2")
  final rawTypeValue = normalized['type'];
  if (rawTypeValue is String) {
    final enumCandidate = ConnectorType.fromKey(rawTypeValue);
    if (enumCandidate == null) {
      // Free-form label — map heuristically and preserve the original
      normalized['rawType'] = normalized['rawType'] ?? rawTypeValue;
      normalized['type'] = connectorTypeFromLabel(rawTypeValue).key;
    }
  }

  // Status: accept enum key ("available") or free-form ("In Use")
  final rawStatusValue = normalized['status'];
  if (rawStatusValue is String) {
    if (ConnectorStatus.fromKey(rawStatusValue) == ConnectorStatus.unknown &&
        rawStatusValue != ConnectorStatus.unknown.key) {
      normalized['statusLabel'] = normalized['statusLabel'] ?? rawStatusValue;
      normalized['status'] = ConnectorStatus.fromLabel(rawStatusValue).key;
    }
  }

  return normalized;
}

/// Normalizes a JSON payload from either the pre-#560 search-side
/// [ChargingStation] shape (`lat` / `lng`) or the canonical ev-side
/// shape (`latitude` / `longitude`) so [ChargingStation.fromJson] can
/// consume either.
Map<String, dynamic> _normalizeChargingStationJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);
  if (!normalized.containsKey('latitude') && normalized.containsKey('lat')) {
    normalized['latitude'] = normalized['lat'];
  }
  if (!normalized.containsKey('longitude') &&
      normalized.containsKey('lng')) {
    normalized['longitude'] = normalized['lng'];
  }
  return normalized;
}

/// A single physical connector attached to a [ChargingStation].
///
/// Canonical type after #560. Previously there were two incompatible
/// connector types — the EV side used the [ConnectorType] enum, while
/// the search side used a free-form `type` string with `powerKW`,
/// `currentType`, `quantity`, and a free-form `status` string. The
/// canonical model keeps the typed enum ([type], [status]) while
/// preserving the original labels ([rawType], [statusLabel]) so the
/// OpenChargeMap-specific display strings survive the round-trip.
@freezed
abstract class EvConnector with _$EvConnector {
  const EvConnector._();

  const factory EvConnector({
    @Default('') String id,
    @ConnectorTypeJsonConverter() required ConnectorType type,
    @Default(0) double maxPowerKw,
    @ConnectorStatusJsonConverter()
    @Default(ConnectorStatus.unknown)
    ConnectorStatus status,
    String? tariffId,

    /// Original free-form type label as returned by the upstream API
    /// (e.g. "CCS Type 2", "Tesla Supercharger"). Preserved so the UI
    /// can show the more specific label when it exists, falling back to
    /// [type] via [ConnectorType.label].
    String? rawType,

    /// "AC", "DC", "AC/DC" — preserved from OpenChargeMap responses.
    String? currentType,

    /// Number of physical connectors of this type at the station.
    @Default(0) int quantity,

    /// Original free-form status label returned by the upstream API
    /// (e.g. "Currently Available"). Preserved so the UI can show the
    /// specific label when present.
    String? statusLabel,
  }) = _EvConnector;

  /// Accepts BOTH the legacy search-side shape (`powerKW`, free-form
  /// `type` String, free-form `status` String) and the canonical
  /// ev-side shape (`maxPowerKw`, [ConnectorType] key, [ConnectorStatus]
  /// key). Free-form labels are preserved in [rawType] / [statusLabel].
  factory EvConnector.fromJson(Map<String, dynamic> json) =>
      _$EvConnectorFromJson(_normalizeConnectorJson(json));

  /// Legacy alias matching the pre-#560 search-side `Connector.powerKW`.
  double get powerKW => maxPowerKw;
}

/// An EV charging station, typically sourced from OCPI / DATEX II /
/// OpenChargeMap / Bundesnetzagentur.
///
/// Canonical type after #560 — this replaces the second
/// `ChargingStation` that used to live in `features/search/domain/
/// entities/`. [fromJson] accepts both the legacy `lat`/`lng` and the
/// canonical `latitude`/`longitude` key naming so data persisted
/// before the consolidation still rehydrates correctly; [toJson]
/// always writes the canonical form.
@freezed
abstract class ChargingStation with _$ChargingStation {
  const ChargingStation._();

  const factory ChargingStation({
    required String id,
    required String name,
    String? operator,
    required double latitude,
    required double longitude,
    String? address,
    @Default(<EvConnector>[])
    @EvConnectorListConverter()
    List<EvConnector> connectors,
    @Default(<String>[]) List<String> amenities,
    @OpeningHoursNullableConverter() OpeningHours? openingHours,
    DateTime? lastUpdate,
    // ------------------------------------------------------------------
    // Fields ported from the legacy search/ ChargingStation (#560).
    // Kept optional / defaulted so existing EV callers don't have to
    // pass them.
    // ------------------------------------------------------------------
    @Default(0) double dist,
    String? postCode,
    String? place,
    @Default(0) int totalPoints,
    bool? isOperational,
    String? usageCost,
    String? updatedAt,
    String? countryCode,
  }) = _ChargingStation;

  /// Accepts BOTH the legacy `lat`/`lng` naming (pre-#560 search-side
  /// entity) and the canonical `latitude`/`longitude` naming. This is
  /// the piece that removes the need for the [EvFavoriteStations]
  /// fallback parser that existed before the consolidation.
  factory ChargingStation.fromJson(Map<String, dynamic> json) =>
      _$ChargingStationFromJson(_normalizeChargingStationJson(json));

  /// Whether any connector is currently reported as `available`.
  bool get hasAvailableConnector => connectors
      .any((c) => c.status == ConnectorStatus.available);

  /// Highest advertised max power across all connectors.
  double get maxPowerKw => connectors.isEmpty
      ? 0
      : connectors
          .map((c) => c.maxPowerKw)
          .reduce((a, b) => a > b ? a : b);

  /// Legacy alias matching the pre-#560 search-side `lat` getter. Keeps
  /// the rename from `lat`/`lng` to `latitude`/`longitude` a soft
  /// migration for the handful of consumers that still read the short
  /// names.
  double get lat => latitude;

  /// Legacy alias matching the pre-#560 search-side `lng` getter.
  double get lng => longitude;
}

// ---------------------------------------------------------------------------
// JSON converters
// ---------------------------------------------------------------------------

/// Serializes [ConnectorType] from `vehicle_profile.dart` as its string key.
class ConnectorTypeJsonConverter
    implements JsonConverter<ConnectorType, String> {
  const ConnectorTypeJsonConverter();

  @override
  ConnectorType fromJson(String json) =>
      ConnectorType.fromKey(json) ?? ConnectorType.type2;

  @override
  String toJson(ConnectorType object) => object.key;
}

/// Serializes [ConnectorStatus] as its string key.
class ConnectorStatusJsonConverter
    implements JsonConverter<ConnectorStatus, String> {
  const ConnectorStatusJsonConverter();

  @override
  ConnectorStatus fromJson(String json) => ConnectorStatus.fromKey(json);

  @override
  String toJson(ConnectorStatus object) => object.key;
}

/// Serializes a list of [EvConnector] as plain JSON maps.
class EvConnectorListConverter
    implements JsonConverter<List<EvConnector>, List<dynamic>> {
  const EvConnectorListConverter();

  @override
  List<EvConnector> fromJson(List<dynamic> json) => json
      .whereType<Map<dynamic, dynamic>>()
      .map((e) => EvConnector.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  @override
  List<Map<String, dynamic>> toJson(List<EvConnector> object) =>
      object.map((c) => c.toJson()).toList();
}

/// Serializes a nullable [OpeningHours] as a plain JSON map.
class OpeningHoursNullableConverter
    implements JsonConverter<OpeningHours?, Map<String, dynamic>?> {
  const OpeningHoursNullableConverter();

  @override
  OpeningHours? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : OpeningHours.fromJson(json);

  @override
  Map<String, dynamic>? toJson(OpeningHours? object) => object?.toJson();
}
