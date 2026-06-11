// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/approach_detector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../favorites/providers/favorite_stations_provider.dart';
import '../../../../core/domain/station.dart';
import '../../providers/approach_simulator_provider.dart';
import '../../providers/effective_approach_state_provider.dart';

/// Discoverable test surface for the approach-overlay flow (#2163).
///
/// Picks the first fuel-favorite station the user has saved, pushes a
/// synthetic [ApproachInRadius] into the simulator for 30 s, then
/// auto-collapses through `ApproachLeaving` → idle. While active, the
/// trip-recording banner's PiP layout shows the price for the picked
/// station — exactly what the real detector would render in-radius.
///
/// Disabled when there are no favorite stations yet (no realistic
/// target available); pushes the user toward starring a station rather
/// than synthesising one from thin air.
class ApproachTestPanel extends ConsumerWidget {
  const ApproachTestPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // The favorites provider walks down to Hive — under widget tests
    // that don't bootstrap storage `ref.watch` re-throws the
    // ProviderException. Wrap the whole read so the panel degrades
    // to "no target available" rather than crashing the trip-
    // recording screen.
    Station? target;
    try {
      final favorites = ref.watch(favoriteStationsProvider);
      target = favorites.value?.data.firstOrNull;
    } on Object {
      target = null;
    }
    ApproachState? current;
    try {
      current = ref.watch(effectiveApproachStateProvider);
    } on Object {
      current = null;
    }
    final isSimulating =
        current is ApproachInRadius || current is ApproachLeaving;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l?.approachOverlaySection ?? 'Approach-station overlay',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (isSimulating)
                  TextButton.icon(
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(l?.approachTestStopButton ?? 'Stop test'),
                    onPressed: () =>
                        ref.read(approachSimulatorProvider.notifier).clear(),
                  )
                else
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.local_gas_station_outlined),
                    label: Text(
                      l?.approachTestSimulateButton ?? 'Test approach overlay',
                    ),
                    onPressed:
                        target == null ? null : () => _simulate(ref, target!),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _Caption(target: target, isSimulating: isSimulating),
          ],
        ),
      ),
    );
  }

  void _simulate(WidgetRef ref, Station station) {
    ref.read(approachSimulatorProvider.notifier).simulate(station);
  }
}

class _Caption extends StatelessWidget {
  final Station? target;
  final bool isSimulating;

  const _Caption({required this.target, required this.isSimulating});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    if (isSimulating && target != null) {
      return Text(
        l?.approachTestActiveCaption(
              target!.name.isNotEmpty ? target!.name : target!.street,
            ) ??
            'Test active — overlay shows the price for ${target!.name}',
        style: style,
      );
    }
    if (target == null) {
      return Text(
        l?.approachTestUnavailable ??
            'Add a favorite station to test the approach overlay',
        style: style,
      );
    }
    return Text(
      target!.name.isNotEmpty ? target!.name : target!.street,
      style: style,
    );
  }
}
