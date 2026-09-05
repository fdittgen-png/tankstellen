// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/location_search_service.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/widgets/help_banner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/presentation/widgets/route_input.dart';
import '../../../../core/domain/search_mode.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/search_screen_ui_provider.dart';
import 'amenity_filter_wrap.dart';
import 'brand_filter_chips.dart';
import 'criteria/criteria_section_header.dart';
import 'fuel_type_selector.dart';
import 'location_input.dart' show LocationInput, LocationInputWidgetState;
import 'route_planning_controls.dart';
import 'search_mode_toggle.dart';
import 'search_radius_slider.dart';

/// The scrollable form body of the search-criteria screen, extracted from
/// `SearchCriteriaScreen` so the screen stays under the file-length cap
/// (#2592). All search/save actions are owned by the parent State and
/// passed in as callbacks; the form watches its own filter providers and
/// surfaces the radius (nearby) vs the route-planning controls (route).
///
/// #3927 — "Save as my defaults" lives in the app-bar overflow, and the
/// form carries no primary action: the shell's green Search button IS the
/// sheet's submit (the screen registers a `SearchFabAction` that fires the
/// same dispatch).
///
/// #3961 — the sticky bar that briefly held a second Search button is
/// gone; its two survivors end the form instead: the reason the search is
/// unavailable, when it is, and Reset.
class SearchCriteriaForm extends ConsumerWidget {
  const SearchCriteriaForm({
    super.key,
    required this.routeInputKey,
    required this.locationInputKey,
    required this.routePlanningOn,
    required this.mode,
    required this.onGpsSearch,
    required this.onZipSearch,
    required this.onCitySearch,
    required this.onRouteSearch,
    required this.onReset,
    this.disabledReason,
  });

  final GlobalKey<RouteInputWidgetState> routeInputKey;
  final GlobalKey<LocationInputWidgetState> locationInputKey;
  final bool routePlanningOn;
  final SearchMode mode;
  final Future<void> Function() onGpsSearch;
  final void Function(String zip) onZipSearch;
  final void Function(ResolvedLocation city) onCitySearch;
  final void Function(List<RouteWaypoint> waypoints) onRouteSearch;

  /// #3961 — restores the saved defaults. The Reset that used to sit in
  /// the sticky bar is the LAST thing in the criteria now: "start over"
  /// belongs at the end of the form, not beside the primary action.
  final VoidCallback onReset;

  /// Why the search cannot run right now (route mode without both
  /// endpoints, or a search already in flight), or null when it can.
  /// The shell's green Search button greys out in that state, and a
  /// greyed button that does not say why is exactly what #3927 fixed —
  /// so the reason survives the bar's removal, here at the end of the
  /// form beside [onReset].
  final String? disabledReason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final radius = ref.watch(searchRadiusProvider);
    final openOnly = ref.watch(openOnlyFilterProvider);
    final amenities = ref.watch(selectedAmenitiesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      // #522 / #1962 — compact the form so every filter fits above the
      // fold on an S23 Ultra at 1x text scale. Section gaps are 8 dp,
      // label-to-control gaps 4 dp, and the surrounding padding is 8 dp
      // at the top.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HelpBanner(
            storageKey: StorageKeys.helpBannerCriteria,
            icon: Icons.lightbulb_outline,
            message: l10n.helpBannerCriteria,
          ),
          if (routePlanningOn) ...[
            SearchModeToggle(
              mode: mode,
              onChanged: (m) =>
                  ref.read(activeSearchModeProvider.notifier).set(m),
            ),
            const SizedBox(height: 8),
          ],
          // #2111 — segmented control labels the active mode.
          if (mode == SearchMode.nearby) ...[
            LocationInput(
              key: locationInputKey,
              onGpsSearch: onGpsSearch,
              onZipSearch: onZipSearch,
              onCitySearch: onCitySearch,
            ),
          ] else ...[
            RouteInput(key: routeInputKey, onSearch: onRouteSearch),
          ],
          const SizedBox(height: 8),
          CriteriaSectionHeader(l10n.fuelType),
          const SizedBox(height: 4),
          const FuelTypeSelector(),
          const SizedBox(height: 8),
          // #2592 — the radius is meaningless along a route; route mode
          // surfaces the route-planning params instead.
          if (mode == SearchMode.nearby)
            SearchRadiusSlider(
              radiusKm: radius,
              onChanged: (value) =>
                  ref.read(searchRadiusProvider.notifier).set(value),
            )
          else if (mode == SearchMode.route)
            const RoutePlanningControls(),
          SwitchListTile(
            key: const ValueKey('criteria-open-only-toggle'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: openOnly,
            onChanged: (value) {
              ref.read(openOnlyFilterProvider.notifier).set(value);
            },
            title: Text(l10n.openOnlyFilter),
            secondary: const Icon(Icons.schedule),
          ),
          const SizedBox(height: 4),
          CriteriaSectionHeader(l10n.amenities),
          const SizedBox(height: 4),
          AmenityFilterWrap(
            selected: amenities,
            onToggle: (a) =>
                ref.read(selectedAmenitiesProvider.notifier).toggle(a),
          ),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final stations = ref.watch(fuelStationsProvider);
              if (stations.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CriteriaSectionHeader(l10n.criteriaBrands),
                  const SizedBox(height: 4),
                  BrandFilterChips(stations: stations),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (disabledReason case final reason?) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reason,
                    key: const ValueKey('criteria-disabled-reason'),
                    style: AppText.label(context),
                    // One line for every shipped translation at 360 dp;
                    // the second is the escape valve for en_XA at 320 dp,
                    // so the reason degrades to wrapping rather than to a
                    // truncated half-sentence.
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            key: const ValueKey('criteria-reset-button'),
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: Text(l10n.criteriaReset),
          ),
        ],
      ),
    );
  }
}
