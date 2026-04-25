/// Pure parsing helpers for the CNE "Bencina en Línea" envelope (#596,
/// #563 split). Lives separately from `ChileStationService` so the
/// JSON-shape contract — which is what the live endpoint typically
/// breaks first — can be exercised with recorded fixtures, without
/// touching Dio, Hive, or any network state. Adding network or storage
/// imports here defeats the point of the split.
///
/// Public surface:
///  - [parseChileStationsResponse]: top-level envelope → list of
///    [Station]. Drops entries with missing/zero coordinates.
///  - [fuelForChileProductKey]: the canonical CNE product-key →
///    [FuelType] mapping (case-insensitive).
///  - [chileDroppedProductKeys]: keys we deliberately ignore until
///    matching enums land (e.g. `kerosene`).
library;

import '../../../features/search/domain/entities/fuel_type.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../error/exceptions.dart';
import '../../utils/geo_utils.dart';

/// CNE product keys → our canonical [FuelType].
///
/// Five products ship today; kerosene has no enum yet and is
/// intentionally omitted so the parser skips it silently.
///
/// Gasolina 93 and Gasolina 95 both map to [FuelType.e5]. Chilean
/// petrol cars fill with either octane grade; 95 is the closer
/// benchmark to the European E5 RON-95 and wins when both prices are
/// quoted for the same station (see [_parsePrices]).
const Map<String, FuelType> _chileProductKeyToFuel = {
  'gasolina_93': FuelType.e5,
  'gasolina_95': FuelType.e5,
  'gasolina_97': FuelType.e98,
  'diesel': FuelType.diesel,
  'glp': FuelType.lpg,
  // Some deployments use `gas_licuado` instead of `glp`; accept both.
  'gas_licuado': FuelType.lpg,
};

/// Product keys we deliberately drop because no [FuelType] exists yet.
/// Exposed so tests can pin the MVP policy.
const Set<String> chileDroppedProductKeys = {'kerosene', 'parafina'};

/// CNE product key → [FuelType] (case-insensitive). Returns `null`
/// when the key has no matching slot today (kerosene / parafina /
/// unknown).
FuelType? fuelForChileProductKey(String productKey) =>
    _chileProductKeyToFuel[productKey.toLowerCase()];

/// Parse the CNE "estaciones" envelope into [Station] instances.
///
/// The CNE envelope shape we depend on is:
/// ```json
/// { "data": [ { "codigo": ..., "ubicacion": {...}, "precios": {...} }, ... ] }
/// ```
/// Anything else (a top-level non-map, an `{error: "..."}` with no `data`)
/// raises [ApiException]; an empty / missing `data` array yields an
/// empty list.
List<Station> parseChileStationsResponse(
  dynamic data, {
  required double fromLat,
  required double fromLng,
}) {
  final parsed = _coerceMap(data);
  if (parsed == null) {
    throw const ApiException(message: 'CNE returned unparseable body');
  }

  // Propagate a CNE-level error. When auth fails the API usually
  // returns a JSON body with `error` or `message` set and an HTTP
  // 401/403 (caught in the service shell), but some proxies return
  // 200 + error.
  final errField = parsed['error'] ?? parsed['message'];
  if (errField != null && parsed['data'] == null) {
    throw ApiException(message: 'CNE error: $errField');
  }

  final list = parsed['data'];
  if (list is! List) return const [];

  final stations = <Station>[];
  for (final raw in list) {
    if (raw is! Map) continue;
    final s = _parseOneStation(raw, fromLat: fromLat, fromLng: fromLng);
    if (s != null) stations.add(s);
  }
  return stations;
}

// ──────────────────────────────────────────────────────────────────────
// Internals
// ──────────────────────────────────────────────────────────────────────

Station? _parseOneStation(
  Map raw, {
  required double fromLat,
  required double fromLng,
}) {
  final idRaw = (raw['codigo'] ?? raw['id'] ?? raw['id_estacion'])?.toString();
  if (idRaw == null || idRaw.isEmpty) return null;

  // CNE `ubicacion` holds `latitud` / `longitud`. Some mirrored feeds
  // use flat `latitud` / `longitud` on the station — accept both.
  final ubi = raw['ubicacion'];
  final lat = _parseDouble(ubi is Map ? ubi['latitud'] : raw['latitud']);
  final lng = _parseDouble(ubi is Map ? ubi['longitud'] : raw['longitud']);
  if (lat == null || lng == null) return null;
  if (lat == 0 && lng == 0) return null;

  final brand = _parseBrand(raw);
  final nameRaw =
      (raw['nombre_fantasia'] ?? raw['nombre'])?.toString().trim();
  final name = (nameRaw != null && nameRaw.isNotEmpty) ? nameRaw : brand;

  final street = _joinStreet(raw);
  final comuna = raw['nombre_comuna']?.toString().trim() ?? '';

  final prices = _parsePrices(raw);

  final distKm = _roundedDistance(fromLat, fromLng, lat, lng);

  // Stable 'cl-' prefix so the favorites currency lookup finds CL.
  final id = idRaw.startsWith('cl-') ? idRaw : 'cl-$idRaw';

  return Station(
    id: id,
    name: name,
    brand: brand,
    street: street,
    postCode: '',
    place: comuna,
    lat: lat,
    lng: lng,
    dist: distKm,
    e5: prices[FuelType.e5],
    e98: prices[FuelType.e98],
    diesel: prices[FuelType.diesel],
    lpg: prices[FuelType.lpg],
    isOpen: _isOpen(raw),
  );
}

Map<FuelType, double> _parsePrices(Map raw) {
  final out = <FuelType, double>{};
  final precios = raw['precios'];
  if (precios is! Map) return out;

  // Walk every quoted product, mapping known keys to a [FuelType].
  // Unknown keys are silently ignored so upstream additions (EV at
  // CNE? future biofuels?) don't break the parser.
  precios.forEach((key, value) {
    final k = key.toString().toLowerCase();
    final price = _parsePesoPerLitre(value);
    if (price == null) return;

    final fuel = _chileProductKeyToFuel[k];
    if (fuel == null) return; // kerosene / parafina / unknown → drop

    // Merge 93 + 95 into e5. When both are quoted we prefer 95
    // (closer to the European E5 RON-95 benchmark).
    if (fuel == FuelType.e5) {
      final existing = out[FuelType.e5];
      if (existing == null) {
        out[FuelType.e5] = price;
      } else if (k == 'gasolina_95') {
        // 95 wins over a previously-inserted 93.
        out[FuelType.e5] = price;
      }
      return;
    }

    out[fuel] = price;
  });
  return out;
}

/// CNE prices are pesos per litre (e.g. `1290.0` CLP/L). Chilean
/// pesos have no decimals in daily use; keep the raw numeric value
/// as the local-currency unit the forecourt sign shows. No scaling.
double? _parsePesoPerLitre(dynamic raw) {
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

/// CNE nests the distributor under `distribuidor.nombre`; older
/// payloads use a flat `distribuidor` string. Accept both.
String _parseBrand(Map raw) {
  final dist = raw['distribuidor'];
  if (dist is Map) {
    final n = dist['nombre']?.toString().trim();
    if (n != null && n.isNotEmpty) return n;
  } else if (dist is String && dist.trim().isNotEmpty) {
    return dist.trim();
  }
  final marca = raw['marca']?.toString().trim();
  if (marca != null && marca.isNotEmpty) return marca;
  return 'Independent';
}

String _joinStreet(Map raw) {
  final calle = raw['direccion_calle']?.toString().trim() ?? '';
  final numero = raw['direccion_numero']?.toString().trim() ?? '';
  if (calle.isEmpty && numero.isEmpty) return '';
  if (numero.isEmpty) return calle;
  if (calle.isEmpty) return numero;
  return '$calle $numero';
}

/// CNE does not expose a reliable open/closed flag per station — the
/// `horario_atencion` field often reads `"24_horas"` or a free-text
/// schedule. We treat stations as open by default and fall back to
/// `false` only when the field explicitly says `cerrado`.
bool _isOpen(Map raw) {
  final h = raw['horario_atencion']?.toString().toLowerCase().trim();
  if (h == null || h.isEmpty) return true;
  if (h.contains('cerrado')) return false;
  return true;
}

/// Haversine distance in km, rounded to one decimal — mirrors
/// `StationServiceHelpers.roundedDistance` so the parser stays free of
/// the mixin's HTTP/result-wrapping baggage.
double _roundedDistance(double lat1, double lng1, double lat2, double lng2) {
  final d = distanceKm(lat1, lng1, lat2, lng2);
  return double.parse(d.toStringAsFixed(1));
}
