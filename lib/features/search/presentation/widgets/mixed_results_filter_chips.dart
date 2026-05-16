import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;
import '../../domain/entities/search_result_item.dart';
import '../../providers/mixed_results_filter_provider.dart';
import '../../providers/search_provider.dart';

/// Filter chips for the unified fuel + EV results list (#1784):
/// a Fuel / EV / Both kind selector, and — when EV rows are in the
/// list — EV connector-type and minimum-power filters.
///
/// The EV filter row is hidden when there are no EV results, or when
/// the user has narrowed the list to Fuel-only, so it never shows
/// filters that cannot affect anything. Only connector types actually
/// present in the result set get a chip.
class MixedResultsFilterChips extends ConsumerWidget {
  const MixedResultsFilterChips({super.key});

  /// Minimum-power presets (kW); `0` means no minimum.
  static const _powerPresets = <double>[0, 50, 150];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final kind = ref.watch(resultKindFilterProvider);
    final connectorFilter = ref.watch(evConnectorFilterProvider);
    final minPower = ref.watch(evMinPowerFilterProvider);

    // Connector types present across the raw (unfiltered) result set,
    // so the offered chips stay stable as the user toggles filters.
    final rawItems =
        ref.watch(searchStateProvider).value?.data ?? const <SearchResultItem>[];
    // No EV rows at all (a fuel-only search) → the kind selector and
    // EV filters have nothing to act on; render nothing.
    if (!rawItems.any((i) => i is EVStationResult)) {
      return const SizedBox.shrink();
    }

    final availableConnectors = <ConnectorType>{
      for (final item in rawItems)
        if (item is EVStationResult)
          ...item.station.connectors.map((c) => c.type),
    };

    final showEvFilters =
        kind != ResultKind.fuel && availableConnectors.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _chip(
                label: l10n?.unifiedFilterBoth ?? 'Both',
                selected: kind == ResultKind.both,
                onSelected: () => ref
                    .read(resultKindFilterProvider.notifier)
                    .set(ResultKind.both),
              ),
              const SizedBox(width: 6),
              _chip(
                label: l10n?.unifiedFilterFuel ?? 'Fuel',
                selected: kind == ResultKind.fuel,
                onSelected: () => ref
                    .read(resultKindFilterProvider.notifier)
                    .set(ResultKind.fuel),
              ),
              const SizedBox(width: 6),
              _chip(
                label: l10n?.unifiedFilterEv ?? 'EV',
                selected: kind == ResultKind.ev,
                onSelected: () => ref
                    .read(resultKindFilterProvider.notifier)
                    .set(ResultKind.ev),
              ),
            ],
          ),
        ),
        if (showEvFilters)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(
              children: [
                for (final preset in _powerPresets) ...[
                  _chip(
                    label: preset == 0
                        ? (l10n?.evPowerAny ?? 'Any')
                        : (l10n?.evPowerKw(preset.round()) ??
                            '${preset.round()} kW+'),
                    selected: minPower == preset,
                    onSelected: () => ref
                        .read(evMinPowerFilterProvider.notifier)
                        .set(preset),
                  ),
                  const SizedBox(width: 6),
                ],
                for (final type in ConnectorType.values)
                  if (availableConnectors.contains(type)) ...[
                    _chip(
                      label: _connectorLabel(type, l10n),
                      selected: connectorFilter.contains(type),
                      onSelected: () => ref
                          .read(evConnectorFilterProvider.notifier)
                          .toggle(type),
                    ),
                    const SizedBox(width: 6),
                  ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static String _connectorLabel(ConnectorType type, AppLocalizations? l10n) {
    return switch (type) {
      ConnectorType.type2 => l10n?.connectorType2 ?? 'Type 2',
      ConnectorType.ccs => l10n?.connectorCcs ?? 'CCS',
      ConnectorType.chademo => l10n?.connectorChademo ?? 'CHAdeMO',
      ConnectorType.tesla => l10n?.connectorTesla ?? 'Tesla',
      ConnectorType.schuko => l10n?.connectorSchuko ?? 'Schuko',
      ConnectorType.type1 => l10n?.connectorType1 ?? 'Type 1',
      ConnectorType.threePin => l10n?.connectorThreePin ?? '3-pin',
    };
  }
}
