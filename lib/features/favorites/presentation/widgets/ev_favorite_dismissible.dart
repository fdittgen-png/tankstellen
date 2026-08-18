// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/favorite_dismissible.dart';
import '../../../../core/domain/ev/charging_station.dart';
import '../../providers/ev_favorites_provider.dart';
import 'ev_favorite_card.dart';

/// Wraps an [EvFavoriteCard] in the shared [FavoriteDismissible] swipe
/// gesture (mirrors `FavoriteStationDismissible`, #1958): swipe right
/// launches navigation, swipe left removes the favorite — from
/// `evFavoritesProvider` — with an undo snackbar. The swipe chrome +
/// #3159 capture-before-await handling live in core.
///
/// Before this, EV-charger favorites were rendered as a bare card and
/// could not be swiped at all, unlike fuel-station favorites.
class EvFavoriteDismissible extends ConsumerWidget {
  final ChargingStation station;

  const EvFavoriteDismissible({super.key, required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = station.name;

    return FavoriteDismissible<EvFavorites>(
      dismissKey: 'ev-fav-${station.id}',
      label: label,
      latitude: station.latitude,
      longitude: station.longitude,
      // #3159 — captured synchronously before any await in the swipe
      // callback; evFavoritesProvider is keepAlive, so the captured
      // notifier stays valid for the undo.
      captureHandle: () => ref.read(evFavoritesProvider.notifier),
      removeFavorite: (favorites) => favorites.remove(station.id),
      undoRemove: (favorites) =>
          favorites.add(station.id, stationData: station),
      child: EvFavoriteCard(
        key: ValueKey(station.id),
        station: station,
        onTap: () => EvStationDetailRoute(station).push<void>(context),
        onFavoriteTap: () =>
            ref.read(evFavoritesProvider.notifier).remove(station.id),
      ),
    );
  }
}
