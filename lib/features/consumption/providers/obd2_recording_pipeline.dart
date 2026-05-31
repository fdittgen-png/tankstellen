// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../vehicle/domain/entities/vehicle_profile.dart';
import '../data/obd2/adapter_reconnect_scanner.dart';
import '../data/obd2/obd2_connection_service.dart';
import '../data/obd2/obd2_service.dart';
import '../data/obd2/obd2_session_context_block.dart';
import '../data/obd2/reconnect_connector.dart';
import '../data/obd2/trip_recording_controller.dart';
import '../domain/entities/gps_sample_diagnostic.dart';
import '../domain/services/gps_live_estimate_folder.dart';
import '../domain/services/obd2_gps_estimate_fallback.dart';
import '../domain/trip_recorder.dart';
import 'obd2_breadcrumb_provider.dart';
import 'recording_pipeline.dart';
import 'reference_vehicle_match.dart';
import 'trip_baseline_recorder.dart';
import 'trip_gps_stream_controller.dart';
import 'trip_haptic_controller.dart';
import 'trip_oem_fuel_level_controller.dart';
import 'trip_recording_phase.dart';
import 'trip_recording_state.dart';

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
  })  : _ref = ref,
        _host = host,
        _haptics = haptics,
        _gps = gps,
        _baselines = baselines,
        _oemFuel = oemFuel,
        _readActiveVehicle = readActiveVehicle,
        _readOemPidsFlag = readOemPidsFlag,
        _readDiagnosticCaptureFlag = readDiagnosticCaptureFlag;

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

  Obd2Service? _service;
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
    _service = service;
    // #2261 concern 6 — re-arm the deferred capability probe for this
    // recording; the first live sample kicks it.
    _capabilityReconcileKicked = false;
    // #1312 — snapshot adapter identity NOW: the service is disconnected
    // during `stop` before the entry is saved, so it can't be read off
    // the live service at save time. Null → the detail card hides the row.
    _adapterMac = service.adapterMac;
    _adapterName = service.adapterName;
    _adapterFirmware = service.adapterFirmware;
    // #812 phase 3 — snapshot the active vehicle so the controller can
    // hand it to `readFuelRateLPerHour`; a null vehicle / fields fall back
    // to the service defaults. Vehicle id resolved up-front so the
    // controller can tag any pause-on-drop snapshot (#797 phase 1).
    final activeVehicle = _readActiveVehicle();
    final eagerVehicleId = _readActiveVehicle()?.id;
    // #797 phase 3 — pinned MAC + auto-reconnect scanner factory. Null MAC
    // (unpaired) skips the scanner; the grace window is the sole recovery.
    final pinnedMac = activeVehicle?.obd2AdapterMac;
    // #1395 — wire the diagnostic breadcrumb sink for this trip; both the
    // controller and the [Obd2Service] push through the SAME keepAlive
    // notifier so the trace survives the recording screen popping.
    final breadcrumbs = _ref.read(obd2BreadcrumbsProvider.notifier);
    breadcrumbs.clear(); // fresh suspicion-rate denominator for THIS trip
    service.breadcrumbCollector = breadcrumbs;
    // #1422 phase 1 — match the active vehicle to the bundled catalog so
    // the controller can use the engine-tech-derived η_v default instead
    // of the legacy 0.85 literal until VeLearner converges. Null on no-match.
    final matchedReference = tryMatchReferenceVehicle(_ref, activeVehicle);
    // #2506 — build the SHARED GPS-physics live-estimate + coaching folder
    // (mirrors the GPS-only pipeline). Folded per no-fuel-PID tick inside the
    // controller so the OBD2 live screen carries `~ estimated` consumption +
    // GPS coaching instead of dashing a no-fuel-PID car's whole drive — live
    // mirrors the post-trip `Obd2GpsEstimateFallback`. Null vehicle / matrix
    // → population-default class + cold-start scale.
    final gpsEstimateFolder = GpsLiveEstimateFolder.forVehicle(
      activeVehicle,
      activeVehicle?.gpsCalibration,
    );
    final ctl = TripRecordingController(
      service: service,
      vehicle: activeVehicle,
      referenceVehicle: matchedReference,
      vehicleId: eagerVehicleId,
      pinnedAdapterMac: pinnedMac,
      automatic: automatic,
      // #2459 — diagnostic capture (Feature.debugMode); default off.
      diagnosticCapture: _readDiagnosticCaptureFlag(),
      reconnectScannerFactory: _buildReconnectScannerFactory(),
      breadcrumbCollector: breadcrumbs,
      gpsEstimateFolder: gpsEstimateFolder,
    );
    _controller = ctl;

    // #769 — resolve the active vehicle + fuel family and load its
    // learned baselines from Hive (delegated to TripBaselineRecorder).
    await _baselines.load();

    await ctl.start();
    // #1374 / #1981 — GPS trip-path sampling, default-on. Fire-and-forget
    // — the permission round-trip must not block trip-start.
    unawaited(_gps.start(ctl));
    // #1615 — opt-in experimental OEM-PID exact-fuel-level poll. A no-op
    // when the flag is off or the adapter is not OEM-PID-capable.
    _oemFuel.start(
      enabled: _readOemPidsFlag(),
      vin: ctl.vin,
      capability: service.capability,
      port: service,
      onLitres: ctl.updateOemFuelLevelLitres,
    );
    // #1303 — seed the active-trip WAL snapshot now that the controller
    // knows its session id + odometer reads (stays on the notifier).
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
      // `state.gpsCoachingHint`, so publishing it here lights the chips on the
      // OBD2 live screen too. Null (measured fuel present / no hint) clears it.
      final gpsHint = ctl.latestGpsCoachingHint;
      _host.state = _host.state.copyWith(
        phase: _phaseFor(ctl),
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
      final newPhase = _phaseFor(ctl);
      // #1330 phase 3 — surface the controller's drop reason. Cleared
      // when leaving the drop state.
      if (newPhase == TripRecordingPhase.pausedDueToDrop) {
        _host.state = _host.state.copyWith(
          phase: newPhase,
          dropReason: ctl.dropReason,
        );
      } else {
        _host.state = _host.state.copyWith(
          phase: newPhase,
          clearDropReason: true,
        );
      }
      // #1303 — phase transitions force an immediate snapshot.
      unawaited(_host.flushActiveSnapshot(force: true));
    });
    // #2274 concern 2 — going live clears any connecting stage so the
    // recording screen swaps the progress card for live metrics that frame.
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
    // #726 — persist every trip (incl. discarded); fill-up is separate.
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
    _service = null;
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

  /// Map the controller's enum onto the provider's phase. Mirrors the
  /// notifier's former `_phaseFor`.
  TripRecordingPhase _phaseFor(TripRecordingController ctl) {
    switch (ctl.currentState) {
      case TripRecordingControllerState.idle:
        return TripRecordingPhase.idle;
      case TripRecordingControllerState.recording:
        return TripRecordingPhase.recording;
      case TripRecordingControllerState.paused:
        return TripRecordingPhase.paused;
      case TripRecordingControllerState.pausedDueToDrop:
        return TripRecordingPhase.pausedDueToDrop;
      case TripRecordingControllerState.stopped:
        return TripRecordingPhase.finished;
    }
  }

  /// Build the reconnect-scanner factory handed to [TripRecordingController]
  /// (#797 phase 3). Returns null in tests / environments where
  /// [obd2ConnectionProvider] can't be resolved — the controller then
  /// falls back to grace-window-only recovery.
  AdapterReconnectScanner? Function(
    String pinnedMac,
    VoidCallback onReconnect,
  )? _buildReconnectScannerFactory() {
    final Obd2ConnectionService connection;
    try {
      connection = _ref.read(obd2ConnectionProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
        'where': 'Obd2RecordingPipeline: connection provider unavailable'
      }));
      return null;
    }
    return (pinnedMac, onReconnect) {
      // One connector per drop holds the gate bookkeeping across the
      // scanner's repeated connect cycles. The connect callback prefers a
      // DIRECT GATT connect (works for clones that stop advertising in
      // standby) and only falls back to an RSSI-gated scan (#2245).
      // #2524 — swap the pipeline's pointer (so stop() tears down the LIVE
      // svc) AND the controller's via `replaceService` (so the loop polls the
      // reconnected transport, not the closed one). See `replaceService`.
      final connector = ReconnectConnector(
        connection: connection,
        onConnected: (svc) {
          _service = svc;
          _controller?.replaceService(svc);
        },
      );
      return AdapterReconnectScanner(
        pinnedMac: pinnedMac,
        probe: (mac) async => true,
        connect: connector.attempt,
        // #2261 concern 2 — after the active-scan miss ceiling switch to a
        // passive autoConnect GATT wait for the rest of the 15-min grace.
        passiveConnect: connector.attemptPassive,
        onReconnect: onReconnect,
      );
    };
  }
}
