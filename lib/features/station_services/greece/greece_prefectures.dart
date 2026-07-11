// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/domain/search_params.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/utils/geo_utils.dart';

/// Internal data representation of a Greek prefecture used by
/// [GreeceStationService] as a virtual station.
///
/// The Greek Paratiritirio Timon feed publishes daily / weekly fuel
/// prices at *prefecture* (νομός) granularity — there is no
/// per-station breakdown — so each prefecture surfaces as a single
/// synthetic [Station] stamped with that prefecture's most recent
/// daily mean. See `greece_station_service.dart` for the contract.
class GreekPrefecture {
  /// The observatory-mirror `REGION` code (e.g. `N. ATHINON`,
  /// `N. THESSALONIKIS` — `N.` = Νομός, transliterated) as published by
  /// the emvouvakis FuelPricesGreeceAPI rows (#3539). Matched against
  /// each row's `REGION` column.
  final String apiName;

  /// Stable Tankstellen-side station id (e.g. `gr-attica`). The
  /// `gr-` prefix is what `Countries.countryCodeForStationId` keys
  /// off — must not change without touching the favorites/currency
  /// lookup.
  final String id;

  /// Bilingual label shown in the UI: native Greek + Latin
  /// transliteration (e.g. `Αττική / Attica`).
  final String displayName;

  /// Capital of the prefecture, used as the synthetic station's
  /// `place` field.
  final String place;

  /// Latitude of the prefecture's capital (OpenStreetMap).
  final double lat;

  /// Longitude of the prefecture's capital (OpenStreetMap).
  final double lng;

  const GreekPrefecture({
    required this.apiName,
    required this.id,
    required this.displayName,
    required this.place,
    required this.lat,
    required this.lng,
  });
}

/// Representative prefectures used as virtual stations. Coordinates
/// are each prefecture's capital (OpenStreetMap). The set is
/// deliberately small and geographically spread so a user searching
/// from anywhere in Greece hits at least one entry within a sensible
/// radius, without flooding the map with 50+ synthetic pins.
const List<GreekPrefecture> kGreekPrefectures = [
  GreekPrefecture(
    apiName: 'N. ATHINON',
    id: 'gr-attica',
    displayName: 'Αττική / Attica',
    place: 'Αθήνα',
    lat: 37.9838,
    lng: 23.7275,
  ),
  GreekPrefecture(
    apiName: 'N. THESSALONIKIS',
    id: 'gr-thessaloniki',
    displayName: 'Θεσσαλονίκη / Thessaloniki',
    place: 'Θεσσαλονίκη',
    lat: 40.6401,
    lng: 22.9444,
  ),
  GreekPrefecture(
    apiName: 'N. ACHAIAS',
    id: 'gr-achaea',
    displayName: 'Αχαΐα / Achaea',
    place: 'Πάτρα',
    lat: 38.2466,
    lng: 21.7346,
  ),
  GreekPrefecture(
    apiName: 'N. LARISAS',
    id: 'gr-larissa',
    displayName: 'Λάρισα / Larissa',
    place: 'Λάρισα',
    lat: 39.6390,
    lng: 22.4191,
  ),
  GreekPrefecture(
    apiName: 'N. IRAKLIOU',
    id: 'gr-heraklion',
    displayName: 'Ηράκλειο / Heraklion',
    place: 'Ηράκλειο',
    lat: 35.3387,
    lng: 25.1442,
  ),
  GreekPrefecture(
    apiName: 'N. IOANNINON',
    id: 'gr-ioannina',
    displayName: 'Ιωάννινα / Ioannina',
    place: 'Ιωάννινα',
    lat: 39.6650,
    lng: 20.8537,
  ),
  GreekPrefecture(
    apiName: 'N. DODEKANISON',
    id: 'gr-dodecanese',
    displayName: 'Δωδεκάνησα / Dodecanese',
    place: 'Ρόδος',
    lat: 36.4349,
    lng: 28.2176,
  ),
  GreekPrefecture(
    apiName: 'N. CHANION',
    id: 'gr-chania',
    displayName: 'Χανιά / Chania',
    place: 'Χανιά',
    lat: 35.5138,
    lng: 24.0180,
  ),
];

/// Observatory `fuel_type` parsing utilities.
///
/// Single source of truth for how the Paratiritirio Timon enum maps
/// onto canonical [FuelType] values, plus the policy of which keys
/// are intentionally dropped (`DIESEL_HEATING`, `SUPER`).
class GreeceObservatoryKeys {
  GreeceObservatoryKeys._();

  /// Observatory-mirror row column → canonical [FuelType] (#3539 — the
  /// emvouvakis API publishes one row per prefecture per day with one
  /// COLUMN per fuel, unlike the old fuelpricesgr `fuel_type` array).
  ///
  /// `HOME_HEATING_DIESEL` and `Super` are intentionally absent from
  /// the map. [droppedObservatoryKeys] pins the policy for tests.
  static const Map<String, FuelType> fuelForObservatoryKey = {
    'unleaded_95_octane': FuelType.e5,
    'unleaded_100_octane': FuelType.e98,
    'automotive_diesel': FuelType.diesel,
    'autogas': FuelType.lpg,
  };

  /// Columns the parser deliberately drops because no [FuelType] exists
  /// (HOME_HEATING_DIESEL is not a motoring fuel; Super is phased-out
  /// leaded) — plus the non-fuel `DATE` / `REGION` envelope columns.
  static const Set<String> droppedObservatoryKeys = {
    'home_heating_diesel',
    'super',
    'date',
    'region',
  };

  /// Case-insensitive lookup for a row column name. Returns `null`
  /// for unknown columns and for the intentionally dropped ones
  /// ([droppedObservatoryKeys]).
  static FuelType? lookup(String key) =>
      fuelForObservatoryKey[key.toLowerCase()];

  /// Parse one prefecture-day row (a map of fuel columns, #3539) into
  /// a [FuelType] → EUR-per-litre map. Unknown columns, dropped
  /// columns (`HOME_HEATING_DIESEL`, `Super`, the `DATE` / `REGION`
  /// envelope), nulls (the API publishes `null` for fuels a prefecture
  /// did not report that day), zero / negative prices, and non-numeric
  /// prices are silently filtered out.
  static Map<FuelType, double> parsePrices(dynamic rawRow) {
    final out = <FuelType, double>{};
    if (rawRow is! Map) return out;
    for (final entry in rawRow.entries) {
      final fuel = lookup(entry.key.toString());
      if (fuel == null) continue; // unknown / intentionally dropped
      final price = _parseEuroPerLitre(entry.value);
      if (price == null) continue;
      out[fuel] = price;
    }
    return out;
  }

  /// Observatory prices are EUR per litre with up to three decimals
  /// (e.g. `1.721`). Accepts `num` and numeric strings. Rejects zero
  /// and negative values.
  static double? _parseEuroPerLitre(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) {
      if (raw <= 0) return null;
      return raw.toDouble();
    }
    if (raw is String) {
      final t = raw.trim();
      if (t.isEmpty) return null;
      final v = double.tryParse(t);
      if (v == null || v <= 0) return null;
      return v;
    }
    return null;
  }
}

/// Order [all] so the prefectures nearest to [params] come first,
/// then take the four closest. Keeps us from fanning out to the
/// entire country with eight serial HTTP calls when the user is
/// standing in one prefecture.
List<GreekPrefecture> prefecturesForQuery(
  SearchParams params,
  List<GreekPrefecture> all,
) {
  final ordered = List<GreekPrefecture>.from(all)
    ..sort((a, b) {
      final da = distanceKm(params.lat, params.lng, a.lat, a.lng);
      final db = distanceKm(params.lat, params.lng, b.lat, b.lng);
      return da.compareTo(db);
    });
  // Fetch the four closest prefectures. Covers the mainland / island
  // cases without making 8 serial HTTP calls per search.
  return ordered.take(4).toList();
}
