import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/hive_boxes.dart';
import '../domain/situation_classifier.dart';

part 'vehicle_baseline_summary_provider.g.dart';

/// Key shape produced by [BaselineStore._keyFor]; kept in sync here
/// so the summary reader doesn't have to instantiate the full store
/// just to peek at the sample counts.
String _vehicleKey(String vehicleId) => 'baseline:$vehicleId';

/// Sample count per [DrivingSituation] for a vehicle (#779).
///
/// Reads the stored Welford accumulator for the vehicle directly
/// from the Hive baseline box and returns the `n` field as the
/// sample count. Transient situations (`hardAccel`, `fuelCutCoast`)
/// are never persisted, so they're filtered out — the UI shouldn't
/// surface them as "learning".
///
/// Returns an empty map when the box is closed (widget tests without
/// Hive init) or when no baseline has been saved for the vehicle yet.
@Riverpod(keepAlive: true)
Map<DrivingSituation, int> vehicleBaselineSummary(Ref ref, String vehicleId) {
  if (!Hive.isBoxOpen(HiveBoxes.obd2Baselines)) return const {};
  final raw =
      Hive.box<String>(HiveBoxes.obd2Baselines).get(_vehicleKey(vehicleId));
  if (raw == null || raw.isEmpty) return const {};

  Map<String, dynamic> decoded;
  try {
    decoded = json.decode(raw) as Map<String, dynamic>;
  } catch (e) {
    debugPrint('vehicleBaselineSummary: corrupt payload for $vehicleId: $e');
    return const {};
  }

  final perSituation = decoded['perSituation'];
  if (perSituation is! Map) return const {};

  final result = <DrivingSituation, int>{};
  for (final s in DrivingSituation.values) {
    if (s == DrivingSituation.hardAccel ||
        s == DrivingSituation.fuelCutCoast) {
      continue;
    }
    final acc = perSituation[s.name];
    if (acc is Map) {
      final n = acc['n'];
      if (n is int) {
        result[s] = n;
      } else if (n is num) {
        result[s] = n.toInt();
      }
    }
  }
  return result;
}

/// Wipe every baseline entry for [vehicleId] (#779). Invalidates the
/// summary provider so the UI rebuilds to the zero state.
///
/// `keepAlive: true` prevents Riverpod from disposing the provider
/// mid-await — without it, the `ref.invalidate` call at the tail of
/// this method lands on a torn-down element.
@Riverpod(keepAlive: true)
Future<void> resetVehicleBaselines(Ref ref, String vehicleId) async {
  if (!Hive.isBoxOpen(HiveBoxes.obd2Baselines)) return;
  final box = Hive.box<String>(HiveBoxes.obd2Baselines);
  await box.delete(_vehicleKey(vehicleId));
  ref.invalidate(vehicleBaselineSummaryProvider(vehicleId));
}
