/// Pure parsing helpers for the French Prix-Carburants (gouv.fr) feed
/// (#563 split). Lives separately from `PrixCarburantsStationService`
/// so the JSON-shape contract — which is what the live endpoint
/// typically breaks first — can be exercised with recorded fixtures,
/// without touching Dio or any network state. Adding network or
/// storage imports here defeats the point of the split.
///
/// Public surface:
///  - [parsePrixCarburantsStation]: single API record → [Station]
///    (or `null` when the record cannot be coerced into one).
///  - [extractPrixCarburantsResults]: top-level envelope → list of
///    raw record maps. Tolerates non-map payloads (returns `[]`).
///  - [parsePrixCarburantsOpeningHours]: cleans up the opaque
///    `Automate-24-24, Lundi07.00-18.30, ...` string into a
///    line-per-day `HH:MM-HH:MM` form.
///  - [parsePrixCarburantsServices]: coerces the `services_service`
///    field (sometimes `null`, sometimes a JSON list) to a flat
///    `List<String>`.
///  - [parsePrixCarburantsStringList]: same shape-coercion for the
///    `carburants_disponibles` / `carburants_indisponibles` arrays.
///  - [detectPrixCarburantsBrand]: brand-detection from address +
///    ville + services text, with the `pop='A'` autoroute fallback
///    and the `'Independent'` sentinel from #482.
///  - [parsePrixCarburantsMostRecentUpdate]: pick the most recent
///    `*_maj` ISO timestamp on a record and format as `dd/MM HH:mm`.
library;

import 'package:flutter/foundation.dart';

import '../../search/domain/entities/station.dart';
import '../../search/domain/entities/station_amenity.dart';
import '../../../core/utils/geo_utils.dart';

/// Extract the `results` list from a Prix-Carburants API envelope.
///
/// The endpoint always wraps station records in
/// `{ "results": [...], "total_count": N }`. Returns `[]` when the
/// payload is not a map, the `results` key is missing, or the value
/// is `null`. The caller never has to null-check.
List<Map<String, dynamic>> extractPrixCarburantsResults(dynamic data) {
  if (data is Map<String, dynamic>) {
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((r) => r as Map<String, dynamic>)
        .toList();
  }
  return [];
}

/// Parse a single Prix-Carburants record into a [Station].
///
/// [searchLat] and [searchLng] are the user's query origin, used to
/// stamp `Station.dist` via [distanceKm]. They may be 0,0 for the
/// `getStationDetail` path where distance is irrelevant.
///
/// Coordinates come from the GeoJSON `geom` field; some legacy
/// records omit it and instead carry `latitude`/`longitude` as
/// integer strings multiplied by 100000 — those are normalised here.
///
/// Returns `null` only on a hard [FormatException] inside the body
/// (the bare minimum invariant — `{}` returns a near-empty Station,
/// not `null`, mirroring the previous service behaviour).
Station? parsePrixCarburantsStation(
  Map<String, dynamic> r,
  double searchLat,
  double searchLng,
) {
  try {
    final geom = r['geom'] as Map<String, dynamic>?;
    double lat = (geom?['lat'] as num?)?.toDouble() ?? 0;
    double lng = (geom?['lon'] as num?)?.toDouble() ?? 0;

    // Some stations have lat/lng in old format (multiplied by 100000)
    if (lat == 0 || lng == 0) {
      final latStr = r['latitude']?.toString() ?? '0';
      final lngStr = r['longitude']?.toString() ?? '0';
      lat = (double.tryParse(latStr) ?? 0) / 100000;
      lng = (double.tryParse(lngStr) ?? 0) / 100000;
    }

    // Use flat price fields (already in EUR, e.g., 2.129)
    final adresse = r['adresse'] as String? ?? '';
    final ville = r['ville'] as String? ?? '';
    final cp = r['cp'] as String? ?? '';

    return Station(
      id: r['id']?.toString() ?? '',
      name: adresse,
      brand: detectPrixCarburantsBrand(adresse, r['services_service'], r),
      street: adresse,
      postCode: cp,
      place: ville,
      lat: lat,
      lng: lng,
      dist: _roundedDistance(searchLat, searchLng, lat, lng),
      e5: _toDouble(r['sp95_prix']),
      e10: _toDouble(r['e10_prix']),
      e98: _toDouble(r['sp98_prix']),
      diesel: _toDouble(r['gazole_prix']),
      e85: _toDouble(r['e85_prix']),
      lpg: _toDouble(r['gplc_prix']),
      isOpen: true,
      updatedAt: parsePrixCarburantsMostRecentUpdate(r),
      is24h: r['horaires_automate_24_24'] == 'Oui',
      openingHoursText: parsePrixCarburantsOpeningHours(r['horaires_jour']),
      services: parsePrixCarburantsServices(r['services_service']),
      amenities: parseAmenitiesFromServices(
        parsePrixCarburantsServices(r['services_service']),
      ),
      availableFuels: parsePrixCarburantsStringList(r['carburants_disponibles']),
      unavailableFuels: parsePrixCarburantsStringList(r['carburants_indisponibles']),
      stationType: r['pop']?.toString(),
      department: r['departement']?.toString(),
      region: r['region']?.toString(),
    );
  } on FormatException catch (e, st) {
    debugPrint('Prix-Carburants station parse failed: $e\n$st');
    return null;
  }
}

/// Format the most recent `*_maj` ISO timestamp on a record as
/// `dd/MM HH:mm`. Returns `null` when no timestamp fields are
/// populated; falls back to a trimmed substring on malformed input.
String? parsePrixCarburantsMostRecentUpdate(Map<String, dynamic> r) {
  final dates = <String>[
    r['gazole_maj']?.toString() ?? '',
    r['sp95_maj']?.toString() ?? '',
    r['e10_maj']?.toString() ?? '',
    r['sp98_maj']?.toString() ?? '',
    r['e85_maj']?.toString() ?? '',
    r['gplc_maj']?.toString() ?? '',
  ].where((d) => d.isNotEmpty).toList();
  if (dates.isEmpty) return null;
  dates.sort((a, b) => b.compareTo(a)); // Most recent first
  // Format: "2026-03-23T00:01:00+00:00" → "23/03 00:01"
  try {
    final dt = DateTime.parse(dates.first);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } on FormatException catch (e, st) {
    debugPrint('Prix-Carburants date parse failed: $e\n$st');
    final raw = dates.first;
    final cut = raw.length >= 16 ? raw.substring(0, 16) : raw;
    return cut.replaceAll('T', ' ');
  }
}

/// Clean up the Prix-Carburants opening-hours string.
///
/// Source format: `"Automate-24-24, Lundi07.00-18.30, Mardi07.00-18.30..."`
/// Output: one day per line, with `HH:MM` instead of `HH.MM`. Returns
/// `null` for `null` or empty input so the caller can suppress the
/// row entirely.
String? parsePrixCarburantsOpeningHours(dynamic hoursStr) {
  if (hoursStr == null) return null;
  final s = hoursStr.toString();
  if (s.isEmpty) return null;
  // Format: "Automate-24-24, Lundi07.00-18.30, Mardi07.00-18.30..."
  // Clean up: add spaces around times
  return s
      .replaceAll('Automate-24-24, ', '')
      .replaceAllMapped(RegExp(r'(\d{2})\.(\d{2})-(\d{2})\.(\d{2})'),
          (m) => '${m[1]}:${m[2]}-${m[3]}:${m[4]}')
      .replaceAllMapped(RegExp(r'(\d{2})\.(\d{2})'),
          (m) => '${m[1]}:${m[2]}')
      .replaceAll(', ', '\n');
}

/// Coerce the `services_service` field to a flat `List<String>`.
/// Non-list inputs (`null`, scalars, malformed) yield `[]`.
List<String> parsePrixCarburantsServices(dynamic services) {
  if (services is List) return services.map((e) => e.toString()).toList();
  return [];
}

/// Generic list-of-strings coercion shared by `carburants_disponibles`
/// and `carburants_indisponibles`. Same null-tolerance contract as
/// [parsePrixCarburantsServices].
List<String> parsePrixCarburantsStringList(dynamic list) {
  if (list is List) return list.map((e) => e.toString()).toList();
  return [];
}

/// Detect a brand from a Prix-Carburants record.
///
/// The endpoint does not publish a `brand` column, so we infer it
/// from the address, ville, and services text via a hand-curated
/// substring map covering the most common French chains.
///
/// Returns one of:
/// - A canonical brand name (e.g. `'TotalEnergies'`, `'E.Leclerc'`).
/// - `'Autoroute'` for highway service-area stations (`pop == 'A'`).
/// - `'Independent'` (the #482 sentinel) when no rule matches —
///   detail views render this as a localised "independent station"
///   row so the user can distinguish unbranded sites from a
///   detection bug.
String detectPrixCarburantsBrand(
  String adresse,
  dynamic services,
  Map<String, dynamic> r,
) {
  // Check address, ville, and services for known brand names
  final ville = r['ville']?.toString() ?? '';
  final allServices = services is List ? services.join(' ') : (services?.toString() ?? '');
  final text = '$adresse $ville $allServices'.toUpperCase();

  const brandMap = {
    'TOTALENERGIES': 'TotalEnergies',
    'TOTAL ACCESS': 'TotalEnergies',
    'TOTAL ': 'Total',
    'LECLERC': 'E.Leclerc',
    'CARREFOUR': 'Carrefour',
    'INTERMARCHE': 'Intermarché',
    'INTERMARCHÉ': 'Intermarché',
    'AUCHAN': 'Auchan',
    'SUPER U': 'Super U',
    'SYSTEME U': 'Système U',
    'SYSTÈME U': 'Système U',
    'U EXPRESS': 'Système U',
    'HYPER U': 'Système U',
    'CASINO': 'Casino',
    'GEANT CASINO': 'Casino',
    'BP ': 'BP',
    'SHELL': 'Shell',
    'ESSO': 'Esso',
    'AVIA': 'AVIA',
    'VITO': 'Vito',
    'NETTO': 'Netto',
    'DYNEFF': 'Dyneff',
    'ENI': 'ENI',
    'AGIP': 'ENI',
    'Q8 ': 'Q8',
    'TAMOIL': 'Tamoil',
    'JET ': 'JET',
    'LUKOIL': 'Lukoil',
    'REPSOL': 'Repsol',
    'CEPSA': 'Cepsa',
    'GALP': 'Galp',
  };

  for (final entry in brandMap.entries) {
    if (text.contains(entry.key)) return entry.value;
  }

  // Fallback: use station type
  final pop = r['pop']?.toString() ?? '';
  if (pop == 'A') return 'Autoroute';
  // #482 — explicit "genuinely brandless" sentinel instead of the
  // previous magic string `'Station'`. Detail views can now render a
  // localised "Station indépendante" row so the user can distinguish
  // an unbranded independent station from a brand-detection bug.
  // The sentinel is also observable via `BrandRegistry.independentLabel`.
  return 'Independent';
}

/// Coerce arbitrary scalar (`num`, `String`, `null`) to a `double?`.
/// Used by [parsePrixCarburantsStation] for every `*_prix` column.
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

/// Haversine distance, rounded to 1 decimal place. Mirrors the
/// `StationServiceHelpers.roundedDistance` mixin method so the
/// parser stays free of mixin coupling.
double _roundedDistance(double lat1, double lng1, double lat2, double lng2) {
  final d = distanceKm(lat1, lng1, lat2, lng2);
  return double.parse(d.toStringAsFixed(1));
}
