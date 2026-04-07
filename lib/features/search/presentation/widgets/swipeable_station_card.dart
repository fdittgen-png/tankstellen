import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/station.dart';
import '../../providers/search_provider.dart';
import 'station_card.dart';

/// Station card with bidirectional swipe:
/// - Swipe right -> open in maps/navigation
/// - Swipe left -> ignore/hide station
class SwipeableStationCard extends ConsumerWidget {
  final Station station;
  final bool isFavorite;
  final VoidCallback onNavigate;
  final VoidCallback onIgnore;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final PriceTier? priceTier;

  const SwipeableStationCard({
    super.key,
    required this.station,
    required this.isFavorite,
    required this.onNavigate,
    required this.onIgnore,
    required this.onTap,
    required this.onFavoriteTap,
    this.priceTier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('swipe-${station.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onNavigate();
          return false; // Don't dismiss — just trigger navigation
        } else {
          onIgnore();
          return true; // Dismiss — remove from list
        }
      },
      // Swipe right background -> Navigate
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: theme.colorScheme.primary,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.navigation, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(l10n?.navigate ?? 'Navigate',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      // Swipe left background -> Ignore
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.orange.shade700,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hide',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.visibility_off, color: Colors.white, size: 20),
          ],
        ),
      ),
      child: StationCard(
        station: station,
        selectedFuelType: ref.watch(selectedFuelTypeProvider),
        isFavorite: isFavorite,
        onTap: onTap,
        onFavoriteTap: onFavoriteTap,
        priceTier: priceTier,
      ),
    );
  }
}
