// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
///  - [parsePrixCarburantsHoursInput]: resolves a record's opening-hours
///    signal from the derived `horaires_jour` column with a fallback to
///    the canonical structured `horaires` column (#3219).
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

import 'dart:async';
import 'dart:convert';

import '../../search/domain/entities/station.dart';
import '../../search/domain/entities/station_amenity.dart';
import '../../../core/country/country_time.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/logging/error_logger.dart';
import '../opening_hours/open_state_from_hours.dart';
import 'france_opening_hours_adapter.dart';

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
///
/// [now] is the clock seam for the schedule-derived `isOpen` (#3198);
/// it defaults to France's wall clock so a user browsing FR from another
/// timezone still gets the open state at the *station*, not at home.
Station? parsePrixCarburantsStation(
  Map<String, dynamic> r,
  double searchLat,
  double searchLng, {
  DateTime? now,
}) {
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

    // #3175 — when BOTH coordinate sources (geom and the legacy
    // latitude/longitude pair) are missing or zero, drop the record
    // instead of emitting a phantom station at (0,0): distanceKm
    // short-circuits a (0,0) endpoint to 0, so the phantom would
    // bypass the radius post-filter and sort as the closest station.
    if (lat == 0 && lng == 0) return null;

    // Use flat price fields (already in EUR, e.g., 2.129)
    final adresse = r['adresse'] as String? ?? '';
    final ville = r['ville'] as String? ?? '';
    final cp = r['cp'] as String? ?? '';

    // #753 — scope the id with the `fr-` country prefix so a French
    // numeric id (e.g. `12345`) cannot collide with another country's
    // numeric id space. Stripped before any call back out to the
    // Prix-Carburants API by `prix_carburants_station_service.dart`.
    final rawId = r['id']?.toString() ?? '';
    // #3219 — resolve the hours signal ONCE (derived `horaires_jour`,
    // falling back to the canonical structured `horaires` column).
    final hoursInput = parsePrixCarburantsHoursInput(r);
    final automate24h = hoursInput['horaires_automate_24_24'] == 'Oui';
    // #2751 — carry the STRUCTURED schedule on the search Station so the
    // detail fast path renders staffed hours instead of collapsing an
    // automate station to "Open 24 hours" via legacyOpeningHoursBridge.
    final openingHours = const FranceOpeningHoursAdapter().parse(hoursInput);
    return Station(
      id: rawId.isEmpty
          ? ''
          : (rawId.startsWith('fr-') ? rawId : 'fr-$rawId'),
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
      // #3198 — schedule-derived (automate dispenses 24/7 → open; else the
      // parsed weekly schedule decides; null when no usable hours).
      isOpen: automate24h
          ? true
          : openStateFromHours(openingHours, now ?? nowInCountry('FR')),
      updatedAt: parsePrixCarburantsMostRecentUpdate(r),
      is24h: automate24h,
      openingHoursText:
          parsePrixCarburantsOpeningHours(hoursInput['horaires_jour']),
      openingHours: openingHours,
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
    unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'Prix-Carburants station parse failed'}));
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
    unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'Prix-Carburants date parse failed'}));
    final raw = dates.first;
    final cut = raw.length >= 16 ? raw.substring(0, 16) : raw;
    return cut.replaceAll('T', ' ');
  }
}

/// Clean up the Prix-Carburants opening-hours string (legacy back-compat
/// text; the structured schedule now comes from [FranceOpeningHoursAdapter]).
///
/// Source format: `"Automate-24-24, Lundi07.00-18.30, Mardi07.00-18.30..."`
/// Output: one day per line, with `HH:MM` instead of `HH.MM` and — fixing the
/// missing-space bug (#2710) — a space between the day name and the first
/// clock (`Lundi 07:00-18:30`, not the old glued `Lundi07:00-18:30`). Returns
/// `null` for `null` or empty input so the caller can suppress the row.
String? parsePrixCarburantsOpeningHours(dynamic hoursStr) {
  if (hoursStr == null) return null;
  final s = hoursStr.toString();
  if (s.isEmpty) return null;
  // Format: "Automate-24-24, Lundi07.00-18.30, Mardi07.00-18.30..."
  // Clean up: strip the automate prefix, separate the glued day↔clock,
  // convert `HH.MM` → `HH:MM`, one day per line.
  return s
      .replaceAll('Automate-24-24, ', '')
      // #2710 — insert a space between a glued day name and its first clock
      // (`Lundi07.00` → `Lundi 07.00`) so the legacy text reads correctly too.
      .replaceAllMapped(RegExp(r'([A-Za-zÀ-ÿ])(\d{1,2}\.\d{2})'),
          (m) => '${m[1]} ${m[2]}')
      .replaceAllMapped(RegExp(r'(\d{2})\.(\d{2})-(\d{2})\.(\d{2})'),
          (m) => '${m[1]}:${m[2]}-${m[3]}:${m[4]}')
      .replaceAllMapped(RegExp(r'(\d{2})\.(\d{2})'),
          (m) => '${m[1]}:${m[2]}')
      .replaceAll(', ', '\n');
}

/// Resolve a Prix-Carburants record's opening-hours signal into the
/// `{'horaires_jour': …, 'horaires_automate_24_24': 'Oui'|'Non'}` map the
/// [FranceOpeningHoursAdapter] consumes (#3219).
///
/// The v2 feed publishes the SAME schedule twice: the canonical structured
/// `horaires` column (the JSON rendition of the flux XML
/// `<horaires>/<jour>/<horaire>` tree) and the DERIVED flattened
/// `horaires_jour` string. Roughly half the live records carry only one of
/// the two, and the derived column is the one the upstream's flattening
/// drops first — the field failure behind #3219: with `horaires_jour` null
/// every consumer downstream went hours-less, and ONLY the orthogonal
/// `horaires_automate_24_24` flag survived (rendered as "Open 24 hours" via
/// the legacy bridge), so 24/7 stations kept hours while per-day schedules
/// vanished. This resolver prefers the derived column (back-compat
/// byte-for-byte) and falls back to flattening the structured column into
/// the identical `Lundi07.00-18.30, …` form — the same normalisation the
/// flux XML path performs in `_flattenHoraires` — so one adapter grammar
/// serves both. The automate flag is the union of the flattened column and
/// the structured `@automate-24-24` attribute. Pure, never throws.
Map<String, dynamic> parsePrixCarburantsHoursInput(Map<String, dynamic> r) {
  final structured = _flattenStructuredHoraires(r['horaires']);
  final automate = r['horaires_automate_24_24'] == 'Oui' ||
      (structured?.automate24h ?? false);
  return <String, dynamic>{
    'horaires_jour': r['horaires_jour'] ?? structured?.joined,
    // i18n-ignore: gouv.fr feed enum value, not user-facing text
    'horaires_automate_24_24': automate ? 'Oui' : 'Non',
  };
}

/// Flatten the structured `horaires` column (a JSON string — or an already
/// decoded map — of the flux `<horaires>` tree) into the comma-joined
/// `horaires_jour` form (`"Lundi07.00-18.30, Mardi08.00-12.00, …"`), plus
/// the `@automate-24-24` attribute ("1"/"Oui" → true). Mirrors the flux XML
/// path's `_flattenHoraires` exactly: only days with a usable
/// `@ouverture`/`@fermeture` pair contribute (`horaire` may be a single map
/// or a list of split shifts); day stubs without ranges are skipped, so a
/// schedule-less record still resolves to "no data", never to a fabricated
/// closed week. Returns `null` when the column is absent/blank/unparseable
/// AND carries no automate flag.
({String? joined, bool automate24h})? _flattenStructuredHoraires(
  dynamic raw,
) {
  dynamic decoded = raw;
  if (raw is String) {
    if (raw.trim().isEmpty) return null;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }
  if (decoded is! Map) return null;

  final automateRaw =
      decoded['@automate-24-24']?.toString().trim().toLowerCase();
  final automate24h = automateRaw == '1' || automateRaw == 'oui';

  final jourRaw = decoded['jour'];
  final jours = jourRaw is List ? jourRaw : [if (jourRaw != null) jourRaw];
  final parts = <String>[];
  for (final jour in jours) {
    if (jour is! Map) continue;
    final nom = jour['@nom']?.toString().trim() ?? '';
    if (nom.isEmpty) continue;
    final horaireRaw = jour['horaire'];
    final horaires =
        horaireRaw is List ? horaireRaw : [if (horaireRaw != null) horaireRaw];
    for (final h in horaires) {
      if (h is! Map) continue;
      final open = h['@ouverture']?.toString().trim() ?? '';
      final close = h['@fermeture']?.toString().trim() ?? '';
      if (open.isEmpty || close.isEmpty) continue;
      parts.add('$nom$open-$close');
    }
  }

  if (parts.isEmpty && !automate24h) return null;
  return (joined: parts.isEmpty ? null : parts.join(', '), automate24h: automate24h);
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
