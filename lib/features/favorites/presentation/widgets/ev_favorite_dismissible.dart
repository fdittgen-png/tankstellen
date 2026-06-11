// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ev/domain/entities/charging_station.dart';
import '../../providers/ev_favorites_provider.dart';
import 'ev_favorite_card.dart';

/// Wraps an [EvFavoriteCard] in the same swipe-to-act gesture the
/// fuel-station favorites use (mirrors `FavoriteStationDismissible`,
/// #1958): swipe right launches navigation, swipe left removes the
/// favorite — from `evFavoritesProvider` — with an undo snackbar.
///
/// Before this, EV-charger favorites were rendered as a bare card and
/// could not be swiped at all, unlike fuel-station favorites.
class EvFavoriteDismissible extends ConsumerWidget {
  final ChargingStation station;

  const EvFavoriteDismissible({super.key, required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final label = station.name;

    return Dismissible(
      key: ValueKey('ev-fav-${station.id}'),
      confirmDismiss: (direction) async {
        // #3159 — capture before any await: the dismissed row's element
        // unmounts once the swipe completes, so the snackbar's onUndo (and
        // any post-await ref use) would throw a StateError on the dead
        // WidgetRef. evFavoritesProvider is keepAlive, so the captured
        // notifier stays valid for the undo.
        final favorites = ref.read(evFavoritesProvider.notifier);
        if (direction == DismissDirection.startToEnd) {
          await NavigationUtils.openInMaps(
            station.latitude,
            station.longitude,
            label: label,
          );
          return false;
        }
        await favorites.remove(station.id);
        if (!context.mounted) return true;
        final l10nSnack = AppLocalizations.of(context);
        SnackBarHelper.showWithUndo(
          context,
          l10nSnack?.removedFromFavoritesName(label) ??
              '$label removed from favorites',
          undoLabel: l10nSnack?.undo ?? 'Undo',
          onUndo: () => favorites.add(station.id, stationData: station),
        );
        return true;
      },
      background: Semantics(
        label: l10n?.semanticsNavigateTo(label) ?? 'Navigate to $label',
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          color: Theme.of(context).colorScheme.primary,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.navigation, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n?.navigate ?? 'Navigate',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      secondaryBackground: Semantics(
        label: l10n?.semanticsRemoveFromFavorites(label) ??
            'Remove $label from favorites',
        child: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: DarkModeColors.error(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n?.remove ?? 'Remove',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.delete, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
      child: EvFavoriteCard(
        key: ValueKey(station.id),
        station: station,
        onTap: () => context.push('/ev-station', extra: station),
        onFavoriteTap: () =>
            ref.read(evFavoritesProvider.notifier).remove(station.id),
      ),
    );
  }
}
