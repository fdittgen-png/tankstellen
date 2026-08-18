// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/storage/hive_boxes.dart';
import '../data/baselines_sync.dart';
import '../../sync/providers/baseline_sync_enabled_provider.dart';

/// #3670 — test seam for the server baseline merge: the production path
/// calls the static [BaselinesSync.merge] (no injection point), so the
/// non-blocking-stop contract test overrides this to a never-completing
/// future and asserts the stop path still returns.
@visibleForTesting
Future<String?> Function({
  required String vehicleId,
  String? localJson,
})? debugBaselineMergeOverride;

/// #780 — fold the server baseline copy into the local one after the
/// stop-path flush. Extracted from [TripBaselineRecorder] (#3670) and
/// FIRE-AND-FORGET by contract: awaiting this network round-trip inside
/// `stop()` held the save UI at "Saving to history…" for minutes when
/// the self-host Supabase was grinding TLS handshakes. Never throws.
Future<void> syncBaselineAfterFlush(Ref ref, String vehicleId) async {
  try {
    // #780 phase 3 — honour the opt-in setting. Default false so users
    // who never toggled it in the sync setup screen don't silently
    // upload driving data.
    final enabled = ref.read(baselineSyncEnabledProvider);
    if (!enabled) return;
    if (!Hive.isBoxOpen(HiveBoxes.obd2Baselines)) return;
    final box = Hive.box<String>(HiveBoxes.obd2Baselines);
    final key = 'baseline:$vehicleId';
    final localJson = box.get(key);
    // #3670 — hard cap: even in the background this merge must not
    // grind a flaky endpoint forever (the transport's own retries can
    // exceed a minute on repeated TLS handshake failures).
    final mergeFn = debugBaselineMergeOverride;
    final merged = await (mergeFn != null
            ? mergeFn(vehicleId: vehicleId, localJson: localJson)
            : BaselinesSync.merge(vehicleId: vehicleId, localJson: localJson))
        .timeout(const Duration(seconds: 15));
    if (merged != null && merged != localJson) {
      await box.put(key, merged);
      // No in-memory cache refresh needed — the recorder nulls its
      // store right after scheduling this call and the next trip
      // creates a fresh BaselineStore whose loadVehicle reads the
      // merged JSON from disk.
    }
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.providers, e, st,
        context: const {'where': 'TripRecording.stop: baseline sync failed'}));
  }
}
