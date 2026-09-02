// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/brand_registry.dart';
import '../../../../core/domain/station.dart';
import '../../providers/brand_filter_provider.dart';
import 'criteria/criteria_chip_group.dart';

/// Wrapping brand filter chips with major brands grouped (#3927).
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

    // #3927 — the brand strip used to scroll horizontally and clipped its
    // labels mid-word ("Intermarch…"). It now wraps like the fuel and
    // amenity groups: the "All" / highway toggles are pinned, the brands
    // fold behind one "Show more (n)" chip, and an active brand filter is
    // always visible whatever its rank.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CriteriaChipGroup(
        groupKeyPrefix: 'criteria-brand',
        selectedFlags: [
          for (final brand in sortedBrands) selectedBrands.contains(brand),
        ],
        pinned: [
          // "All" chip
          ChoiceChip(
            key: const ValueKey('criteria-brand-all'),
            avatar: const Icon(Icons.select_all, size: 16),
            label: Text(l10n.brandFilterAll),
            selected: isAllSelected,
            onSelected: (_) => ref.read(selectedBrandsProvider.notifier).clear(),
            visualDensity: VisualDensity.compact,
          ),
          // Highway exclusion chip
          if (hasHighwayStations)
            FilterChip(
              avatar: const Icon(Icons.no_crash, size: 16),
              label: Text(l10n.brandFilterNoHighway),
              selected: excludeHighway,
              onSelected: (_) =>
                  ref.read(excludeHighwayStationsProvider.notifier).toggle(),
              visualDensity: VisualDensity.compact,
            ),
          // Highway-only chip
          if (hasHighwayStations)
            FilterChip(
              label: Text(l10n.brandFilterHighway),
              selected: selectedBrands.contains('Autoroute'),
              onSelected: (_) =>
                  ref.read(selectedBrandsProvider.notifier).toggle('Autoroute'),
              visualDensity: VisualDensity.compact,
            ),
        ],
        // Brand chips (grouped by canonical name)
        chips: [
          for (final brand in sortedBrands)
            FilterChip(
              key: ValueKey('criteria-brand-$brand'),
              label: Text('$brand (${brandCounts[brand]})'),
              selected: selectedBrands.contains(brand),
              onSelected: (_) =>
                  ref.read(selectedBrandsProvider.notifier).toggle(brand),
              visualDensity: VisualDensity.compact,
            ),
        ],
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
