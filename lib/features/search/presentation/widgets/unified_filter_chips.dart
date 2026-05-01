import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../l10n/app_localizations.dart';

part 'unified_filter_chips.g.dart';

/// Three-way filter selector for the unified fuel + EV search list
/// (#1116 phase 3c). The user can narrow the list to fuel-only,
/// EV-only, or see both kinds of refueling options together.
///
/// Defaults to [UnifiedFilter.both] — the unified view's whole point is
/// the mixed feed, so the inclusive choice is the natural starting
/// state. The phase-3a [unifiedSearchResultsProvider] returns a single
/// [List<RefuelOption>] regardless of selection; this provider drives a
/// cheap downstream filter on the rendered list rather than re-running
/// either upstream search.
enum UnifiedFilter { fuel, ev, both }

/// Riverpod state holder for the active [UnifiedFilter]. Non-keep-alive
/// because the chip selection is screen-scoped: leaving the search
/// results screen and coming back resets to [UnifiedFilter.both], which
/// matches the expectation that filters are session-local.
@riverpod
class UnifiedFilterState extends _$UnifiedFilterState {
  @override
  UnifiedFilter build() => UnifiedFilter.both;

  /// Imperatively set the filter selection. Used by the chip widget's
  /// `onSelected` callbacks.
  // ignore: use_setters_to_change_properties
  void set(UnifiedFilter value) => state = value;
}

/// Horizontal row of three [FilterChip]s — Fuel / EV / Both — wired to
/// [unifiedFilterStateProvider]. Visual styling mirrors
/// `EvFilterChips` so the chip row sits flush in a screen that already
/// hosts EV-style filters.
class UnifiedFilterChips extends ConsumerWidget {
  const UnifiedFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(unifiedFilterStateProvider);
    final notifier = ref.read(unifiedFilterStateProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _UnifiedChip(
            label: l10n?.unifiedFilterFuel ?? 'Fuel',
            selected: selected == UnifiedFilter.fuel,
            onSelected: () => notifier.set(UnifiedFilter.fuel),
          ),
          const SizedBox(width: 8),
          _UnifiedChip(
            label: l10n?.unifiedFilterEv ?? 'EV',
            selected: selected == UnifiedFilter.ev,
            onSelected: () => notifier.set(UnifiedFilter.ev),
          ),
          const SizedBox(width: 8),
          _UnifiedChip(
            label: l10n?.unifiedFilterBoth ?? 'Both',
            selected: selected == UnifiedFilter.both,
            onSelected: () => notifier.set(UnifiedFilter.both),
          ),
        ],
      ),
    );
  }
}

class _UnifiedChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _UnifiedChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
