// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';

import '../domain/station.dart';
import 'impl/osm_brand_enricher.dart';

/// #3326 — enrich [stations] with OSM brand names, but never block the caller
/// (e.g. the radar's first paint) longer than [budget].
///
/// On a cold brand cache `enrich` calls Nominatim (slow + rate-limited); the
/// stations already carry coordinates + prices, so a search shouldn't wait on
/// the optional brand label. If enrichment resolves within [budget] the
/// enriched list is returned; otherwise [stations] is returned immediately and
/// enrichment keeps running in the background (its token is NOT cancelled) to
/// warm the persistent brand cache for the next search. Never throws — a
/// failed enrichment just yields the un-enriched stations.
Future<List<Station>> enrichWithinBudget(
  OsmBrandEnricher? enricher,
  List<Station> stations, {
  required Duration budget,
  CancelToken? cancelToken,
}) {
  if (enricher == null) return Future.value(stations);
  // Best-effort: an enrichment error (fast or slow) must never break the
  // search — fall back to the un-enriched stations.
  final pending = enricher
      .enrich(stations, cancelToken: cancelToken)
      .catchError((_) => stations);
  return pending.timeout(
    budget,
    onTimeout: () {
      unawaited(pending.then((_) {}, onError: (_) {}));
      return stations;
    },
  );
}
