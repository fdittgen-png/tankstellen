// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_provider.dart';

/// #3760 — the [RecordingPipelineHost] adapter and the [StartTripOutcome]
/// enum, split out of `trip_recording_provider.dart` as a `part`
/// (move-only, behaviour preserved). Stays in the library so the adapter
/// keeps its private access to the notifier's state seam and WAL helpers.

/// Adapts the [TripRecording] notifier to the [Obd2RecordingPipelineHost]
/// seam its pipelines need (#2190 / #2227). Lives in the same library as
/// the notifier so it can reach the notifier's `state` setter, last-trip
/// identity fields, the active-vehicle read, the shared `_saveToHistory`
/// write, and the #1303 active-trip WAL snapshot helpers without widening
/// the notifier's public API — mirroring the `_DroppedSessionHostAdapter`
/// idiom on the controller (#2188). Implements the wider OBD2 host; a
/// [GpsOnlyRecordingPipeline] only reaches the narrower base subset.
class _RecordingPipelineHostAdapter implements Obd2RecordingPipelineHost {
  _RecordingPipelineHostAdapter(this._n);

  final TripRecording _n;

  @override
  TripRecordingState get state => _n._stateForPipeline();

  @override
  set state(TripRecordingState value) => _n._setStateFromPipeline(value);

  @override
  set lastTripVehicleId(String? value) => _n._lastTripVehicleId = value;

  @override
  set lastTripStartedAt(DateTime? value) => _n._lastTripStartedAt = value;

  @override
  String? readActiveVehicleId() => _n._tryReadActiveVehicle()?.id;

  @override
  Future<TripPersistOutcome> saveToHistory(
    TripSummary summary, {
    bool automatic = false,
    List<TripSample> samples = const [],
    List<GpsSampleDiagnostic> gpsSampleDiagnostics = const [],
    String? vehicleId,
    String? adapterMac,
    String? adapterName,
    String? adapterFirmware,
    int gpsFixCount = 0,
    TripTermination? termination,
    RecordingSessionJournal? sessionJournal,
  }) =>
      _n._saveToHistory(
        summary,
        automatic: automatic,
        samples: samples,
        gpsSampleDiagnostics: gpsSampleDiagnostics,
        vehicleId: vehicleId,
        adapterMac: adapterMac,
        adapterName: adapterName,
        adapterFirmware: adapterFirmware,
        gpsFixCount: gpsFixCount,
        termination: termination,      // #3794
        sessionJournal: sessionJournal, // #3794
      );

  // #2548 — staged save-progress: the pipeline drives the `saving` phase
  // + stage through the notifier (mirrors the start `setConnectStage`).
  @override
  void setSaveStage(TripSaveStage stage) => _n.setSaveStage(stage);

  // #2227 — WAL snapshot hooks driven by the OBD2 pipeline. The
  // GPS-only pipeline does not use these (its [RecordingPipelineHost]
  // calls keep to state + save), so they stay no-ops for it.
  @override
  void seedActiveSnapshot() => _n._seedActiveSnapshot();

  @override
  void maybeFlushActiveSnapshot() => _n._maybeFlushActiveSnapshot();

  @override
  Future<void> flushActiveSnapshot({bool force = false}) =>
      _n._flushActiveSnapshot(force: force);

  @override
  Future<void> clearActiveSnapshot() => _n._clearActiveSnapshot();

  @override
  Future<List<TripSample>> readAllCapturedSamples() =>
      _n.readAllCapturedSamples(); // #3878
}

/// Outcome surfaced by [TripRecording.startTrip] so the UI layer can
/// decide whether to fire the adapter picker (#888).
enum StartTripOutcome {
  /// A service was supplied and the recording session started.
  started,

  /// No service was supplied and the resolved vehicle has no pinned
  /// adapter — the caller should open `showObd2AdapterPicker`, then
  /// hand the resulting service back into [TripRecording.start].
  needsPicker,

  /// A trip is already running; the call was a no-op.
  alreadyActive,
}
