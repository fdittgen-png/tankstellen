import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/station.dart';
import '../../providers/brand_filter_provider.dart';

/// Horizontally scrollable brand filter chips extracted from search results.
///
/// Shows an "All" chip to reset, followed by one chip per unique brand
/// (sorted alphabetically). Multi-select: tapping a chip toggles it.
/// Also includes a highway exclusion toggle when any station has
/// stationType == "A".
class BrandFilterChips extends ConsumerWidget {
  /// The full unfiltered station list (before brand filtering).
  final List<Station> stations;

  const BrandFilterChips({super.key, required this.stations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedBrands = ref.watch(selectedBrandsProvider);
    final excludeHighway = ref.watch(excludeHighwayStationsProvider);

    // Extract unique brands, sorted alphabetically, skip empty
    final brands = _extractBrands(stations);
    if (brands.isEmpty) return const SizedBox.shrink();

    final hasHighwayStations = stations.any((s) => s.stationType == 'A');
    final isAllSelected = selectedBrands.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "All" chip
            Semantics(
              label: '${l10n?.brandFilterAll ?? "All"}${isAllSelected ? ", selected" : ""}',
              child: ChoiceChip(
                avatar: const Icon(Icons.select_all, size: 16),
                label: Text(l10n?.brandFilterAll ?? 'All'),
                selected: isAllSelected,
                onSelected: (_) =>
                    ref.read(selectedBrandsProvider.notifier).clear(),
                visualDensity: VisualDensity.compact,
              ),
            ),
            // Highway exclusion chip (only if highway stations exist)
            if (hasHighwayStations) ...[
              const SizedBox(width: 6),
              Semantics(
                label: '${l10n?.brandFilterNoHighway ?? "No highway"}${excludeHighway ? ", selected" : ""}',
                child: FilterChip(
                  avatar: const Icon(Icons.no_crash, size: 16),
                  label: Text(l10n?.brandFilterNoHighway ?? 'No highway'),
                  selected: excludeHighway,
                  onSelected: (_) => ref
                      .read(excludeHighwayStationsProvider.notifier)
                      .toggle(),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
            // Brand chips
            for (final brand in brands) ...[
              const SizedBox(width: 6),
              Semantics(
                label: '$brand${selectedBrands.contains(brand) ? ", selected" : ""}',
                child: FilterChip(
                  label: Text(brand),
                  selected: selectedBrands.contains(brand),
                  onSelected: (_) =>
                      ref.read(selectedBrandsProvider.notifier).toggle(brand),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Extract unique non-empty brand names, sorted alphabetically.
  static List<String> _extractBrands(List<Station> stations) {
    final brandSet = <String>{};
    for (final s in stations) {
      final brand = s.brand.trim();
      if (brand.isNotEmpty) {
        brandSet.add(brand);
      }
    }
    final sorted = brandSet.toList()..sort();
    return sorted;
  }
}

/// Applies brand and highway filters to a station list.
///
/// Returns all stations if no filters are active.
List<Station> applyBrandFilter(
  List<Station> stations, {
  required Set<String> selectedBrands,
  required bool excludeHighway,
}) {
  var result = stations;

  if (selectedBrands.isNotEmpty) {
    result = result.where((s) => selectedBrands.contains(s.brand.trim())).toList();
  }

  if (excludeHighway) {
    result = result.where((s) => s.stationType != 'A').toList();
  }

  return result;
}
