// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/navigation/search_fab_action_provider.dart';
import '../../../../core/location/location_consent.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../feature_management/domain/feature_dependency_graph.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/presentation/widgets/route_input.dart'
    show RouteInputWidgetState;
import '../../../route_search/providers/route_input_provider.dart';
import '../../../route_search/providers/route_search_params_provider.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../../../core/domain/search_mode.dart';
import '../../providers/brand_filter_provider.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/search_screen_ui_provider.dart';
import '../widgets/criteria/criteria_action_bar.dart';
import '../widgets/location_input.dart' show LocationInputWidgetState;
import '../widgets/search_criteria_form.dart';

part 'search_criteria_screen_actions.dart';

/// Full-screen modal for editing search criteria (mode, location, fuel, radius,
/// filters, equipment). Pops on submission and delegates to the relevant
/// state providers.
/// Stable route name for the search-criteria modal (#2810). The shell's three
/// push paths tag the route with this so they can detect it is already current
/// and refuse to stack a duplicate (the "search just re-opens the same form
/// again and again" bug).
const String kSearchCriteriaRouteName = 'search-criteria';

/// Whether the [kSearchCriteriaRouteName] modal is the current (top) route on
/// [nav] (#2810). Every push site calls this and bails when it returns true,
/// so a repeat tap can never stack a second criteria screen. `popUntil` with an
/// always-true predicate inspects the top route without popping anything.
bool searchCriteriaRouteIsCurrent(NavigatorState nav) {
  var current = false;
  nav.popUntil((r) {
    current = r.settings.name == kSearchCriteriaRouteName;
    return true;
  });
  return current;
}

class SearchCriteriaScreen extends ConsumerStatefulWidget {
  const SearchCriteriaScreen({super.key});

  @override
  ConsumerState<SearchCriteriaScreen> createState() =>
      _SearchCriteriaScreenState();
}

class _SearchCriteriaScreenState extends ConsumerState<SearchCriteriaScreen>
    with _SearchCriteriaActions {
  SearchFabAction? _registeredFabAction;
  SearchFabActionController? _fabNotifier;

  @override
  void initState() {
    super.initState();
    _fabNotifier = ref.read(searchFabActionControllerProvider.notifier);
    // Defer to post-frame: the input widgets' state (and their text
    // controllers) only stabilises after the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFabAction());
  }

  @override
  void dispose() {
    final action = _registeredFabAction;
    final notifier = _fabNotifier;
    if (action != null && notifier != null) {
      // #2139 — microtask fires before any frame; addPostFrameCallback
      // can be skipped if no frame is scheduled, leaving a stale
      // action that makes the FAB look enabled but no-op.
      unawaited(
        Future.microtask(() {
          try {
            notifier.clearFor(this); // #2553 — clear by owner, not action.
          } catch (_) {
            // ignore: silent_catch — ProviderContainer torn down (e.g. test teardown) — no-op.
          }
        }),
      );
    }
    super.dispose();
  }

  /// The mode the sheet is actually in: route planning can be gated off
  /// (#1447 phase 4), in which case the stored mode is preserved but the
  /// sheet behaves as Nearby.
  SearchMode _effectiveMode({required bool watch}) {
    final mode = watch
        ? ref.watch(activeSearchModeProvider)
        : ref.read(activeSearchModeProvider);
    final manifest = watch
        ? ref.watch(featureManifestProvider)
        : ref.read(featureManifestProvider);
    final enabledFlags = watch
        ? ref.watch(enabledFeaturesProvider)
        : ref.read(enabledFeaturesProvider);
    final routePlanningOn = isEffectivelyEnabled(
      Feature.routePlanning,
      manifest,
      enabledFlags,
    );
    return routePlanningOn ? mode : SearchMode.nearby;
  }

  /// Why the search cannot run, or null when it can. #3927 — the sheet's
  /// action bar shows this line above the disabled button; the shell FAB
  /// mirrors the same condition as its `enabled` flag, so the two can
  /// never disagree.
  String? _submitDisabledReason(AppLocalizations l10n, SearchMode mode) {
    if (mode != SearchMode.route) return null;
    final routeState = ref.watch(routeInputControllerProvider);
    if (routeState.isSearching) return l10n.criteriaSubmitDisabledSearching;
    if (!routeState.canSearch) return l10n.criteriaSubmitDisabledRoute;
    return null;
  }

  void _updateFabAction() {
    if (!mounted) return;
    // #2810 — only the CURRENTLY-displayed criteria screen may own the FAB
    // action. Without this an offstage instance (the user swiped to another
    // branch, its dispose hasn't fired) can re-register its action — sometimes
    // disabled — via this post-frame / ref.listen callback AFTER the shell
    // cleared the FAB on the branch change, leaving the centre FAB looking
    // faded/dead on Map/Favoris.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    final l10n = AppLocalizations.of(context);
    final effectiveMode = _effectiveMode(watch: false);

    final bool enabled;
    final VoidCallback onTap;
    if (effectiveMode == SearchMode.route) {
      enabled = ref.read(routeInputControllerProvider).canSearch;
      onTap = _onFabRouteTap;
    } else {
      enabled = true;
      onTap = _onFabNearbyTap;
    }

    final action = SearchFabAction(
      icon: Icons.search,
      tooltip: l10n.fabRunSearch,
      enabled: enabled,
      onTap: onTap,
    );
    // #2553 — register under this State as owner (self-clears by owner).
    ref.read(searchFabActionControllerProvider.notifier).setFor(this, action);
    _registeredFabAction = action;
  }

  // #2139 — defensively clear if invoked after dispose (covers the
  // window before the dispose-microtask fires).
  bool _bailIfStale() {
    if (mounted) return false;
    // #2553 — clear by owner identity (see SearchFabActionController).
    if (_registeredFabAction != null) _fabNotifier?.clearFor(this);
    return true;
  }

  void _onFabRouteTap() {
    if (_bailIfStale()) return;
    onRouteSubmit();
  }

  void _onFabNearbyTap() {
    if (_bailIfStale()) return;
    onNearbySubmit();
  }

  /// The action bar's primary tap — the same dispatch the shell FAB runs.
  void _onSubmit() {
    if (_effectiveMode(watch: false) == SearchMode.route) {
      onRouteSubmit();
    } else {
      onNearbySubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // #2131 — re-register the FAB when mode or canSearch flip.
    ref.listen<SearchMode>(
      activeSearchModeProvider,
      (_, _) => _updateFabAction(),
    );
    ref.listen<RouteInputState>(routeInputControllerProvider, (p, n) {
      if (p?.canSearch != n.canSearch) _updateFabAction();
    });

    // #1447 phase 4 — when routePlanning is gated off, hide the toggle
    // and treat the stored mode as Nearby (the stored value is preserved).
    final mode = _effectiveMode(watch: true);
    final routePlanningOn = isEffectivelyEnabled(
      Feature.routePlanning,
      ref.watch(featureManifestProvider),
      ref.watch(enabledFeaturesProvider),
    );

    return PageScaffold(
      title: l10n.searchCriteriaTitle,
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: l10n.tooltipClose,
        onPressed: () => Navigator.of(context).pop(),
      ),
      // #3927 — "Save as my defaults" was a full-width outlined button at
      // the bottom of the form, reading as the sheet's primary action. It
      // is a rare, deliberate action: the app-bar overflow is its place.
      actions: [
        PopupMenuButton<_CriteriaOverflowAction>(
          key: const ValueKey('criteria-overflow-menu'),
          icon: const Icon(Icons.more_vert),
          tooltip: l10n.moreActionsTooltip,
          onSelected: (_) => unawaited(saveAsDefaults()),
          itemBuilder: (_) => [
            PopupMenuItem<_CriteriaOverflowAction>(
              key: const ValueKey('criteria-save-defaults-button'),
              value: _CriteriaOverflowAction.saveDefaults,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark_add, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      l10n.saveAsDefaults,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      bodyPadding: EdgeInsets.zero,
      // #3927 — the sheet owns its primary action again: a labelled,
      // full-width Search button that says why it is disabled, plus the
      // Reset that the form never had.
      bottomNavigationBar: CriteriaActionBar(
        onSubmit: _onSubmit,
        onReset: resetCriteria,
        disabledReason: _submitDisabledReason(l10n, mode),
      ),
      // #2592 — the form body lives in SearchCriteriaForm so this screen
      // stays under the file-length cap; the State retains the search /
      // save actions and the FAB wiring and passes them down.
      body: SafeArea(
        child: SearchCriteriaForm(
          routeInputKey: routeInputKey,
          locationInputKey: locationInputKey,
          routePlanningOn: routePlanningOn,
          mode: mode,
          onGpsSearch: performGpsSearch,
          onZipSearch: performZipSearch,
          onCitySearch: performCitySearch,
          onRouteSearch: performRouteSearch,
        ),
      ),
    );
  }
}

/// The criteria sheet's app-bar overflow entries (#3927). One today —
/// the enum keeps `PopupMenuButton`'s dispatch typed for the next one.
enum _CriteriaOverflowAction { saveDefaults }
