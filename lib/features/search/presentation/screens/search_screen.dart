import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/responsive_search_layout.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/location/location_consent.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/frame_callbacks.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/widgets/inline_map.dart';
import '../../providers/search_provider.dart';
import '../widgets/demo_mode_banner.dart';
import '../widgets/search_results_list.dart';
import '../widgets/search_summary_bar.dart';
import '../widgets/user_position_bar.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/ev_search_provider.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/services/service_result.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/search_mode.dart';
import '../../domain/entities/search_result_item.dart';
import '../../domain/entities/station.dart';
import '../../providers/selected_station_provider.dart';
import '../widgets/ev_station_card.dart';
import '../../../station_detail/presentation/widgets/station_detail_inline.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/providers/profile_provider.dart';
import '../widgets/nearest_shortcut_card.dart';
import '../widgets/route_results_view.dart';

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

    if (fuelType == FuelType.electric) {
      try {
        final locationService = ref.read(locationServiceProvider);
        final position = await locationService.getCurrentPosition();
        unawaited(ref.read(eVSearchStateProvider.notifier).searchNearby(
              lat: position.latitude,
              lng: position.longitude,
              radiusKm: radius,
            ));
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(
              context,
              '${AppLocalizations.of(context)?.gpsError ?? "GPS error"}: $e');
        }
      }
    } else {
      unawaited(ref.read(searchStateProvider.notifier).searchByGps(
            fuelType: fuelType,
            radiusKm: radius,
          ));
    }
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
    final l10n = AppLocalizations.of(context);
    final isWide = isWideScreen(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(l10n?.appTitle ?? 'Fuel Prices'),
        ),
        toolbarHeight: isLandscape ? 40 : null,
      ),
      body: isWide
          ? _buildWideLayout(context)
          : _buildSearchContent(context),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    final selectedId = ref.watch(selectedStationProvider);

    return Row(
      children: [
        Expanded(child: _buildSearchContent(context)),
        const VerticalDivider(width: 1),
        Expanded(
          child: selectedId != null
              ? StationDetailInline(
                  stationId: selectedId,
                  onClose: () => ref.read(selectedStationProvider.notifier).clear(),
                )
              : const InlineMap(),
        ),
      ],
    );
  }

  Widget _buildSearchContent(BuildContext context) {
    final country = ref.watch(activeCountryProvider);
    final searchState = ref.watch(searchStateProvider);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        DemoModeBanner(country: country),
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
            } catch (e) {
              if (!context.mounted) return;
              SnackBarHelper.showError(context, e.toString());
            }
          },
        ),
        // Results dominate the remaining vertical space.
        Expanded(
          child: Semantics(
            label: 'Search results',
            child: _buildResults(context, l10n, searchState),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(
    BuildContext context,
    AppLocalizations? l10n,
    AsyncValue<ServiceResult<List<Station>>> searchState,
  ) {
    final searchMode = ref.watch(activeSearchModeProvider);
    final fuelType = ref.watch(selectedFuelTypeProvider);

    // Route mode — RouteResultsView returns slivers, wrap in CustomScrollView
    if (searchMode == SearchMode.route) {
      return const CustomScrollView(
        slivers: [RouteResultsView()],
      );
    }

    // EV mode (when Electric fuel type is selected)
    if (fuelType == FuelType.electric) {
      final evState = ref.watch(eVSearchStateProvider);
      return evState.when(
        data: (result) {
          if (result.data.isEmpty) {
            return EmptyState(
              icon: Icons.ev_station,
              title: l10n?.searchEvStations ??
                  'Search to find EV charging stations',
              actionLabel: l10n?.searchNearby ?? 'Search nearby',
              onAction: _performGpsSearch,
            );
          }
          return ListView.builder(
            itemCount: result.data.length,
            itemBuilder: (context, index) {
              final station = result.data[index];
              return EVStationCard(
                key: ValueKey('ev-${station.id}'),
                result: EVStationResult(station),
                onTap: () => context.push('/ev-station', extra: station),
              );
            },
          );
        },
        loading: () => const ShimmerStationList(),
        error: (error, _) =>
            ServiceChainErrorWidget(error: error, onRetry: _performGpsSearch),
      );
    }

    // Default: fuel station results
    return searchState.when(
      data: (result) {
        if (result.data.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NearestShortcutCard(onTap: _performGpsSearch),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.startSearch ?? 'Search to find fuel stations.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return SearchResultsList(result: result, onRefresh: _performGpsSearch);
      },
      loading: () => const ShimmerStationList(),
      error: (error, _) =>
          ServiceChainErrorWidget(error: error, onRetry: _performGpsSearch),
    );
  }
}
