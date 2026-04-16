import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/search_result_item.dart';
import '../../providers/ev_search_provider.dart';
import 'ev_station_card.dart';

/// Renders the EV-charging-station results list for the Search screen.
///
/// Stateless: the parent screen owns the search trigger callback and the
/// active EV state provider. This widget just maps `evState.when` to the
/// three render paths (loading / empty / list / error).
///
/// Pulled out of `search_screen.dart` so the screen's `_buildResults`
/// helper drops the 30-line EV branch and so this widget can be
/// exercised by widget tests in isolation.
class EvSearchResultsView extends ConsumerWidget {
  /// Triggered by the empty-state action and by the error-state retry
  /// button. Usually the screen's `_performGpsSearch`.
  final VoidCallback onSearch;

  const EvSearchResultsView({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final evState = ref.watch(eVSearchStateProvider);

    return evState.when(
      data: (result) {
        if (result.data.isEmpty) {
          return EmptyState(
            icon: Icons.ev_station,
            title: l10n?.searchEvStations ??
                'Search to find EV charging stations',
            actionLabel: l10n?.searchNearby ?? 'Search nearby',
            onAction: onSearch,
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
      error: (error, stackTrace) =>
          ServiceChainErrorWidget(
            error: error,
            onRetry: onSearch,
            stackTrace: stackTrace,
            searchContext: 'EV charging search',
          ),
    );
  }
}
