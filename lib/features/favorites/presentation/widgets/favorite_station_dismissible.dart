// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/time/app_clock.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/widgets/favorite_dismissible.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../search/presentation/widgets/station_card.dart';
import '../../domain/stale_price_policy.dart';
import '../../providers/favorites_provider.dart';

/// Wraps a [StationCard] in the shared [FavoriteDismissible] swipe
/// gesture for the Favorites list: swipe right launches turn-by-turn
/// navigation, swipe left removes the favorite (with an undo
/// snackbar). The swipe chrome + #3159 capture-before-await handling
/// live in core; this file only binds the fuel-station provider and
/// card.
class FavoriteStationDismissible extends ConsumerWidget {
  final Station station;

  const FavoriteStationDismissible({super.key, required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = station.displayName;

    return FavoriteDismissible<Favorites>(
      dismissKey: 'fav-${station.id}',
      label: label,
      latitude: station.lat,
      longitude: station.lng,
      // #3159 — captured synchronously before any await in the swipe
      // callback; favoritesProvider is keepAlive, so the captured
      // notifier stays valid for the undo.
      captureHandle: () => ref.read(favoritesProvider.notifier),
      removeFavorite: (favorites) => favorites.remove(station.id),
      undoRemove: (favorites) =>
          favorites.add(station.id, stationData: station),
      child: StationCard(
        key: ValueKey(station.id),
        station: station,
        selectedFuelType: FuelType.all,
        isFavorite: true,
        // #3905 — a favorite is re-read for weeks; flag a price whose
        // upstream stamp is older than kStalePriceThreshold so a July
        // "Updated 16/07" no longer reads as current in September.
        isStalePrice: isStalePrice(
          station.updatedAt,
          now: ref.watch(appClockProvider).now(),
        ),
        profileFuelType: ref.watch(activeProfileProvider)?.preferredFuelType,
        onTap: () => StationDetailRoute(station.id).push<void>(context),
        onFavoriteTap: () {
          unawaited(ref.read(favoritesProvider.notifier).remove(station.id));
        },
      ),
    );
  }
}
