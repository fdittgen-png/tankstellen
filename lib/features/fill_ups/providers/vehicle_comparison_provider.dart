// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The selection and the read model behind the #4365 personal-vehicle
/// comparison — and the one place that guarantees choosing a column
/// never switches the car the rest of the app is showing.
///
/// ## The active vehicle is not touched
///
/// [VehicleComparisonSelection] owns its own list of ids. It never
/// reads and never writes `activeVehicleProfileProvider`, and
/// `buildVehicleHistoryComparison` is a pure function of explicit ids,
/// so there is no path from "compare these two" to "now drive that
/// one". The two pieces of state are independent by construction, and
/// deleting a compared vehicle leaves the selection intact so it can be
/// recovered rather than silently reset.
///
/// ## The aggregation is not in a widget build
///
/// The whole history walk happens here, behind a provider that
/// recomputes only when the records, the vehicles or the selection
/// change. An edit, a delete, a correction or a reassignment lands in
/// `fillUpListProvider`, which this watches — so the affected result
/// refreshes on its own, and the selection and the active vehicle both
/// survive it untouched.
library;

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/vehicle_profile.dart';
import '../../../core/time/app_clock.dart';
import '../../trips/api.dart';
import '../../vehicle/api.dart';
import '../domain/services/vehicle_history_comparison.dart';
import '../domain/services/vehicle_history_comparison_builder.dart';
import 'consumption_providers.dart';

part 'vehicle_comparison_provider.g.dart';

/// Which vehicles the driver put side by side, over which period.
///
/// [vehicleIds] keeps the DISPLAY order (the order they were picked);
/// [VehicleComparisonKey] normalises it for caching. An id stays here
/// even when its profile is gone, so the selection is recoverable.
@immutable
final class VehicleComparisonSelection {
  const VehicleComparisonSelection({
    this.vehicleIds = const [],
    this.period = ComparisonPeriod.allHistory,
    this.referenceVehicleId,
  });

  final List<String> vehicleIds;
  final ComparisonPeriod period;

  /// The column deltas are measured against, or null for "the first".
  final String? referenceVehicleId;

  VehicleComparisonKey get key =>
      VehicleComparisonKey(vehicleIds: vehicleIds, period: period);

  /// The reference actually in force — the explicit one when it is
  /// still selected, otherwise the first selected vehicle.
  String? get effectiveReferenceId =>
      vehicleIds.contains(referenceVehicleId)
          ? referenceVehicleId
          : (vehicleIds.isEmpty ? null : vehicleIds.first);

  bool get isComparable => vehicleIds.length >= 2;

  VehicleComparisonSelection copyWith({
    List<String>? vehicleIds,
    ComparisonPeriod? period,
    String? referenceVehicleId,
  }) =>
      VehicleComparisonSelection(
        vehicleIds: vehicleIds ?? this.vehicleIds,
        period: period ?? this.period,
        referenceVehicleId: referenceVehicleId ?? this.referenceVehicleId,
      );

  @override
  bool operator ==(Object other) =>
      other is VehicleComparisonSelection &&
      other.period == period &&
      other.referenceVehicleId == referenceVehicleId &&
      other.vehicleIds.length == vehicleIds.length &&
      other.vehicleIds.join(',') == vehicleIds.join(',');

  @override
  int get hashCode =>
      Object.hash(vehicleIds.join(','), period, referenceVehicleId);
}

/// The compared vehicles and the report period. Independent of the
/// active vehicle in both directions.
@Riverpod(keepAlive: true)
class VehicleComparisonSelector extends _$VehicleComparisonSelector {
  @override
  VehicleComparisonSelection build() => const VehicleComparisonSelection();

  /// Add or remove [vehicleId]. Never touches the active vehicle.
  void toggle(String vehicleId) {
    final ids = [...state.vehicleIds];
    if (!ids.remove(vehicleId)) ids.add(vehicleId);
    state = state.copyWith(vehicleIds: ids);
  }

  /// Replace the whole selection, preserving the given order.
  void select(Iterable<String> vehicleIds) {
    state = state.copyWith(vehicleIds: vehicleIds.toList(growable: false));
  }

  /// Forget [vehicleId] — the recovery action offered when a compared
  /// vehicle has been deleted.
  void drop(String vehicleId) {
    state = state.copyWith(
        vehicleIds: [
          for (final id in state.vehicleIds)
            if (id != vehicleId) id,
        ]);
  }

  void setPeriod(ComparisonPeriod period) {
    state = state.copyWith(period: period);
  }

  void setReference(String vehicleId) {
    state = state.copyWith(referenceVehicleId: vehicleId);
  }
}

/// The comparison for one explicit [key] — the reusable result #4366
/// and #4367 read.
///
/// Keyed by the selected ids, the period and the evidence version, so
/// two surfaces asking the same question share one computation and a
/// different question gets a different answer rather than a stale one.
@riverpod
VehicleHistoryComparison vehicleHistoryComparison(
    Ref ref, VehicleComparisonKey key) {
  final vehicles = ref.watch(vehicleProfileListProvider);
  return buildVehicleHistoryComparison(
    key: key,
    fillUps: ref.watch(fillUpListProvider),
    trips: ref.watch(tripHistoryListProvider),
    asOf: ref.watch(appClockProvider).now(),
    vehicles: {for (final VehicleProfile v in vehicles) v.id: v},
  );
}

/// The comparison the personal surface is currently showing.
@riverpod
VehicleHistoryComparison selectedVehicleComparison(Ref ref) =>
    ref.watch(vehicleHistoryComparisonProvider(
        ref.watch(vehicleComparisonSelectorProvider).key));
