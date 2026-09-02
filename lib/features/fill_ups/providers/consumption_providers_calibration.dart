// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'consumption_providers.dart';

/// #3762 — the post-save calibration side-effects of [FillUpList]
/// (service reminders, η_v learner, GPS calibration matrix), split out
/// of `consumption_providers.dart` as a `part` mixin to satisfy the
/// #1680 file-length ratchet. Move-only: behaviour preserved verbatim.
mixin _FillUpListCalibration on _$FillUpList {
  Future<void> _evaluateReminders(FillUp fillUp) async {
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null || fillUp.odometerKm <= 0) return;
    try {
      final evaluator = ref.read(serviceReminderEvaluatorProvider);
      await evaluator.evaluate(
        vehicleId: vehicleId,
        currentOdometerKm: fillUp.odometerKm,
      );
      // Invalidate the reminder list so the vehicle edit screen
      // picks up the new `pendingAcknowledgment` flag immediately.
      ref.invalidate(serviceReminderListProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'FillUpList: reminder evaluation failed'}));
    }
  }

  /// Run the pump-gain learner against the new fill-up. Returns the
  /// [PumpGainOutcome] (null when the learner is unwired or failed) so
  /// downstream hooks (#1423 phase 3 broken-MAP belief) can read
  /// [PumpGainResult.proposedEta] without re-running the learner.
  /// #3887 — pump-anchored fuel gain: a closing full-to-full window
  /// re-anchors every estimated fuel-rate branch on the pump's litres.
  /// #3917 — every fill publishes its inventory (calibrated or the skip
  /// reason) through [lastFillInventoryProvider]; #3918 — the tank's
  /// dominant fuel key is stamped on the profile for the readers.
  Future<PumpGainOutcome?> _reconcilePumpGain(FillUp fillUp) async {
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null || fillUp.liters <= 0) return null;
    try {
      final learner = ref.read(pumpGainLearnerProvider);
      if (learner == null) return null;
      final summariesById = <String, TripSummary>{
        for (final t in ref.read(tripHistoryListProvider)) t.id: t.summary,
      };
      final vehicleFills = [
        for (final f in state)
          if (f.vehicleId == vehicleId || f.vehicleId == null) f,
      ];
      final outcome = await learner.evaluate(
        vehicleId: vehicleId,
        closing: fillUp,
        fillUps: vehicleFills,
        tripSummariesById: summariesById,
      );
      await _stampTankFuelKey(vehicleId, vehicleFills);
      final result = outcome.result;
      if (result != null) {
        ref.read(lastPumpGainResultProvider.notifier).set(result);
      }
      ref.invalidate(vehicleProfileListProvider);
      if (!fillUp.isCorrection) {
        await ref
            .read(lastFillInventoryProvider.notifier)
            .set(FillInventory.fromOutcome(fillUp, outcome));
      }
      return outcome;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'FillUpList: pump-gain reconciliation failed'}));
      return null;
    }
  }

  /// #3918 — write the tank's dominant grade (the mix estimate on a
  /// multi-fuel vehicle, else the last physical fill's fuel) so the
  /// fuel-rate readers resolve `pumpGainByFuel` by what the tank holds.
  Future<void> _stampTankFuelKey(String vehicleId, List<FillUp> fills) async {
    final repo = ref.read(vehicleProfileRepositoryProvider);
    final vehicle = repo.getById(vehicleId);
    if (vehicle == null) return;
    final physical = fills.where((f) => !f.isCorrection).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (physical.isEmpty) return;
    String key = physical.first.fuelType.apiValue;
    if (vehicle.multiFuelCapable) {
      final mix = estimateTankMix(vehicle: vehicle, fillUps: fills);
      final dominant = mix?.shares.firstOrNull;
      if (dominant != null) key = dominant.fuel.apiValue;
    }
    if (vehicle.tankFuelKey == key) return;
    await repo.save(vehicle.copyWith(tankFuelKey: key));
  }
  Future<void> _reconcileGpsCalibrationMatrix(FillUp fillUp) async {
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null) return;
    if (fillUp.liters <= 0) return;
    try {
      final vehicleRepo = ref.read(vehicleProfileRepositoryProvider);
      final vehicle = vehicleRepo.getById(vehicleId);
      if (vehicle == null) return;

      // Trajets linked to this fill-up's window. We restrict to
      // GPS-only + hybrid kinds — gpsPlusObd2 trips already had
      // their OBD2 fuel-rate ground truth and aren't useful signal
      // for the GPS matrix (they'd over-fit it to OBD2-instrumented
      // driving patterns).
      final tripHistory = ref.read(tripHistoryRepositoryProvider);
      if (tripHistory == null) return;
      // #3741 — `loadById` per linked trip; never full-decode history.
      final inWindow = <TripHistoryEntry>[];
      for (final id in fillUp.linkedTripIds) {
        final t = tripHistory.loadById(id);
        if (t != null && t.summary.kind != TripKind.gpsPlusObd2) {
          inWindow.add(t);
        }
      }
      if (inWindow.isEmpty) return;

      final trajetFeatures = <GpsDrivingFeatures>[];
      var totalKm = 0.0;
      for (final t in inWindow) {
        final f = GpsDrivingFeatures.from(t.samples);
        if (f != null) {
          trajetFeatures.add(f);
          totalKm += f.distanceKm;
        }
      }
      if (trajetFeatures.isEmpty || totalKm <= 0) return;

      final matrix =
          vehicle.gpsCalibration ?? GpsCalibrationMatrix.coldStart();
      // The reconciler manages its own residual window; we'd
      // need a per-vehicle residual log to persist across runs.
      // For the MVP we pass an empty list — the variance figure
      // reflects only this fill-up's residual and grows accurate
      // as the matrix iterates. A follow-up wires per-vehicle
      // residual history into Hive.
      final updated = GpsMatrixReconciler.reconcile(
        matrix: matrix,
        trajets: trajetFeatures,
        actualLitersBurned: fillUp.liters,
        totalDistanceKm: totalKm,
        recentResiduals: const <double>[],
      );
      if (updated == null) return;

      // #3122 — the calibration refinement is a real local modification:
      // stamp it so the LWW sync merge propagates (and protects) it.
      await vehicleRepo.save(
        vehicle.copyWith(
          gpsCalibration: updated,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      ref.invalidate(vehicleProfileListProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'GPS matrix reconciliation failed'}));
    }
  }
}
