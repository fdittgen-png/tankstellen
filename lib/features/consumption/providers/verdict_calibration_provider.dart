// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/verdict_calibration_store.dart';
import '../domain/gps_kpi_verdict.dart';

part 'verdict_calibration_provider.g.dart';

/// #3503 — the verdict-driven KPI calibration store, backed by the shared
/// Hive `settings` box (same pattern as the last-good-adapter pin store).
@Riverpod(keepAlive: true)
VerdictCalibrationStore verdictCalibrationStore(Ref ref) =>
    VerdictCalibrationStore(ref.watch(settingsStorageProvider));

/// #3503 — the resolved KPI bands: the defaults until enough #3501 verdicts
/// accumulate, then the personal set the store derives. Invalidated by
/// [TripHistoryList.setVerdict] after each new label so the KPI card
/// re-bands on the next build.
@Riverpod(keepAlive: true)
GpsKpiBands gpsKpiBands(Ref ref) {
  try {
    return ref.watch(verdictCalibrationStoreProvider).deriveBands();
  } catch (_) {
    // A not-yet-bootstrapped settings graph (widget tests, cold start)
    // must never take the KPI card down — band with the defaults.
    return GpsKpiBands.defaults;
  }
}
