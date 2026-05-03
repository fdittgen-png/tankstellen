import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/feedback/auto_record_badge_provider.dart';
import '../../../core/feedback/auto_record_badge_service.dart';
import '../../../core/location/geolocator_wrapper.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/baselines_sync.dart';
import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../vehicle/domain/entities/vehicle_profile.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../data/baseline_store.dart';
import '../data/obd2/active_trip_repository.dart';
import '../data/obd2/adapter_registry.dart';
import '../data/obd2/adapter_reconnect_scanner.dart';
import '../data/obd2/obd2_connection_service.dart';
import '../data/obd2/obd2_service.dart';
import '../data/obd2/trip_recording_controller.dart';
import 'obd2_breadcrumb_provider.dart';
import '../data/trip_history_repository.dart';
import '../domain/cold_start_baselines.dart';
import '../domain/situation_classifier.dart';
import '../domain/trip_recorder.dart';
import 'haptic_feedback_policy.dart';
import 'trip_history_provider.dart';
import 'trip_recording_phase.dart';
import 'trip_recording_state.dart';

// Re-export the phase, state, and haptic-policy types so existing
// callers (widgets, screens, tests) that import this file keep
// resolving without touching every import site after the #563
// provider-split refactor. New callers should import the individual
// files directly.
export 'haptic_feedback_policy.dart'
    show HapticIntensity, hapticForBandTransition;
export 'trip_recording_phase.dart' show TripRecordingPhase;
export 'trip_recording_state.dart' show TripRecordingState;
// #1330 phase 3 — re-export TripDropReason so widgets watching
// `tripRecordingProvider.select((s) => s.dropReason)` resolve the
// type without a second import.
export '../data/obd2/trip_recording_controller.dart' show TripDropReason;

part 'trip_recording_provider.g.dart';

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
class TripRecording extends _$TripRecording {
  Obd2Service? _service;
  TripRecordingController? _controller;
  StreamSubscription<TripLiveReading>? _liveSub;
  StreamSubscription<TripRecordingControllerState>? _stateSub;
  // #1374 phase 1 — Geolocator position stream feeding the
  // controller's per-tick GPS latch. Only created when
  // `Feature.gpsTripPath` is enabled at trip-start; the flag-off
  // path leaves this null and never touches the plugin, so the
  // battery / permission cost is exactly zero for users who haven't
  // opted in. Cancelled on stop alongside the live + state subs.
  StreamSubscription<Position>? _gpsSub;
  SituationClassifier? _classifier;
  BaselineStore? _store;
  String? _vehicleId;
  ConsumptionFuelFamily _fuelFamily = ConsumptionFuelFamily.gasoline;

  // #1312 — adapter identity captured at trip-start so it survives
  // into the saved [TripHistoryEntry] even if the [Obd2Service] has
  // been disconnected by the time `_saveToHistory` runs (`stop`
  // disconnects the service before saving). Sourced from the service
  // fields stamped by [Obd2ConnectionService] on connect; null when
  // the service was constructed without going through the connection
  // layer (test fakes).
  String? _adapterMac;
  String? _adapterName;
  String? _adapterFirmware;

  /// Tests count haptic fires via these instead of hooking the
  /// platform channel. The production path also still calls
  /// [HapticFeedback], so counting here doesn't short-circuit the
  /// real vibration on a device.
  @visibleForTesting
  int hapticLightCount = 0;
  @visibleForTesting
  int hapticMediumCount = 0;

  /// Exposed for tests: the underlying [TripRecordingController] while
  /// a trip is active. Lets the #1040 sample-persistence test inject a
  /// deterministic buffer through [TripRecordingController.debugCaptureSample]
  /// without spinning up a real polling clock. Null between trips.
  @visibleForTesting
  TripRecordingController? get debugController => _controller;

  /// Snapshot of the vehicle the last [startTrip] call was scoped to.
  /// Exposed so the save-as-fill-up path can figure out which
  /// trajets to auto-link (#888). Null before the first call, or
  /// after a [reset] / fresh [build].
  String? _lastTripVehicleId;
  DateTime? _lastTripStartedAt;

  // ---------------------------------------------------------------------------
  // #1303 — write-through persistence of the in-progress trip
  // ---------------------------------------------------------------------------

  /// Optional override for tests: hand-built repository wrapping an
  /// in-memory Hive box. Production reads the box from
  /// [HiveBoxes.obd2ActiveTrip] when needed; this lets tests skip
  /// the box-open dance.
  ActiveTripRepository? _activeRepoOverride;

  /// Last persisted snapshot, kept in memory so the debounced
  /// flush can re-use the trip identity (id, startedAt, vehicleId)
  /// across writes without rebuilding it from scratch.
  ActiveTripSnapshot? _activeSnapshot;

  /// Wall-clock of the most recent flush. Used by the debounce
  /// gate so we don't pay a Hive write on every sample.
  DateTime? _lastSnapshotFlushAt;

  /// Sample count since the last flush. Forces an out-of-band
  /// write when the user has been driving long enough to fill the
  /// buffer past the count threshold even if the time threshold
  /// hasn't elapsed (e.g. a 5 Hz fast tier on stop-and-go traffic).
  int _samplesSinceLastFlush = 0;

  /// Time-based debounce: at most one Hive write every 5 seconds
  /// while the trip is healthy. Aligned with the controller's
  /// 4 Hz emit cadence — 4 Hz × 5 s = 20 emits per write, which
  /// is a comfortable balance between recovery freshness and
  /// flash-write wear.
  static const Duration _snapshotFlushInterval = Duration(seconds: 5);

  /// Sample-count fallback: flush when this many emits have
  /// accumulated since the previous write, regardless of clock.
  /// 30 covers ~7.5 s at 4 Hz so the upper bound on a freshness
  /// gap is bounded by either rule.
  static const int _snapshotFlushSampleThreshold = 30;

  /// Most recent vehicle id this provider kicked a trip for.
  ///
  /// Readable by the consumption providers so the fill-up auto-link
  /// can filter trajets to the vehicle that was actually driven —
  /// decoupling the trajets flow from the fill-up flow (#888).
  String? get lastTripVehicleId => _lastTripVehicleId;

  /// Timestamp captured on the most recent [startTrip] call. Used by
  /// the auto-link window in the fill-up flow as a "latest-known
  /// driving activity" lower bound when no prior fill-up exists.
  DateTime? get lastTripStartedAt => _lastTripStartedAt;

  @override
  TripRecordingState build() {
    return const TripRecordingState();
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
  Future<StartTripOutcome> startTrip({
    String? vehicleId,
    String? adapterMac,
    Obd2Service? service,
  }) async {
    if (state.isActive) return StartTripOutcome.alreadyActive;
    final activeVehicle = _tryReadActiveVehicle();
    final resolvedVehicleId = vehicleId ?? activeVehicle?.id;
    final resolvedMac = adapterMac ?? activeVehicle?.obd2AdapterMac;
    _lastTripVehicleId = resolvedVehicleId;
    _lastTripStartedAt = DateTime.now();
    if (service != null) {
      await start(service);
      return StartTripOutcome.started;
    }
    // TODO(#1004 phase 2b-3) — when the orchestrator's no-picker
    // start lands, plumb `automatic: true` into the resulting [start]
    // call here so the [PausedTripEntry] written on a mid-trip BLE
    // drop carries the automatic flag at WAL recovery time. For now
    // the picker fork below is the only orchestrator-driven path and
    // it goes through UI before re-entering [start], which provides
    // the [automatic] argument explicitly.
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
    if (state.isActive) return;
    _lastTripStartedAt ??= DateTime.now();
    _service = service;
    // #1312 — snapshot adapter identity NOW. The service is
    // disconnected during `stop` before `_saveToHistory` runs, so we
    // can't read these off the live service at save time. Best-effort
    // — a null reading just means the trip detail card will hide the
    // adapter row.
    _adapterMac = service.adapterMac;
    _adapterName = service.adapterName;
    _adapterFirmware = service.adapterFirmware;
    // #812 phase 3 — snapshot the active vehicle so the controller
    // can hand it to `readFuelRateLPerHour` on every tick. The
    // speed-density fallback reads engineDisplacementCc +
    // volumetricEfficiency off the profile; a null vehicle or null
    // fields fall back to the service-level defaults. We read the
    // vehicle a second time below for the baseline-store
    // bookkeeping; both reads are cheap Riverpod cache hits.
    final activeVehicle = _tryReadActiveVehicle();
    // Resolve the vehicle id up-front so the controller can tag any
    // pause-on-drop snapshot it writes to the `obd2_paused_trips`
    // Hive box (#797 phase 1). Cheap Riverpod cache hit — same
    // provider call used again below for the baseline store.
    final eagerVehicleId = _tryReadActiveVehicle()?.id;
    // #797 phase 3 — pass the pinned MAC + a factory for the auto-
    // reconnect scanner. Null MAC (unpaired vehicle) skips the
    // scanner entirely and leaves the grace-window path as the sole
    // recovery mechanism. The factory uses the already-wired
    // [Obd2ConnectionService] to drive the BT scan + reconnect,
    // keeping the controller free of plugin imports.
    final pinnedMac = activeVehicle?.obd2AdapterMac;
    // #1395 — wire the diagnostic breadcrumb sink for this trip. Both
    // the controller (for `_deriveFuelRateLPerHour` snapshots) and
    // the underlying [Obd2Service] (for the live PID 5E + MAF reads
    // inside `readFuelRateLPerHour`) push through the SAME notifier
    // — the provider keeps it keepAlive across recordings so the
    // user can still inspect the trace from the overlay after the
    // recording screen pops. Going through the notifier (which
    // implements [Obd2BreadcrumbRecorder]) means every push also
    // republishes the entries list to the overlay listeners.
    final breadcrumbs = ref.read(obd2BreadcrumbsProvider.notifier);
    // Clear any leftover breadcrumbs from a prior trip — we want a
    // fresh suspicion-rate denominator for THIS recording.
    breadcrumbs.clear();
    service.breadcrumbCollector = breadcrumbs;
    final ctl = TripRecordingController(
      service: service,
      vehicle: activeVehicle,
      vehicleId: eagerVehicleId,
      pinnedAdapterMac: pinnedMac,
      automatic: automatic,
      reconnectScannerFactory: _buildReconnectScannerFactory(),
      breadcrumbCollector: breadcrumbs,
    );
    _controller = ctl;
    _classifier = SituationClassifier();

    // #769 — resolve the active vehicle + fuel family and load its
    // learned baselines from Hive. Falls back silently to cold-start
    // defaults when the box isn't open (widget tests) or the active
    // vehicle is unavailable.
    try {
      final vehicle = ref.read(activeVehicleProfileProvider);
      _vehicleId = vehicle?.id;
      _lastTripVehicleId ??= vehicle?.id;
      _fuelFamily = _resolveFuelFamily(vehicle?.preferredFuelType);
      if (Hive.isBoxOpen(HiveBoxes.obd2Baselines)) {
        _store = BaselineStore(
          box: Hive.box<String>(HiveBoxes.obd2Baselines),
        );
        if (_vehicleId != null) {
          await _store!.loadVehicle(_vehicleId!);
        }
      }
    } catch (e, st) {
      debugPrint('TripRecording.start: baseline setup failed: $e\n$st');
      _store = null;
    }

    await ctl.start();
    // #1374 phase 1 — opt-in GPS sampling. Only when the user has
    // explicitly turned the feature on do we open a Geolocator
    // position stream; the flag-off path skips the plugin entirely so
    // a default-config user pays no battery cost. Errors on the
    // stream are logged and swallowed (a permission revoke mid-trip
    // must not derail the recording) — the controller's per-tick
    // latch simply stops being refreshed and subsequent samples
    // carry `latitude: null, longitude: null`.
    _startGpsSubscriptionIfEnabled(ctl);
    // #1303 — seed the active-trip snapshot identity now that the
    // controller knows its session id + odometer reads. The first
    // flush happens off the live-stream debounce below; if the
    // process dies before the first sample lands, the empty
    // snapshot is still enough to put the user back in the
    // recording UI on next launch.
    _seedActiveSnapshot();
    _liveSub = ctl.live.listen((reading) {
      final situation = _classifyFrom(reading);
      _recordToStore(reading, situation);
      final band = _classifyBandFrom(reading, situation);
      final delta = _computeDelta(reading, situation);
      _fireBandTransitionHaptic(state.band, band);
      state = state.copyWith(
        phase: _phaseFor(ctl),
        live: reading,
        situation: situation,
        band: band,
        liveDeltaFraction: delta,
      );
      // #1303 — debounced write-through. Cheap when the gate
      // rejects (a single timestamp comparison + counter bump).
      _maybeFlushActiveSnapshot();
    });
    // #797 phase 1 — listen to explicit state changes so the UI
    // surfaces "pausedDueToDrop" even when no TripLiveReading lands
    // (the drop kills the per-PID callbacks that would have woken the
    // live listener). Pure state transitions don't reshape band/delta,
    // so we only copyWith the phase here.
    _stateSub = ctl.stateChanges.listen((_) {
      final newPhase = _phaseFor(ctl);
      // #1330 phase 3 — surface the controller's drop reason so the
      // pause banner can pick the right copy (transport error vs
      // silent failure). Cleared when leaving the drop state.
      if (newPhase == TripRecordingPhase.pausedDueToDrop) {
        state = state.copyWith(
          phase: newPhase,
          dropReason: ctl.dropReason,
        );
      } else {
        state = state.copyWith(
          phase: newPhase,
          clearDropReason: true,
        );
      }
      // #1303 — phase transitions force an immediate snapshot so
      // a recovered crash lands on the right phase (the controller
      // moving from recording → pausedDueToDrop should NOT be lost
      // if the OS kills us before the next debounce window).
      unawaited(_flushActiveSnapshot(force: true));
    });
    state = state.copyWith(phase: TripRecordingPhase.recording);
  }

  /// Map the controller's enum onto the provider's phase. Stays a
  /// private helper so the provider's state model doesn't leak the
  /// raw enum to widgets that should keep consuming `TripRecordingPhase`.
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

  /// #767 — fire a short haptic when the band crosses *into* heavy
  /// territory. Positive improvements (normal → eco) stay silent so
  /// the vibration is a corrective nudge, not constant feedback.
  void _fireBandTransitionHaptic(
    ConsumptionBand previous,
    ConsumptionBand current,
  ) {
    switch (hapticForBandTransition(previous, current)) {
      case HapticIntensity.light:
        hapticLightCount++;
        HapticFeedback.lightImpact();
      case HapticIntensity.medium:
        hapticMediumCount++;
        HapticFeedback.mediumImpact();
      case HapticIntensity.none:
        break;
    }
  }

  /// Map a [FuelType] apiValue onto a [ConsumptionFuelFamily] for
  /// the cold-start tables. Everything that isn't diesel maps to
  /// gasoline — LPG/CNG calorific values are close enough to petrol
  /// that the cold-start number is within measurement noise.
  /// Read the active vehicle profile, swallowing any provider-wiring
  /// errors that show up in widget tests (where the Riverpod graph
  /// for the vehicle-active-profile chain isn't always overridden).
  /// Returns null — both a cold-start no-vehicle and an
  /// unavailable-provider state — which the caller handles by
  /// letting `readFuelRateLPerHour` fall back to its generic
  /// defaults.
  VehicleProfile? _tryReadActiveVehicle() {
    try {
      return ref.read(activeVehicleProfileProvider);
    } catch (e, st) {
      debugPrint('TripRecording: active vehicle unavailable: $e\n$st');
      return null;
    }
  }

  ConsumptionFuelFamily _resolveFuelFamily(String? apiValue) {
    if (apiValue == null) return ConsumptionFuelFamily.gasoline;
    if (apiValue.startsWith('diesel')) return ConsumptionFuelFamily.diesel;
    return ConsumptionFuelFamily.gasoline;
  }

  void _recordToStore(TripLiveReading r, DrivingSituation situation) {
    final store = _store;
    final vid = _vehicleId;
    if (store == null || vid == null) return;
    final baseline = coldStartBaseline(_fuelFamily, situation);
    final live = _liveConsumptionFor(r, baseline);
    if (live == null) return;
    store.record(
      vehicleId: vid,
      situation: situation,
      value: live,
    );
  }

  SituationBaseline _baselineFor(DrivingSituation situation) {
    final store = _store;
    final vid = _vehicleId;
    if (store == null || vid == null) {
      return coldStartBaseline(_fuelFamily, situation);
    }
    return store.lookup(
      vehicleId: vid,
      situation: situation,
      fuelFamily: _fuelFamily,
    );
  }

  DrivingSituation _classifyFrom(TripLiveReading r) {
    final cls = _classifier;
    if (cls == null) return DrivingSituation.idle;
    return cls.onSample(DrivingSample(
      timestamp: DateTime.now(),
      speedKmh: r.speedKmh ?? 0,
      rpm: r.rpm ?? 0,
      throttlePercent: r.engineLoadPercent, // close-enough proxy
      engineLoadPercent: r.engineLoadPercent,
      fuelRateLPerHour: r.fuelRateLPerHour,
    ));
  }

  ConsumptionBand _classifyBandFrom(
    TripLiveReading r,
    DrivingSituation situation,
  ) {
    final baseline = _baselineFor(situation);
    final live = _liveConsumptionFor(r, baseline);
    if (live == null) return ConsumptionBand.normal;
    return classifyBand(
      situation: situation,
      live: live,
      baseline: baseline,
    );
  }

  double? _computeDelta(
    TripLiveReading r,
    DrivingSituation situation,
  ) {
    final baseline = _baselineFor(situation);
    if (baseline.value <= 0) return null;
    final live = _liveConsumptionFor(r, baseline);
    if (live == null) return null;
    return (live - baseline.value) / baseline.value;
  }

  /// Compute the live consumption value in the baseline's unit —
  /// L/h for idle baselines, L/100 km otherwise. Returns null when
  /// the car isn't reporting enough data to derive the metric.
  double? _liveConsumptionFor(
    TripLiveReading r,
    SituationBaseline baseline,
  ) {
    final fuelRate = r.fuelRateLPerHour;
    final speed = r.speedKmh;
    if (fuelRate == null) return null;
    if (baseline.unit == BaselineUnit.lPerHour) return fuelRate;
    if (speed == null || speed <= 5) return null; // avoid /0
    return fuelRate * 100.0 / speed;
  }

  void pause() {
    final ctl = _controller;
    if (ctl == null || !state.isActive) return;
    ctl.pause();
    state = state.copyWith(phase: TripRecordingPhase.paused);
  }

  void resume() {
    final ctl = _controller;
    if (ctl == null) {
      // #1347 — cold-start recovery left us with a snapshot but no
      // controller. The pause banner's Resume button reaches us
      // here; without this path the tap is a silent no-op and the
      // captured samples are stranded in Hive forever. True "continue
      // recording" requires re-pairing the OBD2 adapter (out of scope
      // — see the #1347 follow-up issue); the minimum correct
      // behaviour is to finalise the snapshot into trip history so
      // the partial drive is preserved.
      if (_activeSnapshot != null &&
          state.phase == TripRecordingPhase.pausedDueToDrop) {
        unawaited(_finalizeRecoveredSnapshot());
      }
      return;
    }
    if (state.phase != TripRecordingPhase.paused &&
        state.phase != TripRecordingPhase.pausedDueToDrop) {
      return;
    }
    ctl.resume();
    state = state.copyWith(phase: TripRecordingPhase.recording);
  }

  /// Stop the polling loop, refresh the odometer one last time,
  /// release the service, and return the accumulated [TripSummary].
  /// Safe to call when no trip is active — returns a default empty
  /// summary so callers don't have to null-check.
  ///
  /// [automatic] flags the saved [TripHistoryEntry] as auto-recorded
  /// (#1004 phase 2a). Defaults to `false` so existing manual call
  /// sites keep their behaviour unchanged. The hands-free
  /// [AutoTripCoordinator] calls [stopAndSaveAutomatic] (the typed
  /// wrapper below) so the launcher-icon badge increments only when
  /// the coordinator was the one that decided to save.
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    final ctl = _controller;
    final svc = _service;
    if (ctl == null || svc == null) {
      // #1347 — cold-start recovery left us with a snapshot on disk
      // but no controller / service. The pause banner's End button
      // reaches us here; without this path the tap silently throws
      // away the captured samples (`StoppedTripResult.empty()` and a
      // zero-state reset). Salvage the snapshot into trip history so
      // the user keeps their partial drive.
      if (_activeSnapshot != null &&
          state.phase == TripRecordingPhase.pausedDueToDrop) {
        return _finalizeRecoveredSnapshot();
      }
      state = const TripRecordingState();
      return const StoppedTripResult.empty();
    }
    try {
      await ctl.refreshOdometer();
    } catch (e, st) {
      debugPrint('TripRecording.stop: refreshOdometer failed: $e\n$st');
    }
    // Snapshot the captured-samples buffer BEFORE stop() tears down
    // the controller — without this the trip-detail charts render the
    // "No samples recorded" empty state on every saved trip (#1040).
    final capturedSamples = List<TripSample>.unmodifiable(ctl.capturedSamples);
    final summary = await ctl.stop();
    final odometerStartKm = ctl.odometerStartKm;
    final odometerLatestKm = ctl.odometerLatestKm;
    await _liveSub?.cancel();
    _liveSub = null;
    await _stateSub?.cancel();
    _stateSub = null;
    // #1374 phase 1 — tear down the Geolocator subscription if one
    // was opened (flag-on path only). Best-effort: a null sub is the
    // common case (flag off) and a cancel that throws shouldn't
    // block trip teardown.
    await _gpsSub?.cancel();
    _gpsSub = null;
    _controller = null;
    // #726 — persist to the trip history rolling log. Every trip
    // (including discarded ones) is logged; the fill-up flow is a
    // *separate* decision. Best-effort: a Hive write failure here
    // shouldn't block service teardown.
    await _saveToHistory(
      summary,
      samples: capturedSamples,
      automatic: automatic,
    );
    // #769 — flush learned baselines before releasing the service so
    // the next trip starts from the updated values. Best-effort: a
    // Hive write failure here shouldn't block teardown.
    final store = _store;
    final vid = _vehicleId;
    if (store != null && vid != null) {
      try {
        await store.flush(vid);
      } catch (e, st) {
        debugPrint('TripRecording.stop: baseline flush failed: $e\n$st');
      }
      // #780 — fold in the server copy once the local flush lands.
      // `syncVehicleBaseline` returns the merged JSON; if the merge
      // changed anything, we rewrite Hive and reload so the next
      // trip sees the higher-confidence per-situation accumulators.
      // Entirely best-effort: offline, unauthenticated, or sync
      // errors all return the local payload unchanged.
      await _syncBaselineAfterFlush(vid);
    }
    _store = null;
    _vehicleId = null;
    // #1312 — clear the captured adapter identity once the trip has
    // been persisted; the next [start] call snapshots fresh values
    // from whichever service it receives.
    _adapterMac = null;
    _adapterName = null;
    _adapterFirmware = null;
    try {
      await svc.disconnect();
    } catch (e, st) {
      debugPrint('TripRecording.stop: service disconnect failed: $e\n$st');
    }
    _service = null;
    // #1303 — the trip is finalised in history; the active-trip
    // snapshot is no longer the source of truth and would lure the
    // recovery service into resurrecting a stopped trip on next
    // launch. Clear it. Best-effort.
    await _clearActiveSnapshot();
    state = state.copyWith(phase: TripRecordingPhase.finished);
    return StoppedTripResult(
      summary: summary,
      odometerStartKm: odometerStartKm,
      odometerLatestKm: odometerLatestKm,
    );
  }

  /// Typed entry point for the hands-free [AutoTripCoordinator]
  /// (#1004 phase 2a). Forwards to [stop] with `automatic: true` so
  /// the saved [TripHistoryEntry] is tagged as auto-recorded and the
  /// launcher-icon badge increments. Kept as a thin wrapper so the
  /// coordinator binds to a stable, no-arg `Future<void>` seam — the
  /// internal stop signature can grow more flags later without
  /// breaking the coordinator's call site.
  Future<void> stopAndSaveAutomatic() async {
    await stop(automatic: true);
  }

  /// Return to idle — used after the caller consumes the
  /// [StoppedTripResult] (saves as fill-up or discards).
  ///
  /// Keeps [lastTripVehicleId] / [lastTripStartedAt] intact so the
  /// subsequent fill-up save path can still resolve the link-window
  /// (#888) after the user lands back on the fill-up screen.
  void reset() {
    state = const TripRecordingState();
    // #1303 — also drop any stale snapshot. `reset` runs when the
    // user discards a stopped trip from the summary screen; without
    // this call the recovery service would re-surface the discarded
    // trip on next cold start.
    unawaited(_clearActiveSnapshot());
  }

  // ---------------------------------------------------------------------------
  // #1303 — write-through persistence helpers
  // ---------------------------------------------------------------------------

  /// Allow tests / wiring to inject a custom [ActiveTripRepository].
  /// Production never calls this — the box is resolved lazily from
  /// [HiveBoxes.obd2ActiveTrip].
  @visibleForTesting
  void debugSetActiveRepo(ActiveTripRepository repo) {
    _activeRepoOverride = repo;
  }

  /// Read the active-trip repo, returning null when the box isn't
  /// open (widget tests, fresh installs). The provider falls back to
  /// the in-memory snapshot only — recovery doesn't happen if
  /// there's no Hive to read from.
  ActiveTripRepository? _resolveActiveRepo() {
    final override = _activeRepoOverride;
    if (override != null) return override;
    if (!Hive.isBoxOpen(HiveBoxes.obd2ActiveTrip)) return null;
    try {
      return ActiveTripRepository(
        box: Hive.box<String>(HiveBoxes.obd2ActiveTrip),
      );
    } catch (e, st) {
      debugPrint('TripRecording active repo: $e\n$st');
      return null;
    }
  }

  /// Open a Geolocator position stream and route every fix through
  /// [TripRecordingController.updateGpsFix] (#1374 phase 1).
  ///
  /// No-op when [Feature.gpsTripPath] is disabled — that's the
  /// default for every existing user, so this method must NEVER pull
  /// on the Geolocator plugin in that case (zero battery cost). When
  /// the flag is on we open the stream at [LocationAccuracy.high]
  /// because the eventual heatmap (Phase 3) wants ~10 m precision;
  /// downgrading to medium / low is a Phase 2 follow-up if device
  /// testing flags battery as an issue.
  ///
  /// Stream errors are logged and swallowed: a permission revoke
  /// mid-trip, a temporary loss of fix, or the OS killing the
  /// position service must NOT derail the OBD2 trip recording. The
  /// controller's per-tick latch simply stops being refreshed and
  /// subsequent samples carry `latitude: null, longitude: null`.
  void _startGpsSubscriptionIfEnabled(TripRecordingController ctl) {
    final flags = ref.read(featureFlagsProvider.notifier);
    if (!flags.isEnabled(Feature.gpsTripPath)) return;
    final geolocator = ref.read(geolocatorWrapperProvider);
    try {
      _gpsSub = geolocator
          .getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      )
          .listen(
        (pos) => ctl.updateGpsFix(
          latitude: pos.latitude,
          longitude: pos.longitude,
        ),
        onError: (Object error) {
          debugPrint('TripRecording GPS stream error: $error');
        },
      );
    } catch (e, st) {
      debugPrint('TripRecording GPS subscribe failed: $e\n$st');
    }
  }

  /// Initialise [_activeSnapshot] from controller state immediately
  /// after [start] succeeds. The snapshot is kept null until then so
  /// the lifecycle-paused hook on a never-started provider is a no-op.
  void _seedActiveSnapshot() {
    final ctl = _controller;
    if (ctl == null) return;
    final id = ctl.sessionId ?? DateTime.now().toIso8601String();
    final startedAt = _lastTripStartedAt ?? DateTime.now();
    _activeSnapshot = ActiveTripSnapshot(
      id: id,
      vehicleId: _lastTripVehicleId ?? _vehicleId,
      vin: ctl.vin,
      automatic: false, // refined on every flush via _buildSnapshotFor
      phase: 'recording',
      summary: const TripSummary(
        distanceKm: 0,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
      ),
      samples: const [],
      odometerStartKm: ctl.odometerStartKm,
      odometerLatestKm: ctl.odometerLatestKm,
      startedAt: startedAt,
      lastFlushedAt: DateTime.now(),
    );
    _lastSnapshotFlushAt = null;
    _samplesSinceLastFlush = 0;
    // First-write seed so the recovery service has something on
    // disk even if the OS kills us before the first live sample
    // lands. Best-effort, fire-and-forget.
    unawaited(_flushActiveSnapshot(force: true));
  }

  /// Build a fresh snapshot from the controller's current state.
  /// Returns null when there's no controller (defensive).
  ActiveTripSnapshot? _buildSnapshotFor(TripRecordingController ctl) {
    final base = _activeSnapshot;
    if (base == null) return null;
    final phaseStr = _phaseStringFor(ctl);
    return base.copyWith(
      phase: phaseStr,
      summary: _summaryFromCtl(ctl),
      samples: ctl.capturedSamples,
      odometerStartKm: ctl.odometerStartKm,
      odometerLatestKm: ctl.odometerLatestKm,
      lastFlushedAt: DateTime.now(),
    );
  }

  /// Map the controller's enum to the string the snapshot
  /// serialises. Centralised so the recovery service doesn't have
  /// to translate enum names — both sides agree on the wire format.
  String _phaseStringFor(TripRecordingController ctl) {
    switch (ctl.currentState) {
      case TripRecordingControllerState.idle:
        return 'idle';
      case TripRecordingControllerState.recording:
        return 'recording';
      case TripRecordingControllerState.paused:
        return 'paused';
      case TripRecordingControllerState.pausedDueToDrop:
        return 'pausedDueToDrop';
      case TripRecordingControllerState.stopped:
        return 'stopped';
    }
  }

  /// Pull the recorder's running summary; lets the snapshot carry
  /// the latest distance / fuel / harsh counts without forcing the
  /// controller to expose more debug surface than [capturedSamples].
  TripSummary _summaryFromCtl(TripRecordingController ctl) {
    // capturedSamples is a List<TripSample>; the controller exposes
    // the running summary indirectly via stop()/buildSummary, but
    // there's no public mid-trip accessor. Rather than reach into
    // the controller's recorder we recompute distance + max RPM
    // from the captured buffer — it's already the post-debounce
    // 1 Hz feed and is plenty for the staleness / preview rendering
    // that recovery does. A perfect mid-trip summary (idle/harsh
    // counters) would require the controller to expose its own
    // recorder snapshot; we leave that for a future iteration if
    // recovery acquires a richer preview.
    final samples = ctl.capturedSamples;
    if (samples.isEmpty) {
      return const TripSummary(
        distanceKm: 0,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
      );
    }
    var distanceKm = 0.0;
    var maxRpm = 0.0;
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      if (s.rpm > maxRpm) maxRpm = s.rpm;
      if (i == 0) continue;
      final prev = samples[i - 1];
      final dtSec = s.timestamp
              .difference(prev.timestamp)
              .inMicroseconds /
          Duration.microsecondsPerSecond;
      if (dtSec <= 0) continue;
      final avgSpeed = (prev.speedKmh + s.speedKmh) / 2.0;
      distanceKm += avgSpeed * dtSec / 3600.0;
    }
    final startedAt = samples.first.timestamp;
    final endedAt = samples.last.timestamp;
    return TripSummary(
      distanceKm: distanceKm,
      maxRpm: maxRpm,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      startedAt: startedAt,
      endedAt: endedAt,
    );
  }

  /// Cheap gate called from the live-stream listener. Promotes to
  /// a real flush when either the time threshold or the sample
  /// threshold is crossed.
  void _maybeFlushActiveSnapshot() {
    _samplesSinceLastFlush++;
    final last = _lastSnapshotFlushAt;
    final now = DateTime.now();
    if (last != null) {
      final elapsed = now.difference(last);
      if (elapsed < _snapshotFlushInterval &&
          _samplesSinceLastFlush < _snapshotFlushSampleThreshold) {
        return;
      }
    }
    unawaited(_flushActiveSnapshot());
  }

  /// Persist the current snapshot. Always writes when called — the
  /// debounce gate lives upstream in [_maybeFlushActiveSnapshot]
  /// which decides whether to call this method. Forced callers
  /// (lifecycle backgrounded, phase transition, seed) skip the gate
  /// and invoke this directly so they can't lose the next interval.
  Future<void> _flushActiveSnapshot({bool force = false}) async {
    // `force` is kept on the signature for self-documenting call
    // sites (`_flushActiveSnapshot(force: true)` reads as "I do not
    // want this skipped"). The semantics are unconditional today;
    // earlier drafts had an internal gate here too which double-
    // counted with [_maybeFlushActiveSnapshot]. Keeping the param
    // makes the intent at the call site obvious without changing
    // behaviour.
    if (!force && _controller == null) return;
    final ctl = _controller;
    if (ctl == null) return;
    final repo = _resolveActiveRepo();
    if (repo == null) return;
    final next = _buildSnapshotFor(ctl);
    if (next == null) return;
    _activeSnapshot = next;
    _lastSnapshotFlushAt = next.lastFlushedAt;
    _samplesSinceLastFlush = 0;
    try {
      await repo.saveSnapshot(next);
    } catch (e, st) {
      debugPrint('TripRecording flush snapshot failed: $e\n$st');
    }
  }

  /// #1347 — finalise the recovered active-trip snapshot into trip
  /// history when the user taps Resume / End on the pause banner
  /// after a cold-start recovery. The controller is null in this
  /// state (`restoreFromSnapshot` deliberately leaves it that way),
  /// so [stop] cannot run its normal teardown; this helper writes
  /// the snapshot's captured samples + summary into the rolling
  /// trip-history log instead, clears the snapshot from Hive, and
  /// transitions state to `finished` so the recording screen renders
  /// the summary view.
  ///
  /// True "continue recording" — re-pair the adapter, reattach a
  /// controller carrying the snapshot's session id + prior samples,
  /// and resume polling — is intentionally out of scope here. See the
  /// #1347 follow-up issue. The salvage path's only job is to make
  /// sure the partial drive isn't silently lost.
  Future<StoppedTripResult> _finalizeRecoveredSnapshot() async {
    final snapshot = _activeSnapshot;
    if (snapshot == null) {
      state = const TripRecordingState();
      return const StoppedTripResult.empty();
    }
    // Resolve every Riverpod-backed dependency synchronously up
    // front. Reading `ref` after an `await` is unsafe — the provider
    // could be disposed by then (rare in production thanks to
    // `keepAlive: true`, frequent in tests where the container goes
    // out of scope before the unawaited future settles).
    TripHistoryRepository? historyRepo;
    TripHistoryList? historyList;
    Future<AutoRecordBadgeService>? badgeFuture;
    try {
      historyRepo = ref.read(tripHistoryRepositoryProvider);
    } catch (e, st) {
      debugPrint(
          'TripRecording recovered finalise: history repo read failed: $e\n$st');
    }
    try {
      historyList = ref.read(tripHistoryListProvider.notifier);
    } catch (e, st) {
      debugPrint(
          'TripRecording recovered finalise: history list read failed: $e\n$st');
    }
    if (snapshot.automatic) {
      try {
        badgeFuture = ref.read(autoRecordBadgeServiceProvider.future);
      } catch (e, st) {
        debugPrint(
            'TripRecording recovered finalise: badge service read failed: $e\n$st');
      }
    }

    final result = StoppedTripResult(
      summary: snapshot.summary,
      odometerStartKm: snapshot.odometerStartKm,
      odometerLatestKm: snapshot.odometerLatestKm,
    );
    // Transition state synchronously so the recording screen flips to
    // the summary view immediately — even if the Hive writes below
    // race against provider disposal in a test harness.
    state = state.copyWith(phase: TripRecordingPhase.finished);

    if (historyRepo != null) {
      try {
        await historyRepo.save(TripHistoryEntry(
          id: snapshot.id,
          vehicleId: snapshot.vehicleId,
          summary: snapshot.summary,
          automatic: snapshot.automatic,
          samples: snapshot.samples,
        ));
      } catch (e, st) {
        debugPrint(
            'TripRecording recovered finalise: save failed: $e\n$st');
      }
    }

    // Clear the snapshot BEFORE the best-effort observer-refresh and
    // badge bump below — the recovery service must not resurrect a
    // finalised trip on next launch even if those follow-up steps
    // throw or race against provider disposal in a test harness.
    await _clearActiveSnapshot();

    try {
      historyList?.refresh();
    } catch (e, st) {
      debugPrint(
          'TripRecording recovered finalise: list refresh failed: $e\n$st');
    }

    // Mirror the auto-record badge bookkeeping the regular
    // `_saveToHistory` path applies — a recovered auto-trip is still
    // an "unseen" trip the user should see in the launcher.
    if (badgeFuture != null) {
      try {
        final badge = await badgeFuture;
        await badge.increment();
      } catch (e, st) {
        debugPrint(
            'TripRecording recovered finalise: badge bump failed: $e\n$st');
      }
    }

    return result;
  }

  /// Drop the persisted snapshot + clear in-memory bookkeeping.
  /// Safe to call when nothing was ever written.
  Future<void> _clearActiveSnapshot() async {
    _activeSnapshot = null;
    _lastSnapshotFlushAt = null;
    _samplesSinceLastFlush = 0;
    final repo = _resolveActiveRepo();
    if (repo == null) return;
    try {
      await repo.clearSnapshot();
    } catch (e, st) {
      debugPrint('TripRecording clear snapshot failed: $e\n$st');
    }
  }

  /// Lifecycle hook entry point — called by the wiring layer's
  /// [WidgetsBindingObserver] when the host app transitions into
  /// the background. We force-flush so the latest sample buffer
  /// is on disk before the OS has a chance to kill us.
  ///
  /// No-op when no trip is active (the snapshot is null) so the
  /// hook is safe to fire on every backgrounding regardless of
  /// recording state.
  Future<void> onAppBackgrounded() async {
    if (_controller == null) return;
    if (!state.isActive) return;
    await _flushActiveSnapshot(force: true);
  }

  /// Surface the recovered snapshot from a previous cold-start
  /// recovery walk. Phase 2 of #1303: hands the user back into a
  /// `pausedDueToDrop`-shaped state with their captured samples
  /// preserved and exposed as `state.live.distanceKmSoFar` so the
  /// recording screen renders something meaningful.
  ///
  /// Does NOT auto-reconnect OBD2 — that's the existing reconnect
  /// scanner's job. The user manually resumes after they're back
  /// in the recording UI; that path picks up from a fresh BT
  /// connect through the regular adapter picker.
  ///
  /// Returns true when the snapshot was applied, false when the
  /// provider was already mid-trip (a fresh launch that started a
  /// trip before recovery ran — extremely unlikely but defensive).
  bool restoreFromSnapshot(ActiveTripSnapshot snapshot) {
    if (state.isActive) return false;
    _activeSnapshot = snapshot;
    _lastTripVehicleId = snapshot.vehicleId;
    _lastTripStartedAt = snapshot.startedAt;
    state = state.copyWith(
      phase: TripRecordingPhase.pausedDueToDrop,
    );
    return true;
  }

  /// #780 — merge local + server baselines for [vehicleId] via the
  /// sync service. Called after the Hive flush so the payload on
  /// disk is what actually gets sent, and the merged result (higher
  /// per-situation sample counts) overwrites disk for the next
  /// trip. No-op when the Hive box is closed or the sync client
  /// is offline/unauthenticated — both paths return the input
  /// payload unchanged.
  Future<void> _syncBaselineAfterFlush(String vehicleId) async {
    try {
      // #780 phase 3 — honour the opt-in setting. Default false so
      // users who never toggled it in the sync setup screen don't
      // silently upload driving data. Ungated favourite sync etc.
      // are unaffected.
      final settings = ref.read(settingsStorageProvider);
      final enabled = settings.getSetting(
            StorageKeys.syncBaselinesEnabled,
          ) ==
          true;
      if (!enabled) return;
      if (!Hive.isBoxOpen(HiveBoxes.obd2Baselines)) return;
      final box = Hive.box<String>(HiveBoxes.obd2Baselines);
      final key = 'baseline:$vehicleId';
      final localJson = box.get(key);
      final merged = await BaselinesSync.merge(
        vehicleId: vehicleId,
        localJson: localJson,
      );
      if (merged != null && merged != localJson) {
        await box.put(key, merged);
        // No in-memory cache refresh needed — _store is nulled out
        // right after this call and the next trip creates a fresh
        // BaselineStore whose loadVehicle reads the merged JSON
        // from disk.
      }
    } catch (e, st) {
      debugPrint('TripRecording.stop: baseline sync failed: $e\n$st');
    }
  }

  /// Build the reconnect-scanner factory handed to
  /// [TripRecordingController] (#797 phase 3). The returned closure
  /// is called once per drop with the pinned MAC + an onReconnect
  /// hook; it wires the scanner's probe and connect callbacks to
  /// the already-provided [Obd2ConnectionService].
  ///
  /// Returns null in tests / environments where [obd2ConnectionProvider]
  /// can't be resolved — in that case the controller falls back to
  /// the grace-window-only recovery.
  AdapterReconnectScanner? Function(
    String pinnedMac,
    VoidCallback onReconnect,
  )? _buildReconnectScannerFactory() {
    final Obd2ConnectionService connection;
    try {
      connection = ref.read(obd2ConnectionProvider);
    } catch (e, st) {
      debugPrint('TripRecording: connection provider unavailable: $e\n$st');
      return null;
    }
    return (pinnedMac, onReconnect) {
      ResolvedObd2Candidate? lastCandidate;
      return AdapterReconnectScanner(
        pinnedMac: pinnedMac,
        probe: (mac) async {
          try {
            // One scan window per probe — the service closes it at
            // its built-in timeout. We take the first batch that
            // contains the pinned MAC and short-circuit.
            await for (final batch in connection.scan()) {
              for (final c in batch) {
                if (c.candidate.deviceId == mac) {
                  lastCandidate = c;
                  return true;
                }
              }
            }
          } catch (e, st) {
            debugPrint('TripRecording reconnect probe failed: $e\n$st');
          }
          return false;
        },
        connect: (mac) async {
          final candidate = lastCandidate;
          if (candidate == null) return false;
          try {
            final svc = await connection.connect(candidate);
            // Swap the controller's owned service pointer and
            // hand ownership of the old (dead) service over to
            // GC. The controller's scheduler will re-prime
            // against the new transport on the next tick.
            _service = svc;
            return true;
          } catch (e, st) {
            debugPrint('TripRecording reconnect connect failed: $e\n$st');
            return false;
          }
        },
        onReconnect: onReconnect,
      );
    };
  }

  Future<void> _saveToHistory(
    TripSummary summary, {
    bool automatic = false,
    List<TripSample> samples = const [],
  }) async {
    // Skip empty trips — the user tapped Stop without any usable
    // sample, or the service disconnected immediately. No signal, no
    // history clutter.
    if (summary.distanceKm < 0.01 && summary.startedAt == null) return;
    try {
      final repo = ref.read(tripHistoryRepositoryProvider);
      if (repo == null) return;
      final id = summary.startedAt?.toIso8601String() ??
          DateTime.now().toIso8601String();
      await repo.save(TripHistoryEntry(
        id: id,
        vehicleId: _vehicleId,
        summary: summary,
        automatic: automatic,
        samples: samples,
        // #1312 — adapter identity snapshotted at [start] time. Null
        // for legacy / fake-service code paths; the detail card hides
        // the row entirely in that case.
        adapterMac: _adapterMac,
        adapterName: _adapterName,
        adapterFirmware: _adapterFirmware,
      ));
      ref.read(tripHistoryListProvider.notifier).refresh();
      // Phase 5 (#1004): bump the launcher-icon badge so the user sees
      // "something happened while I was driving" without opening the
      // app. The decrement fires when the user lands on the trip
      // detail screen for this auto-recorded trip.
      if (automatic) {
        try {
          final badge = await ref.read(autoRecordBadgeServiceProvider.future);
          await badge.increment();
        } catch (e, st) {
          debugPrint('TripRecording auto-record badge increment: $e\n$st');
        }
      }
    } catch (e, st) {
      debugPrint('TripRecording._saveToHistory: $e\n$st');
    }
  }
}

/// Returned by [TripRecording.stop]. Bundles the summary with the
/// raw odometer reads so the save-as-fill-up flow can pre-fill the
/// form.
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
