import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;
import '../../providers/ev_providers.dart';

/// Horizontal row of filter chips allowing the user to narrow displayed
/// EV charging stations by connector type, minimum power, and
/// availability.
class EvFilterChips extends ConsumerWidget {
  const EvFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(evFilterControllerProvider);
    final notifier = ref.read(evFilterControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: Text(l10n?.evAvailableOnly ?? 'Available only'),
            selected: filter.availableOnly,
            onSelected: notifier.setAvailableOnly,
          ),
          const SizedBox(width: 8),
          ...ConnectorType.values.map((type) {
            final selected = filter.connectorTypes.contains(type);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_labelFor(context, type)),
                selected: selected,
                onSelected: (_) => notifier.toggleConnector(type),
              ),
            );
          }),
          const SizedBox(width: 4),
          _PowerDropdown(
            value: filter.minPowerKw,
            onChanged: notifier.setMinPowerKw,
          ),
        ],
      ),
    );
  }

  static String _labelFor(BuildContext context, ConnectorType type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case ConnectorType.type2:
        return l10n?.connectorType2 ?? 'Type 2';
      case ConnectorType.ccs:
        return l10n?.connectorCcs ?? 'CCS';
      case ConnectorType.chademo:
        return l10n?.connectorChademo ?? 'CHAdeMO';
      case ConnectorType.tesla:
        return l10n?.connectorTesla ?? 'Tesla';
      case ConnectorType.schuko:
        return l10n?.connectorSchuko ?? 'Schuko';
      case ConnectorType.type1:
        return l10n?.connectorType1 ?? 'Type 1';
      case ConnectorType.threePin:
        return l10n?.connectorThreePin ?? '3-pin';
    }
  }
}

class _PowerDropdown extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _PowerDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButton<double>(
      value: value,
      hint: Text(l10n?.evMinPower ?? 'Min power'),
      items: const [
        DropdownMenuItem(value: 0, child: Text('Any')),
        DropdownMenuItem(value: 11, child: Text('11 kW+')),
        DropdownMenuItem(value: 22, child: Text('22 kW+')),
        DropdownMenuItem(value: 50, child: Text('50 kW+')),
        DropdownMenuItem(value: 150, child: Text('150 kW+')),
        DropdownMenuItem(value: 300, child: Text('300 kW+')),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
