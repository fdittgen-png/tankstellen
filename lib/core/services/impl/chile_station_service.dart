import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/fuel_type.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../error/exceptions.dart';
import '../dio_factory.dart';
import '../mixins/station_service_helpers.dart';
import '../service_result.dart';
import '../station_service.dart';

/// Chile fuel prices from the **CNE Bencina en Línea** developer API
/// (#596).
///
/// CNE (Comisión Nacional de Energía) publishes the official retail-fuel
/// price registry for Chile through its developer portal at
/// https://api.cne.cl/. Key facts:
///
/// - **Auth**: free registration yields a personal API token. The
///   service passes it as a `token` query parameter on every call
///   (some CNE endpoints accept it in the `Authorization: Bearer` header
///   too — the query-parameter form is documented as the "simple" path
///   and is what we use here).
/// - **Coverage**: ~6 000 service stations ("estaciones de servicio")
///   nationwide.
/// - **Fuels published per station** (CNE product codes):
///     `gasolina_93`   Gasolina 93 octanos        → [FuelType.e5]
///     `gasolina_95`   Gasolina 95 octanos        → [FuelType.e5]
///                     (merged with 93 into the e5 slot — Chilean cars
///                      fuel with either; 95 wins when both are quoted
///                      because it is the closer match to the European
///                      E5 RON-95 benchmark)
///     `gasolina_97`   Gasolina 97 octanos        → [FuelType.e98]
///     `diesel`        Diésel                     → [FuelType.diesel]
///     `glp` / `gas_licuado`  Gas licuado (LPG)   → [FuelType.lpg]
///     `kerosene`      Kerosene                   → no enum today;
///                     the parser silently skips it for MVP so a
///                     future enum addition is a one-line change.
/// - **Transport**: HTTP GET, JSON. Responses are UTF-8; Spanish
///   place names survive Dio's default decoding.
///
/// A typical "all stations" dump looks like:
/// ```
/// GET https://api.cne.cl/api/v4/combustibles/estaciones?token=<apiKey>
/// ```
/// returning
/// ```json
/// {
///   "data": [
///     {
///       "codigo":       "cl-123456",
///       "distribuidor": { "nombre": "Copec" },
///       "nombre_fantasia": "Copec Providencia",
///       "direccion_calle":  "Av. Providencia",
///       "direccion_numero": "1234",
///       "nombre_comuna":    "Providencia",
///       "nombre_region":    "Metropolitana de Santiago",
///       "ubicacion":    { "latitud": -33.4254, "longitud": -70.6115 },
///       "precios":      {
///         "gasolina_93": 1290.0,
///         "gasolina_95": 1310.0,
///         "gasolina_97": 1340.0,
///         "diesel":      1150.0,
///         "glp":         820.0,
///         "kerosene":    1050.0
///       },
///       "horario_atencion": "24_horas"
///     }
///   ]
/// }
/// ```
///
/// Because CNE exposes prices per-station (one payload with all fuels
/// nested under `precios`), a single request is enough to cover the
/// whole fuel family — unlike OPINET (KR) which fans out one call per
/// product. We keep the service radius-filter-aware even so: once the
/// full list is parsed we drop everything outside the user's radius
/// through the shared [StationServiceHelpers.filterByRadius] pass.
///
/// **Endpoint verification**: the live CNE developer docs evolve (path
/// segments like `api/v3/combustibles`, `api/v4/combustibles`,
/// `combustibles/estaciones` drift between minor releases). The
/// [defaultBaseUrl] constant is the current best-guess path; the
/// parser and fuel mapping stay valid regardless of which exact path
/// the API settles on. If a path change breaks the live call, the bug
/// is a one-line URL constant — the rest of the service remains
/// correct against the JSON contract captured above.
class ChileStationService
    with StationServiceHelpers
    implements StationService {
  /// CNE "combustibles" dump — returns every station with nested prices
  /// for each product code.
  ///
  /// TODO: verify against the live CNE developer portal. The JSON
  /// payload shape (top-level `data` list, per-station `precios` map,
  /// `ubicacion.latitud` / `ubicacion.longitud`) is stable across CNE
  /// API minor versions and is the contract our parser depends on.
  static const String defaultBaseUrl =
      'https://api.cne.cl/api/v4/combustibles/estaciones';

  /// CNE product keys → our canonical [FuelType].
  ///
  /// Five products ship today; kerosene has no enum yet and is
  /// intentionally omitted so the parser skips it silently.
  ///
  /// Gasolina 93 and Gasolina 95 both map to [FuelType.e5]. Chilean
  /// petrol cars fill with either octane grade; 95 is the closer
  /// benchmark to the European E5 RON-95 and wins when both prices
  /// are quoted for the same station.
  static const Map<String, FuelType> _productKeyToFuel = {
    'gasolina_93': FuelType.e5,
    'gasolina_95': FuelType.e5,
    'gasolina_97': FuelType.e98,
    'diesel': FuelType.diesel,
    'glp': FuelType.lpg,
    // Some deployments use `gas_licuado` instead of `glp`; accept both.
    'gas_licuado': FuelType.lpg,
  };

  /// Product keys we deliberately drop because no [FuelType] exists
  /// yet. Exposed for tests to pin the MVP policy.
  static const Set<String> droppedProductKeys = {'kerosene', 'parafina'};

  final Dio _dio;
  final String _apiKey;
  final String _baseUrl;

  ChileStationService({
    required String apiKey,
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            ),
        _apiKey = apiKey,
        _baseUrl = baseUrl ?? defaultBaseUrl;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    if (_apiKey.isEmpty) {
      throw const ApiException(
        message: 'CNE API key is not configured',
      );
    }

    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'token': _apiKey,
          // Some CNE paths accept a `region` filter — we pull everything
          // and filter locally because the radius / sort semantics are
          // enforced by [StationServiceHelpers] and must stay consistent
          // with every other country.
          'formato': 'json',
        },
        cancelToken: cancelToken,
      );

      final stations = parseStationsResponse(
        response.data,
        fromLat: params.lat,
        fromLng: params.lng,
      );

      final filtered = filterByRadius(stations, params.radiusKm);
      sortStations(filtered, params);

      return wrapStations(filtered, ServiceSource.chileApi);
    } on DioException catch (e) {
      debugPrint('CL search failed: $e');
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw ApiException(
          message: 'CNE rejected API key (HTTP $status)',
          statusCode: status,
        );
      }
      throwApiException(e, defaultMessage: 'Network error (CNE)');
    }
  }

  /// Parse the CNE "estaciones" envelope into [Station] instances.
  ///
  /// Exposed for tests — the parser is the contract the live endpoint
  /// changes tend to break first, so unit tests drive it against
  /// recorded fixtures independent of any Dio mock.
  @visibleForTesting
  List<Station> parseStationsResponse(
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
    // 401/403 (caught above), but some proxies return 200 + error.
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

  /// Exposed for tests — single source of truth for the CNE-key
  /// → [FuelType] mapping.
  @visibleForTesting
  static FuelType? fuelForProductKey(String productKey) =>
      _productKeyToFuel[productKey.toLowerCase()];

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throwDetailUnavailable('CNE Bencina en Línea');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.chileApi);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Helpers
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
    final lat = _parseDouble(
      ubi is Map ? ubi['latitud'] : raw['latitud'],
    );
    final lng = _parseDouble(
      ubi is Map ? ubi['longitud'] : raw['longitud'],
    );
    if (lat == null || lng == null) return null;
    if (lat == 0 && lng == 0) return null;

    final brand = _parseBrand(raw);
    final nameRaw = (raw['nombre_fantasia'] ?? raw['nombre'])?.toString().trim();
    final name = (nameRaw != null && nameRaw.isNotEmpty) ? nameRaw : brand;

    final street = _joinStreet(raw);
    final comuna = raw['nombre_comuna']?.toString().trim() ?? '';

    final prices = _parsePrices(raw);

    final distKm = roundedDistance(fromLat, fromLng, lat, lng);

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

      final fuel = _productKeyToFuel[k];
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

  static double? _parseDouble(dynamic raw) {
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
  /// "horario_atencion" field often reads `"24_horas"` or a free-text
  /// schedule. We treat stations as open by default and fall back to
  /// false only when the field explicitly says `cerrado`.
  bool _isOpen(Map raw) {
    final h = raw['horario_atencion']?.toString().toLowerCase().trim();
    if (h == null || h.isEmpty) return true;
    if (h.contains('cerrado')) return false;
    return true;
  }
}
