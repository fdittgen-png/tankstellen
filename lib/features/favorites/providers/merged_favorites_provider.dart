// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/search_result_item.dart';
import '../../../core/domain/station.dart';
import 'ev_favorites_provider.dart';
import 'favorite_stations_provider.dart';

part 'merged_favorites_provider.g.dart';

/// The user's fuel + EV favorites merged into one mixed
/// [SearchResultItem] list (#1786), ordered by distance so the
/// favorites tab renders a single interleaved list (#1787) rather than
/// two labelled sections.
///
/// The two Hive boxes stay separate — the merge is purely at the
/// provider layer. Fuel favorites come from [favoriteStationsProvider]
/// (which owns the per-country price refresh and the loading / error
/// lifecycle the tab still reads); EV favorites from
/// [evFavoriteStationsProvider]. `isFavorite` / `toggle` are untouched.
@riverpod
List<SearchResultItem> mergedFavorites(Ref ref) {
  final fuel = ref.watch(favoriteStationsProvider).value;
  final ev = ref.watch(evFavoriteStationsProvider);

  final items = <SearchResultItem>[
    for (final s in fuel?.data ?? const <Station>[]) FuelStationResult(s),
    for (final cs in ev) EVStationResult(cs),
  ];
  // A shared key so the two kinds interleave instead of stacking — the
  // stored distance is the only ordering both entities carry.
  items.sort((a, b) => a.dist.compareTo(b.dist));
  return items;
}
