// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../feature_management/domain/feature_dependency_graph.dart';
import '../../../route_search/providers/route_search_params_provider.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/search_mode.dart';
import '../../providers/radar_search_provider.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import '../screens/search_criteria_screen.dart';
import 'results/price_freshness_segment.dart';
import 'results/summary_chip.dart';
import 'user_position_bar.dart';

/// **Row A** of the two-row results chrome (#3926, epic #3925).
///
/// One tappable band that replaced three stacked strips: the country data
/// source link, the fuel/radius chip row and the "Your position: GPS
/// (1 min)" bar with its second refresh icon. It now carries four
/// segments — fuel · radius (or "along the route") · position or search
/// address · price freshness — and opens the full [SearchCriteriaScreen]
/// on tap, exactly as the old chip row did.
///
/// The segments live in a [Wrap]: an expanded translation moves a whole
/// pill to the next line instead of clipping it, so the band survives
/// en_XA at 320 dp and a 1.3× text scale.
///
/// #3939 (Epic #3937) — every segment renders its **value only**: `E85`,
/// not "E85 / Bioéthanol"; `10 km`, not "Within 10 km"; `1 min`, not
/// "Prices from 1 min ago". The leaf, the radius glyph and the clock
/// already say the nouns those labels repeated, and the full sentence
/// survives as the pill's tooltip and its screen-reader label — so a
/// long-press and a screen reader lose nothing at all.
///
/// The open-data attribution that used to sit above this bar now lives in
/// the footer under the results list, and the position bar's refresh icon
/// was folded into the single app-bar refresh.
class SearchSummaryBar extends ConsumerWidget {
  const SearchSummaryBar({super.key});

  Future<void> _openCriteria(BuildContext context) async {
    final nav = Navigator.of(context);
    // #2810 — don't stack a duplicate criteria modal if one is already on top
    // (the summary bar stays visible behind the modal). The shared guard +
    // tagged route name keep every push path consistent.
    if (searchCriteriaRouteIsCurrent(nav)) return;
    await nav.push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const SearchCriteriaScreen(),
        settings: const RouteSettings(name: kSearchCriteriaRouteName),
      ),
    );
  }

  /// The fuel pill's VISIBLE text: the pump code alone (`E85`, `Diesel`,
  /// and the PEMEX grade names in Mexico). The wildcard keeps its word —
  /// "All" has no code.
  String _fuelValue(AppLocalizations l10n, FuelType type, String countryCode) {
    if (type == FuelType.all) return l10n.allFuels;
    return fuelDisplayLabel(type, countryCode: countryCode);
  }

  /// What the pill says on long-press and to a screen reader: the full
  /// name the visible code stands for.
  String _fuelTooltip(AppLocalizations l10n, FuelType type) =>
      l10n.searchSummaryFuelTooltip(
        type == FuelType.all ? l10n.allFuels : type.displayName,
      );

  /// The segment that follows the fuel pill. In nearby mode it shows the
  /// radius ("Within {km} km"); in route mode it names the corridor and its
  /// sampling spacing ("Along the route · every {km} km", #3926) — or a
  /// "Searching the route…" placeholder while results stream in (#2592).
  Widget _scopeSegment(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SearchMode mode,
  ) {
    // #2676 — while the on-search Fuel Station Radar owns the results, the
    // radius segment is meaningless (the radar scans its own cached
    // corridor); it becomes a "radar result" badge so the bar signals the
    // list is a radar scan, not a regular search.
    if (ref.watch(radarSearchProvider.select((s) => s.active))) {
      return SummaryChip(
        icon: const Icon(Icons.radar, size: 14),
        label: l10n.fuelStationRadarResultBadge,
      );
    }
    if (mode != SearchMode.route) {
      final kmText = ref.watch(searchRadiusProvider).round().toString();
      // #3939 — the radius glyph already says "within a radius of"; the
      // pill keeps the number and hands the sentence to the tooltip.
      return SummaryChip(
        key: const Key('search_summary_radius'),
        icon: const Icon(Icons.radar, size: 14),
        label: l10n.searchSummaryRadiusValue(kmText),
        tooltip: l10n.searchCriteriaRadiusBadge(kmText),
      );
    }
    final routeState = ref.watch(routeSearchStateProvider);
    final searching =
        routeState.isLoading || routeState.value?.isPartial == true;
    if (searching) {
      // #2783 — a live spinner (not the static route icon) so a route search
      // in progress — including the progressive/partial phase where real
      // cards are already showing — clearly reads as still ongoing.
      return SummaryChip(
        icon: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: l10n.routeSearchingChip,
      );
    }
    final segmentText = ref
        .watch(routeSegmentSearchParamProvider)
        .round()
        .toString();
    return SummaryChip(
      icon: const Icon(Icons.route, size: 14),
      label: l10n.searchSummaryAlongRoute(segmentText),
    );
  }

  /// Position or address segment. A ZIP/address search names the place it
  /// searched around; otherwise the user's own position (source + age) is
  /// shown by [UserPositionBar], now a compact pill rather than its own
  /// full-width strip.
  Widget _whereSegment(WidgetRef ref) {
    final location = ref.watch(searchLocationProvider);
    if (location.isNotEmpty) {
      return SummaryChip(
        key: const Key('search_summary_address'),
        icon: const Icon(Icons.place_outlined, size: 14),
        label: location,
      );
    }
    return const UserPositionBar();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fuelType = ref.watch(selectedFuelTypeProvider);
    final countryCode = ref.watch(activeCountryProvider).code;
    final theme = Theme.of(context);

    // #2592 — route mode replaces the meaningless radius segment with the
    // route-planning summary. Gate on Feature.routePlanning exactly as the
    // criteria screen does, so a gated-off install keeps the radius chip.
    final storedMode = ref.watch(activeSearchModeProvider);
    final manifest = ref.watch(featureManifestProvider);
    final enabledFlags = ref.watch(enabledFeaturesProvider);
    final mode =
        isEffectivelyEnabled(Feature.routePlanning, manifest, enabledFlags)
        ? storedMode
        : SearchMode.nearby;

    // #3926 — the radar re-scans continuously and paints its own result set,
    // so the regular search's download age would describe a list the user is
    // not looking at. No freshness segment while it owns the results.
    final radarActive = ref.watch(radarSearchProvider.select((s) => s.active));

    return Semantics(
      label: l10n.searchCriteriaSemanticLabel,
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: () => _openCriteria(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SummaryChip(
                  key: const Key('search_summary_fuel'),
                  icon: Icon(
                    fuelType.icon,
                    size: 14,
                    color: FuelColors.forType(fuelType),
                  ),
                  label: _fuelValue(l10n, fuelType, countryCode),
                  tooltip: _fuelTooltip(l10n, fuelType),
                ),
                _scopeSegment(context, ref, l10n, mode),
                _whereSegment(ref),
                if (!radarActive) const PriceFreshnessSegment(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
