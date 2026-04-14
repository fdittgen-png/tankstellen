import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import '../../../search/presentation/widgets/station_card.dart';
import '../../providers/favorites_provider.dart';

/// Wraps a [StationCard] in a swipe-to-act gesture for the Favorites
/// list. Swiping right launches turn-by-turn navigation in the system
/// maps app; swiping left removes the favorite (with an undo snackbar).
///
/// Stateless apart from watching `activeProfileProvider` for the
/// preferred fuel type and `favoritesProvider` for the remove/undo
/// actions. Pulled out of `favorites_screen.dart` so the screen's
/// `_buildFavoritesTab` helper drops the 80-line inline `Dismissible`
/// block and so the swipe gestures can be exercised by widget tests.
class FavoriteStationDismissible extends ConsumerWidget {
  final Station station;

  const FavoriteStationDismissible({super.key, required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final label = station.displayName;

    return Dismissible(
      key: ValueKey('fav-${station.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await NavigationUtils.openInMaps(
            station.lat,
            station.lng,
            label: label,
          );
          return false;
        }
        await ref.read(favoritesProvider.notifier).remove(station.id);
        if (!context.mounted) return true;
        final l10nSnack = AppLocalizations.of(context);
        SnackBarHelper.showWithUndo(
          context,
          l10nSnack?.removedFromFavoritesName(label) ??
              '$label removed from favorites',
          undoLabel: l10nSnack?.undo ?? 'Undo',
          onUndo: () => ref
              .read(favoritesProvider.notifier)
              .add(station.id, stationData: station),
        );
        return true;
      },
      background: Semantics(
        label: 'Navigate to $label',
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          color: Theme.of(context).colorScheme.primary,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.navigation,
                  color: Colors.white, size: 20),
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
        label: 'Remove $label from favorites',
        child: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: Colors.red,
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
      child: StationCard(
        key: ValueKey(station.id),
        station: station,
        selectedFuelType: FuelType.all,
        isFavorite: true,
        profileFuelType: ref.watch(activeProfileProvider)?.preferredFuelType,
        onTap: () => context.push('/station/${station.id}'),
        onFavoriteTap: () {
          ref.read(favoritesProvider.notifier).remove(station.id);
        },
      ),
    );
  }
}
