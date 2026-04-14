import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/brand_registry.dart';
import '../../domain/entities/station.dart';
import '../../providers/brand_filter_provider.dart';

/// Horizontally scrollable brand filter chips with major brands grouped.
///
/// Shows an "All" chip to reset, then major brands (from [BrandRegistry]),
/// then "Others" for independent/unrecognized brands. Also includes a
/// highway exclusion toggle when highway stations exist.
class BrandFilterChips extends ConsumerWidget {
  final List<Station> stations;

  const BrandFilterChips({super.key, required this.stations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedBrands = ref.watch(selectedBrandsProvider);
    final excludeHighway = ref.watch(excludeHighwayStationsProvider);

    final brandCounts = extractGroupedBrands(stations);
    if (brandCounts.isEmpty) return const SizedBox.shrink();

    final hasHighwayStations = stations.any((s) => s.stationType == 'A');
    final isAllSelected = selectedBrands.isEmpty;

    // Sort: major brands first (by count descending), "Others" last
    final sortedBrands = brandCounts.keys.toList()
      ..sort((a, b) {
        if (a == BrandRegistry.othersLabel) return 1;
        if (b == BrandRegistry.othersLabel) return -1;
        return (brandCounts[b] ?? 0).compareTo(brandCounts[a] ?? 0);
      });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "All" chip
            ChoiceChip(
              avatar: const Icon(Icons.select_all, size: 16),
              label: Text(l10n?.brandFilterAll ?? 'All'),
              selected: isAllSelected,
              onSelected: (_) =>
                  ref.read(selectedBrandsProvider.notifier).clear(),
              visualDensity: VisualDensity.compact,
            ),
            // Highway exclusion chip
            if (hasHighwayStations) ...[
              const SizedBox(width: 6),
              FilterChip(
                avatar: const Icon(Icons.no_crash, size: 16),
                label: Text(l10n?.brandFilterNoHighway ?? 'No highway'),
                selected: excludeHighway,
                onSelected: (_) => ref
                    .read(excludeHighwayStationsProvider.notifier)
                    .toggle(),
                visualDensity: VisualDensity.compact,
              ),
            ],
            // Highway-only chip
            if (hasHighwayStations) ...[
              const SizedBox(width: 6),
              FilterChip(
                label: Text(l10n?.brandFilterHighway ?? 'Autoroute'),
                selected: selectedBrands.contains('Autoroute'),
                onSelected: (_) =>
                    ref.read(selectedBrandsProvider.notifier).toggle('Autoroute'),
                visualDensity: VisualDensity.compact,
              ),
            ],
            // Brand chips (grouped by canonical name)
            for (final brand in sortedBrands) ...[
              const SizedBox(width: 6),
              FilterChip(
                label: Text('$brand (${brandCounts[brand]})'),
                selected: selectedBrands.contains(brand),
                onSelected: (_) =>
                    ref.read(selectedBrandsProvider.notifier).toggle(brand),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Group stations by canonical brand name. Returns {brand: count}.
  ///
  /// Previously this silently dropped stations whose brand string was
  /// empty (via `.where((b) => b.isNotEmpty)`). That caused the chip
  /// counts to not add up to the total station count — a 10-station
  /// search could render a chip strip totalling 7, with three stations
  /// invisible in the filter UI even though they still appeared in the
  /// results list (#481). The fix passes every station through
  /// `BrandRegistry.countByBrand`, which handles empty strings by
  /// bucketing them into `Others` — keeping the chip counts in sync
  /// with the filter predicate in `applyBrandFilter`.
  @visibleForTesting
  static Map<String, int> extractGroupedBrands(List<Station> stations) {
    final rawBrands = stations.map((s) => s.brand.trim()).toList();
    return BrandRegistry.countByBrand(rawBrands);
  }
}

/// Applies brand and highway filters to a station list.
///
/// Uses [BrandRegistry] to match canonical brand names, so selecting
/// "TotalEnergies" matches "Total", "Total Access", "TOTALENERGIES", etc.
List<Station> applyBrandFilter(
  List<Station> stations, {
  required Set<String> selectedBrands,
  required bool excludeHighway,
}) {
  var result = stations;

  if (selectedBrands.isNotEmpty) {
    result = result.where((s) {
      final canonical = BrandRegistry.canonicalize(s.brand.trim());
      final label = canonical ?? BrandRegistry.othersLabel;

      // Check if any selected brand matches
      if (selectedBrands.contains(label)) return true;

      // Special case: "Autoroute" matches highway stations
      if (selectedBrands.contains('Autoroute') && s.stationType == 'A') {
        return true;
      }

      return false;
    }).toList();
  }

  if (excludeHighway) {
    result = result.where((s) => s.stationType != 'A').toList();
  }

  return result;
}
