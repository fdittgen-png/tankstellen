// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/feedback/auto_record_badge_provider.dart';
import '../../../core/feedback/auto_record_badge_service.dart';
import '../../../core/storage/hive_boxes.dart';
import '../data/trips_sync.dart';
import '../../../core/sync/trips_sync_enabled_provider.dart';
import '../../feature_management/api.dart';
import '../../../core/domain/vehicle_profile.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../../obd2/api.dart';
import '../data/trip_history_repository.dart';
import '../domain/entities/gps_sample_diagnostic.dart';
import '../domain/entities/trip_save_stage.dart';
import '../domain/entities/trip_start_stage.dart';
import '../domain/services/recovered_summary_rebuild.dart';
import '../domain/services/physics_scale_calibrator.dart';
import '../domain/trip_recorder.dart';
import 'active_vehicle_read.dart';
import 'gps_only_recording_pipeline.dart';
import 'recording_battery_exemption.dart';
import 'recording_companion_association.dart';
import 'recording_lifecycle_marks_recorder.dart';
import 'recording_pipeline.dart';
import 'trip_discard_guard.dart';
import 'trip_baseline_recorder.dart';
import 'trip_gps_stream_controller.dart';
import 'trip_haptic_controller.dart';
import 'trip_oem_fuel_level_controller.dart';
import 'trip_history_provider.dart';
import 'trip_recording_phase.dart';
import 'trip_recording_state.dart';
import '../../../core/logging/error_logger.dart';
import '../domain/entities/trip_termination.dart';
import '../domain/recording_session_journal.dart';
import '../../../core/telemetry/process_death_context.dart';

// Re-exports so existing callers keep resolving after the #563 split;
// new callers should import the individual files directly.
export 'haptic_feedback_policy.dart'
    show HapticIntensity, hapticForBandTransition;
export 'trip_recording_phase.dart' show TripRecordingPhase;
export 'trip_recording_state.dart' show TripRecordingState;
// #1330 — TripDropReason for `select((s) => s.dropReason)` watchers.
export '../../obd2/api.dart' show TripDropReason;
// #2190 — StoppedTripResult lives beside the RecordingPipeline seam
// (circular-import avoidance); re-exported for its ~10 callers.
export 'recording_pipeline.dart' show StoppedTripResult;
// #2274 concern 2 — the connecting phase carries a TripStartStage on the
// state; re-export it so callers that drive the start flow through this
// provider resolve the stage type without a second import.
export '../domain/entities/trip_start_stage.dart' show TripStartStage;
// #2548 — the saving phase carries a TripSaveStage; re-export it so
// callers resolve the type without a second import.
export '../domain/entities/trip_save_stage.dart' show TripSaveStage;

// #3504 — re-export: keeps the #3132 driving->consumption count flat.
export 'trip_history_provider.dart';

part 'trip_recording_provider.g.dart';
part 'trip_recording_provider_core.dart';
part 'trip_recording_provider_host.dart';
part 'trip_recording_provider_lifecycle.dart';
part 'trip_recording_provider_persist.dart';
part 'trip_recording_provider_snapshot.dart';

/// App-wide owner of the trip recording (#726).
///
/// Hoisted out of [TripRecordingScreen]'s state so a trip survives
/// navigation — the user can start recording, switch to the Search
/// tab, tap a station, come back, and find the trip still running.
/// Lives for the app's lifetime (`keepAlive: true`) because dropping
/// it mid-drive would silently throw away the trip.
///
/// Owns the [Obd2Service] while a trip is active; the
/// [Obd2ConnectionService] hands ownership here on [start] and gets
/// it back on [stop].
@Riverpod(keepAlive: true)
class TripRecording extends _$TripRecording
    with
        _TripRecordingCore,
        _TripRecordingSnapshot,
        _TripRecordingPersist,
        _TripRecordingLifecycle {
  @override
  TripRecordingState build() {
    return const TripRecordingState();
  }

  /// #2190 — read / publish the recording state on behalf of an alternate
  /// [RecordingPipeline]. The Riverpod `state` getter + setter are
  /// protected to the notifier instance, so the [RecordingPipelineHost]
  /// adapter routes its access through these methods rather than touching
  /// `state` from outside the class — mirroring the `_emitState()` seam the
  /// controller exposes to its [DroppedSessionHost] (#2188).
  TripRecordingState _stateForPipeline() => state;
  void _setStateFromPipeline(TripRecordingState value) {
    state = value;
  }

  /// Standalone entry point for starting a trajet (#888).
  ///
  /// Unlike [start] (which already expects a connected [Obd2Service]),
  /// this call resolves the vehicle + adapter from the active profile
  /// by default. Callers can override either by passing [vehicleId]
  /// or [adapterMac] explicitly.
  ///
  /// Returns:
  ///  - [StartTripOutcome.started] when [service] was supplied by
  ///    the caller — the provider takes ownership and kicks off the
  ///    recording immediately.
  ///  - [StartTripOutcome.needsPicker] when no [service] is supplied
  ///    and the resolved vehicle has no pinned adapter MAC. The UI
  ///    layer is expected to fire `showObd2AdapterPicker`, then call
  ///    back into [start] with the returned service.
  ///  - [StartTripOutcome.alreadyActive] when a trip is already
  ///    running — no double-start.
  ///
  /// Trajets are first-class: this method does NOT require a pending
  /// fill-up, does NOT block on one, and does NOT read any fill-up
  /// state. The fill-up save path (#888) derives the trip→tank link
  /// from the rolling trip-history log independently.
  ///
  /// [automatic] flags the controller so any [PausedTripEntry]
  /// written on a mid-trip BLE drop (#1004 phase 4-WAL) carries the
  /// auto-record provenance. Defaults to `false` so manual UI
  /// callers are unchanged; the orchestrator no-picker path
  /// (`AutoTripCoordinator`) passes `true`.
  Future<StartTripOutcome> startTrip({
    String? vehicleId,
    String? adapterMac,
    Obd2Service? service,
    bool automatic = false,
  }) async {
    if (state.isActive || _startInProgress) {
      return StartTripOutcome.alreadyActive;
    }
    final activeVehicle = _tryReadActiveVehicle();
    final resolvedVehicleId = vehicleId ?? activeVehicle?.id;
    final resolvedMac = adapterMac ?? activeVehicle?.obd2AdapterMac;
    _lastTripVehicleId = resolvedVehicleId;
    _lastTripStartedAt = DateTime.now();
    if (service != null) {
      // #1004 phase 2b-3 — orchestrator-driven no-picker start path.
      // The caller supplies the connected `Obd2Service` directly so
      // `automatic: true` flows through to the controller and the
      // resulting [PausedTripEntry] (if BLE drops mid-trip) carries
      // the auto-record provenance at WAL recovery time.
      await start(service, automatic: automatic);
      return StartTripOutcome.started;
    }
    if (resolvedMac == null || resolvedMac.isEmpty) {
      return StartTripOutcome.needsPicker;
    }
    // Pinned adapter but no service handed in — the UI picker is
    // still the right place to fire a connect: it reuses the exact
    // same scan + connect flow (with retry/error surfacing) and
    // short-circuits on the pinned MAC. Keeping the connect logic
    // at the UI layer avoids pulling a Bluetooth stack into provider
    // code and keeps #888's scope to the decoupling concern.
    return StartTripOutcome.needsPicker;
  }

  /// Begin a recording session backed by [service]. The provider
  /// takes ownership of the service — don't disconnect it from the
  /// caller; [stop] handles the full teardown.
  ///
  /// [automatic] flags the controller so any [PausedTripEntry] it
  /// writes on a mid-trip BLE drop (#1004 phase 4-WAL) carries the
  /// auto-record provenance. Defaults to false so existing manual
  /// call sites are unchanged. The hands-free [AutoTripCoordinator]
  /// path passes `automatic: true`.
  Future<void> start(Obd2Service service, {bool automatic = false}) async {
    // #1932 — synchronous re-entrancy guard. Both the check and the
    // flag set run before `start()`'s first `await`, so a second start
    // racing into the window (e.g. the AutoTripCoordinator and a manual
    // UI start firing together) is rejected instead of orphaning a
    // second controller. Cleared in a `finally` so a throwing start
    // never locks recording out permanently.
    if (state.isActive || _startInProgress) return;
    _startInProgress = true;
    if (!automatic) {
      // #3313 — manual (foreground) start: prompt once, FGS-gated. Auto
      // starts skip it (may be backgrounded; the dialog can't show).
      unawaited(ref.read(recordingBatteryExemptionProvider).maybePrompt());
      // #3437 — same foreground moment: fire-and-forget CDM association for
      // the pinned dongle (no-op without one / FGS-off / iOS / pre-34).
      triggerCompanionAssociationForPinnedAdapter(ref);
    }
    try {
      await _startInternal(service, automatic: automatic);
    } finally {
      _startInProgress = false;
    }
  }

  Future<void> _startInternal(
    Obd2Service service, {
    bool automatic = false,
  }) async {
    _lastTripStartedAt ??= DateTime.now();
    _lastTripAutomatic = automatic; // #3251 — stamp the WAL seed honestly.
    // #769 — record the vehicle id the trip is scoped to up-front so the
    // fill-up auto-link window resolves it even if the baseline load
    // races. Cheap Riverpod cache hit.
    _lastTripVehicleId ??= _tryReadActiveVehicle()?.id;
    // #2227 — the OBD2 recording loop lives in [Obd2RecordingPipeline].
    // The notifier selects it (mirroring the GPS-only selection in
    // [startGpsOnly]) and delegates the live loop + teardown; the WAL
    // snapshot (#1303) + cold-start recovery (#1347) stay here, driven
    // through the [RecordingPipelineHost]. The collaborators are passed
    // in (not reconstructed) so test counters accumulate as before.
    final pipeline = Obd2RecordingPipeline(
      ref: ref,
      host: _RecordingPipelineHostAdapter(this),
      haptics: _haptics,
      gps: _gps,
      baselines: _baselines,
      oemFuel: _oemFuel,
      readActiveVehicle: _tryReadActiveVehicle,
      readOemPidsFlag: _readOemPidsFlag,
      readDiagnosticCaptureFlag: _readDiagnosticCaptureFlag,
    );
    _pipeline = pipeline;
    await pipeline.start(service, automatic: automatic);
  }

  // ---------------------------------------------------------------------------
  // #2025 / #2190 — GPS-only recording path. Lets users record a trajet
  // without an OBD2 dongle: samples come from Geolocator, the TripRecorder
  // accumulator runs the same harsh-event / distance / idle integration
  // it does for OBD2 trips, and the persisted summary carries
  // `kind: TripKind.gpsOnly` so downstream surfaces (confidence-tier
  // badge, recording-screen redesign) can adapt. The pipeline itself now
  // lives in [GpsOnlyRecordingPipeline], selected into `_pipeline` here
  // and driven through the [RecordingPipelineHost] seam below.
  // ---------------------------------------------------------------------------

  /// Start a GPS-only trajet recording (#2025). Skips the OBD2 service
  /// + adapter picker entirely; instead installs a [GpsOnlyRecordingPipeline]
  /// that opens a Geolocator stream and feeds a pure [TripRecorder] with
  /// synthetic samples (speed from `Position.speed`, all engine fields
  /// null, lat/lon/altitude/bearing from the fix).
  ///
  /// Returns:
  ///  - [StartTripOutcome.started] when the stream was opened. Caller
  ///    pushes the recording screen.
  ///  - [StartTripOutcome.alreadyActive] when a trip is already
  ///    running (OBD2 or GPS-only).
  Future<StartTripOutcome> startGpsOnly() async {
    if (state.isActive || _startInProgress) {
      return StartTripOutcome.alreadyActive;
    }
    _startInProgress = true;
    unawaited(ref.read(recordingBatteryExemptionProvider).maybePrompt()); // #3313
    try {
      final pipeline = GpsOnlyRecordingPipeline(
        ref: ref,
        host: _RecordingPipelineHostAdapter(this),
      );
      _pipeline = pipeline;
      pipeline.start();
      return StartTripOutcome.started;
    } finally {
      _startInProgress = false;
    }
  }

  /// #2025 — mid-trip upgrade hook. Appends an externally-built
  /// [TripSample] (carrying OBD2 telemetry) to the in-progress
  /// GPS-only buffer + recorder so the final [TripSummary.kind] flips
  /// to `gpsPlusObd2` via [TripKind.fromSamples].
  ///
  /// No-op when no GPS-only trip is active. Future UX surface
  /// (banner: "OBD2 detected — attach to current trip?") drives
  /// this; until then the API lives here so the acceptance scenario
  /// is testable + the data layer supports it the moment any
  /// caller starts producing OBD2-flavoured samples.
  @visibleForTesting
  void debugAppendObd2SampleToGpsOnly(TripSample sample) {
    final pipeline = _pipeline;
    if (pipeline is! GpsOnlyRecordingPipeline) return;
    pipeline.appendObd2Sample(sample);
  }
}
