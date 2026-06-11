// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_log.dart';
import '../../core/logging/error_logger.dart';
import '../../core/storage/hive_boxes.dart';
import '../../core/storage/hive_storage.dart';
import '../../features/obd2/data/ios_state_restoration_provider.dart';
import '../../features/consumption/providers/auto_record_orchestrator.dart';
import '../../features/obd2/providers/obd2_comm_diagnostics_gate_provider.dart';
import '../../features/obd2/providers/obd2_debug_logging_provider.dart';
import '../../features/consumption/providers/trip_ve_recompute_provider.dart';
import '../../features/vehicle/data/reference_vehicle_catalog_provider.dart';
import '../../features/vehicle/data/repositories/vehicle_profile_repository.dart';
import '../../features/vehicle/data/vehicle_profile_migrator.dart';
import '../../features/vehicle/providers/vehicle_aggregate_updater_provider.dart';
import '../../features/widget/providers/nearest_widget_refresh_provider.dart';

/// One-shot migrations + keep-alive provider warm-ups — extracted from
/// `AppInitializer` by the #3139 phase decomposition.
///
/// ## Ordering contract (#3139)
///
/// Every method here is scheduled by `AppInitializer` via
/// `_deferPostFirstFrame` (except [startNearestWidgetHeartbeat], which
/// `_launch` calls synchronously right after the error handlers install)
/// and none of them depends on another — each was its own deferred block
/// pre-decomposition and keeps its own try/catch + errorLogger context,
/// so one failing warm-up never blocks the rest. The single intra-phase
/// ordering rule lives INSIDE [startAutoRecordOrchestrator]: the #3167
/// iOS Core Bluetooth state-restoration opt-in must complete before the
/// orchestrator's first Bluetooth touch, which is why both run in the
/// same method (same deferred block as before).
class ProviderWarmupPhase {
  ProviderWarmupPhase._();

  /// #950 phase 4 — backfill `referenceVehicleId` on existing
  /// VehicleProfile entries from the reference catalog. One-shot:
  /// gated on `vehicleCatalogMigrationDone` so subsequent launches
  /// skip the work. Runs after the first frame because reading the
  /// bundled JSON asset shouldn't block the landing UI.
  static Future<void> migrateVehicleCatalog(
    ProviderContainer container,
    HiveStorage storage,
  ) async {
    try {
      final migrator = VehicleProfileCatalogMigrator(
        repository: VehicleProfileRepository(storage),
        settings: storage,
      );
      if (migrator.hasRun) return;
      final catalog =
          await container.read(referenceVehicleCatalogProvider.future);
      final matched = await migrator.run(catalog: catalog);
      log.info('VehicleProfileCatalogMigrator: matched $matched profile(s)');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: {'where': 'vehicleProfileCatalogMigrator'}));
    }
  }

  /// #1858 — instantiate the keep-alive η_v recompute listener so it
  /// is watching vehicle-profile edits before the user can reach the
  /// Edit-vehicle screen. Reading the provider triggers its `build`,
  /// which wires the `ref.listen`; deferred because no η_v edit can
  /// happen until well after first frame.
  static Future<void> warmTripVeRecomputeListener(
    ProviderContainer container,
  ) async {
    try {
      container.read(tripVeRecomputeListenerProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: {'where': 'tripVeRecomputeListener kick-off'}));
    }
  }

  /// #1925 — arm the OBD2 debug-session recorder from the persisted
  /// opt-in flag. Reading the provider runs its `build`, which mirrors
  /// the flag onto `Obd2DebugSessionRecorder.enabled`, so a user who
  /// opted in last session has logging armed before the next connect
  /// even if they never open Settings.
  static Future<void> armObd2DebugSessionLogging(
    ProviderContainer container,
  ) async {
    try {
      container.read(obd2DebugSessionLoggingProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: {'where': 'obd2DebugSessionLogging kick-off'}));
    }
  }

  /// #2465 — arm the OBD2 comm-health diagnostics collector from
  /// Feature.debugMode. Reading the keep-alive gate provider runs its
  /// `build`, which mirrors the flag onto
  /// `Obd2CommDiagnostics.instance.enabled` and keeps it in sync as the
  /// user toggles Developer mode. A no-op in production (dev mode off).
  static Future<void> armObd2CommDiagnosticsGate(
    ProviderContainer container,
  ) async {
    try {
      container.read(obd2CommDiagnosticsGateProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: {'where': 'obd2CommDiagnosticsGate kick-off'}));
    }
  }

  /// #609 — kick the 2-minute nearest-widget heartbeat so the home-screen
  /// widget stays fresh while the app is running. The provider is
  /// keepAlive and owns its own Timer; disposal cancels it cleanly.
  ///
  /// Synchronous: `_launch` calls this on the critical path right after
  /// the error handlers install (pre-decomposition placement).
  static void startNearestWidgetHeartbeat(ProviderContainer container) {
    try {
      container.read(nearestWidgetRefreshProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: {'where': 'nearestWidgetRefresh start'}));
    }
  }

  /// #1004 phase 2b-2 — instantiate the auto-record orchestrator. The
  /// provider is `keepAlive: true` and watches the vehicle list
  /// internally; reading it once is enough to spin up coordinators
  /// for any vehicle that already has `autoRecord: true`. Deferred to
  /// a post-frame microtask so a slow listener factory (Android
  /// platform channel handshake) cannot delay the first paint. The
  /// try/catch belongs here, not just inside the provider, because a
  /// bug in `defaultTargetPlatform` resolution or in the listener
  /// factory would otherwise crash the whole launch path.
  static Future<void> startAutoRecordOrchestrator(
    ProviderContainer container,
  ) async {
    // #3167 — opt the shared FBP central manager into Core Bluetooth
    // state restoration BEFORE the orchestrator's first Bluetooth
    // touch, sequenced in the SAME deferred block so the ordering is
    // guaranteed. This also drains the host bridge's launch signal
    // ("relaunched by Core Bluetooth?") that tags the first
    // auto-record connect trace. No-op off iOS; a failure never
    // blocks the orchestrator below.
    try {
      await container.read(iosStateRestorationServiceProvider).initialize();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: {'where': 'iosStateRestoration init'}));
    }
    try {
      container.read(autoRecordOrchestratorProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: {'where': 'autoRecordOrchestrator init'}));
    }
  }

  /// #1193 phase 2 — wire the vehicle aggregator's `runForVehicle`
  /// hook onto `TripHistoryRepository.onSavedHook` so every saved
  /// trip with a non-null vehicleId triggers a background recompute
  /// of the rolling driving aggregates. Deferred to the post-frame
  /// microtask because the trip-history Hive box is opened during
  /// the storage phase but the Riverpod provider may not have read
  /// it yet — by post-frame the provider graph has settled. Errors
  /// are logged but never block launch (the aggregator is purely an
  /// optimisation; trips still save without it).
  static Future<void> wireVehicleAggregatorHook(
    ProviderContainer container,
  ) async {
    try {
      // #1794 — the aggregator hook reads `obd2TripHistory`, a
      // deferred box; wait for the post-first-frame opens first.
      await HiveBoxes.initDeferred();
      final wired = wireAggregatorIntoTripHistory(container);
      if (!wired) {
        log.info('AppInitializer: vehicle aggregator hook deferred — '
            'trip-history box not open yet');
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: {'where': 'vehicle aggregator wiring'}));
    }
  }
}
