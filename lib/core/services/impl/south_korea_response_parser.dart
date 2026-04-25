/// Pure parsing helpers for the OPINET (KNOC) `aroundAll.do` envelope
/// (#597, #563 split). Lives separately from `SouthKoreaStationService`
/// so the JSON-shape contract — which is what the live endpoint
/// typically breaks first — can be exercised with recorded fixtures,
/// without touching Dio or any network state. Adding network or storage
/// imports here defeats the point of the split.
///
/// Public surface:
///  - [OpinetProductCodes]: the canonical OPINET product-code →
///    [FuelType] mapping plus the static `lookup` helper that
///    `SouthKoreaStationService.fuelForProductCode` delegates to.
///  - [OpinetStationAccumulator]: in-flight merge target while the
///    service walks the four product-code calls (gasoline, premium,
///    diesel, LPG).
///  - [mergeOpinetProductResponse]: drains one product's
///    `RESULT.OIL[]` array into a `Map<UNI_ID, OpinetStationAccumulator>`.
library;

import '../../../features/search/domain/entities/fuel_type.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../error/exceptions.dart';
import '../../utils/geo_utils.dart';

/// OPINET `prodcd` parsing utilities.
///
/// Single source of truth for how OPINET product codes map onto
/// canonical [FuelType] values. Kerosene (`C004`) is intentionally
/// absent; the service never issues a request for it and the parser
/// silently skips any payload that arrives.
class OpinetProductCodes {
  OpinetProductCodes._();

  /// OPINET product codes → our canonical [FuelType].
  ///
  /// The four we ship today; kerosene (`C004`) has no enum yet and is
  /// intentionally omitted so the parser skips it silently.
  static const Map<String, FuelType> fuelForProductCode = {
    'B027': FuelType.e5, // Gasoline (휘발유)
    'B034': FuelType.e98, // Premium Gasoline (고급휘발유)
    'D047': FuelType.diesel, // Diesel (경유)
    'K015': FuelType.lpg, // LPG (부탄)
  };

  /// Returns the [FuelType] for an OPINET `prodcd`, or `null` for
  /// unknown / intentionally dropped codes (e.g. kerosene `C004`).
  static FuelType? lookup(String productCode) =>
      fuelForProductCode[productCode];
}

/// In-flight accumulator while merging per-product OPINET responses.
///
/// Each OPINET `aroundAll.do` call returns prices for a single product
/// only; the service fires four calls (gasoline, premium gasoline,
/// diesel, LPG) and folds them into a single [Station] per `UNI_ID`
/// using one accumulator per station.
class OpinetStationAccumulator {
  final String uniId;
  String? brandCode; // POLL_DIV_CD (SKE, GS, HDO, …)
  String? name; // OS_NM
  String? address; // NEW_ADR
  double? lat; // GIS_Y_COOR
  double? lng; // GIS_X_COOR
  double? apiDistanceKm; // DISTANCE (meters → km)
  final Map<FuelType, double> prices = <FuelType, double>{};

  OpinetStationAccumulator({required this.uniId});

  /// Pull the address / coords / distance fields off the first
  /// product-call payload that carries them. Subsequent calls for the
  /// same `UNI_ID` only update the price map.
  void absorbBase(Map raw) {
    brandCode ??= raw['POLL_DIV_CD']?.toString();
    name ??= raw['OS_NM']?.toString().trim();
    address ??= raw['NEW_ADR']?.toString().trim();

    lat ??= _parseDouble(raw['GIS_Y_COOR']);
    lng ??= _parseDouble(raw['GIS_X_COOR']);

    final distRaw = raw['DISTANCE'];
    final distMeters = _parseDouble(distRaw);
    if (distMeters != null && distMeters > 0) {
      final km = double.parse((distMeters / 1000.0).toStringAsFixed(1));
      apiDistanceKm ??= km;
    }
  }

  /// Materialize the accumulated state into a [Station]. Returns
  /// `null` when coordinates are missing or both zero (bad upstream
  /// data — silently dropped).
  Station? toStation(double fromLat, double fromLng) {
    final resolvedLat = lat;
    final resolvedLng = lng;
    if (resolvedLat == null || resolvedLng == null) return null;
    if (resolvedLat == 0 && resolvedLng == 0) return null;

    final brand = _brandFromCode(brandCode);
    final distKm = apiDistanceKm ??
        _roundedDistance(fromLat, fromLng, resolvedLat, resolvedLng);

    return Station(
      id: 'kr-$uniId',
      name: name?.isNotEmpty == true ? name! : brand,
      brand: brand,
      street: address ?? '',
      postCode: '',
      place: '',
      lat: resolvedLat,
      lng: resolvedLng,
      dist: distKm,
      e5: prices[FuelType.e5],
      e98: prices[FuelType.e98],
      diesel: prices[FuelType.diesel],
      lpg: prices[FuelType.lpg],
      isOpen: true, // OPINET does not expose a reliable open/closed flag
    );
  }
}

/// Drain one OPINET single-product response into [byId], merging on
/// `UNI_ID` so the same station gathers prices across the four
/// product-code calls.
///
/// Throws [ApiException] on:
///  - a non-map top-level payload (proxy garbage, HTML error pages),
///  - an OPINET-level `ERROR` field (auth failure with HTTP 200).
///
/// A missing / empty `RESULT.OIL` array is treated as "no stations
/// for this product" and silently returned.
void mergeOpinetProductResponse(
  dynamic data,
  Map<String, OpinetStationAccumulator> byId,
  FuelType fuelType,
) {
  final parsed = _coerceMap(data);
  if (parsed == null) {
    throw const ApiException(message: 'OPINET returned unparseable body');
  }

  // Propagate an OPINET-level error (RESULT.OIL is always a list on
  // success; when auth fails OPINET returns `{"RESULT":{"OIL":[]}}`
  // with an HTTP 200 and sometimes a top-level `ERROR` field).
  final errField = parsed['ERROR'];
  if (errField != null) {
    throw ApiException(message: 'OPINET error: $errField');
  }

  final result = parsed['RESULT'];
  if (result is! Map) return; // tolerate empty
  final oil = result['OIL'];
  if (oil is! List) return;

  for (final raw in oil) {
    if (raw is! Map) continue;
    final uniId = raw['UNI_ID']?.toString();
    if (uniId == null || uniId.isEmpty) continue;

    final acc = byId.putIfAbsent(
      uniId,
      () => OpinetStationAccumulator(uniId: uniId),
    );
    acc.absorbBase(raw);

    final priceRaw = raw['PRICE'];
    final price = _parseWonPerLitre(priceRaw);
    if (price != null) acc.prices[fuelType] = price;
  }
}

// ──────────────────────────────────────────────────────────────────────
// Internals
// ──────────────────────────────────────────────────────────────────────

/// OPINET prices are integer strings in **KRW per litre** (e.g.
/// `"1689"` = ₩1 689/L). Tankstellen holds prices as `double` in the
/// local currency unit, matching what the forecourt sign shows. No
/// scaling is applied — we keep KRW/L as-is.
double? _parseWonPerLitre(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) {
    if (raw <= 0) return null;
    return raw.toDouble();
  }
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final v = double.tryParse(trimmed);
    if (v == null || v <= 0) return null;
    return v;
  }
  return null;
}

double? _parseDouble(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  if (raw is String) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }
  return null;
}

Map? _coerceMap(dynamic data) {
  if (data is Map) return data;
  return null;
}

/// Map OPINET `POLL_DIV_CD` codes to forecourt brand labels. Covers
/// the four "refiners" that dominate the Korean market plus the
/// generic independent label (`RTO`, `ETC`).
String _brandFromCode(String? code) {
  switch (code) {
    case 'SKE':
      return 'SK에너지';
    case 'GSC':
      return 'GS칼텍스';
    case 'HDO':
      return '현대오일뱅크';
    case 'SOL':
      return 'S-OIL';
    case 'RTO':
      return '알뜰주유소';
    case 'NHO':
      return 'NH농협';
    case 'ETC':
    case null:
    case '':
      return 'Independent';
    default:
      return code;
  }
}

/// Haversine distance in km, rounded to one decimal — mirrors
/// `StationServiceHelpers.roundedDistance` so the parser stays free of
/// the mixin's HTTP/result-wrapping baggage.
double _roundedDistance(double lat1, double lng1, double lat2, double lng2) {
  final d = distanceKm(lat1, lng1, lat2, lng2);
  return double.parse(d.toStringAsFixed(1));
}
