import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../search/domain/entities/station.dart';

/// Station-first entry point for the fill-up form (#715).
///
/// Shown when the user taps the fill-up FAB on the consumption tab.
/// Lists the user's favorite stations so picking one attaches full
/// context to the fill-up (station id + name + fuel + current price
/// when cached), which in turn lets the receipt parser dispatch
/// directly to the right brand layout.
///
/// A "Skip — add without a station" link at the bottom preserves the
/// old blank-form flow for cases where the user logs a fill-up from a
/// station that is not in the app (travelling abroad, retroactive
/// entry, etc.).
class PickStationForFillUpScreen extends ConsumerWidget {
  const PickStationForFillUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final storage = ref.watch(storageRepositoryProvider);
    final favoriteIds = storage.getFavoriteIds();
    final stations = <Station>[];
    for (final id in favoriteIds) {
      final raw = storage.getFavoriteStationData(id);
      if (raw == null) continue;
      try {
        stations.add(Station.fromJson(raw));
      } catch (e, st) {
        debugPrint('PickStationForFillUp: skipping malformed favorite $id: $e\n$st');
      }
    }
    final profileFuel =
        ref.watch(activeProfileProvider)?.preferredFuelType;

    return PageScaffold(
      title: l?.pickStationTitle ?? 'Pick a station',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l?.tooltipBack ?? 'Back',
        onPressed: () => context.pop(),
      ),
      bodyPadding: EdgeInsets.zero,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l?.pickStationHelper ??
                  'Start the fill-up from a known station so prices, brand '
                      'and fuel type fill themselves in.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: stations.isEmpty
                ? _EmptyState(
                    message: l?.pickStationEmpty ??
                        'No favorite stations yet — add some from the Search '
                            'or Favorites tab, or skip and fill in manually.',
                  )
                : ListView.separated(
                    itemCount: stations.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final station = stations[index];
                      return _StationTile(
                        station: station,
                        profileFuel: profileFuel,
                        onTap: () => _openFillUp(context, station, profileFuel),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: TextButton.icon(
                key: const Key('pick_station_skip'),
                onPressed: () =>
                    context.pushReplacement('/consumption/add'),
                icon: const Icon(Icons.skip_next_outlined),
                label: Text(
                  l?.pickStationSkip ?? 'Skip — add without a station',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFillUp(
    BuildContext context,
    Station station,
    Object? profileFuel,
  ) {
    final price = _priceForFuel(station, profileFuel);
    context.pushReplacement(
      '/consumption/add',
      extra: <String, Object?>{
        'stationId': station.id,
        'stationName': station.brand.isNotEmpty ? station.brand : station.name,
        'fuelType': profileFuel,
        'pricePerLiter': ?price,
      },
    );
  }

  double? _priceForFuel(Station s, Object? fuel) {
    final code = _fuelKey(fuel);
    return switch (code) {
      'e5' => s.e5,
      'e10' => s.e10,
      'e98' => s.e98,
      'diesel' => s.diesel,
      'diesel_premium' => s.dieselPremium,
      'e85' => s.e85,
      'lpg' => s.lpg,
      'cng' => s.cng,
      _ => s.e10 ?? s.e5 ?? s.diesel,
    };
  }

  String? _fuelKey(Object? fuel) {
    if (fuel == null) return null;
    // Tolerate both FuelType objects and string keys without importing
    // the entity here — the caller hands whatever the profile stored.
    try {
      final dynamic f = fuel;
      return (f.apiValue as String?)?.toLowerCase();
    } catch (_) {
      return fuel.toString().toLowerCase();
    }
  }
}

class _StationTile extends StatelessWidget {
  final Station station;
  final Object? profileFuel;
  final VoidCallback onTap;

  const _StationTile({
    required this.station,
    required this.profileFuel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        station.brand.isNotEmpty ? station.brand : station.name;
    final subtitleParts = <String>[];
    if (station.street.isNotEmpty) subtitleParts.add(station.street);
    if (station.place.isNotEmpty) subtitleParts.add(station.place);
    return ListTile(
      key: Key('pick_station_tile_${station.id}'),
      leading: const Icon(Icons.local_gas_station),
      title: Text(title),
      subtitle: Text(subtitleParts.join(' • ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_border, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
