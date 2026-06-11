// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/country/country_time.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/cached_dataset_mixin.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/persistent_dataset.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/logging/error_logger.dart';
import '../../station_detail/domain/opening_hours.dart';
import '../opening_hours/open_state_from_hours.dart';
import 'spain_opening_hours_adapter.dart';
import 'spain_provinces.dart';

/// Spanish fuel prices from Geoportal Gasolineras (MITECO).
/// Free, no API key, no registration.
///
/// The API has no coordinate/radius search — only by province/municipality.
/// Strategy: fetch all stations, calculate distances locally, filter by radius.
/// The full dataset (~12,000 stations) is cached aggressively.
class MitecoStationService
    with StationServiceHelpers, KeyedCachedDatasetMixin
    implements StationService {
  static const String defaultBaseUrl =
      'https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes'
      '/PreciosCarburantes';

  final Dio _dio;
  final String _baseUrl;
  final CacheStrategy? _cache;
  final DateTime Function() _now;
  final WeeklyOpeningHours Function(String horario) _parseOpeningHours;

  /// #2181 — Dio injectable for tests; defaults to the standard factory.
  /// #2193 — [baseUrl] injectable too, harmonising the override surface
  /// with Portugal / Slovenia / South Korea; defaults to [defaultBaseUrl].
  /// #2264 — [cache] enables per-province disk persistence (read-through);
  /// omit it for the pure in-memory behaviour the parser tests rely on.
  /// #3189 — [now] is the clock seam for the schedule-derived `isOpen`;
  /// defaults to the wall clock.
  /// #3156 — [parseOpeningHours] is the parse-count seam for the no-re-parse
  /// regression test; defaults to the real [SpainOpeningHoursAdapter].
  MitecoStationService({
    Dio? dio,
    String? baseUrl,
    CacheStrategy? cache,
    DateTime Function()? now,
    WeeklyOpeningHours Function(String horario)? parseOpeningHours,
  })  : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
            ),
        _baseUrl = baseUrl ?? defaultBaseUrl,
        _cache = cache,
        // #3198 — default the clock seam to SPAIN's wall clock, not the
        // device's, so a user browsing ES from another timezone gets the
        // open state at the station.
        _now = now ?? (() => nowInCountry('ES')),
        _parseOpeningHours =
            parseOpeningHours ?? const SpainOpeningHoursAdapter().parse;

  // #2264 — soft/hard dataset TTLs mirror the ES FuelServicePolicy (soft 6 h,
  // hard 24 h). The legacy single-list 10-minute cache is replaced by a
  // per-province cache so province A's stations are never served for B.
  static const Duration _softTtl = Duration(hours: 6);
  static const Duration _hardTtl = Duration(hours: 24);

  /// Per-province raw rows, keyed by `IDProvincia` (#2264 — province A's
  /// stations are never served for B). Kept for [getStationDetail]'s id
  /// lookup; they are also the persisted format, so the on-disk
  /// `dataset:ES:province-<id>` entries of existing installs stay readable.
  final Map<String, List<Map<String, dynamic>>> _rowsByProvince = {};

  /// Per-province *parsed* [Station] templates (#3156). The expensive parse —
  /// including the regex [SpainOpeningHoursAdapter] pass per row — runs ONCE
  /// per dataset refresh (inside the keyed-mixin `store` callback), not on
  /// every search; a dense province used to re-pay 800-2500 row parses per
  /// repeat search. Templates carry placeholder `dist`/`isOpen`;
  /// [_withSearchContext] stamps the real per-search values.
  final Map<String, List<Station>> _stationsByProvince = {};

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      // #2264 — fetch every province overlapping the search radius (a point
      // near a border touches several) and merge, so a station physically
      // nearby but administratively in the neighbour is not dropped.
      final provinceIds =
          spainProvincesNear(params.lat, params.lng, params.radiusKm);

      // Dedupe across province borders by station id, pairing every cached
      // template with its distance to the search centre. #3152
      // filter-before-copyWith: only the in-result survivors below pay the
      // `copyWith` + open-now computation.
      final candidates = <(Station, double)>[];
      final seenIds = <String>{};
      for (final provinceId in provinceIds) {
        final templates =
            await _stationsForProvince(provinceId, cancelToken: cancelToken);
        for (final t in templates) {
          if (!seenIds.add(t.id)) continue;
          candidates
              .add((t, roundedDistance(params.lat, params.lng, t.lat, t.lng)));
        }
      }

      // Same semantics as [StationServiceHelpers.filterByRadius] (within
      // radius; if nothing found, the nearest 20), applied on the (template,
      // dist) pairs so out-of-radius templates are never materialised.
      var survivors = [
        for (final c in candidates)
          if (c.$2 <= params.radiusKm) c,
      ];
      if (survivors.isEmpty && candidates.isNotEmpty) {
        candidates.sort((a, b) => a.$2.compareTo(b.$2));
        survivors = candidates.take(20).toList();
      }

      final stations = [
        for (final (template, dist) in survivors)
          _withSearchContext(template, dist),
      ];

      // Sort
      sortStations(stations, params);

      return wrapStations(stations, ServiceSource.mitecoApi, limit: 50);
    } on DioException catch (e, st) {
      throwApiException(e, defaultMessage: 'Error de red', stackTrace: st);
    }
  }

  /// Returns the parsed [Station] templates for one province, served from (in
  /// order): the fresh in-memory copy, the persisted Hive copy (read-through,
  /// when a cache is wired), then the network — and persisted on a fresh
  /// fetch. The TTL / read-through / dedupe / offline state machine lives in
  /// the shared [KeyedCachedDatasetMixin] (#3156 — it used to be hand-rolled
  /// here, a fork that mixin fixes never reached); this method only wires the
  /// per-province seams and parses rows → templates once per refresh.
  Future<List<Station>> _stationsForProvince(
    String provinceId, {
    CancelToken? cancelToken,
  }) async {
    await loadKeyedPersistentDataset<List<Map<String, dynamic>>>(
      key: provinceId,
      cached: _rowsByProvince[provinceId],
      softTtl: _softTtl,
      hardTtl: _hardTtl,
      persistent: _persistentFor(provinceId),
      fetch: () => _fetchProvince(provinceId, cancelToken: cancelToken),
      store: (rows) {
        _rowsByProvince[provinceId] = rows;
        // #3156 — parse once per dataset refresh, NOT once per search. The
        // two maps are only ever written together here, so a non-null
        // `_rowsByProvince[id]` guarantees its parsed twin below.
        _stationsByProvince[provinceId] =
            rows.map(_parseStation).whereType<Station>().toList(
                  growable: false,
                );
      },
    );
    return _stationsByProvince[provinceId] ?? const [];
  }

  PersistentDataset<List<Map<String, dynamic>>>? _persistentFor(
    String provinceId,
  ) {
    final cache = _cache;
    if (cache == null) return null;
    return PersistentDataset<List<Map<String, dynamic>>>(
      cache: cache,
      countryCode: 'ES',
      datasetName: 'province-$provinceId',
      source: ServiceSource.mitecoApi,
      serialize: (rows) => {'rows': rows},
      deserialize: (json) => (json['rows'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchProvince(
    String provinceId, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<dynamic>(
      '$_baseUrl/EstacionesTerrestres/FiltroProvincia/$provinceId',
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException(message: 'Invalid MITECO response');
    }

    if (data['ResultadoConsulta'] != 'OK') {
      throw ApiException(
        message: data['ResultadoConsulta']?.toString() ?? 'API error',
      );
    }

    final list = data['ListaEESSPrecio'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// Parse one raw MITECO row into a [Station] *template* (#3156): every
  /// search-independent field is final, while `dist` (0 placeholder) and
  /// `isOpen` (legacy heuristic placeholder) are stamped per search / detail
  /// tap by [_withSearchContext]. Templates are cached per province in
  /// [_stationsByProvince], so this — including the regex opening-hours
  /// adapter — runs once per dataset refresh.
  Station? _parseStation(Map<String, dynamic> r) {
    try {
      // Coordinates use comma as decimal separator
      final lat = _parseCommaDouble(r['Latitud']?.toString());
      final lng = _parseCommaDouble(r['Longitud (WGS84)']?.toString());
      if (lat == null || lng == null) return null;

      final brand = r['Rótulo']?.toString() ?? '';
      final address = r['Dirección']?.toString() ?? '';
      final city = r['Localidad']?.toString() ?? '';
      final postalCode = r['C.P.']?.toString() ?? '';
      final horario = r['Horario']?.toString() ?? '';

      // #2713 — parse the MITECO `Horario` string (e.g. `L-D: 24H`,
      // `L-V: 06:00-23:00; S-D: 08:00-23:00`) into the common
      // [WeeklyOpeningHours]. The legacy `openingHoursText` / `isOpen` stay
      // for back-compat; the structured `weeklyHours` is the canonical
      // signal the #2706 detail-fallback threads into the detail screen.
      final weeklyHours = _parseOpeningHours(horario);

      // #753 — `es-` prefix so a MITECO `IDEESS` (bare numeric) cannot
      // collide with another country's numeric id space.
      final rawId = r['IDEESS']?.toString() ?? '';
      return Station(
        id: rawId.isEmpty
            ? ''
            : (rawId.startsWith('es-') ? rawId : 'es-$rawId'),
        name: brand.isNotEmpty ? brand : address,
        brand: brand,
        street: address,
        postCode: postalCode,
        place: city,
        lat: lat,
        lng: lng,
        // Placeholder — [_withSearchContext] stamps the real per-search
        // distance (templates are parsed before any search centre is known).
        dist: 0,
        e5: _parseCommaDouble(r['Precio Gasolina 95 E5']?.toString()),
        e10: _parseCommaDouble(r['Precio Gasolina 95 E10']?.toString()),
        e98: _parseCommaDouble(r['Precio Gasolina 98 E5']?.toString()),
        diesel: _parseCommaDouble(r['Precio Gasoleo A']?.toString()),
        dieselPremium: _parseCommaDouble(r['Precio Gasoleo Premium']?.toString()),
        // #3189 — E85 lives in 'Precio Bioetanol' (the live row carries
        // '% BioEtanol': '85,0'); the 'Precio Gasolina 95 E85' column is kept
        // as a fallback (a couple of live stations still populate it).
        e85: _parseCommaDouble(r['Precio Bioetanol']?.toString()) ??
            _parseCommaDouble(r['Precio Gasolina 95 E85']?.toString()),
        lpg: _parseCommaDouble(r['Precio Gases licuados del petróleo']?.toString()),
        cng: _parseCommaDouble(r['Precio Gas Natural Comprimido']?.toString()),
        // Placeholder (legacy non-empty heuristic) — [_withSearchContext]
        // stamps the schedule-derived value at the moment of each search.
        isOpen: horario.isNotEmpty && horario != 'Cerrado',
        openingHoursText: horario.isNotEmpty ? horario : null,
        openingHours: weeklyHours.availability ==
                OpeningHoursAvailability.notProvided
            ? null
            : weeklyHours,
        // #3189 — MITECO `Margen` (D/I/N: road side the station sits on) was
        // stuffed into `stationType`, whose contract is R(etail)/A(utoroute).
        // It is intentionally NOT mapped.
      );
    } on FormatException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'MITECO station parse failed'}));
      return null;
    }
  }

  /// Stamp a cached [template] with the per-search values: the distance to
  /// the search centre and the schedule-derived open state *at this moment*
  /// (#3156 — `isOpen` is recomputed on every search precisely so the 6 h
  /// province cache can never pin a stale open/closed flag; the pre-cache
  /// code recomputed it implicitly by re-parsing every row).
  Station _withSearchContext(Station template, double dist) =>
      template.copyWith(dist: dist, isOpen: _isOpenNow(template));

  /// #3189/#3198 open-now derivation, computed from the template's
  /// already-parsed fields: the structured schedule decides when available
  /// (`openingHours` is null exactly when the adapter returned
  /// `notProvided`). Without a usable schedule only the explicit `Cerrado`
  /// marker is a real signal — a non-empty but unparseable horario no
  /// longer asserts "open" (#3198: that legacy heuristic presented
  /// possibly-closed stations as open); it is honest unknown (`null`).
  bool? _isOpenNow(Station template) {
    final derived = openStateFromHours(template.openingHours, _now());
    if (derived != null) return derived;
    final horario = (template.openingHoursText ?? '').trim().toLowerCase();
    if (horario.startsWith('cerrado')) return false;
    return null;
  }

  /// Parse a number string that uses comma as decimal separator.
  /// "1,817" → 1.817, "" → null, null → null
  double? _parseCommaDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    // #2706 — MITECO is a BULK feed: there is no per-station detail endpoint.
    // A search already cached every province's full rows in [_rowsByProvince],
    // and each row carries name/brand/street/prices/coords. So a detail tap
    // that falls through the provider's in-search fast path (widget rows,
    // deep links, favorites) is resolved from that cache rather than throwing.
    final rawId = stationId.startsWith('es-')
        ? stationId.substring(3) // inverse of the `es-` prefixing at _parseStation
        : stationId;
    final row = _findCachedRow(rawId);
    if (row != null) {
      // Reuse the search parser; `dist` is irrelevant on the detail screen
      // (stamped 0, as the pre-#3156 own-coords-as-centre parse yielded).
      final template = _parseStation(row);
      if (template != null) {
        return ServiceResult<StationDetail>(
          data: StationDetail(station: _withSearchContext(template, 0)),
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
        );
      }
    }
    // Cold cache (no prior search) — IDEESS does not encode its province, so a
    // cold re-fetch is impossible here; preserve today's behaviour and let the
    // provider's error/retry branch handle it. Cold-resolution is a follow-up.
    throwDetailUnavailable('MITECO API');
  }

  /// Linear scan of every cached province for the raw `IDEESS` row matching
  /// [rawId] (#2706). A per-detail-tap scan is cheap and deliberately does NOT
  /// restructure [_rowsByProvince].
  Map<String, dynamic>? _findCachedRow(String rawId) {
    for (final rows in _rowsByProvince.values) {
      for (final row in rows) {
        if (row['IDEESS']?.toString() == rawId) return row;
      }
    }
    return null;
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.mitecoApi);
  }
}
