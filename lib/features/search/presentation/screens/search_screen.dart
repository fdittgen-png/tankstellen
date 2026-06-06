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
import '../../../consumption/data/pip_controller.dart';
import '../../../consumption/providers/pip_mode_provider.dart';
import '../../../map/presentation/widgets/inline_map.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../../station_detail/presentation/widgets/station_detail_inline.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/search_mode.dart';
import '../../providers/radar_pin_provider.dart';
import '../../providers/radar_search_provider.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/selected_station_provider.dart';
import '../widgets/demo_mode_banner.dart';
import '../widgets/radar_pin_help_sheet.dart';
import '../widgets/radar_screen_pin_mixin.dart';
import '../widgets/radar_search_fab.dart';
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

class _SearchScreenState extends ConsumerState<SearchScreen>
    with RadarScreenPinMixin {
  bool _autoSearchAttempted = false;

  /// #2677 — the single app-wide PiP controller (`pipControllerProvider`).
  /// Never construct a second one: the `tankstellen/pip` channel admits one
  /// handler. Drives the minimise button + (#2678) the auto-PiP opt-in.
  late final PipController _pip;

  /// #2678 — last value pushed to [PipController.setAutoEnterEnabled], so the
  /// build only crosses the channel when the radar opt-in actually changes.
  bool? _radarAutoPipRequested;

  @override
  void initState() {
    super.initState();
    _pip = ref.read(pipControllerProvider);
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
  // #2677 — radar pin + reduce-to-PiP (Android-only via PipController.isSupported)
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    // #2677 — release the wake lock + restore system UI if the user leaves
    // while pinned (best-effort, sync). See RadarScreenPinMixin.
    disposePin();
    // #2678 — drop the auto-PiP opt-in so leaving the app from an unrelated
    // screen never shrinks the search UI into a tile. The controller itself
    // is owned by `pipControllerProvider`, not disposed here.
    unawaited(_pip.setAutoEnterEnabled(false));
    super.dispose();
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

    // #2677 — while the on-search radar owns the results, surface the same
    // pin + reduce-to-PiP controls the trip-recording screen carries. Both
    // are Android-only (the minimise button hides where PiP can't host app
    // UI); iOS shows neither — gated on the radar being active.
    final radarActive = ref.watch(radarSearchProvider).active;

    // #2678 — arm the native auto-PiP opt-in while the radar is active, so the
    // app shrinks into the tile (onUserLeaveHint) when the user leaves to
    // Maps mid-scan — mirroring the trip-recording arming. The global OS
    // observer (TankstellenApp) is unchanged; only this per-screen flag is
    // new. Disarmed on dismiss (radar inactive) + in dispose. Android-only:
    // `setAutoEnterEnabled` is an inert no-op where PiP can't host app UI.
    if (radarActive != _radarAutoPipRequested) {
      _radarAutoPipRequested = radarActive;
      unawaited(_pip.setAutoEnterEnabled(radarActive));
      // #2785 — auto-pin the moment the radar starts when the preference is
      // on (defaults true), mirroring the trip-recording autoPin. Scheduled
      // post-frame so we never setState during build; re-checks the radar is
      // still active and the user hasn't already pinned. A later manual unpin
      // stands; the next radar start re-applies.
      if (radarActive && !pinned && ref.read(radarAutoPinProvider)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !pinned && ref.read(radarSearchProvider).active) {
            unawaited(enablePinNow());
          }
        });
      }
    }

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
        if (radarActive) ...[
          // Pin — wake lock + immersive bars (copied from the trip screen).
          Semantics(
            container: true,
            button: true,
            toggled: pinned,
            label: pinned
                ? (l10n?.tripRecordingPinSemanticOn ?? 'Unpin recording form')
                : (l10n?.tripRecordingPinSemanticOff ?? 'Pin recording form'),
            // #2785 — long-press opens the pin-help sheet (what pinning does
            // + the "always pin when the radar starts" toggle).
            child: GestureDetector(
              onLongPress: () =>
                  showRadarPinHelp(context, onEnableNow: enablePinNow),
              child: IconButton(
                key: const Key('radarPinButton'),
                icon: Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: pinned ? Theme.of(context).colorScheme.primary : null,
                ),
                tooltip: l10n?.tripRecordingPinTooltip ??
                    'Pinning keeps the screen on — uses more battery',
                isSelected: pinned,
                onPressed: togglePin,
              ),
            ),
          ),
          // Minimise to a PiP tile — Android-only.
          if (_pip.isSupported)
            IconButton(
              key: const Key('radarMinimiseButton'),
              icon: const Icon(Icons.picture_in_picture_alt),
              tooltip: l10n?.tripRecordingMinimiseTooltip ??
                  'Minimise to a floating tile',
              onPressed: () => _pip.enterPip(),
            ),
        ],
        const SettingsAppBarAction(),
      ],
      bodyPadding: EdgeInsets.zero,
      // #2682 — the Fuel Station Radar launches from a "Start recording"-style
      // extended-FAB pill (`RadarSearchFab`) floated bottom-right via the
      // Scaffold FAB slot, clear of the shell's central search FAB (docked into
      // the bottom-nav notch) + the bottom nav itself. The pill flips to a stop
      // treatment while the radar owns the results list.
      floatingActionButton: const RadarSearchFab(),
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

    // #2939 — while the Fuel Station Radar owns the results, the split MAP
    // stays put and SYNCS the selection (clustered, fit-to-pane, two-way
    // list<->map sync) — exactly like route mode keeps its map. Selecting a
    // row must NOT swap the right pane to the detail card and hide the radar
    // map. The dedicated detail is still reachable from the marker/row's
    // "view details" affordance (the list-card detail navigation). Off radar,
    // the pre-#2939 behaviour is unchanged: a selection shows the inline
    // detail, falling back to the map placeholder.
    final radarActive = ref.watch(radarSearchProvider).active;

    return ResponsiveMasterDetail(
      master: _buildSearchContent(context),
      detail: (!radarActive && selectedId != null)
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
    // just the active country. #2680 — credit only the countries that
    // actually PRODUCED a station (contributingCountryCodes), not every
    // country the corridor geographically crossed, so a leg that returned
    // nothing (E85 in Spain) is dropped from the banner. Empty for nearby
    // mode / single-country routes.
    final isRoute = ref.watch(activeSearchModeProvider) == SearchMode.route;
    final corridorCodes = isRoute
        ? (ref
                .watch(routeSearchStateProvider)
                .value
                ?.contributingCountryCodes(ref.watch(selectedFuelTypeProvider)) ??
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
