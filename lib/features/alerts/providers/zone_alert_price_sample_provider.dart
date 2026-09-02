// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/search_result_item.dart';
import '../../../core/domain/station.dart';
import '../../favorites/api.dart';
import '../../search/api.dart';

part 'zone_alert_price_sample_provider.g.dart';

/// Stations whose CURRENT prices seed the zone-alert threshold (#3905).
///
/// The zone-alert sheet used to open with a hard-coded `1.500` threshold —
/// far below a ~2.2 € diesel price, so a freshly saved alert could never
/// fire. The sheet now defaults to "the local price minus 5 %", and this
/// is the local sample it reads: the last search results first (they are
/// the stations around the user right now), else the favorites cache.
/// Both are already in memory — no network call is made for the form.
/// Empty when neither has loaded; the sheet then falls back to its
/// constant default.
@riverpod
List<Station> zoneAlertPriceSample(Ref ref) {
  final searchItems = ref.watch(searchStateProvider).asData?.value.data;
  final fromSearch = <Station>[
    for (final item in searchItems ?? const <SearchResultItem>[])
      if (item is FuelStationResult) item.station,
    ];
  if (fromSearch.isNotEmpty) return fromSearch;
  return ref.watch(favoriteStationsProvider).asData?.value.data ??
      const <Station>[];
}
