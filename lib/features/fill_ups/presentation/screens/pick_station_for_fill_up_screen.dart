// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/fuel_type.dart';
import '../../../../core/error/guarded.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../vehicle/api.dart' show activeVehicleProfileProvider;
import '../../domain/entities/fill_up.dart';
import '../../providers/consumption_providers.dart';
import '../widgets/known_station_lookup.dart';
import 'pick_station_candidates.dart';
import 'pick_station_sections.dart';

/// Station-first entry point for the fill-up form (#715).
///
/// Shown when the user taps the fill-up FAB on the consumption tab.
/// Picking a station attaches full context to the fill-up (station id
/// + name + fuel + current price when cached), which in turn lets the
/// receipt parser dispatch directly to the right brand layout.
///
/// #3906 — three sections, all from data the app already holds (no
/// network call on open):
///   * **Last station** — the station of the active vehicle's most
///     recent fill-up, pinned on top;
///   * **Favorites** — the user's favorite stations;
///   * **Nearby** — the ≤10 nearest stations of the last search result,
///     each with its distance from the last known position; a one-line
///     hint when nothing was searched yet.
///
/// A "Skip — add without a station" link at the bottom preserves the
/// blank-form flow for stations the app does not know (travelling
/// abroad, retroactive entry, etc.).
class PickStationForFillUpScreen extends ConsumerWidget {
  const PickStationForFillUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profileFuel = ref.watch(activeProfileProvider)?.preferredFuelType;
    final candidates = buildPickStationCandidates(
      fillUps: guard(
        () => ref.watch(fillUpListProvider),
        where: 'PickStationForFillUp: fill-up history unavailable',
        fallback: const <FillUp>[],
      ),
      vehicleId: guard(
        () => ref.watch(activeVehicleProfileProvider)?.id,
        where: 'PickStationForFillUp: active vehicle unavailable',
        fallback: null,
      ),
      favorites: favoriteStations(ref),
      searchResults: cachedSearchStations(ref),
      position: _position(ref),
    );
    final last = candidates.last;

    return PageScaffold(
      title: l.pickStationTitle,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l.tooltipBack,
        onPressed: () => context.pop(),
      ),
      bodyPadding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    l.pickStationHelper,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (last != null) ...[
                  PickStationSectionHeader(
                    key: const Key('pick_station_section_last'),
                    text: l.pickStationSectionLast,
                  ),
                  PickStationEntryTile(
                    entry: last,
                    icon: Icons.history,
                    onTap: () => _openFillUp(context, last, profileFuel),
                  ),
                ],
                PickStationSectionHeader(
                  key: const Key('pick_station_section_favorites'),
                  text: l.pickStationSectionFavorites,
                ),
                if (candidates.favorites.isEmpty)
                  PickStationSectionHint(text: l.pickStationEmpty)
                else
                  for (final e in candidates.favorites)
                    PickStationEntryTile(
                      entry: e,
                      onTap: () => _openFillUp(context, e, profileFuel),
                    ),
                PickStationSectionHeader(
                  key: const Key('pick_station_section_nearby'),
                  text: l.pickStationSectionNearby,
                ),
                if (candidates.nearby.isEmpty)
                  PickStationSectionHint(
                    key: const Key('pick_station_nearby_empty'),
                    text: l.pickStationNearbyEmpty,
                  )
                else
                  for (final e in candidates.nearby)
                    PickStationEntryTile(
                      entry: e,
                      icon: Icons.near_me_outlined,
                      onTap: () => _openFillUp(context, e, profileFuel),
                    ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextButton.icon(
                key: const Key('pick_station_skip'),
                onPressed: () =>
                    const AddFillUpRoute().pushReplacement(context),
                icon: const Icon(Icons.skip_next_outlined),
                label: Text(l.pickStationSkip),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Last known position (persisted by the search tab) — null when the
  /// app has never had one; nearby rows then use the search result's
  /// own distance.
  ({double lat, double lng})? _position(WidgetRef ref) {
    return guard(
      () {
        final p = ref.watch(userPositionProvider);
        return p == null ? null : (lat: p.lat, lng: p.lng);
      },
      where: 'PickStationForFillUp: user position unavailable',
      fallback: null,
    );
  }

  void _openFillUp(
    BuildContext context,
    PickStationEntry entry,
    FuelType? profileFuel,
  ) {
    // #3135 — the pre-fill crosses as a typed AddFillUpRoute instead of
    // a stringly-keyed Map.
    AddFillUpRoute(
      stationId: entry.id,
      stationName: entry.title,
      fuelType: profileFuel,
      pricePerLiter: entry.priceFor(profileFuel),
    ).pushReplacement(context);
  }
}
