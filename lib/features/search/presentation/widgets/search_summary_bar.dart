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
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/search_mode.dart';
import '../../providers/radar_search_provider.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import '../screens/search_criteria_screen.dart';

/// Compact, 1-row summary bar shown above the results list.
///
/// Displays the current search criteria (fuel type, quantity, radius) and a
/// "Rechercher" action that opens the full [SearchCriteriaScreen]. Tapping
/// anywhere on the bar also opens the criteria screen.
///
/// Designed to be under 56dp tall and to leave the maximum amount of
/// vertical space for the results list below.
class SearchSummaryBar extends ConsumerWidget {
  const SearchSummaryBar({super.key});

  Future<void> _openCriteria(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const SearchCriteriaScreen(),
      ),
    );
  }

  String _fuelLabel(BuildContext context, FuelType type) {
    if (type == FuelType.all) {
      return AppLocalizations.of(context)?.allFuels ?? 'All';
    }
    return type.displayName;
  }

  /// The chip that follows the fuel chip. In nearby mode it shows the
  /// radius ("Within {km} km"); in route mode it shows a "Searching the
  /// route…" placeholder while results stream in, then the route-segment
  /// summary ("Every {km} km") once the search completes (#2592).
  Widget _secondChip(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
    SearchMode mode,
  ) {
    // #2676 — while the on-search Fuel Station Radar owns the results, the
    // radius chip is meaningless (the radar scans its own cached corridor);
    // replace it with a "radar result" badge so the grey bar signals the
    // list is a radar scan, not a regular search.
    if (ref.watch(radarSearchProvider).active) {
      return _SummaryChip(
        icon: const Icon(Icons.radar, size: 16),
        label: l10n?.fuelStationRadarResultBadge ?? 'Fuel Station Radar result',
      );
    }
    if (mode != SearchMode.route) {
      final kmText = ref.watch(searchRadiusProvider).round().toString();
      return _SummaryChip(
        icon: const Icon(Icons.radar, size: 16),
        label: l10n?.searchCriteriaRadiusBadge(kmText) ?? 'Within $kmText km',
      );
    }
    final routeState = ref.watch(routeSearchStateProvider);
    final searching =
        routeState.isLoading || routeState.value?.isPartial == true;
    if (searching) {
      // #2783 — a live spinner (not the static route icon) so a route search
      // in progress — including the progressive/partial phase where real
      // cards are already showing — clearly reads as still ongoing.
      return _SummaryChip(
        icon: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: l10n?.routeSearchingChip ?? 'Searching the route…',
      );
    }
    final segmentText =
        ref.watch(routeSegmentSearchParamProvider).round().toString();
    return _SummaryChip(
      icon: const Icon(Icons.route, size: 16),
      label: l10n?.routeSegmentSummaryBadge(segmentText) ??
          'Every $segmentText km',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fuelType = ref.watch(selectedFuelTypeProvider);
    final theme = Theme.of(context);

    // #2592 — route mode replaces the meaningless radius chip with the
    // route-planning summary. Gate on Feature.routePlanning exactly as the
    // criteria screen does, so a gated-off install keeps the radius chip.
    final storedMode = ref.watch(activeSearchModeProvider);
    final manifest = ref.watch(featureManifestProvider);
    final enabledFlags = ref.watch(enabledFeaturesProvider);
    final mode = isEffectivelyEnabled(
            Feature.routePlanning, manifest, enabledFlags)
        ? storedMode
        : SearchMode.nearby;

    final fuelColor = FuelColors.forType(fuelType);

    return Semantics(
      label: l10n?.searchCriteriaSemanticLabel ??
          'Search criteria summary. Tap to edit.',
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: () => _openCriteria(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Fuel type chip
                        _SummaryChip(
                          icon: Icon(fuelType.icon,
                              size: 16, color: fuelColor),
                          label: _fuelLabel(context, fuelType),
                        ),
                        const SizedBox(width: 6),
                        // Second chip: radius (nearby) or route-planning
                        // summary (route) — see [_secondChip] (#2592).
                        _secondChip(context, ref, l10n, mode),
                      ],
                    ),
                  ),
                ),
                // #2131 — inline "Search" tonal button removed; the
                // central FAB owns the open-criteria action now. The
                // tap-anywhere-on-bar affordance below is kept as a
                // discoverable shortcut on the status row itself.
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // #2117 — chip sits on the summary bar's `surfaceContainerHighest`
        // surface; surfaceContainerLow is the M3 inversion that reads as
        // a recessed pill rather than fighting the bar.
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
