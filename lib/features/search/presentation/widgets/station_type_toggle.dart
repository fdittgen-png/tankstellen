import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/station_type_filter.dart';
import '../../providers/station_type_filter_provider.dart';

/// A segmented toggle for switching between fuel and EV search modes.
class StationTypeToggle extends ConsumerWidget {
  const StationTypeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(activeStationTypeFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SegmentedButton<StationTypeFilter>(
        segments: const [
          ButtonSegment(
            value: StationTypeFilter.fuel,
            icon: Icon(Icons.local_gas_station, size: 18),
            label: Text('Fuel'),
          ),
          ButtonSegment(
            value: StationTypeFilter.ev,
            icon: Icon(Icons.ev_station, size: 18),
            label: Text('EV'),
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
