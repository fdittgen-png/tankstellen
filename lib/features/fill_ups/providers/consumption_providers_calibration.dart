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

  /// Run the η_v learner against the new fill-up. Returns the resulting
  /// [VeLearnResult] (or `null` when guards rejected) so downstream
  /// hooks (#1423 phase 3 broken-MAP belief) can read
  /// [VeLearnResult.proposedEta] without re-running the learner.
  Future<VeLearnResult?> _reconcileVolumetricEfficiency(
    FillUp fillUp,
    FillUp? previous,
  ) async {
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null) return null;
    if (fillUp.liters <= 0) return null;
    try {
      final learner = ref.read(veLearnerProvider);
      if (learner == null) return null;
      final result = await learner.reconcileAfterFillUp(
        vehicleId: vehicleId,
        pumpedLiters: fillUp.liters,
        fillUpTimestamp: fillUp.date,
        previousFillUpTimestamp: previous?.date,
      );
      if (result != null) {
        ref
            .read(lastVeLearnResultProvider.notifier)
            .set(result);
        // Refresh the vehicle list so the edit screen reflects the
        // bumped η_v sample count immediately.
        ref.invalidate(vehicleProfileListProvider);
      }
      return result;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'FillUpList: VE reconciliation failed'}));
      return null;
    }
  }

  /// Refine the active vehicle's [GpsCalibrationMatrix] against the
  /// observed fuel burn at this fill-up (#2081 / Epic #2055).
  ///
  /// Looks up GPS-only / hybrid trajets in the fill-up's linked
  /// window, builds the feature aggregate per trajet, and passes
  /// them through [GpsMatrixReconciler.reconcile] to update the
  /// matrix's `baseline` coefficient + the bookkeeping fields
  /// (count, variance, last-reconciled-at). Skips silently when:
  ///
  /// - No vehicle is linked to the fill-up.
  /// - No GPS-only / hybrid trajets exist in the window.
  /// - The reconciler returns null (degenerate inputs).
  ///
  /// Cold-starts the matrix from the vehicle's defaults when the
  /// field is null — first GPS-only fill-up reconciliation will
  /// seed the matrix and step it once toward the observed truth.
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
