// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../domain/entities/search_mode.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import '../screens/search_criteria_screen.dart';
import 'nearest_shortcut_card.dart';
import 'route_results_view.dart';
import 'search_results_list.dart';

/// Renders the result panel of `SearchScreen` based on the current
/// [SearchMode] and [FuelType]:
///
///  * Route mode -> [RouteResultsView] inside a `CustomScrollView`
///  * Otherwise -> [SearchResultsList] over the standard
///    `searchStateProvider` `AsyncValue` (shimmer/empty/loaded/error),
///    rendering fuel and EV results in one combined mixed list
///
/// Pulled out of `search_screen.dart` so the screen's `_buildResults`
/// helper drops 50 lines and so the empty/loading/error branches can be
/// exercised by widget tests in isolation. The screen still owns
/// `_performGpsSearch`, so it is passed in as [onGpsRetry].
class SearchResultsContent extends ConsumerWidget {
  final Future<void> Function() onGpsRetry;

  const SearchResultsContent({super.key, required this.onGpsRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final searchMode = ref.watch(activeSearchModeProvider);
    final searchState = ref.watch(searchStateProvider);

    if (searchMode == SearchMode.route) {
      return const CustomScrollView(
        slivers: [RouteResultsView()],
      );
    }

    // #494 — the nearest-stations shortcut only makes sense for users
    // whose preferred landing screen is "nearest". If they picked
    // favorites / cheapest / map, pushing "Stations les plus proches"
    // at them ignores their explicit preference.
    final profile = ref.watch(activeProfileProvider);
    final showNearestShortcut =
        profile == null || profile.landingScreen == LandingScreen.nearest;

    return searchState.when(
      data: (result) {
        if (result.data.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showNearestShortcut) ...[
                    NearestShortcutCard(onTap: onGpsRetry),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    l10n?.startSearch ?? 'Search to find fuel stations.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // #1695 — the empty state always carries an actionable
                  // search CTA: without it (e.g. a non-"nearest" landing
                  // mode, where the shortcut card above is hidden) the
                  // screen was dead-end centered text.
                  FilledButton.icon(
                    key: const Key('emptySearchCta'),
                    onPressed: () => _openCriteria(context),
                    icon: const Icon(Icons.search),
                    label: Text(l10n?.searchCriteriaOpen ?? 'Search'),
                  ),
                ],
              ),
            ),
          );
        }
        return SearchResultsList(result: result, onRefresh: onGpsRetry);
      },
      loading: () => const ShimmerStationList(),
      error: (error, stackTrace) =>
          ServiceChainErrorWidget(
            error: error,
            onRetry: onGpsRetry,
            stackTrace: stackTrace,
            searchContext: 'Station search (${ref.read(selectedFuelTypeProvider).apiValue})',
          ),
    );
  }
}

/// Open the full search-criteria screen (#1695) — shared by the
/// empty-state CTA here and the [SearchSummaryBar]'s tune action.
Future<void> _openCriteria(BuildContext context) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const SearchCriteriaScreen(),
    ),
  );
}
