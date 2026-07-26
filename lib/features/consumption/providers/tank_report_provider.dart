// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../vehicle/api.dart';
import '../domain/services/tank_report.dart';
import '../domain/trip_summary.dart';
import 'consumption_providers.dart';
import 'trip_history_provider.dart';

part 'tank_report_provider.g.dart';

/// The active vehicle's per-tank insight report (#3616).
///
/// Scopes fill-ups with the same convention every trajets surface uses
/// (`vehicleId` match OR legacy null tagging), resolves the closing
/// pleins' linked trips from the already-loaded history list, and hands
/// both to the pure [buildTankReport]. Re-derives whenever a fill-up or
/// trip lands — cheap: the walk is O(fills + linked trips) over data the
/// two watched providers already hold in memory.
@riverpod
TankReport tankReport(Ref ref) {
  final active = ref.watch(activeVehicleProfileProvider);
  final fills = ref.watch(fillUpListProvider);
  final trips = ref.watch(tripHistoryListProvider);

  final scoped = active == null
      ? fills
      : [
          for (final f in fills)
            if (f.vehicleId == active.id || f.vehicleId == null) f,
        ];
  final summariesById = <String, TripSummary>{
    for (final t in trips) t.id: t.summary,
  };
  return buildTankReport(
    fillUps: scoped,
    tripSummariesById: summariesById,
  );
}
