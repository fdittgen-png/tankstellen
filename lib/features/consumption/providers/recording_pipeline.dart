// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/entities/gps_sample_diagnostic.dart';
import '../domain/trip_recorder.dart';
import 'trip_recording_state.dart';

/// Strategy seam for a complete trip-recording pipeline (#2190).
///
/// The [TripRecording] notifier historically owned two mutually-
/// exclusive recording pipelines as sibling field sets and branched on
/// an `if (_gpsOnlyMode)` boolean at every lifecycle boundary:
///
///   * the sensor-rich **OBD2** pipeline (engine signals via the
///     [Obd2Service] / [TripRecordingController]), and
///   * the **GPS-only** pipeline (#2025 — no dongle, samples synthesised
///     from Geolocator fixes feeding a pure [TripRecorder]).
///
/// This interface lifts that branch into virtual dispatch: the notifier
/// holds a single `RecordingPipeline?` selected at start (null = the
/// inline OBD2 path; a [RecordingPipeline] = an alternate strategy such
/// as [GpsOnlyRecordingPipeline]) and delegates the lifecycle operations
/// that used to fork on the boolean. A future third source (CarPlay /
/// Android Auto telemetry) becomes a new implementation rather than
/// another `_xMode` bool and another `if`-branch on every method
/// (open/closed — the #2190 motivation).
///
/// ## Why the OBD2 path stays inline (slice-3 scoping)
///
/// #2190 explicitly recommends staging the extraction — "interface +
/// GPS-only impl first, OBD2 impl second" — because the OBD2 `start` /
/// `stop` bodies are woven through ~15 notifier-private collaborators
/// (baseline store, haptics, the GPS-fix stream, the OEM-PID poll, the
/// debounced active-trip snapshot persistence, the reconnect-scanner
/// factory, adapter-identity snapshotting, baseline flush + sync,
/// service disconnect). Pulling all of that behind a uniform `start` /
/// `stop` would widen the seam past a behaviour-preserving refactor.
/// So the OBD2 path remains the notifier's inline default (`_pipeline ==
/// null`) and only the genuinely self-contained GPS-only pipeline is
/// extracted to a concrete strategy in this slice. The interface is
/// shaped so an `Obd2RecordingPipeline` can adopt it later without
/// disturbing callers.
abstract class RecordingPipeline {
  /// True for a GPS-only / dongle-less pipeline. Lets the notifier and
  /// tests assert which strategy was selected without depending on the
  /// concrete type.
  bool get isGpsOnly;

  /// Pause the live recording loop, if the pipeline has one. The
  /// GPS-only pipeline ignores this (its position stream keeps running);
  /// the OBD2 pipeline forwards it to the controller. Returns true when
  /// the call actually paused a live recording so the notifier knows to
  /// flip its `phase` to `paused`.
  bool pause() => false;

  /// Resume a paused recording. Mirror of [pause]; the GPS-only pipeline
  /// is a no-op. Returns true when a live recording was resumed.
  bool resume() => false;

  /// Tear the pipeline down, persist the finished trip, and return the
  /// [StoppedTripResult] the recording screen renders into its summary
  /// view. [automatic] tags the saved entry as auto-recorded (#1004).
  ///
  /// Mirrors the contract of the notifier's own `stop` so the branch
  /// `if (_gpsOnlyMode) return _stopGpsOnly(...)` collapses to a single
  /// `return _pipeline!.stop(...)` delegation.
  Future<StoppedTripResult> stop({bool automatic = false});
}

/// Narrow seam a [RecordingPipeline] uses to drive and read the
/// [TripRecording] notifier without owning the notifier's Riverpod
/// `state`, its trip-identity bookkeeping, or the shared history-write
/// path (#2190).
///
/// Mirrors the injected-host idiom established by [DroppedSessionHost]
/// (#2188): the pipeline owns the *recording* concern (its recorder, its
/// sample buffer, its position subscription) while the bits that belong
/// to the notifier — publishing `state`, the last-trip identity fields,
/// and `_saveToHistory` — stay on the notifier and are reached through
/// this interface. Keeps the pipeline unit-testable against a fake host
/// (no real notifier / Riverpod container required).
abstract class RecordingPipelineHost {
  /// Read back the notifier's current public recording state.
  TripRecordingState get state;

  /// Publish a new recording state (the notifier's `state =` setter).
  set state(TripRecordingState value);

  /// Record the vehicle / start-time the in-flight trip is scoped to,
  /// so the fill-up auto-link window can resolve it later (#888).
  set lastTripVehicleId(String? value);
  set lastTripStartedAt(DateTime? value);

  /// Resolve the active vehicle profile id, swallowing provider-wiring
  /// errors (returns null in widget tests / no-vehicle state).
  String? readActiveVehicleId();

  /// Persist the finished trip into the rolling trip-history log. Shared
  /// with the OBD2 path — every trip (including discarded stubs, which
  /// the implementation filters) flows through the same write so the
  /// stub-discard + trip-sync + auto-record-badge bookkeeping is applied
  /// identically regardless of pipeline.
  ///
  /// [vehicleId] / [adapterMac] / [adapterName] / [adapterFirmware] let
  /// the OBD2 pipeline stamp the saved entry with the dongle identity it
  /// snapshotted at start (#1312) and the baseline-store vehicle id; the
  /// GPS-only path leaves them null and the detail card hides the rows.
  Future<void> saveToHistory(
    TripSummary summary, {
    bool automatic,
    List<TripSample> samples,
    List<GpsSampleDiagnostic> gpsSampleDiagnostics,
    String? vehicleId,
    String? adapterMac,
    String? adapterName,
    String? adapterFirmware,
  });
}

/// The wider host an [Obd2RecordingPipeline] needs (#2227): the base
/// [RecordingPipelineHost] plus the active-trip WAL snapshot hooks.
///
/// The write-through persistence of an in-progress trip (#1303) and its
/// cold-start recovery (#1347) stay on the notifier — they survive the
/// recording loop being torn down (recovery runs with no pipeline at
/// all), so they belong to the notifier, not the strategy. The OBD2
/// pipeline drives them through these hooks so the snapshot cadence is
/// byte-identical to the pre-extraction inline path. The GPS-only path
/// has no WAL, so it only needs the narrower [RecordingPipelineHost] —
/// keeping these hooks off the base interface means GPS-only fakes don't
/// have to stub WAL methods they never exercise.
abstract class Obd2RecordingPipelineHost implements RecordingPipelineHost {
  /// Seed the active-trip snapshot once the OBD2 controller is started
  /// and knows its session id + odometer reads (#1303).
  void seedActiveSnapshot();

  /// Cheap debounced WAL gate, called from the live-sample listener.
  void maybeFlushActiveSnapshot();

  /// Force / debounced WAL flush; phase transitions force it (#1303).
  Future<void> flushActiveSnapshot({bool force});

  /// Drop the persisted snapshot once the trip is finalised in history.
  Future<void> clearActiveSnapshot();
}

/// Returned by [TripRecording.stop] / [RecordingPipeline.stop]. Bundles
/// the summary with the raw odometer reads so the save-as-fill-up flow
/// can pre-fill the form.
///
/// Lives here (rather than on the notifier) because it is the
/// [RecordingPipeline.stop] return type — keeping it next to the strategy
/// seam avoids a circular import between the notifier and its pipelines.
/// `TripRecording`'s library re-exports it so existing callers that import
/// the provider keep resolving the type unchanged.
class StoppedTripResult {
  final TripSummary summary;
  final double? odometerStartKm;
  final double? odometerLatestKm;

  const StoppedTripResult({
    required this.summary,
    required this.odometerStartKm,
    required this.odometerLatestKm,
  });

  const StoppedTripResult.empty()
      : summary = const TripSummary(
          distanceKm: 0,
          maxRpm: 0,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
        ),
        odometerStartKm = null,
        odometerLatestKm = null;

  /// End-of-trip km, derived: latest odometer read if we have one,
  /// otherwise start + integrated distance. Null when neither
  /// odometer read ever succeeded.
  double? get endOdometerKm =>
      odometerLatestKm ??
      (odometerStartKm == null
          ? null
          : odometerStartKm! + summary.distanceKm);
}
