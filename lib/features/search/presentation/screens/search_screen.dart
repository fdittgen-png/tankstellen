// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/responsive_search_layout.dart';
import '../../../../app/shell/settings_app_bar_action.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/location/location_consent.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/frame_callbacks.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/widgets/inline_map.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../../station_detail/presentation/widgets/station_detail_inline.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/search_mode.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/selected_station_provider.dart';
import '../widgets/demo_mode_banner.dart';
import '../widgets/search_results_content.dart';
import '../widgets/search_summary_bar.dart';
import '../widgets/user_position_bar.dart';

/// Main search screen — results-first layout.
///
/// The screen is dominated by the [SearchResultsList]. A compact
/// [SearchSummaryBar] sits at the top and opens the dedicated
/// `SearchCriteriaScreen` for editing the active search.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  bool _autoSearchAttempted = false;

  @override
  void initState() {
    super.initState();
    safePostFrame(() {
      if (_autoSearchAttempted) return;
      _autoSearchAttempted = true;

      // Don't clobber an existing search result.
      final existing = ref.read(searchStateProvider);
      if (existing.hasValue && existing.value!.data.isNotEmpty) return;

      final profile = ref.read(activeProfileProvider);
      if (profile?.landingScreen == LandingScreen.cheapest) {
        final zip = profile?.homeZipCode;
        if (zip != null && zip.isNotEmpty) {
          _performZipSearch(zip);
        } else {
          _tryGpsSearchIfConsented();
        }
      } else if (profile?.landingScreen == LandingScreen.nearest) {
        _tryGpsSearchIfConsented();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Search actions
  // ---------------------------------------------------------------------------

  /// Launches a GPS search only if location consent has already been granted.
  ///
  /// If consent is missing we leave the screen in its empty state — the user
  /// can still open the criteria screen manually to start a search.
  void _tryGpsSearchIfConsented() {
    final settings = ref.read(settingsStorageProvider);
    if (!LocationConsentDialog.hasConsent(settings)) return;
    _performGpsSearch();
  }

  Future<void> _performGpsSearch() async {
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    final settings = ref.read(settingsStorageProvider);
    if (!LocationConsentDialog.hasConsent(settings)) {
      if (!mounted) return;
      final consented = await LocationConsentDialog.show(context);
      if (!consented) {
        if (mounted) {
          SnackBarHelper.show(
              context,
              AppLocalizations.of(context)?.locationDenied ??
                  'Location permission denied. You can search by postal code.');
        }
        return;
      }
      await LocationConsentDialog.recordConsent(settings);
    }

    // SearchState dispatches to EV or fuel service internally based on fuelType.
    unawaited(ref.read(searchStateProvider.notifier).searchByGps(
          fuelType: fuelType,
          radiusKm: radius,
        ));
  }

  void _performZipSearch(String zip) {
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    unawaited(ref.read(searchStateProvider.notifier).searchByZipCode(
          zipCode: zip,
          fuelType: fuelType,
          radiusKm: radius,
        ));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // #2401 — Tankerkönig returns ONLY the queried fuel's price, so
    // switching the fuel chip leaves the other fuels null. Re-run the
    // last search whenever the selected fuel changes so the data layer
    // refetches for the new fuel. `repeatLastSearch` is a no-op before
    // the first search (no last query) and while one is in flight, so
    // this is safe to fire on every chip change. Combined with the
    // `bestDisplayPrice` resolver (#2400) the map is never blank even
    // before the re-search lands.
    ref.listen<FuelType>(selectedFuelTypeProvider, (prev, next) {
      if (prev != next) {
        unawaited(
          ref.read(searchStateProvider.notifier).repeatLastSearch(),
        );
      }
    });

    final l10n = AppLocalizations.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return PageScaffold(
      title: l10n?.appTitle ?? 'Fuel Prices',
      toolbarHeight: isLandscape ? 40 : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            unawaited(
              ref.read(searchStateProvider.notifier).repeatLastSearch(),
            );
          },
          tooltip: l10n?.refreshPrices ?? 'Refresh prices',
        ),
        const SettingsAppBarAction(),
      ],
      bodyPadding: EdgeInsets.zero,
      // #2530 — the shared master/detail scaffold owns the breakpoint +
      // foldable-hinge + 1:1/2:3 ratios. Compact (< 600dp) renders
      // `_buildSearchContent` full-width, byte-for-byte unchanged. On wide
      // screens the detail pane is the selected-station inline view,
      // falling back to the inline map when nothing is selected. Search
      // thereby picks up the consistent 2:3 expanded ratio (it was a flat
      // 1:1 before this consolidation).
      body: _buildWideLayout(context),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    final selectedId = ref.watch(selectedStationProvider);

    return ResponsiveMasterDetail(
      master: _buildSearchContent(context),
      detail: selectedId != null
          ? StationDetailInline(
              stationId: selectedId,
              onClose: () =>
                  ref.read(selectedStationProvider.notifier).clear(),
            )
          : null,
      detailPlaceholder: const InlineMap(),
    );
  }

  Widget _buildSearchContent(BuildContext context) {
    final country = ref.watch(activeCountryProvider);
    final l10n = AppLocalizations.of(context);

    // #2622 — in route mode, surface the corridor's multi-country data
    // sources (#2626) so a cross-border result credits every provider, not
    // just the active country. Empty for nearby mode / single-country routes.
    final isRoute = ref.watch(activeSearchModeProvider) == SearchMode.route;
    final corridorCodes = isRoute
        ? (ref.watch(routeSearchStateProvider).value?.corridorCountryCodes ??
            const <String>{})
        : const <String>{};

    return Column(
      children: [
        DemoModeBanner(country: country, corridorCountryCodes: corridorCodes),
        // Compact summary bar — top-level entry point for editing criteria.
        const SearchSummaryBar(),
        UserPositionBar(
          onUpdatePosition: () async {
            final settings = ref.read(settingsStorageProvider);
            if (!LocationConsentDialog.hasConsent(settings)) {
              if (!mounted) return;
              final consented = await LocationConsentDialog.show(context);
              if (!consented) return;
              await LocationConsentDialog.recordConsent(settings);
            }
            try {
              await ref.read(userPositionProvider.notifier).updateFromGps();
              final state = ref.read(searchStateProvider);
              if (state.hasValue && state.value!.data.isNotEmpty) {
                unawaited(_performGpsSearch());
              }
            } catch (e, st) {
              // #1692 — never surface a raw exception toString() to the
              // user; show a localized, actionable message instead.
              // #2146 — route to the exportable log so the cause is
              // recoverable from a bug report.
              unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
                'where': 'SearchScreen: userPosition.updateFromGps',
              }));
              if (!context.mounted) return;
              SnackBarHelper.showError(
                context,
                AppLocalizations.of(context)?.searchFailedSnackbar ??
                    'Search failed — please try again',
              );
            }
          },
        ),
        // Results dominate the remaining vertical space.
        Expanded(
          child: Semantics(
            label: l10n?.searchResultsSemanticLabel ?? 'Search results',
            child: SearchResultsContent(onGpsRetry: _performGpsSearch),
          ),
        ),
      ],
    );
  }
}
