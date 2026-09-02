// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/fuel_colors.dart';
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

  String _fuelLabel(BuildContext context, FuelType type) {
    if (type == FuelType.all) {
      return AppLocalizations.of(context).allFuels;
    }
    return type.displayName;
  }

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
      return SummaryChip(
        icon: const Icon(Icons.radar, size: 14),
        label: l10n.searchCriteriaRadiusBadge(kmText),
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
                  icon: Icon(
                    fuelType.icon,
                    size: 14,
                    color: FuelColors.forType(fuelType),
                  ),
                  label: _fuelLabel(context, fuelType),
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
