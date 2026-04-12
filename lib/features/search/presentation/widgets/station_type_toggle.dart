import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/station_type_filter.dart';
import '../../providers/station_type_filter_provider.dart';

/// A segmented toggle for switching between fuel and EV search modes.
class StationTypeToggle extends ConsumerWidget {
  const StationTypeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(activeStationTypeFilterProvider);
    final l = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SegmentedButton<StationTypeFilter>(
        segments: [
          ButtonSegment(
            value: StationTypeFilter.fuel,
            icon: const Icon(Icons.local_gas_station, size: 18),
            label: Text(l?.stationTypeFuel ?? 'Fuel'),
          ),
          ButtonSegment(
            value: StationTypeFilter.ev,
            icon: const Icon(Icons.ev_station, size: 18),
            label: Text(l?.stationTypeEv ?? 'EV'),
          ),
        ],
        selected: {filter},
        onSelectionChanged: (selected) {
          ref
              .read(activeStationTypeFilterProvider.notifier)
              .set(selected.first);
        },
      ),
    );
  }
}
