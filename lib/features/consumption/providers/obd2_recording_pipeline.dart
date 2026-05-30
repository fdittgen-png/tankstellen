// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../vehicle/data/reference_vehicle_catalog_provider.dart';
import '../../vehicle/data/vehicle_profile_catalog_matcher.dart';
import '../../vehicle/domain/entities/reference_vehicle.dart';
import '../../vehicle/domain/entities/vehicle_profile.dart';
import '../data/obd2/adapter_reconnect_scanner.dart';
import '../data/obd2/obd2_connection_service.dart';
import '../data/obd2/obd2_service.dart';
import '../data/obd2/reconnect_connector.dart';
import '../data/obd2/trip_recording_controller.dart';
import '../domain/entities/gps_sample_diagnostic.dart';
import '../domain/services/obd2_gps_estimate_fallback.dart';
import '../domain/trip_recorder.dart';
import 'obd2_breadcrumb_provider.dart';
import 'recording_pipeline.dart';
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
/// factory (#797 / #2245). The four focused collaborators are *injected*
/// from the notifier so they outlive a single recording and the test
/// counters accumulate exactly as the inline fields did.
///
/// Deliberately NOT owned: the Riverpod `state`, the last-trip identity
/// fields, the shared `_saveToHistory` write, and the #1303 active-trip WAL
/// snapshot (+ its #1347 cold-start recovery) stay on the notifier and are
/// reached through the [Obd2RecordingPipelineHost] — the WAL survives the
/// recording loop being torn down (recovery runs with no pipeline at all),
/// so it belongs to the notifier. Behaviour-preserving: the seed / flush
/// cadence is driven through the same host hooks the inline path used.
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
  })  : _ref = ref,
        _host = host,
        _haptics = haptics,
        _gps = gps,
        _baselines = baselines,
        _oemFuel = oemFuel,
        _readActiveVehicle = readActiveVehicle,
        _readOemPidsFlag = readOemPidsFlag;

  final Ref _ref;
  final Obd2RecordingPipelineHost _host;
  final TripHapticController _haptics;
  final TripGpsStreamController _gps;
  final TripBaselineRecorder _baselines;
  final TripOemFuelLevelController _oemFuel;
  final VehicleProfile? Function() _readActiveVehicle;
  final bool Function() _readOemPidsFlag;

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
    // #797 phase 3 — pass the pinned MAC + a factory for the auto-reconnect
    // scanner. Null MAC (unpaired vehicle) skips the scanner entirely and
    // leaves the grace-window path as the sole recovery mechanism.
    final pinnedMac = activeVehicle?.obd2AdapterMac;
    // #1395 — wire the diagnostic breadcrumb sink for this trip. Both
    // the controller and the underlying [Obd2Service] push through the
    // SAME notifier (kept keepAlive across recordings) so the user can
    // inspect the trace from the overlay after the recording screen pops.
    final breadcrumbs = _ref.read(obd2BreadcrumbsProvider.notifier);
    // Clear any leftover breadcrumbs from a prior trip — fresh
    // suspicion-rate denominator for THIS recording.
    breadcrumbs.clear();
    service.breadcrumbCollector = breadcrumbs;
    // #1422 phase 1 — match the active vehicle to the bundled catalog so
    // the controller can fall through to the engine-tech-derived η_v
    // default instead of the legacy 0.85 literal until VeLearner
    // converges. Null on no-vehicle / no-catalog / no-match.
    final matchedReference = _tryMatchReferenceVehicle(activeVehicle);
    final ctl = TripRecordingController(
      service: service,
      vehicle: activeVehicle,
      referenceVehicle: matchedReference,
      vehicleId: eagerVehicleId,
      pinnedAdapterMac: pinnedMac,
      automatic: automatic,
      reconnectScannerFactory: _buildReconnectScannerFactory(),
      breadcrumbCollector: breadcrumbs,
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
      _host.state = _host.state.copyWith(
        phase: _phaseFor(ctl),
        live: reading,
        situation: classified.situation,
        band: classified.band,
        liveDeltaFraction: classified.delta,
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
    // recording screen swaps the inline progress card for the live
    // metrics on the same frame.
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
    // controller — without this the trip-detail charts render the
    // "No samples recorded" empty state on every saved trip (#1040).
    final capturedSamples = List<TripSample>.unmodifiable(ctl.capturedSamples);
    // #1458 phase 2 — snapshot the GPS cadence diagnostics buffer BEFORE
    // teardown, same reason. Always captured (empty when GPS off).
    final capturedGpsDiagnostics = List<GpsSampleDiagnostic>.unmodifiable(
      ctl.capturedGpsSampleDiagnostics,
    );
    // #2431 — back-fill consumption from the GPS-physics estimate when the
    // adapter+ECU supported no fuel PID (all-null → blank fuel branch);
    // a no-op when any real fuel signal was seen (see fillWhenNoFuelPid).
    final filled = Obd2GpsEstimateFallback.fillWhenNoFuelPid(
      summary: await ctl.stop(),
      samples: capturedSamples,
      vehicle: _readActiveVehicle(),
    );
    final summary = filled.summary;
    final odometerStartKm = ctl.odometerStartKm;
    final odometerLatestKm = ctl.odometerLatestKm;
    await _liveSub?.cancel();
    _liveSub = null;
    await _stateSub?.cancel();
    _stateSub = null;
    // #1374 phase 1 — tear down the Geolocator subscription if one was
    // opened. Best-effort.
    await _gps.stop();
    // #1615 — tear down the OEM-PID fuel-level poll. Best-effort.
    await _oemFuel.stop();
    _controller = null;
    // #726 — persist to the trip history rolling log through the host.
    // Every trip (including discarded ones) is logged; the fill-up flow
    // is a *separate* decision. Best-effort.
    await _host.saveToHistory(
      summary,
      samples: filled.samples,
      gpsSampleDiagnostics: capturedGpsDiagnostics,
      automatic: automatic,
      vehicleId: _baselines.vehicleId,
      adapterMac: _adapterMac,
      adapterName: _adapterName,
      adapterFirmware: _adapterFirmware,
    );
    // #769 / #780 — flush learned baselines + fold in the server copy
    // before releasing the service. Best-effort.
    await _baselines.flushAndSync();
    // #1312 — clear the captured adapter identity once persisted.
    _adapterMac = null;
    _adapterName = null;
    _adapterFirmware = null;
    try {
      await svc.disconnect();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
        'where': 'Obd2RecordingPipeline.stop: service disconnect failed'
      }));
    }
    _service = null;
    // #1303 — the trip is finalised in history; clear the WAL snapshot
    // so recovery doesn't resurrect a stopped trip on next launch.
    await _host.clearActiveSnapshot();
    _host.state = _host.state.copyWith(phase: TripRecordingPhase.finished);
    return StoppedTripResult(
      summary: summary,
      odometerStartKm: odometerStartKm,
      odometerLatestKm: odometerLatestKm,
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

  /// Resolve the catalog row for [profile] (#1422 phase 1). Null when the
  /// catalog hasn't loaded, the profile is null, or no tier hits.
  /// Swallows provider-wiring errors so widget tests don't have to
  /// override the catalog graph just to start a recording.
  ReferenceVehicle? _tryMatchReferenceVehicle(VehicleProfile? profile) {
    if (profile == null) return null;
    try {
      final catalog = _ref.read(referenceVehicleCatalogProvider).value;
      if (catalog == null || catalog.isEmpty) return null;
      return VehicleProfileCatalogMatcher.bestMatch(
        profile: profile,
        catalog: catalog,
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
        'where': 'Obd2RecordingPipeline: reference catalog unavailable'
      }));
      return null;
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
      final connector = ReconnectConnector(
        connection: connection,
        onConnected: (svc) => _service = svc,
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
