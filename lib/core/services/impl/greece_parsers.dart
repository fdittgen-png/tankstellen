/// Pure parsing helpers for the Greek Paratiritirio Timon (Fuel Price
/// Observatory) feed exposed via the community
/// [fuelpricesgr](https://github.com/mavroprovato/fuelpricesgr) FastAPI
/// wrapper (#576, #563 split).
///
/// Lives separately from [GreeceStationService] so the JSON-shape
/// contract — which is what the live endpoint typically breaks first —
/// can be exercised with recorded fixtures, without touching Dio, Hive,
/// or any network state. Adding network or storage imports here defeats
/// the point of the split.
///
/// Public surface:
///  - [parsePrefectureResponse]: prefecture daily-price envelope →
///    synthetic [Station] (or `null` when nothing usable came back).
///  - [fuelForObservatoryKey]: the canonical Observatory `fuel_type`
///    enum → [FuelType] mapping (case-insensitive).
///  - [droppedObservatoryKeys]: keys we deliberately ignore because no
///    [FuelType] enum exists today (DIESEL_HEATING, SUPER).
///  - [GreekPrefecture]: data class for the static prefecture catalog
///    used as virtual stations.
library;

import '../../../features/search/domain/entities/fuel_type.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../error/exceptions.dart';
import '../mixins/station_service_helpers.dart';

/// Observatory fuel_type enum → canonical [FuelType].
///
/// `DIESEL_HEATING` and `SUPER` are intentionally absent from the
/// map. [droppedObservatoryKeys] pins the policy for tests.
const Map<String, FuelType> _fuelForObservatoryKey = {
  'unleaded_95': FuelType.e5,
  'unleaded_100': FuelType.e98,
  'diesel': FuelType.diesel,
  'gas': FuelType.lpg,
};

/// Keys the parser deliberately drops because no [FuelType] exists
/// (DIESEL_HEATING is not a motoring fuel; SUPER is phased-out
/// leaded).
const Set<String> droppedObservatoryKeys = {
  'diesel_heating',
  'super',
};

/// Observatory fuel-key → [FuelType] (case-insensitive). Returns
/// `null` when the key has no matching slot today
/// (DIESEL_HEATING / SUPER / unknown).
FuelType? fuelForObservatoryKey(String key) =>
    _fuelForObservatoryKey[key.toLowerCase()];

/// Parse a single prefecture's daily response into a synthetic
/// [Station]. Driven by fixtures so it is independent of any Dio mock.
///
/// The response is either:
/// - A list of `PriceResponse` objects (most recent first), or
/// - An empty list when the prefecture has no recent data.
///
/// We pick the most recent entry (greatest ISO-8601 `date` string —
/// lexicographic order works) and stamp its fuel prices onto the
/// virtual station.
///
/// The prefecture is addressed by its stable `stationId` so callers do
/// not need access to the [GreekPrefecture] catalog.
Station? parsePrefectureResponse(
  dynamic data, {
  required String stationId,
  required String displayName,
  required String place,
  required double prefectureLat,
  required double prefectureLng,
  required double fromLat,
  required double fromLng,
}) {
  final list = _coerceList(data);
  if (list == null) {
    throw const ApiException(
      message: 'Paratiritirio returned unparseable body',
    );
  }

  // Empty list is valid — just means no recent data for this
  // prefecture. Drop the station (a synthetic entry with no prices
  // would clutter the list).
  if (list.isEmpty) return null;

  // Prefer the newest entry. The community API documents "most recent
  // first" but we defend against order drift by picking the entry with
  // the greatest `date` string (ISO-8601 lexicographic order works).
  Map? newest;
  String newestDate = '';
  for (final item in list) {
    if (item is! Map) continue;
    final date = item['date']?.toString() ?? '';
    if (date.compareTo(newestDate) > 0) {
      newestDate = date;
      newest = item;
    }
  }
  if (newest == null) return null;

  final prices = _parsePrices(newest['data']);
  // A prefecture with zero recognised fuel rows is dropped — no
  // synthetic pin for "nothing to show".
  if (prices.isEmpty) return null;

  return Station(
    id: stationId,
    name: displayName,
    brand: 'Paratiritirio',
    street: '',
    postCode: '',
    place: place,
    lat: prefectureLat,
    lng: prefectureLng,
    dist: _roundedDistance(fromLat, fromLng, prefectureLat, prefectureLng),
    e5: prices[FuelType.e5],
    e98: prices[FuelType.e98],
    diesel: prices[FuelType.diesel],
    lpg: prices[FuelType.lpg],
    isOpen: true,
    updatedAt: newestDate.isEmpty ? null : newestDate,
  );
}

// ──────────────────────────────────────────────────────────────────────
// Internals
// ──────────────────────────────────────────────────────────────────────

Map<FuelType, double> _parsePrices(dynamic rawData) {
  final out = <FuelType, double>{};
  if (rawData is! List) return out;
  for (final row in rawData) {
    if (row is! Map) continue;
    final key = row['fuel_type']?.toString() ?? '';
    if (key.isEmpty) continue;
    final fuel = _fuelForObservatoryKey[key.toLowerCase()];
    if (fuel == null) continue; // unknown / intentionally dropped
    final price = _parseEuroPerLitre(row['price']);
    if (price == null) continue;
    out[fuel] = price;
  }
  return out;
}

/// Observatory prices are EUR per litre with up to three decimals
/// (e.g. `1.721`). Accepts `num` and numeric strings. Rejects zero
/// and negative values.
double? _parseEuroPerLitre(dynamic raw) {
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

List? _coerceList(dynamic data) {
  if (data is List) return data;
  return null;
}

/// Mirrors [StationServiceHelpers.roundedDistance] so the parser stays
/// free of the mixin's HTTP/result-wrapping baggage.
///
/// Implemented as a thin wrapper that constructs a throwaway helper
/// instance via the [_DistanceOnly] shim — keeps the haversine in one
/// place and avoids re-deriving it here.
double _roundedDistance(double lat1, double lng1, double lat2, double lng2) {
  return _distanceHelper.roundedDistance(lat1, lng1, lat2, lng2);
}

final _DistanceOnly _distanceHelper = _DistanceOnly();

/// Tiny shim so the parser can use the shared haversine in
/// [StationServiceHelpers] without dragging in a Dio/result-wrapping
/// service shell.
class _DistanceOnly with StationServiceHelpers {}

/// Internal representation of a Greek prefecture used as a virtual
/// station. Public so the catalog can live in this parser file but
/// the prefix underscore on the service-side wrapper is preserved by
/// only ever exposing fully-built [Station] objects to callers above
/// the service shell.
class GreekPrefecture {
  final String apiName;
  final String id;
  final String displayName;
  final String place;
  final double lat;
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
/// from anywhere in Greece hits at least one entry within a
/// sensible radius, without flooding the map with 50+ synthetic
/// pins.
const List<GreekPrefecture> greekPrefectures = [
  GreekPrefecture(
    apiName: 'ATTICA',
    id: 'gr-attica',
    displayName: 'Αττική / Attica',
    place: 'Αθήνα',
    lat: 37.9838,
    lng: 23.7275,
  ),
  GreekPrefecture(
    apiName: 'THESSALONIKI',
    id: 'gr-thessaloniki',
    displayName: 'Θεσσαλονίκη / Thessaloniki',
    place: 'Θεσσαλονίκη',
    lat: 40.6401,
    lng: 22.9444,
  ),
  GreekPrefecture(
    apiName: 'ACHAEA',
    id: 'gr-achaea',
    displayName: 'Αχαΐα / Achaea',
    place: 'Πάτρα',
    lat: 38.2466,
    lng: 21.7346,
  ),
  GreekPrefecture(
    apiName: 'LARISSA',
    id: 'gr-larissa',
    displayName: 'Λάρισα / Larissa',
    place: 'Λάρισα',
    lat: 39.6390,
    lng: 22.4191,
  ),
  GreekPrefecture(
    apiName: 'HERAKLION',
    id: 'gr-heraklion',
    displayName: 'Ηράκλειο / Heraklion',
    place: 'Ηράκλειο',
    lat: 35.3387,
    lng: 25.1442,
  ),
  GreekPrefecture(
    apiName: 'IOANNINA',
    id: 'gr-ioannina',
    displayName: 'Ιωάννινα / Ioannina',
    place: 'Ιωάννινα',
    lat: 39.6650,
    lng: 20.8537,
  ),
  GreekPrefecture(
    apiName: 'DODECANESE',
    id: 'gr-dodecanese',
    displayName: 'Δωδεκάνησα / Dodecanese',
    place: 'Ρόδος',
    lat: 36.4349,
    lng: 28.2176,
  ),
  GreekPrefecture(
    apiName: 'CHANIA',
    id: 'gr-chania',
    displayName: 'Χανιά / Chania',
    place: 'Χανιά',
    lat: 35.5138,
    lng: 24.0180,
  ),
];
