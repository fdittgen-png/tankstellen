// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_controller.dart';

/// Telemetry-ingest seams + trip-identity reads for
/// [TripRecordingController], extracted from the controller file as a
/// `part` mixin so they keep private-member access while the controller
/// stays under the #1680 file-length cap (sanctioned #3760 decomposition
/// — move-only, behaviour preserved): the provider-facing GPS / OEM-fuel
/// push seams, the cadence-diagnostic append, and the odometer / VIN /
/// session-id / distance getters.
mixin _TripRecordingTelemetryIngest on _TripRecordingSessionState {
  /// Push the most recent GPS fix into the per-tick snapshot
  /// (#1374 phase 1).
  ///
  /// Called by the trip-recording provider when the
  /// `Feature.gpsTripPath` flag is enabled and a Geolocator position
  /// stream has produced an update. The next [_emit] tick stamps the
  /// stored values onto the [TripSample] it builds. Pass `null` for
  /// either coord to clear the latch — the sample is then written
  /// with that field omitted (legacy-compatible behaviour).
  ///
  /// Intentionally takes raw doubles instead of a `Position` so this
  /// file stays free of `package:geolocator` imports — the GPS plugin
  /// only lives at the provider seam, which keeps unit-testing the
  /// controller cheap (no Geolocator mocks required) and lets the
  /// flag-off path skip the plugin entirely. [fixAt] is the fix's own
  /// timestamp (#3253); null falls back to the arrival clock.
  void updateGpsFix({
    double? latitude,
    double? longitude,
    double? altitudeM,
    double? hAccuracyM,
    double? bearingDeg,
    double? speedKmh,
    DateTime? fixAt,
  }) {
    _liveSampleSnapshot.updateGpsFix(
      latitude: latitude,
      longitude: longitude,
      altitudeM: altitudeM,
      // #2648 — forward GPS horizontal accuracy + bearing so the next
      // emit stamps them onto the TripSample. The OBD2 / degraded paths
      // used to drop these (the `Position` carried them but they were
      // never threaded through), so they reached only 0.3 % of samples.
      hAccuracyM: hAccuracyM,
      bearingDeg: bearingDeg,
    );
    // #2506 — latch the GPS ground-speed for the live speed fallback. A
    // null / non-finite / negative speed (cold GPS warm-up) is ignored so
    // the latch never regresses to a bogus value. Stored on the controller
    // (not the off-limits live snapshot) so the OBD2 speed PID 0x0D, when
    // present, always wins in [_emit]; this only fills the gap.
    if (speedKmh != null && speedKmh.isFinite && speedKmh >= 0) {
      _latestGpsSpeedKmh = speedKmh;
    }
    // #1979 — buffer every real fix for the GPS-distance source. A
    // null-coord call only clears the per-tick latch; it is not a fix.
    if (latitude != null && longitude != null) {
      // #2509 — latch the first GPS-fix timestamp as a start-time
      // fallback. On a dead OBD2 link no speed/RPM sample ever reaches
      // the recorder, so `_recorder` never stamps `startedAt`; without
      // this the finalised summary's `startedAt` is null and the
      // persist guard discards a real GPS-tracked drive. Only the FIRST
      // fix wins so the start time is the start of the drive, not the
      // latest fix. A healthy OBD2 trip ignores this value (the recorder
      // owns `startedAt`); it is consulted only as a fallback in
      // [_finaliseSummary].
      // #2963 — forward the fix's accuracy + timestamp so the haversine
      // distance source can reject a parked car's GPS jitter (accuracy gate)
      // and a cold-start position jump (teleport gate). Dropped here before,
      // so a 22 s idle scatter at σ≈25 m accumulated ~0.93 phantom km.
      // #3253 — fix time, not arrival: a batched burst blinds the Δt gates.
      final at = fixAt ?? _now();
      _distance.addGpsFix(
        latitude,
        longitude,
        hAccuracyM: hAccuracyM,
        at: at,
      );
      _gpsStartedAt ??= at;
      _gpsEndedAt = at;
    }
  }

  /// #1615 — push the most recent exact-litre OEM-PID fuel reading into
  /// the live snapshot. The next [_emit] tick reads it back onto
  /// [TripLiveReading.fuelLevelLitres]. Pass `null` to clear the latch.
  ///
  /// Like [updateGpsFix], this is the provider seam: the OEM read (a
  /// multi-command async sequence against `OemPidRegistry`) lives in
  /// `TripOemFuelLevelController` at the provider layer, so this file
  /// stays free of feature-flag and registry imports and the flag-off
  /// path never constructs an OEM read.
  void updateOemFuelLevelLitres(double? litres) {
    _liveSampleSnapshot.updateOemFuelLevelLitres(litres);
  }

  /// #1458 phase 2 — append one cadence-diagnostic record at [now]
  /// with the given app [lifecycleState]. The provider calls this from
  /// its position-stream listener immediately AFTER [updateGpsFix] so
  /// the two streams stay aligned: the user-facing
  /// [TripSample.latitude]/[TripSample.longitude] capture path is
  /// unchanged, and the diagnostic is a strictly additive observation
  /// of "did this fix arrive while the app was foreground or paused".
  ///
  /// The index assigned to the diagnostic is the buffer's length at
  /// insertion time so it is monotonic per trip and stable across
  /// process restarts (a forgotten recording that bumps into
  /// [_gpsSampleDiagnosticCap] drops the OLDEST samples first — the
  /// `index` field surfaces those gaps).
  void recordGpsSampleDiagnostic({
    required DateTime now,
    required String lifecycleState,
    DateTime? fixAt,
  }) {
    _sampleBuffer.recordGpsSampleDiagnostic(
      now: now,
      lifecycleState: lifecycleState,
      fixAt: fixAt, // #3785
    );
  }

  /// Exposed for tests: append a cadence diagnostic without going
  /// through [recordGpsSampleDiagnostic]. Lets the provider tests
  /// pre-seed a controller's buffer + drive [stop] end-to-end without
  /// needing a real Geolocator stream.
  @visibleForTesting
  void debugCaptureGpsSampleDiagnostic(GpsSampleDiagnostic diagnostic) {
    _sampleBuffer.debugCaptureGpsSampleDiagnostic(diagnostic);
  }

  /// Read-only snapshot of the most recent GPS latitude pushed in via
  /// [updateGpsFix] (#1374 phase 1). Exposed for tests + diagnostics;
  /// production reads the value through the persisted [TripSample]
  /// fields, not this getter.
  @visibleForTesting
  double? get debugLatestLatitude => _liveSampleSnapshot.latestLatitude;

  /// Read-only snapshot of the most recent GPS longitude pushed in via
  /// [updateGpsFix] (#1374 phase 1). Same caveats as
  /// [debugLatestLatitude].
  @visibleForTesting
  double? get debugLatestLongitude => _liveSampleSnapshot.latestLongitude;

  /// Read-only snapshot of the most recent GPS altitude (metres) pushed
  /// in via [updateGpsFix] (#1935 child A). Same caveats as
  /// [debugLatestLatitude].
  @visibleForTesting
  double? get debugLatestAltitudeM => _liveSampleSnapshot.latestAltitudeM;

  /// Read-only snapshots of the most recent GPS horizontal accuracy
  /// (metres) + bearing (compass degrees) pushed in via [updateGpsFix]
  /// (#2648). Same caveats as [debugLatestLatitude].
  @visibleForTesting
  double? get debugLatestHAccuracyM => _liveSampleSnapshot.latestHAccuracyM;
  @visibleForTesting
  double? get debugLatestBearingDeg => _liveSampleSnapshot.latestBearingDeg;

  /// Odometer reading at trip start. Null when the adapter can't
  /// read the odometer (no PID A6, no PID 31 fallback, unknown
  /// manufacturer). Exposed so the save-as-fill-up flow can pre-fill
  /// the "odometer" field with the END km — which is start + the
  /// recorder's accumulated distance.
  double? get odometerStartKm => _odometerStartKm;

  /// Latest odometer reading read during the trip. Returns null
  /// until the first successful odometer poll. The recording UI
  /// doesn't poll the odometer every tick (it's an expensive Mode
  /// 22 query on some cars) — just once at start and once near the
  /// end via [refreshOdometer].
  double? get odometerLatestKm => _odometerLatestKm;

  /// VIN read once at [start]. Null on older ECUs / adapters that
  /// can't answer Mode 09 PID 02. Exposed so the fill-up screen can
  /// stamp the trip with a vehicle identity independent of the
  /// user's selected profile.
  String? get vin => _vin;

  /// Stable session id (ISO start timestamp). Matches the primary
  /// key used by [TripHistoryEntry] and [PausedTripEntry] so a
  /// paused → finalised transition keeps the row together. Null
  /// before [start] runs.
  String? get sessionId => _sessionId;

  /// Refresh the odometer reading. Call this just before [stop] so
  /// the save-as-fill-up gets a ground-truth end km rather than a
  /// derived value.
  Future<void> refreshOdometer() async {
    _odometerRefreshAt = _now();
    final km = await _service.readOdometerKm();
    if (km == null) return;
    _odometerLatestKm = km;
    // #3877 — remember WHEN and at WHICH trip distance, so a stop that
    // happens after this reading can add the distance driven since.
    _odometerLatestAt = _now();
    _distanceKmAtOdometerLatest = currentDistanceKm;
  }

  /// #3877 — instant of the latest successful odometer reading.
  DateTime? get odometerLatestAt => _odometerLatestAt;

  /// #3877 — trip distance at the latest reading (see [refreshOdometer]).
  double? get distanceKmAtOdometerLatest => _distanceKmAtOdometerLatest;

  /// #3877 — the best current odometer: the latest reading plus the
  /// distance driven since it; null when the car never answered.
  double? get estimatedOdometerNowKm {
    final latest = _odometerLatestKm;
    if (latest == null) return null;
    final since = currentDistanceKm -
        (_distanceKmAtOdometerLatest ?? currentDistanceKm);
    return latest + (since > 0 ? since : 0);
  }

  /// Distance covered by the current trip so far (#800).
  ///
  /// Resolution order (#800 / #1979):
  ///   1. the ground-truth `odometerLatest - odometerStart` when both
  ///      readings are present AND moved forward by more than a
  ///      noise-floor epsilon (odometer PIDs are quantised to 0.1 km
  ///      on most cars — a 0.09-km delta is a sensor artefact);
  ///   2. the haversine-summed GPS track, when a usable one was
  ///      recorded — true road distance, free of the speed sensor's
  ///      over-read;
  ///   3. the trapezoidal integral of buffered speed samples via
  ///      [VirtualOdometer], when the car exposes no odometer
  ///      (Peugeot 107 class) and no GPS track was captured.
  double get currentDistanceKm => _distance.distanceKm(
        odometerStartKm: _odometerStartKm,
        odometerLatestKm: _odometerLatestKm,
      );

  /// `'real'` when [currentDistanceKm] came from the car's odometer,
  /// `'gps'` when it came from the haversine-summed GPS track (#1979),
  /// `'virtual'` when it came from [VirtualOdometer] integration
  /// (#800). Persisted on the finalised [TripSummary] so the fill-up
  /// flow and eco-analytics know whether to treat the km as a ground
  /// truth or as an estimate.
  String get distanceSource => _distance.distanceSource(
        odometerStartKm: _odometerStartKm,
        odometerLatestKm: _odometerLatestKm,
      );

  /// Number of GPS fixes buffered for the distance resolver this trip
  /// (#2509). Surfaced so the save path can distinguish a genuinely
  /// stationary trip (no movement AND no fixes → discard, #1923) from a
  /// real GPS-tracked drive whose OBD2 link was dead (fixes present →
  /// persist). Delegates to [TripDistanceResolver.gpsFixCount].
  int get gpsFixCount => _distance.gpsFixCount;

  /// Append a speed sample to the virtual-odometer buffer, dropping
  /// the oldest entry when the cap is hit. Called from the 5 Hz
  /// vehicle-speed subscription. Delegates to [TripDistanceResolver]
  /// which owns the buffer (#2187).
  void _recordSpeedSample(double speedKmh) =>
      _distance.addSpeedSample(speedKmh);
}
