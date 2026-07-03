// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/sync/trips_sync_enabled_provider.dart';
import '../../driving/providers/live_harsh_event_bus_provider.dart';
import '../../../core/domain/vehicle_profile.dart';
import '../data/adapter_pin_resolution.dart';
import '../data/obd2_connection_errors.dart';
import '../data/obd2_disconnect_quietly.dart';
import '../data/obd2_link_arbiter.dart';
import '../data/obd2_service.dart';
import '../data/obd2_trip_start_budgets.dart';
import '../data/obd2_session_context_block.dart';
import '../data/trip_recording_controller.dart';
import '../../consumption/domain/entities/gps_sample_diagnostic.dart';
import '../../consumption/domain/entities/trip_save_stage.dart';
import '../../consumption/domain/services/gps_live_estimate_folder.dart';
import '../domain/services/obd2_gps_estimate_fallback.dart';
import '../../consumption/domain/trip_recorder.dart';
import 'obd2_breadcrumb_provider.dart';
import 'obd2_controller_phase_mapper.dart';
import 'obd2_reconnect_provider.dart';
import '../../consumption/providers/recording_pipeline.dart';
import '../../consumption/providers/reconnect_scanner_factory.dart';
import '../../consumption/providers/reference_vehicle_match.dart';
import '../../consumption/providers/trip_baseline_recorder.dart';
import '../../consumption/providers/trip_gps_stream_controller.dart';
import '../../consumption/providers/trip_haptic_controller.dart';
import '../../consumption/providers/trip_oem_fuel_level_controller.dart';
import '../../consumption/providers/trip_recording_phase.dart';
import '../../consumption/providers/trip_recording_state.dart';

/// Concrete OBD2 recording strategy (#2227), completing the
/// [RecordingPipeline] seam #2190 opened with [GpsOnlyRecordingPipeline].
/// Owns the sensor-rich OBD2 recording loop that used to be inline on the
/// [TripRecording] notifier (the `_pipeline == null` default path): the
/// owned [Obd2Service], the [TripRecordingController] + its live /
/// stateChanges subscriptions, the adapter-identity snapshot (#1312), the
/// one-shot capability-probe latch (#2261), and the auto-reconnect scanner
/// factory (#797 / #2245). Focused collaborators are *injected* from the
/// notifier so they outlive a single recording.
///
/// Deliberately NOT owned: the Riverpod `state`, the last-trip identity
/// fields, `_saveToHistory`, and the #1303 active-trip WAL (+ #1347
/// cold-start recovery) stay on the notifier via [Obd2RecordingPipelineHost]
/// — the WAL survives the recording loop being torn down (recovery runs with
/// no pipeline at all). The seed / flush cadence uses the same host hooks.
class Obd2RecordingPipeline implements RecordingPipeline {
  Obd2RecordingPipeline({
    required Ref ref,
    required Obd2RecordingPipelineHost host,
    required TripHapticController haptics,
    required TripGpsStreamController gps,
    required TripBaselineRecorder baselines,
    required TripOemFuelLevelController oemFuel,
    required VehicleProfile? Function() readActiveVehicle,
    required bool Function() readOemPidsFlag,
    required bool Function() readDiagnosticCaptureFlag,
    Duration startWatchdog = kObd2TripStartWatchdog, // #3382, overridable in tests
    Duration baselinesBudget = kObd2TripStartBaselinesBudget,
  })  : _ref = ref,
        _host = host,
        _haptics = haptics,
        _gps = gps,
        _baselines = baselines,
        _oemFuel = oemFuel,
        _readActiveVehicle = readActiveVehicle,
        _readOemPidsFlag = readOemPidsFlag,
        _readDiagnosticCaptureFlag = readDiagnosticCaptureFlag,
        _startWatchdog = startWatchdog,
        _baselinesBudget = baselinesBudget;

  final Ref _ref;
  final Obd2RecordingPipelineHost _host;
  final TripHapticController _haptics;
  final TripGpsStreamController _gps;
  final TripBaselineRecorder _baselines;
  final TripOemFuelLevelController _oemFuel;
  final VehicleProfile? Function() _readActiveVehicle;
  final bool Function() _readOemPidsFlag;
  // #2459 — per-trip diagnostic-capture flag (Feature.debugMode).
  final bool Function() _readDiagnosticCaptureFlag;
  final Duration _startWatchdog; // #3382 trip-start abort budgets
  final Duration _baselinesBudget;

  Obd2Service? _service;
  Obd2LinkLease? _lease; // #3420 — the recording's session lease (arbiter)
  TripRecordingController? _controller;
  StreamSubscription<TripLiveReading>? _liveSub;
  StreamSubscription<TripRecordingControllerState>? _stateSub;

  bool _capabilityReconcileKicked = false;

  String? _adapterMac;
  String? _adapterName;
  String? _adapterFirmware;

  @override
  bool get isGpsOnly => false;

  /// The live controller, exposed so the notifier's WAL snapshot
  /// helpers, `pause` / `resume`, and `debugController` read it through
  /// the pipeline instead of owning a field. Null between trips and in
  /// the cold-start-recovered state (where no pipeline exists).
  TripRecordingController? get controller => _controller;

  /// The vehicle id the current recording's baselines are scoped to —
  /// stamped onto the WAL snapshot + the saved entry by the notifier.
  String? get baselineVehicleId => _baselines.vehicleId;

  /// Adapter identity snapshotted at [start] (#1312), read by the
  /// notifier's WAL save so it survives the service being disconnected
  /// before the entry is written.
  String? get adapterMac => _adapterMac;
  String? get adapterName => _adapterName;
  String? get adapterFirmware => _adapterFirmware;

  /// Begin a recording session backed by [service]. The pipeline takes
  /// ownership of the service — [stop] handles the full teardown. Moved
  /// verbatim from `TripRecording._startInternal`; the re-entrancy guard
  /// + `state.isActive` short-circuit stay on the notifier.
  Future<void> start(Obd2Service service, {bool automatic = false}) async {
    // #3420 — claim the link BEFORE the first await: a drop anywhere in the start window belongs to THIS recording, never the #3019 idle loop.
    _lease = Obd2LinkArbiter.instance.tryAcquire('recording', Obd2LinkPriority.recording);
    _service = service;
    // #2261 concern 6 — re-arm the deferred capability probe (first sample).
    _capabilityReconcileKicked = false;
    // #1312 — snapshot adapter identity NOW: the service is disconnected in
    // `stop` before the entry is saved, so it can't be read off the live
    // service then. Null → the detail card hides the row.
    _adapterMac = service.adapterMac;
    _adapterName = service.adapterName;
    _adapterFirmware = service.adapterFirmware;
    // #812 phase 3 — snapshot the active vehicle for `readFuelRateLPerHour`;
    // vehicle id up-front to tag any pause-on-drop snapshot (#797 phase 1).
    final activeVehicle = _readActiveVehicle();
    // #797 phase 3 / #3423 — reconnect pin: vehicle-profile MAC first, else
    // the #3019 last-good auto-pin (picker-started trips reconnect too);
    // null (neither) skips the scanner — grace window is the sole recovery.
    final pinnedMac = resolveAdapterPinMac(activeVehicle?.obd2AdapterMac,
        () => _ref.read(lastGoodAdapterStoreProvider).recall());
    // #1395 — wire the diagnostic breadcrumb sink for this trip; controller
    // and [Obd2Service] push through the SAME keepAlive notifier so the
    // trace survives the recording screen popping.
    final breadcrumbs = _ref.read(obd2BreadcrumbsProvider.notifier);
    breadcrumbs.clear(); // fresh suspicion-rate denominator for THIS trip
    service.breadcrumbCollector = breadcrumbs;
    // #1422 phase 1 — match the active vehicle to the bundled catalog so the
    // controller uses the engine-tech-derived η_v default instead of the
    // legacy 0.85 literal until VeLearner converges. Null on no-match.
    final matchedReference = tryMatchReferenceVehicle(_ref, activeVehicle);
    // #2506 — SHARED GPS-physics live-estimate + coaching folder (mirrors
    // the GPS-only pipeline). Folded per no-fuel-PID tick in the controller
    // so the OBD2 live screen carries `~ estimated` consumption + GPS
    // coaching, mirroring the post-trip `Obd2GpsEstimateFallback`. Null
    // vehicle / matrix → population-default class + cold-start scale.
    final gpsEstimateFolder = GpsLiveEstimateFolder.forVehicle(
      activeVehicle,
      activeVehicle?.gpsCalibration,
    );
    final ctl = TripRecordingController(
      service: service,
      vehicle: activeVehicle,
      referenceVehicle: matchedReference,
      vehicleId: activeVehicle?.id,
      pinnedAdapterMac: pinnedMac,
      automatic: automatic,
      // #2459 — diagnostic capture (Feature.debugMode); default off.
      diagnosticCapture: _readDiagnosticCaptureFlag(),
      reconnectScannerFactory: buildReconnectScannerFactory(
        ref: _ref,
        onConnected: (svc) {
          _service = svc;
          _controller?.replaceService(svc);
        },
        // #2565 — read the live transport kind at handle-drop time so the
        // reconnect dispatches over the SAME transport that dropped. The
        // dead-but-typed service is still wired here.
        readLinkKind: () => _service?.linkKind,
        // #3014 — the live adapter NAME the same way, so the in-trip
        // reconnect trace headline names the adapter, not just the MAC.
        readAdapterName: () => _service?.adapterName,
      ),
      breadcrumbCollector: breadcrumbs,
      gpsEstimateFolder: gpsEstimateFolder,
      // #2663 — forward every (de-noised, post-#2653) harsh event onto the
      // app-wide bus so the driving-coach voice listener can speak it live.
      onHarshEvent: _ref.read(liveHarshEventBusProvider.notifier).add,
    );
    _controller = ctl;

    // #769 baselines + #3382 watchdog-bound init (obd2_trip_start_budgets): on
    // a stall ABORT cleanly (disconnect + recoverable error), never hang.
    try {
      await _baselines.load().timeout(_baselinesBudget);
      await ctl.start().timeout(_startWatchdog);
    } on TimeoutException {
      _controller = null; _lease?.release(); _lease = null;
      unawaited(service.disconnectQuietly());
      throw const Obd2AdapterUnresponsive();
    }
    // #1374 / #1981 — GPS trip-path sampling, default-on; fire-and-forget so
    // the permission round-trip never blocks trip-start.
    unawaited(_gps.start(ctl));
    // #1615 — opt-in OEM-PID exact-fuel-level poll; no-op when off.
    _oemFuel.start(
      enabled: _readOemPidsFlag(),
      vin: ctl.vin,
      capability: service.capability,
      port: service,
      onLitres: ctl.updateOemFuelLevelLitres,
    );
    // #1303 — seed the active-trip WAL snapshot now the controller knows
    // its session id + odometer reads (stays on the notifier).
    _host.seedActiveSnapshot();
    _liveSub = ctl.live.listen((reading) {
      // #2261 concern 6 — run the deferred `0902` capability probe lazily
      // now that the first samples are landing. Fire-and-forget +
      // one-shot.
      if (!_capabilityReconcileKicked) {
        _capabilityReconcileKicked = true;
        unawaited(_service?.ensureCapabilityReconciled() ?? Future.value());
      }
      final classified = _baselines.recordAndClassify(reading);
      _haptics.fireForBandTransition(_host.state.band, classified.band);
      // #2506 — surface the GPS coaching hint the controller computed on a
      // no-fuel-PID tick. `MinimalDriveSummary` swaps to the GPS coaching
      // triplet when `reading.fuelRateLPerHour == null` and reads
      // `state.gpsCoachingHint`. Null (measured fuel / no hint) clears it.
      final gpsHint = ctl.latestGpsCoachingHint;
      _host.state = _host.state.copyWith(
        phase: phaseForController(ctl),
        live: reading,
        situation: classified.situation,
        band: classified.band,
        liveDeltaFraction: classified.delta,
        gpsCoachingHint: gpsHint,
        clearGpsCoachingHint: gpsHint == null,
      );
      // #1303 — debounced write-through (cheap when the gate rejects).
      _host.maybeFlushActiveSnapshot();
    });
    // #797 phase 1 — listen to explicit state changes so the UI surfaces
    // "pausedDueToDrop" even when no TripLiveReading lands.
    _stateSub = ctl.stateChanges.listen((_) {
      final newPhase = phaseForController(ctl);
      // #2767 — surface whether the reconnect scanner has given up active
      // scanning and is passive-waiting, so the GPS-degraded banner can swap
      // its copy. Only meaningful while a drop is being recovered; false in
      // every other phase so a fresh recording / save never inherits a stale
      // flag.
      final passiveWaiting = (newPhase == TripRecordingPhase.degradedGpsOnly ||
              newPhase == TripRecordingPhase.pausedDueToDrop) &&
          ctl.reconnectPassiveWaiting;
      // #1330 phase 3 — surface the controller's drop reason. Cleared
      // when leaving the drop state.
      if (newPhase == TripRecordingPhase.pausedDueToDrop) {
        _host.state = _host.state.copyWith(
          phase: newPhase,
          dropReason: ctl.dropReason,
          reconnectPassiveWaiting: passiveWaiting,
        );
      } else {
        _host.state = _host.state.copyWith(
          phase: newPhase,
          clearDropReason: true,
          reconnectPassiveWaiting: passiveWaiting,
        );
      }
      // #1303 — phase transitions force an immediate snapshot.
      unawaited(_host.flushActiveSnapshot(force: true));
    });
    // #2274 — going live clears the connecting stage for the live-metrics frame.
    _host.state = _host.state.copyWith(
      phase: TripRecordingPhase.recording,
      clearConnectStage: true,
    );
  }

  @override
  bool pause() {
    final ctl = _controller;
    if (ctl == null) return false;
    ctl.pause();
    return true;
  }

  @override
  bool resume() {
    final ctl = _controller;
    if (ctl == null) return false;
    ctl.resume();
    return true;
  }

  @override
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    final ctl = _controller;
    final svc = _service;
    if (ctl == null || svc == null) {
      _host.state = const TripRecordingState();
      return const StoppedTripResult.empty();
    }
    // #2548 — staged save-progress: flip into the transient (non-active)
    // `saving` phase so the screen shows the inline TripSaveProgress card
    // instead of a frozen swap. Finalising (odometer + summary) is beat 1.
    _host.setSaveStage(TripSaveStage.finalizingSummary);
    try {
      await ctl.refreshOdometer();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
        'where': 'Obd2RecordingPipeline.stop: refreshOdometer failed'
      }));
    }
    // Snapshot the captured-samples buffer BEFORE stop() tears down the
    // controller — else the trip-detail charts render empty (#1040).
    final capturedSamples = List<TripSample>.unmodifiable(ctl.capturedSamples);
    // #1458 phase 2 — snapshot GPS cadence diagnostics BEFORE teardown (same
    // reason); always captured (empty when GPS off).
    final capturedGpsDiagnostics = List<GpsSampleDiagnostic>.unmodifiable(
      ctl.capturedGpsSampleDiagnostics,
    );
    // #2431 — back-fill consumption from the GPS-physics estimate when the
    // adapter+ECU supported no fuel PID; a no-op when real fuel was seen.
    final filled = Obd2GpsEstimateFallback.fillWhenNoFuelPid(
      summary: await ctl.stop(),
      samples: capturedSamples,
      vehicle: _readActiveVehicle(),
    );
    final summary = filled.summary;
    final odometerStartKm = ctl.odometerStartKm;
    final odometerLatestKm = ctl.odometerLatestKm;
    // #2509 — GPS-fix count BEFORE teardown: lets the guard keep a real
    // dead-OBD2 GPS-tracked drive apart from a stationary stop.
    final gpsFixCount = ctl.gpsFixCount;
    await _liveSub?.cancel();
    _liveSub = null;
    await _stateSub?.cancel();
    _stateSub = null;
    // #1374 phase 1 — tear down the Geolocator subscription. Best-effort.
    await _gps.stop();
    // #1615 — tear down the OEM-PID fuel-level poll. Best-effort.
    await _oemFuel.stop();
    _controller = null;
    // #2548 beat 2 / #726 — write to history (every trip, incl. discarded).
    _host.setSaveStage(TripSaveStage.savingToHistory);
    final outcome = await _host.saveToHistory(
      summary,
      samples: filled.samples,
      gpsSampleDiagnostics: capturedGpsDiagnostics,
      automatic: automatic,
      vehicleId: _baselines.vehicleId,
      adapterMac: _adapterMac,
      adapterName: _adapterName,
      adapterFirmware: _adapterFirmware,
      gpsFixCount: gpsFixCount,
    );
    // #2548 — third beat, shown ONLY when cloud sync is on (the upload
    // saveToHistory kicked off is fire-and-forget, so it is worded
    // "Syncing in background…" and never blocks the resolve; sync-off
    // resolves straight to the outcome). The gate read must never derail
    // the save flow.
    try {
      if (_ref.read(tripsSyncEnabledProvider)) {
        _host.setSaveStage(TripSaveStage.syncingToCloud);
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
        'where': 'Obd2RecordingPipeline.stop: sync-gate read'
      }));
    }
    // #769 / #780 — flush learned baselines + sync before release.
    await _baselines.flushAndSync();
    // #1312 — clear the captured adapter identity once persisted.
    _adapterMac = null;
    _adapterName = null;
    _adapterFirmware = null;
    try {
      await svc.disconnect();
    } catch (e, st) {
      // #2472 — context adds the obd2Session block only when dev-armed.
      unawaited(errorLogger.log(ErrorLayer.providers, e, st,
          context: obd2DisconnectTraceContext()));
    }
    // #3420 — the lease is held until the disconnect COMPLETED (race 2).
    _service = null; _lease?.release(); _lease = null;
    // #1303 — trip finalised; clear the WAL so recovery doesn't resurrect it.
    await _host.clearActiveSnapshot();
    _host.state = _host.state.copyWith(phase: TripRecordingPhase.finished);
    return StoppedTripResult(
      summary: summary,
      odometerStartKm: odometerStartKm,
      odometerLatestKm: odometerLatestKm,
      // #2509 — surface "no movement detected" only on a stationary discard.
      discardedNoMovement: outcome.isStationaryDiscard,
    );
  }
}
