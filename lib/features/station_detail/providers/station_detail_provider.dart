// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/country/country_config.dart';
import '../../../core/country/country_provider.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../route_search/providers/route_search_provider.dart';
import '../../search/domain/entities/search_result_item.dart';
import '../../search/domain/entities/station.dart';
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

@riverpod
Future<ServiceResult<StationDetail>> stationDetail(
  Ref ref,
  String stationId,
) async {
  // First: serve from an already-loaded result the app holds (search OR
  // route-along-the-way), which carries OSM brand enrichment + structured
  // hours. This avoids a re-fetch, preserves the brand name, and — for a
  // route tap (#2763) — short-circuits the network entirely.
  final cached = _cachedDetail(ref, stationId);
  if (cached != null) return cached;

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
  final originCountry = Countries.countryCodeForStationId(stationId);
  final StationService service;
  if (originCountry == null) {
    service = ref.watch(stationServiceProvider);
  } else {
    final activeCountry = ref.watch(activeCountryProvider).code;
    service = (originCountry == activeCountry)
        ? ref.watch(stationServiceProvider)
        : stationServiceForCountry(ref, originCountry);
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
