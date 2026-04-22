import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../error/exceptions.dart';
import '../../utils/geo_utils.dart';
import '../dio_factory.dart';
import '../mixins/station_service_helpers.dart';
import '../service_result.dart';
import '../station_service.dart';

/// GOV.UK Fuel Finder — new single-endpoint UK fuel price service (#573).
///
/// The UK Competition and Markets Authority's original Motor Fuel Price
/// scheme required each retailer to publish a JSON file on its own
/// domain. The Motor Fuel Price Open Data Regulations 2025 replaced
/// that fan-out with a single aggregated government API served at
/// `developer.fuel-finder.service.gov.uk`, reached via OAuth2 client
/// credentials.
///
/// **This class is a scaffold only.** It is NOT wired into the country
/// service registry — the legacy per-retailer [UkStationService] stays
/// live until the user registers for OAuth2 credentials. Activation is
/// a three-step flip once credentials exist:
///
///   1. Write `uk_fuel_finder_client_id` and `uk_fuel_finder_client_secret`
///      into [FlutterSecureStorage] via the settings screen.
///   2. Flip [_useFuelFinder] to `true` (single constant edit below).
///   3. Register `UkFuelFinderService` in `country_service_registry.dart`
///      for country code `gb` in place of `UkStationService`.
///
/// Keeping the gate inline (not in a central config) deliberately
/// minimises the blast radius of this dormant code path.
///
/// ### OAuth2 flow
///
/// A `_TokenManager` fetches and caches an access token via the client
/// credentials grant. The token is kept in memory with its `expires_in`
/// and refreshed proactively one minute before expiry. A 401 from the
/// token endpoint surfaces as an [ApiException] with "OAuth" in the
/// message so the UI can differentiate credential problems from plain
/// network errors.
///
/// ### Endpoints
///
/// The exact paths are hosted on
/// `https://www.developer.fuel-finder.service.gov.uk` but the developer
/// portal requires authentication to browse — the concrete token and
/// data paths are therefore injectable via constructor so the user can
/// confirm them against the GOV.UK spec once their application is
/// approved and the docs become visible. Defaults match the published
/// portal structure (`/oauth/token` for the OAuth2 step,
/// `/api/v1/stations` for the data step).
class UkFuelFinderService
    with StationServiceHelpers
    implements StationService {
  // ── Activation flag ──────────────────────────────────────────────────────
  //
  // Hard-coded dormant. Flip to `true` only after:
  //   - creds are written to secure storage under the two keys below, AND
  //   - this service is registered in CountryServiceRegistry for 'gb'.
  // ignore: unused_field
  static const bool _useFuelFinder = false;

  // ── Secure storage keys (secrets live here, nowhere else) ────────────────

  /// Secure-storage key for the OAuth2 client id. Populated via settings.
  static const String kClientIdStorageKey = 'uk_fuel_finder_client_id';

  /// Secure-storage key for the OAuth2 client secret. Populated via settings.
  static const String kClientSecretStorageKey = 'uk_fuel_finder_client_secret';

  // ── Default endpoints (overridable for tests + future spec adjustments) ──

  /// Default token endpoint — OAuth2 client-credentials grant.
  static const String defaultTokenUrl =
      'https://www.developer.fuel-finder.service.gov.uk/oauth/token';

  /// Default data endpoint — list of stations with prices.
  static const String defaultStationsUrl =
      'https://www.developer.fuel-finder.service.gov.uk/api/v1/stations';

  // ── Deps ─────────────────────────────────────────────────────────────────

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final String _tokenUrl;
  final String _stationsUrl;
  final _TokenManager _tokenManager;

  UkFuelFinderService({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
    String? tokenUrl,
    String? stationsUrl,
  })  : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
            ),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _tokenUrl = tokenUrl ?? defaultTokenUrl,
        _stationsUrl = stationsUrl ?? defaultStationsUrl,
        _tokenManager = _TokenManager();

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    final token = await _fetchAccessToken(cancelToken: cancelToken);

    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        _stationsUrl,
        cancelToken: cancelToken,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.json,
          // Non-2xx responses throw so we can surface them as ApiException.
          validateStatus: (status) => status != null && status < 400,
        ),
      );
    } on DioException catch (e) {
      throwApiException(e, defaultMessage: 'Fuel Finder request failed');
    }

    final items = _extractStationList(response.data);
    final stations = parseFuelFinderStations(
      items,
      lat: params.lat,
      lng: params.lng,
      radiusKm: params.radiusKm,
    );

    return ServiceResult(
      data: stations,
      source: ServiceSource.ukApi,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throw const ApiException(
      message: 'Station detail not supported for UK Fuel Finder',
    );
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    // Fuel Finder returns the full price table with `searchStations`; the
    // favorites-refresh path piggybacks on that rather than forcing a
    // second round trip.
    return emptyPricesResult(ServiceSource.ukApi);
  }

  // ── OAuth2 ───────────────────────────────────────────────────────────────

  Future<String> _fetchAccessToken({CancelToken? cancelToken}) async {
    final cached = _tokenManager.cachedToken;
    if (cached != null) return cached;

    final clientId = await _secureStorage.read(key: kClientIdStorageKey);
    final clientSecret =
        await _secureStorage.read(key: kClientSecretStorageKey);
    if (clientId == null ||
        clientId.isEmpty ||
        clientSecret == null ||
        clientSecret.isEmpty) {
      throw const ApiException(
        message:
            'Fuel Finder OAuth credentials missing — set client id and '
            'secret in secure storage before enabling.',
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _tokenUrl,
        data: {
          'grant_type': 'client_credentials',
          'client_id': clientId,
          'client_secret': clientSecret,
        },
        cancelToken: cancelToken,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException(
          message: 'OAuth token response empty for Fuel Finder',
        );
      }
      final accessToken = data['access_token']?.toString();
      final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
      if (accessToken == null || accessToken.isEmpty) {
        throw const ApiException(
          message: 'OAuth token response missing access_token',
        );
      }

      _tokenManager.store(accessToken, Duration(seconds: expiresIn));
      return accessToken;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw ApiException(
          message:
              'OAuth authentication failed for Fuel Finder (HTTP $status) '
              '— check client id and secret.',
          statusCode: status,
        );
      }
      throw ApiException(
        message: 'OAuth token request failed: ${e.type.name}',
        statusCode: status,
      );
    }
  }

  // ── Payload parsing ──────────────────────────────────────────────────────

  List<dynamic> _extractStationList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final list = data['stations'] as List<dynamic>? ??
          data['data'] as List<dynamic>? ??
          data['items'] as List<dynamic>? ??
          const <dynamic>[];
      return List<dynamic>.from(list);
    }
    return const <dynamic>[];
  }

  /// Parses Fuel Finder station records into [Station] entities, filters
  /// by radius, dedupes by `site_id`, sorts by distance, caps at 50.
  ///
  /// Exposed for tests.
  @visibleForTesting
  static List<Station> parseFuelFinderStations(
    List<dynamic> items, {
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    final seenIds = <String>{};
    final stations = <Station>[];

    for (final item in items) {
      if (item is! Map) continue;
      try {
        final loc = item['location'];
        final locMap = loc is Map ? loc : null;
        final itemLat = (locMap?['latitude'] as num?)?.toDouble() ??
            (item['latitude'] as num?)?.toDouble() ??
            (item['lat'] as num?)?.toDouble();
        final itemLng = (locMap?['longitude'] as num?)?.toDouble() ??
            (item['longitude'] as num?)?.toDouble() ??
            (item['lng'] as num?)?.toDouble();
        if (itemLat == null || itemLng == null) continue;

        final dist = distanceKm(lat, lng, itemLat, itemLng);
        if (dist > radiusKm) continue;

        final rawId = item['site_id']?.toString() ??
            item['id']?.toString() ??
            '${itemLat.toStringAsFixed(5)}_${itemLng.toStringAsFixed(5)}';
        final stationId = 'uk-$rawId';
        if (!seenIds.add(stationId)) continue;

        final prices = item['prices'] is Map
            ? Map<String, dynamic>.from(item['prices'] as Map)
            : <String, dynamic>{};

        stations.add(Station(
          id: stationId,
          name: item['site_name']?.toString() ??
              item['name']?.toString() ??
              item['brand']?.toString() ??
              '',
          brand: item['brand']?.toString() ?? '',
          street: item['address']?.toString() ?? '',
          postCode: item['postcode']?.toString() ?? '',
          place:
              item['town']?.toString() ?? item['locality']?.toString() ?? '',
          lat: itemLat,
          lng: itemLng,
          dist: dist,
          // E5 → FuelType.e5 (Super Unleaded 95 octane)
          e5: _parsePence(prices['E5'] ?? prices['unleaded']),
          // E10 → FuelType.e10 (95 octane, 10% ethanol)
          e10: _parsePence(prices['E10']),
          // E98 / Super Unleaded → FuelType.e98 (97/98 octane premium petrol)
          e98: _parsePence(
            prices['E98'] ?? prices['super_unleaded'] ?? prices['E5_97'],
          ),
          // B7 / Diesel → FuelType.diesel (7% biodiesel blend, standard UK spec)
          diesel: _parsePence(prices['B7'] ?? prices['diesel']),
          // SDV / Premium Diesel → FuelType.dieselPremium
          dieselPremium: _parsePence(
            prices['SDV'] ?? prices['premium_diesel'] ?? prices['B7_plus'],
          ),
          isOpen: true,
        ));
      } catch (e) {
        debugPrint('UK Fuel Finder parse failed: $e');
        continue;
      }
    }

    stations.sort((a, b) => a.dist.compareTo(b.dist));
    return stations.take(50).toList();
  }

  /// UK prices are published in pence per litre. Anything above 10
  /// is treated as pence and divided by 100; anything at or below 10 is
  /// assumed to already be in pounds.
  ///
  /// Exposed for tests.
  @visibleForTesting
  static double? parsePenceForTest(dynamic value) => _parsePence(value);

  /// Force the cached OAuth token to appear expired so the next
  /// [searchStations] call triggers a fresh `/oauth/token` request.
  /// Exposed for tests only.
  @visibleForTesting
  void expireTokenForTest() => _tokenManager.forceExpire();

  static double? _parsePence(dynamic value) {
    if (value == null) return null;
    final price = double.tryParse(value.toString());
    if (price == null) return null;
    return price > 10 ? price / 100 : price;
  }
}

/// Private OAuth2 token cache. One instance per service — keeps blast
/// radius local instead of pushing a Dio-wide interceptor that would
/// touch unrelated requests.
class _TokenManager {
  String? _accessToken;
  DateTime? _expiresAt;

  /// Returns the cached token if it is still valid for at least 60s,
  /// otherwise `null` (caller must fetch a fresh one).
  String? get cachedToken {
    final token = _accessToken;
    final expiry = _expiresAt;
    if (token == null || expiry == null) return null;
    // Refresh one minute before expiry to avoid racing a request against
    // a token that expires mid-flight.
    if (DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 60)))) {
      return null;
    }
    return token;
  }

  void store(String token, Duration ttl) {
    _accessToken = token;
    _expiresAt = DateTime.now().add(ttl);
  }

  @visibleForTesting
  void forceExpire() {
    _expiresAt = DateTime.now().subtract(const Duration(minutes: 1));
  }
}
