import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import 'uk_fuel_finder_response_parser.dart';
import 'uk_fuel_finder_token_manager.dart';

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
/// ### File split (#563)
///
/// OAuth2 lifecycle lives in
/// [`uk_fuel_finder_token_manager.dart`][UkFuelFinderTokenManager].
/// JSON-to-[Station] parsing lives in
/// [`uk_fuel_finder_response_parser.dart`][UkFuelFinderResponseParser].
/// This shell wires them together and exposes the public test surface
/// the existing test suite depends on.
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
  final UkFuelFinderTokenManager _tokenManager;

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
        _tokenManager = UkFuelFinderTokenManager();

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    final token = await _tokenManager.fetchAccessToken(
      dio: _dio,
      secureStorage: _secureStorage,
      tokenUrl: _tokenUrl,
      clientIdStorageKey: kClientIdStorageKey,
      clientSecretStorageKey: kClientSecretStorageKey,
      cancelToken: cancelToken,
    );

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
    } on DioException catch (e, st) {
      throwApiException(e, defaultMessage: 'Fuel Finder request failed', stackTrace: st);
    }

    final items = UkFuelFinderResponseParser.extractStationList(response.data);
    final stations = UkFuelFinderResponseParser.parseFuelFinderStations(
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

  // ── Test surface (stable — existing tests reach in here) ─────────────────

  /// Static delegator preserved for tests — see
  /// [UkFuelFinderResponseParser.parseFuelFinderStations].
  @visibleForTesting
  static List<Station> parseFuelFinderStations(
    List<dynamic> items, {
    required double lat,
    required double lng,
    required double radiusKm,
  }) =>
      UkFuelFinderResponseParser.parseFuelFinderStations(
        items,
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );

  /// Static delegator preserved for tests — see
  /// [UkFuelFinderResponseParser.parsePence].
  @visibleForTesting
  static double? parsePenceForTest(dynamic value) =>
      UkFuelFinderResponseParser.parsePence(value);

  /// Force the cached OAuth token to appear expired so the next
  /// [searchStations] call triggers a fresh `/oauth/token` request.
  /// Exposed for tests only.
  @visibleForTesting
  void expireTokenForTest() => _tokenManager.forceExpire();
}
