// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/country/country_config.dart';
import '../../../core/country/country_provider.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/services/non_fuel_station_guard.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/storage/storage_providers.dart';
import '../../ev/api.dart';
import '../../route_search/providers/route_search_provider.dart';
import '../../../core/domain/search_result_item.dart';
import '../../../core/domain/station.dart';
import '../../search/providers/search_provider.dart';

part 'station_detail_provider.g.dart';

/// Upper bound on the fallback country-service fetch (#2408). A
/// non-resolvable / stale deep-link id (e.g. the old synthetic
/// `debug-test-station`, or a widget row whose station has since been
/// retired) used to await a fetch that never completed, leaving
/// `StationDetailScreen` stuck in `ShimmerStationDetail` forever. Bounding
/// it makes the future throw a [TimeoutException], which the screen's
/// EXISTING error/retry branch surfaces instead. The search-cache fast
/// path below is untouched — it returns synchronously and never hits this.
const Duration _fallbackFetchTimeout = Duration(seconds: 12);

/// #2778 — country codes (as returned by [Countries.countryCodeForStationId])
/// whose opening hours live ONLY on the detail endpoint, never in the search
/// payload: DE Tankerkönig (`list.php` has no hours, `detail.php` does) and PT
/// DGEG (`PesquisarPostos` has none, `GetDadosPostoMapa` carries `HorarioPosto`).
/// For a search tap on these, the fast path below fetches [getStationDetail] to
/// surface hours instead of serving the hours-less cached station. Every other
/// provider carries hours in the search result (FR/AT/CL/ES via #2777) or has
/// none to show, so none of them pays an extra fetch on a search tap.
const _detailOnlyOpeningHoursCountries = {'DE', 'PT'};

@riverpod
Future<ServiceResult<StationDetail>> stationDetail(
  Ref ref,
  String stationId,
) async {
  // #3455 — an OpenChargeMap `ocm-*` id must NEVER reach a fuel chain.
  // `Countries.countryCodeForStationId` returns null for it (no fuel
  // country prefix), so the fallback below used to send the EV id to the
  // ACTIVE country's fuel detail endpoint — the field-verified 400 burst
  // on FR/UK/LU. Serve the cached EV station instead (same hydration path
  // as the `/ev-station/:id` deep link) and stop here either way.
  if (isNonFuelStationId(stationId)) return _evCachedDetail(ref, stationId);

  // First: serve from an already-loaded result the app holds (search OR
  // route-along-the-way), which carries OSM brand enrichment + structured
  // hours. This avoids a re-fetch, preserves the brand name, and — for a
  // route tap (#2763) — short-circuits the network entirely.
  final cached = _cachedDetail(ref, stationId);

  // `originCountry` is a pure id-prefix parse (#753) — no provider read, no
  // Hive — so it is safe to resolve before deciding whether to touch the
  // country service. We need it for two things: the #2778 detail-only-hours
  // decision below, and the fallback service resolution further down.
  final originCountry = Countries.countryCodeForStationId(stationId);

  // #2778 — DE Tankerkönig / PT DGEG carry opening hours ONLY on the detail
  // endpoint; their search payload has none, so a cached search station has
  // `openingHours == null`. For those, fall through to fetch the real detail;
  // every other cached station is served instantly below.
  final needsDetailHoursFetch = cached != null &&
      cached.data.openingHours == null &&
      originCountry != null &&
      _detailOnlyOpeningHoursCountries.contains(originCountry);

  // Common path: serve the cached station instantly WITHOUT touching the
  // country service (no `activeCountryProvider` read → no Hive). Covers every
  // cached tap except the DE/PT hours upgrade — FR/AT/CL/ES carry hours via the
  // search parse + #2777 codec, route taps short-circuit the network (#2763).
  if (cached != null && !needsDetailHoursFetch) return cached;

  // Fallback: fetch from the country whose id prefix the [stationId]
  // carries (#753) — not the active profile country. Widget rows live
  // forever in SharedPreferences, so the user can tap a row written
  // under a different country than is currently active and still land
  // on the right station. Falls back to the active profile country
  // when the id has no recognised prefix (legacy bare id, demo data).
  //
  // Mirrors the favorites-provider pattern: when the id's origin
  // country matches the active country we reuse the active provider
  // (so test overrides on `stationServiceProvider` still drive the
  // right instance), otherwise we resolve the cross-country service.
  // Only touches `activeCountryProvider` when the id carries a prefix —
  // unprefixed legacy ids skip the comparison entirely so existing
  // unit tests that overrode just `stationServiceProvider` keep
  // working without standing up Hive.
  final StationService service;
  if (originCountry == null) {
    service = ref.watch(stationServiceProvider);
  } else {
    final activeCountry = ref.watch(activeCountryProvider).code;
    service = (originCountry == activeCountry)
        ? ref.watch(stationServiceProvider)
        : stationServiceForCountry(ref, originCountry);
  }

  // #2778 — DE/PT hours upgrade: fetch the real detail to surface hours; on any
  // failure keep the instant cached result so the screen never regresses.
  if (cached != null) {
    try {
      return await service
          .getStationDetail(stationId)
          .timeout(_fallbackFetchTimeout);
    } on Object {
      return cached;
    }
  }

  try {
    return await service.getStationDetail(stationId).timeout(_fallbackFetchTimeout);
  } on Object {
    // #2763 — last-resort cache fallback. The chain threw
    // (ServiceChainExhaustedException — e.g. a transient empty feed slice
    // that never recovered — or the #2408 [TimeoutException]). On a cold
    // deep-link race the search/route state may have populated AFTER the
    // fast-path read above; re-check it now and serve the already-loaded
    // Station rather than hard-failing the screen. Only rethrow (preserving
    // the screen's error/retry branch) when NEITHER state holds the id.
    //
    // Guard on `ref.mounted` so a provider that was disposed while the fetch
    // was in flight (e.g. the user navigated away — the #2408 timeout test)
    // rethrows the original error instead of touching a disposed Ref.
    if (ref.mounted) {
      final lateCache = _cachedDetail(ref, stationId);
      if (lateCache != null) return lateCache;
    }
    rethrow;
  }
}

/// #3455 — serves an `ocm-*` (EV) id from the device's EV caches: the EV
/// favorites payload store first, then the recently-fetched EV station
/// cache — the exact [hydrateEvStationById] lookup the `/ev-station/:id`
/// deep link uses. Maps the [ChargingStation] onto the fuel
/// [StationDetail] shape (no fuel prices — the price rows stay hidden)
/// so a stray `/station/ocm-*` open renders name/coords/address instead
/// of hammering a fuel detail endpoint with 400s.
///
/// An id unknown to the device throws the typed, non-retrying
/// [NonFuelStationIdException] — the screen's existing error branch
/// surfaces it, and the fuel chain is never touched.
ServiceResult<StationDetail> _evCachedDetail(Ref ref, String stationId) {
  final station = hydrateEvStationById(
    stationId,
    ref.read(storageRepositoryProvider),
    ref.read(evStationRepositoryProvider),
  );
  if (station == null) throw NonFuelStationIdException(stationId);
  return ServiceResult(
    data: StationDetail(
      station: Station(
        id: station.id,
        name: station.name,
        brand: station.operator ?? '',
        street: station.address ?? '',
        postCode: station.postCode ?? '',
        place: station.place ?? '',
        lat: station.latitude,
        lng: station.longitude,
        isOpen: station.isOperational,
        updatedAt: station.updatedAt,
      ),
    ),
    source: ServiceSource.cache,
    fetchedAt: DateTime.now(),
  );
}

/// Returns a synchronous cache [ServiceResult] for [stationId] when the app
/// already holds the station in either the current search results or the
/// route-along-the-way results — or null when neither does.
///
/// #753 — matches on EXACT `station.id == stationId` (ids carry the
/// `fr-`/`ar-` country prefix), so a cross-country numeric collision can't
/// shadow the tap. The route-state arm (#2763) makes a route tap render
/// instantly from cache and never reach the network — the primary cure for
/// the route-search "station not found" storm.
ServiceResult<StationDetail>? _cachedDetail(Ref ref, String stationId) {
  Station? station;

  final searchState = ref.read(searchStateProvider);
  if (searchState.hasValue) {
    station = (searchState.value?.data ?? const <SearchResultItem>[])
        .whereType<FuelStationResult>()
        .where((r) => r.station.id == stationId)
        .firstOrNull
        ?.station;
  }

  if (station == null) {
    final routeState = ref.read(routeSearchStateProvider);
    if (routeState.hasValue) {
      station = (routeState.value?.stations ?? const <SearchResultItem>[])
          .whereType<FuelStationResult>()
          .where((r) => r.station.id == stationId)
          .firstOrNull
          ?.station;
    }
  }

  if (station == null) return null;

  // Carry any structured weekly hours the cached station already holds
  // (Epic C4 — e.g. AT E-Control, which has no detail endpoint) into
  // `StationDetail.openingHours` so the display layer renders them directly
  // instead of falling through `legacyOpeningHoursBridge`.
  return ServiceResult(
    data: StationDetail(
      station: station,
      openingHours: station.openingHours,
    ),
    source: ServiceSource.cache,
    fetchedAt: DateTime.now(),
  );
}
