// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/location_search_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/widgets/help_banner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/presentation/widgets/route_input.dart';
import '../../domain/entities/search_mode.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/search_screen_ui_provider.dart';
import 'amenity_filter_wrap.dart';
import 'brand_filter_chips.dart';
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
    required this.onSaveDefaults,
  });

  final GlobalKey<RouteInputWidgetState> routeInputKey;
  final GlobalKey<LocationInputWidgetState> locationInputKey;
  final bool routePlanningOn;
  final SearchMode mode;
  final Future<void> Function() onGpsSearch;
  final void Function(String zip) onZipSearch;
  final void Function(ResolvedLocation city) onCitySearch;
  final void Function(List<RouteWaypoint> waypoints) onRouteSearch;
  final VoidCallback onSaveDefaults;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
            message: l10n?.helpBannerCriteria ??
                'Your profile defaults are pre-filled. Adjust criteria below to refine your search.',
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
            RouteInput(
              key: routeInputKey,
              onSearch: onRouteSearch,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            l10n?.fuelType ?? 'Fuel type',
            style: theme.textTheme.titleSmall,
          ),
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
            title: Text(l10n?.openOnlyFilter ?? 'Open only'),
            secondary: const Icon(Icons.schedule),
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.amenities ?? 'Amenities',
            style: theme.textTheme.titleSmall,
          ),
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
              return BrandFilterChips(stations: stations);
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('criteria-save-defaults-button'),
            onPressed: onSaveDefaults,
            icon: const Icon(Icons.bookmark_add),
            label: Text(
              l10n?.saveAsDefaults ?? 'Save as my defaults',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          // #2131 — the inline Search CTA moved to the central FAB.
        ],
      ),
    );
  }
}
