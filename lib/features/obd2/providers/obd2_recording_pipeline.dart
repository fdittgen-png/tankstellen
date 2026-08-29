// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/sync/trips_sync_enabled_provider.dart';
import '../../driving/providers/live_harsh_event_bus_provider.dart';
import '../../../core/domain/vehicle_profile.dart';
import '../data/adapter_pin_resolution.dart';
import '../domain/obd2_connection_errors.dart';
import '../data/session/obd2_disconnect_quietly.dart';
// #3776 — Obd2LinkSupervisorActions.reportServiceDead (extension scope).
import '../data/session/obd2_link_supervisor.dart';
import '../data/session/obd2_service.dart';
import '../domain/obd2_trip_start_budgets.dart';
import '../data/session/trip_recording_controller.dart';
import '../../trips/api.dart';
import '../domain/services/obd2_gps_estimate_fallback.dart';
import 'obd2_breadcrumb_provider.dart';
import 'obd2_controller_phase_mapper.dart';
import 'obd2_reconnect_provider.dart';
import 'obd2_supervised_teardown.dart';
import '../data/obd2_comm_diagnostics.dart';

/// Concrete OBD2 recording strategy (#2227) behind the [RecordingPipeline]
/// seam (#2190): owns the [Obd2Service], the [TripRecordingController] +
/// its live/stateChanges subscriptions, the adapter-identity snapshot
/// (#1312), the capability-probe latch (#2261) and the reconnect-scanner
/// factory (#797/#2245); collaborators are injected from the notifier.
/// NOT owned (host seam): the Riverpod state, last-trip identity,
/// `_saveToHistory`, and the #1303 WAL (+#1347 recovery — it runs with no
/// pipeline at all).
class Obd2RecordingPipeline implements RecordingPipeline {
  Obd2RecordingPipeline({
    required this._ref,
    required this._host,
    required this._haptics,
    required this._gps,
    required this._baselines,
    required this._oemFuel,
    required this._readActiveVehicle,
    required this._readOemPidsFlag,
    required this._readDiagnosticCaptureFlag,
    this._startWatchdog = kObd2TripStartWatchdog, this._baselinesBudget = kObd2TripStartBaselinesBudget,
  });

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
  // #3500 — per-trip IMU fusion (shared with the GPS-only pipeline); the
  // OBD2 path previously ran NO inertial detector (#2895/#3029 note).
  TripImuFusion? _imuFusion;
  TripRecordingController? _controller;
  StreamSubscription<TripLiveReading>? _liveSub;
  StreamSubscription<TripRecordingControllerState>? _stateSub;

  bool _capabilityReconcileKicked = false;

  String? _adapterMac;
  String? _adapterName;
  String? _adapterFirmware;

  @override
  bool get isGpsOnly => false;

  /// The live controller (WAL snapshots, pause/resume, debug hooks read it
  /// here). Null between trips / in the cold-start-recovered state.
  TripRecordingController? get controller => _controller;

  /// The vehicle id the current recording's baselines are scoped to —
  /// stamped onto the WAL snapshot + the saved entry by the notifier.
  String? get baselineVehicleId => _baselines.vehicleId;

  /// Adapter identity snapshotted at [start] (#1312) — survives the
  /// pre-save disconnect.
  String? get adapterMac => _adapterMac;
  String? get adapterName => _adapterName;
  String? get adapterFirmware => _adapterFirmware;

  /// Begin a recording backed by [service] (pipeline takes ownership;
  /// [stop] tears down). The re-entrancy guard stays on the notifier.
  Future<void> start(Obd2Service service, {bool automatic = false}) async {
    // #3527 — the one supervisor owns the link; this pipeline owns the trip.
    _service = service;
    _capabilityReconcileKicked = false; // #2261 — re-arm the probe.
    // #3808 — a trip REUSING the kept-alive link never calls connect(),
    // so it had no comm-diagnostics session and the health card claimed
    // "no OBD2 session" on a good recording. No-op on the dial path.
    Obd2CommDiagnostics.instance.beginSessionIfAbsent(
      linkKind: service.linkKind,
      redactedMac: redactObd2Mac(service.adapterMac),
    );
    // #1312 — snapshot adapter identity NOW (stop disconnects pre-save).
    _adapterMac = service.adapterMac;
    _adapterName = service.adapterName;
    _adapterFirmware = service.adapterFirmware;
    // #812/#797 — the active vehicle drives `readFuelRateLPerHour` and
    // tags any pause-on-drop snapshot.
    final activeVehicle = _readActiveVehicle();
    // #797/#3423 — reconnect pin: vehicle MAC, else the #3019 auto-pin.
    final pinnedMac = resolveAdapterPinMac(activeVehicle?.obd2AdapterMac,
        () => _ref.read(lastGoodAdapterStoreProvider).recall());
    // #1395 — per-trip breadcrumb sink; cleared for a fresh denominator.
    final breadcrumbs = _ref.read(obd2BreadcrumbsProvider.notifier);
    breadcrumbs.clear();
    service.breadcrumbCollector = breadcrumbs;
    final matchedReference = // #1422 — catalog η_v default; null on miss.
        tryMatchReferenceVehicle(_ref, activeVehicle);
    // #2506 — GPS-physics estimate + coaching folder.
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
        // #2565/#3014 — read the live transport kind + adapter name at
        // handle-drop time, so the reconnect dispatches over the SAME
        // transport and the trace headline names the adapter.
        readLinkKind: () => _service?.linkKind,
        readAdapterName: () => _service?.adapterName,
      ),
      // #3776 — the trip layer never closes a supervisor-owned link; a
      // dead one is handed to the owner, which closes + redials.
      isLinkSupervised: (svc) => supervisorOwnsService(_ref, svc),
      reportSupervisedLinkDead: (svc, reason) {
        try {
          return _ref
              .read(obd2ReconnectProvider.notifier)
              .supervisor
              .reportServiceDead(svc, reason: reason);
        } catch (_) {
          // No supervisor graph (widget tests / legacy path) — the
          // caller closes the service itself.
          return false;
        }
      },
      breadcrumbCollector: breadcrumbs,
      gpsEstimateFolder: gpsEstimateFolder,
      // #2663 — forward every (de-noised, post-#2653) harsh event onto the
      // app-wide bus so the driving-coach voice listener can speak it live.
      onHarshEvent: _ref.read(liveHarshEventBusProvider.notifier).add,
    );
    _controller = ctl;

    // #3500 — shared per-trip IMU fusion: confirmed inertial episodes feed
    // the live harsh-event bus (spoken coaching on OBD2 trips too); sensor
    // failure is non-fatal (logged inside the fusion).
    final imuFusion = buildTripImuFusion(
      _ref,
      onEvent: _ref.read(liveHarshEventBusProvider.notifier).add,
      where: 'Obd2RecordingPipeline.start',
    )..start();
    _imuFusion = imuFusion;

    // #769 baselines + #3382 watchdog-bound init (obd2_trip_start_budgets): on
    // a stall ABORT cleanly (disconnect + recoverable error), never hang.
    try {
      await _baselines.load().timeout(_baselinesBudget);
      await ctl.start().timeout(_startWatchdog);
    } on TimeoutException {
      _controller = null;
      _imuFusion = null;
      unawaited(imuFusion.stop());
      unawaited(service.disconnectQuietly());
      throw const Obd2AdapterUnresponsive();
    }
    // #1374/#1981 — GPS trip-path sampling; never blocks trip-start.
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
      // #3500 — feed real vehicle speed to the fusion's min-speed gate.
      _imuFusion?.feedSpeedKmh(reading.speedKmh);
      // #2261 — deferred `0902` capability probe, one-shot fire-and-forget.
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
      // when leaving the drop state (#3859: the GPS-degraded phase too).
      if (newPhase == TripRecordingPhase.pausedDueToDrop ||
          newPhase == TripRecordingPhase.degradedGpsOnly) {
        _host.state = _host.state.copyWith(
          phase: newPhase,
          dropReason: ctl.dropReason,
          reconnectPassiveWaiting: passiveWaiting,
          parkedPromptDue: ctl.parkedPromptDue, // #3862
        );
      } else {
        _host.state = _host.state.copyWith(
          phase: newPhase,
          clearDropReason: true,
          reconnectPassiveWaiting: passiveWaiting,
          parkedPromptDue: false,
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

  @override // #3862
  bool dismissParkedPrompt() =>
      (_controller?..dismissParkedPrompt()) != null;

  @override
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    final ctl = _controller;
    final svc = _service;
    if (ctl == null || svc == null) {
      _host.state = const TripRecordingState();
      return const StoppedTripResult.empty();
    }
    // #3795 — attribute the end BEFORE teardown. First-writer-wins, so
    // a cause already recorded (grace expiry, watchdog abort) survives.
    ctl.noteTermination(TripTermination(automatic
        ? TripTerminationReason.autoRecordDisconnect
        : TripTerminationReason.userStopped));
    final termination = ctl.termination;
    final sessionJournal = ctl.sessionJournal;
    _host.setSaveStage(TripSaveStage.finalizingSummary); // #2548 beat 1
    try {
      await ctl.refreshOdometer();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
        'where': 'Obd2RecordingPipeline.stop: refreshOdometer failed'
      }));
    }
    // #1040/#1458 — snapshot both buffers BEFORE stop() tears the
    // controller down, else the trip-detail charts render empty.
    final capturedSamples = List<TripSample>.unmodifiable(ctl.capturedSamples);
    final capturedGpsDiagnostics = List<GpsSampleDiagnostic>.unmodifiable(
      ctl.capturedGpsSampleDiagnostics,
    );
    // #2431 — GPS-estimate back-fill when no fuel PID; no-op otherwise.
    final filled = Obd2GpsEstimateFallback.fillWhenNoFuelPid(
      summary: await ctl.stop(),
      samples: capturedSamples,
      vehicle: _readActiveVehicle(),
    );
    // #3500 — harvest the IMU fusion before the summary persists.
    final imuFusion = _imuFusion;
    _imuFusion = null;
    await imuFusion?.stop();
    final summary = imuFusion == null
        ? filled.summary
        : imuFusion.applyTo(filled.summary);
    final odometerStartKm = ctl.odometerStartKm;
    final odometerLatestKm = ctl.odometerLatestKm;
    // #2509 — fix count BEFORE teardown (stationary-discard guard).
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
      // #3794 — how it ended + the lifecycle timeline, onto the trip.
      termination: termination,
      sessionJournal: sessionJournal,
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
    // #3527 — keep-link: a supervisor-owned service stays connected at
    // trip end (see obd2_supervised_teardown.dart for the rationale).
    await teardownServiceRespectingSupervisor(_ref, svc);
    _service = null;
    await _host.clearActiveSnapshot(); // #1303 — no resurrection
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
