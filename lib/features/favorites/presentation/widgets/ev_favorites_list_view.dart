import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ev/domain/entities/charging_station.dart';
import '../../providers/ev_favorites_provider.dart';
import 'ev_favorite_card.dart';
import 'favorites_section_header.dart';

/// Standalone ListView that renders only the user's favorited EV charging
/// stations. Used by the Favorites screen when the user has no fuel-station
/// favorites — the fuel section is suppressed and this view takes over.
///
/// Pulled out of `favorites_screen.dart` so the screen drops the inline
/// 30-line `_buildEvFavoritesSection` helper and so the EV-only list can
/// be exercised by widget tests in isolation.
class EvFavoritesListView extends ConsumerWidget {
  final List<ChargingStation> evStations;

  const EvFavoritesListView({super.key, required this.evStations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        FavoritesSectionHeader(
          icon: Icons.ev_station,
          label: l10n?.evChargingSection ?? 'EV Charging',
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        ),
        ...evStations.map((ev) => EvFavoriteCard(
              key: ValueKey('ev-${ev.id}'),
              station: ev,
              onTap: () => context.push('/ev-station', extra: ev),
              onFavoriteTap: () {
                ref.read(evFavoritesProvider.notifier).remove(ev.id);
                SnackBarHelper.show(
                  context,
                  l10n?.removedFromFavorites ?? 'Removed from favorites',
                );
              },
            )),
      ],
    );
  }
}
