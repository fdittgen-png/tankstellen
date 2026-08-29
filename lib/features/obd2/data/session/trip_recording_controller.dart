// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../vehicle/domain/entities/reference_vehicle.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../../../driving_score/api.dart';
import '../../../trips/api.dart';
import 'obd2_reattach_source.dart';
import '../../domain/degraded_gps_emitter.dart';
import 'dropped_session_host.dart';
import 'dropped_session_manager.dart';
import '../../domain/gps_only_sample_builder.dart';
import '../../domain/instant_consumption_ema.dart';
import 'live_sample_snapshot.dart';
import 'trip_recording_sink.dart';
import '../obd2_breadcrumb_collector.dart';
import '../../domain/obd2_connection_errors.dart';
import '../../domain/obd2_trip_start_budgets.dart';
import '../obd2_debug_session.dart';
import 'obd2_service.dart';
import 'obd2_vin_reader.dart';
import '../paused_trip_repository.dart';
import '../../domain/pid_scheduler.dart';
import '../../domain/trip_distance_resolver.dart';
import '../../domain/trip_drop_detector.dart';
import '../../domain/trip_live_reading.dart';
import '../../domain/trip_sample_buffer.dart';
import '../../domain/vehicle_power_state.dart';
import '../../domain/virtual_odometer.dart';

// Re-export the live-reading DTO so existing callers (providers,
// widget tests) that import this file keep working after the #563
// controller-split refactor. New callers should import the individual
// files directly. The kDistanceSource* re-export was dropped in #3175
// (every consumer already imports trip_distance_source.dart directly);
// the two remaining re-exports stay — 12 importers still rely on them.
export '../../domain/trip_live_reading.dart' show TripLiveReading;
// #2188 — TripDropReason moved with the drop-RECOVERY state machine into
// DroppedSessionManager. Re-export it here so the providers / widgets /
// tests that import it from this file keep working unchanged.
export 'dropped_session_manager.dart' show TripDropReason;

// #3760 — the controller is decomposed into `part` files below the
// #1680 file-length cap: a private mixin chain (the sanctioned
// edit_vehicle_screen pattern) so every moved member keeps
// library-private access and stays virtually dispatchable. Move-only,
// behaviour preserved.
part 'trip_recording_controller_debug.dart';
part 'trip_recording_controller_drop_host.dart';
part 'trip_recording_controller_emit.dart';
part 'trip_recording_controller_lifecycle.dart';
part 'trip_recording_controller_power.dart';
part 'trip_recording_controller_state.dart';
part 'trip_recording_controller_summary.dart';
part 'trip_recording_controller_telemetry_ingest.dart';
part 'trip_recording_controller_transport.dart';

/// Drives the priority-tiered PID polling loop that feeds an
/// [Obd2Service]'s live PIDs into a [TripRecorder] (#726, #814).
///
/// Not a Riverpod notifier — kept as a plain class so the recording
/// screen owns the lifecycle (start on screen mount, stop on tap).
/// The screen subscribes to [live] for UI updates and calls [stop]
/// to finalise the trip.
///
/// ## #814 phase 2 — PidScheduler migration
///
/// Phase 1 (PR #860) shipped the standalone [PidScheduler]. Phase 2
/// wires it here: instead of one monolithic `Timer.periodic(1s)` that
/// reads every PID on every tick, we subscribe each PID at its own
/// target frequency and let the scheduler's weighted round-robin pick
/// the next command:
///
///   - **5 Hz (high priority):** RPM, speed, MAF/MAP, throttle, fuel-
///     rate PID 5E. These drive the eco-feedback band classifier and
///     the live L/100 km readout — users feel a 200 ms refresh.
///   - **1 Hz (medium):** STFT, LTFT, IAT, engine load. Needed for
///     the fuel-rate correction and the situation classifier, but
///     they don't change fast enough to warrant a 200 ms slot.
///   - **0.1 Hz (low):** fuel tank level. 10 s is plenty — the gauge
///     barely moves per tick.
///
/// VIN (Mode 09) is a one-shot read at [start] and is intentionally
/// NOT subscribed — it doesn't change mid-trip, and blasting the
/// adapter with a 0x0902 every 10 s wastes bandwidth the 5 Hz tier
/// needs.
///
/// Emissions are debounced. Every PID response updates an internal
/// snapshot; a secondary timer (running at [_pollInterval]) emits a
/// consolidated [TripLiveReading] off that snapshot. At 5 Hz on the
/// fast tier we would otherwise fire ten+ events per second — more
/// signal than the UI can consume and more state-change churn than
/// the situation/band classifier needs. The debounced approach keeps
/// the event rate bounded at whatever cadence the caller wants
/// (production: 250–500 ms; tests: 1 minute to pin the loop quiet).
///
/// ## #797 phase 1 — survive Bluetooth drops
///
/// Every scheduler-routed transport call is funnelled through
/// [_runTransport] which counts consecutive failures and classifies
/// them. Three consecutive errors within [_dropWindow], OR a typed
/// [Obd2DisconnectedException] / `StateError('Transport closed')`,
/// flip the controller into [TripRecordingControllerState.pausedDueToDrop]:
///   - the scheduler is stopped,
///   - the partial [TripSummary] (distance, fuel estimate so far,
///     harsh counters, odometer reads, VIN) is serialised to the
///     `obd2_paused_trips` Hive box,
///   - a grace timer starts for the configured pause-grace window; if
///     [resume] isn't called before it fires, the paused entry is
///     finalised into the normal trip history as if [stop] had run.
///
/// Phase 1 exposes the state machine without wiring a UI banner —
/// phase 2 brings the auto-reconnect scanner + snackbar UX.
class TripRecordingController
    with
        _TripRecordingSessionState,
        _TripRecordingTelemetryIngest,
        _TripRecordingTransportGuard,
        _TripRecordingPowerWatch,
        _TripRecordingEmit,
        _TripRecordingSummary,
        _TripRecordingDebugSeams,
        _TripRecordingLifecycle {
  /// The OBD2 service the recording loop reads through. NOT `final`
  /// (#2524): an in-trip auto-reconnect builds a brand-new
  /// [Obd2Service] + transport, and [replaceService] swaps this pointer
  /// so [_runTransport] / [refreshOdometer] start polling the LIVE link
  /// instead of the dead old one. Before #2524 this was bound once at
  /// construction and never reassigned — the pipeline's `onConnected`
  /// swapped only its OWN pointer, so the scheduler kept dereferencing
  /// the original (closed) transport, every poll timed out at 2.5 s, a
  /// stranded `_pending` tripped the concurrent-sendCommand guard, and
  /// the rest of the drive recorded nothing.
  /// #3797 — the recording session's lifecycle timeline. Always on and
  /// bounded (see [RecordingSessionJournal]); read at save time so the
  /// trip row and every export can explain how the session went.
  @override
  final RecordingSessionJournal _sessionJournal = RecordingSessionJournal();

  /// The lifecycle timeline of this recording (#3797). Empty until
  /// [start] anchors it.
  RecordingSessionJournal get sessionJournal => _sessionJournal;

  /// #3795 — how this session ended (set via [noteTermination]).
  @override
  TripTermination? _termination;

  @override
  Obd2Service _service;
  // #3776 — link-ownership seam (see the constructor doc).
  @override
  final bool Function(Obd2Service service)? _isLinkSupervised;
  final bool Function(Obd2Service service, String reason)?
      _reportSupervisedLinkDead;
  @override
  final TripRecorder _recorder;
  @override
  final Duration _pollInterval;
  @override
  final DateTime Function() _now;

  /// Active [VehicleProfile] snapshot for the speed-density
  /// fuel-rate fallback (#810, #812 phase 3). Captured once at
  /// construction — the user's vehicle doesn't change mid-trip, and
  /// re-reading the profile every tick would just burn CPU. When
  /// null, `readFuelRateLPerHour` falls back to its generic 1.0 L /
  /// η_v 0.85 defaults — still honest, just less precise.
  @override
  final VehicleProfile? _vehicle;

  /// Reference catalog row matched to [_vehicle] at construction
  /// (#1422 phase 1). Drives the engine-tech-derived η_v default so a
  /// fresh Dacia dCi profile resolves 0.95 instead of the legacy 0.85
  /// catalog literal until VeLearner converges. Null when the active
  /// vehicle has no catalog match (custom EV, niche import, etc.) — the
  /// controller falls back to the stored profile value.
  final ReferenceVehicle? _referenceVehicle;

  /// Vehicle id tagged on paused snapshots + trip-history finalisations
  /// (#797 phase 1). The controller itself doesn't know about the
  /// Riverpod-backed active vehicle profile; the provider passes it
  /// through at construction so the paused-trips box row carries it.
  final String? _vehicleId;

  /// Whether this recording was kicked off by the hands-free
  /// [AutoTripCoordinator] (#1004 phase 4-WAL). Plumbed through to the
  /// persisted [PausedTripEntry] so the launch-time recovery service
  /// can decide whether to bump the launcher-icon badge when it
  /// finalises a stale entry — manual trips never counted toward
  /// "unseen" and must not retroactively start counting just because
  /// the app was killed before the disconnect-save timer fired.
  @override
  final bool _automatic;

  /// #3862 (Epic #3855) — engine off AND stationary this long during a
  /// manual recording → the Stop / Keep prompt; an auto-record trip ends
  /// itself instead.
  static const Duration parkedPromptAfter = Duration(minutes: 3);

  /// #3877 — cadence of the odometer re-read while the engine runs (one
  /// PID per interval; the start value alone was up to a whole trip stale
  /// when the stop came with the engine already off).
  static const Duration odometerRefreshInterval = Duration(minutes: 5);

  /// Per-trip 'diagnostic capture' flag (#2459 — default off; an
  /// internal/dev flag, not a user setting, wired from
  /// `Feature.debugMode`). When ON, `_emit` ALSO stamps the raw mixture
  /// inputs (MAF / MAP / STFT / LTFT) onto each persisted [TripSample]
  /// at a SLOW cadence (every [_diagnosticCaptureInterval], carried
  /// forward in between) so a trip's fuel rate can be re-derived
  /// post-hoc. Default OFF ⇒ those four keys are never written ⇒ zero
  /// storage growth for the overwhelming majority of trips.
  @override
  final bool _diagnosticCapture;

  /// Optional override — tests inject a hand-built scheduler (usually
  /// with a tiny [PidScheduler.tickRate] + a fake transport) to
  /// exercise the scheduler ↔ controller wiring without touching the
  /// real [Obd2Service] chain. Production always passes null and
  /// [start] constructs a scheduler against [service.sendCommand].
  ///
  /// Note: an override bypasses the drop-detection transport wrapper
  /// (#797 phase 1) because the caller pre-wired the transport. Tests
  /// that want to exercise the drop heuristic should use
  /// [schedulerTickRate] instead, which still routes through
  /// [_runTransport].
  @override
  final PidScheduler? _schedulerOverride;

  /// Tick rate for the default-constructed scheduler (#797 phase 1).
  /// Lets tests drive the round-robin faster than the 100 ms
  /// production default without having to construct their own
  /// [PidScheduler] — which would bypass the drop-detection wrapper
  /// in [_runTransport].
  @override
  final Duration _schedulerTickRate;

  /// #2506 — shared GPS-physics estimate + coaching folder (consumption's,
  /// typed as the obd2-owned [TripGpsEstimateOverlay] seam since #3743),
  /// injected by `Obd2RecordingPipeline` so the OBD2 live path mirrors the
  /// GPS-only pipeline through ONE implementation. Null → fields stay null.
  @override
  final TripGpsEstimateOverlay? _gpsEstimateFolder;

  /// Maximum Δt (seconds) between samples that the distance / fuel
  /// integrators bridge (#1927). A longer gap is a connection dropout
  /// or pause — integrating across it fabricates distance and fuel, so
  /// `TripRecorder` and `VirtualOdometer` skip it. 15 s is far above
  /// the ~250 ms poll cadence and the 6 s silent-reconnect window.
  static const double _integrationGapCapSeconds = 15.0;

  /// #2565 — how recent a real GPS fix must be for an OBD2 drop to
  /// degrade to GPS-only recording (and the window past which a degraded
  /// trip whose GPS also died escalates to "paused"). Pinned to the same
  /// 15 s Δt the integrators refuse to bridge (`_integrationGapCapSeconds`).
  static const Duration _gpsAliveWindow = Duration(seconds: 15);

  TripRecordingController({
    required this._service,
    TripRecorder? recorder,
    this._pollInterval = const Duration(milliseconds: 250),
    DateTime Function()? now,
    this._vehicle,
    this._referenceVehicle,
    this._vehicleId,
    PidScheduler? scheduler,
    // #3878 — reads the whole trip (WAL + ring) for the grace finalise.
    Future<List<TripSample>> Function()? allSamplesReader,
    PausedTripRepository? pausedRepo,
    TripHistoryRepository? historyRepo,
    Duration pauseGraceWindow = const Duration(minutes: 15),
    Duration silentReconnectWindow = const Duration(seconds: 6),
    Duration dropWindow = const Duration(seconds: 5),
    int dropThreshold = 3,
    int silentFailureThreshold = 50,
    this._schedulerTickRate = const Duration(milliseconds: 100),
    String? pinnedAdapterMac,
    this._automatic = false,
    this._diagnosticCapture = false,
    Obd2ReattachSource? Function(
      String pinnedMac,
      VoidCallback onReconnect,
    )? reconnectScannerFactory,
    this._isLinkSupervised,
    this._reportSupervisedLinkDead,
    this._breadcrumbCollector,
    this._gpsEstimateFolder,
    void Function(HarshEvent event)? onHarshEvent,
  })  : _recorder = recorder ??
            TripRecorder(
              maxIntegrationGapSeconds: _integrationGapCapSeconds,
              onHarshEvent: onHarshEvent,
            ),
        _now = now ?? DateTime.now,
        _schedulerOverride = scheduler {
    _allSamplesReader = allSamplesReader;
    _dropDetector = TripDropDetector(
      now: _now,
      dropWindow: dropWindow,
      dropThreshold: dropThreshold,
      silentFailureThreshold: silentFailureThreshold,
    );
    _droppedSession = DroppedSessionManager(
      host: _DroppedSessionHostAdapter(this),
      now: _now,
      pauseGraceWindow: pauseGraceWindow,
      silentReconnectWindow: silentReconnectWindow,
      pinnedAdapterMac: pinnedAdapterMac,
      reconnectScannerFactory: reconnectScannerFactory,
      pausedRepo: pausedRepo,
      historyRepo: historyRepo,
    );
    _distance = TripDistanceResolver(
      maxIntegrationGapSeconds: _integrationGapCapSeconds,
      now: _now,
    );
    _liveSampleSnapshot = LiveSampleSnapshot(
      service: _service,
      vehicle: _vehicle,
      referenceVehicle: _referenceVehicle,
      breadcrumbCollector: _breadcrumbCollector,
      onHighPriorityParse: _observeHighPriorityParse,
      onSpeedSample: _recordSpeedSample,
    );
    _degradedEmitter = DegradedGpsEmitter(
      now: _now,
      recorder: _recorder,
      sampleBuffer: _sampleBuffer,
      gpsAliveWindow: _gpsAliveWindow,
      onEscalate: _droppedSession.escalateDegradedToPaused,
      onSampleAt: (at) => _lastSampleAt = at,
      overlayEstimate: (reading,
              {required nowTs, required effectiveSpeedKmh, required altitudeM}) =>
          _overlayGpsEstimate(
        reading,
        nowTs: nowTs,
        fuelRate: null,
        effectiveSpeedKmh: effectiveSpeedKmh,
        rpm: null,
        altitudeM: altitudeM,
      ),
    );
  }

  /// Optional fuel-rate diagnostic breadcrumb sink (#1395). Wired in
  /// by [tripRecordingProvider] when a recording starts so the
  /// controller can record the resolved branch + AFR/density/
  /// displacement/VE actually used by [_deriveFuelRateLPerHour] each
  /// emit, plus surface the running suspicion-rate at trip-end via
  /// [TripSummary.fuelRateSuspect]. Typed as the [Obd2BreadcrumbRecorder]
  /// interface so production passes the Riverpod notifier
  /// (state-republishing) and unit tests pass a raw
  /// [Obd2BreadcrumbCollector].
  @override
  final Obd2BreadcrumbRecorder? _breadcrumbCollector;
}
