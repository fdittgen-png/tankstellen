import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/fuel_type.dart';
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
  /// The Observatory's enum name (e.g. `ATTICA`, `THESSALONIKI`).
  /// Plugged straight into `/data/daily/prefecture/{apiName}`.
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

/// Observatory `fuel_type` parsing utilities.
///
/// Single source of truth for how the Paratiritirio Timon enum maps
/// onto canonical [FuelType] values, plus the policy of which keys
/// are intentionally dropped (`DIESEL_HEATING`, `SUPER`).
class GreeceObservatoryKeys {
  GreeceObservatoryKeys._();

  /// Observatory `fuel_type` enum → canonical [FuelType].
  ///
  /// `DIESEL_HEATING` and `SUPER` are intentionally absent from the
  /// map. [droppedObservatoryKeys] pins the policy for tests.
  static const Map<String, FuelType> fuelForObservatoryKey = {
    'unleaded_95': FuelType.e5,
    'unleaded_100': FuelType.e98,
    'diesel': FuelType.diesel,
    'gas': FuelType.lpg,
  };

  /// Keys the parser deliberately drops because no [FuelType] exists
  /// (DIESEL_HEATING is not a motoring fuel; SUPER is phased-out
  /// leaded).
  static const Set<String> droppedObservatoryKeys = {
    'diesel_heating',
    'super',
  };

  /// Case-insensitive lookup for the Observatory `fuel_type` enum.
  /// Returns `null` for unknown keys and for the intentionally
  /// dropped keys ([droppedObservatoryKeys]).
  static FuelType? lookup(String key) =>
      fuelForObservatoryKey[key.toLowerCase()];

  /// Parse the `data: [...]` array of a `PriceResponse` envelope into
  /// a [FuelType] → EUR-per-litre map. Unknown keys, dropped keys
  /// (`DIESEL_HEATING`, `SUPER`), zero / negative prices, and
  /// non-numeric prices are silently filtered out.
  static Map<FuelType, double> parsePrices(dynamic rawData) {
    final out = <FuelType, double>{};
    if (rawData is! List) return out;
    for (final row in rawData) {
      if (row is! Map) continue;
      final key = row['fuel_type']?.toString() ?? '';
      if (key.isEmpty) continue;
      final fuel = lookup(key);
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
