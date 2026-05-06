import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/refuel/refuel_option.dart';
import '../../../../core/refuel/refuel_provider.dart';
import '../../../../core/refuel/unified_search_results_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ev/domain/entities/charging_station.dart';
import '../../domain/entities/station.dart';
import 'refuel_option_card.dart';
import 'unified_filter_chips.dart';

/// Renders the unified fuel + EV search-results list for #1116
/// phase 3c. Activates only when [unifiedSearchResultsEnabledProvider]
/// is on (the gate sits in [SearchResultsContent]).
///
/// Pulls the merged list from [unifiedSearchResultsProvider], applies
/// the current [UnifiedFilterState] selection, and renders one
/// [RefuelOptionCard] per option. Empty filter result → centered,
/// localized placeholder.
///
/// Filter discrimination uses [RefuelProvider.kind] — the public
/// discriminator on the abstract refuel surface. This avoids any
/// downcast to concrete adapters such as [StationAsRefuelOption] /
/// [ChargingStationAsRefuelOption] (their concrete types remain a
/// private detail of the adapter package).
class UnifiedSearchResultsView extends ConsumerWidget {
  const UnifiedSearchResultsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final all = ref.watch(unifiedSearchResultsProvider);
    final filter = ref.watch(unifiedFilterStateProvider);
    final filtered = _applyFilter(all, filter);

    return Column(
      children: [
        const UnifiedFilterChips(),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n?.unifiedNoResultsForFilter ??
                          'No results match this filter',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final option = filtered[index];
                    return RefuelOptionCard(
                      key: ValueKey('refuel-${option.id}'),
                      option: option,
                      onTap: () => _openDetail(context, option),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Open the detail screen for a tapped option, dispatching by the
  /// underlying entity type. Mirrors the legacy fuel/EV detail routes
  /// — `/station/:id` for fuel, `/ev-station` (with the
  /// `ChargingStation` as `extra`) for EV — so a user switching
  /// between the legacy and unified views lands on the same screens.
  /// Sparse upstream rows that don't map to a concrete type are a
  /// no-op (rare; logged via debug-print would be too noisy).
  void _openDetail(BuildContext context, RefuelOption option) {
    final source = option.source;
    if (source is Station) {
      context.push('/station/${source.id}');
    } else if (source is ChargingStation) {
      context.push('/ev-station', extra: source);
    }
  }

  /// Pure filter — operates on the public [RefuelProviderKind]
  /// discriminator. [UnifiedFilter.both] passes everything through;
  /// [UnifiedFilter.fuel] keeps fuel-only providers; [UnifiedFilter.ev]
  /// keeps EV-only providers. Mixed-site providers (kind `both`) appear
  /// in both fuel and EV filtered views — they belong to either
  /// category from a user-intent standpoint.
  static List<RefuelOption> _applyFilter(
    List<RefuelOption> options,
    UnifiedFilter filter,
  ) {
    switch (filter) {
      case UnifiedFilter.both:
        return options;
      case UnifiedFilter.fuel:
        return options
            .where((o) =>
                o.provider.kind == RefuelProviderKind.fuel ||
                o.provider.kind == RefuelProviderKind.both)
            .toList(growable: false);
      case UnifiedFilter.ev:
        return options
            .where((o) =>
                o.provider.kind == RefuelProviderKind.ev ||
                o.provider.kind == RefuelProviderKind.both)
            .toList(growable: false);
    }
  }
}
