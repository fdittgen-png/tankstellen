// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_controller.dart';

/// The debounced emit tick for [TripRecordingController], extracted
/// from the controller file as a `part` mixin so it keeps
/// private-member access while the controller stays under the #1680
/// file-length cap (sanctioned #3760 decomposition — move-only,
/// behaviour preserved): [_emit] (the per-tick TripSample build +
/// TripLiveReading publish), the shared #2506 GPS-estimate overlay, and
/// the #2565 degraded GPS-only tick delegation.
mixin _TripRecordingEmit
    on _TripRecordingTelemetryIngest, _TripRecordingTransportGuard {
  /// Minimum wall-clock spacing between diagnostic-capture raw-input
  /// stamps (#2459). The fuel-derivation signals drift slowly, so a
  /// ~1 Hz sample is ample for post-hoc re-derivation and keeps the
  /// extra payload roughly 1/4 the per-tick emit cadence. Timestamp of
  /// the last stamp is tracked in [_lastDiagnosticCaptureAt].
  static const Duration _diagnosticCaptureInterval = Duration(seconds: 1);
  DateTime? _lastDiagnosticCaptureAt;

  /// Oldest a high-priority engine parse may be before the snapshot is
  /// treated as a ghost. Generous vs the 5 Hz dynamics tier and the
  /// K-line's ~4-6 reads/s: even a struggling ISO 9141 link refreshes
  /// rpm every ~1-2 s.
  static const Duration _engineDataStalenessLimit = Duration(seconds: 15);

  /// Grace after recording start before the fence may fire — the first
  /// connect + scheduler spin-up takes a few seconds legitimately.
  static const Duration _engineDataStartGrace = Duration(seconds: 30);

  /// Called by the debounced emit timer. Snapshots current state into
  /// a [TripLiveReading], integrates any new fuel/distance since the
  /// last emit, and pushes to [live].
  void _emit() {
    // Don't emit/integrate while paused, while a drop is on the pause
    // banner, OR during the #1904 silent-reconnect window (#1912): the
    // scheduler is stopped then, so the snapshot is stale — feeding it
    // to the recorder would integrate phantom distance/fuel from a
    // frozen speed over real elapsed time.
    if (_paused || _pausedDueToDrop || _droppedSession.silentlyReconnecting) {
      return;
    }
    if (_liveController.isClosed) return;
    // #2565 — `degradedGpsOnly` is NOT gated above: OBD2 is gone (the PID
    // snapshot is stale) but GPS is alive, so build a GPS-only sample +
    // run the estimate overlay instead of freezing.
    if (_degradedGpsOnly) {
      _emitDegradedGpsOnly();
      return;
    }

    final snap = _liveSampleSnapshot;
    final nowTs = _now();

    // #3602 — staleness fence: never stamp snapshot engine values without
    // a recent successful parse backing them. A link that never opened
    // (or died without a transport error) leaves the scheduler at 0 Hz;
    // the null-parse detector is starved blind, and 49 min of a real
    // field drive got ghost engine data (rpm 0, resting throttle) stamped
    // onto every GPS fix — classified 'full OBD2, measured fuel'.
    // Escalate ONCE through the same silent-failure drop path (pause with
    // grace → reconnect → #2565 GPS-only degrade), and skip this tick so
    // nothing stale reaches the recorder.
    final fresh = _lastFreshEngineParseAt;
    final started = _startedAt;
    final pastGrace = started == null ||
        nowTs.difference(started) > _engineDataStartGrace;
    // #3783 — the fence holds while the reconnect grace / protocol work
    // is active: the quiet-window `0100` search legitimately produces no
    // parses for up to ~17 s, and the fence firing mid-search tore down
    // the very link the recovery was bringing up (the 2026-08-25
    // dial-storm spiral).
    final engineStale = pastGrace &&
        !_inReconnectGrace &&
        !_protocolWorkInFlight &&
        (fresh == null ||
            nowTs.difference(fresh) > _engineDataStalenessLimit);
    if (engineStale) {
      if (!_staleEngineEscalated) {
        _staleEngineEscalated = true;
        debugPrint(
          'TripRecordingController: engine data stale '
          '(lastParse=$fresh) — escalating as silent failure (#3602)',
        );
        _onSilentFailure();
      }
      return;
    }
    final fuelRate = snap.deriveFuelRateLPerHour();
    // #1858 — fold this tick into the trip's η_v recompute provenance.
    // Speed-density fuel is the only η_v-derived branch; PID 5E / MAF
    // fuel marks the trip non-recalculable.
    if (fuelRate != null && fuelRate > 0) {
      final veUsed = snap.lastFuelRateBranch == Obd2BranchTag.speedDensity
          ? snap.lastFuelRateVe
          : null;
      if (veUsed != null && veUsed > 0) {
        _veWeightedFuelSum += veUsed * fuelRate;
        _veDerivedFuelRateSum += fuelRate;
      } else {
        _sawNonVeDerivedFuel = true;
      }
    }
    final speedKmh = snap.latestSpeedKmh;
    final rpm = snap.latestRpm;
    final throttlePercent = snap.latestThrottlePercent;
    final engineLoadPercent = snap.latestEngineLoadPercent;
    final coolantTempC = snap.latestCoolantTempC;
    // #2459 — should this tick ALSO carry the diagnostic-capture raw
    // mixture inputs? Only when the per-trip flag is on AND we're past
    // the slow-cadence interval since the last stamp; otherwise the four
    // raw keys stay null (carried-forward = simply not re-written) so the
    // payload doesn't balloon at the 4 Hz emit rate.
    final captureRaw = _diagnosticCapture &&
        (_lastDiagnosticCaptureAt == null ||
            nowTs.difference(_lastDiagnosticCaptureAt!) >=
                _diagnosticCaptureInterval);
    if (captureRaw) _lastDiagnosticCaptureAt = nowTs;
    // The recorder integrates fuel rate and Δt itself, so we only
    // hand it one TripSample per emit — not per PID callback. At a
    // 250 ms emit cadence that's 4 Hz into the recorder, matching
    // the pre-#814 1 Hz loop's behavior closely enough that the
    // distance/fuelLitersConsumed integration is unchanged.
    // #2963 — never persist `speedKmh ?? 0`. A fabricated leading `0`
    // (RPM PID 0x0C acquired before the speed PID 0x0D parses), followed by
    // the car's actual non-zero speed once 0x0D answers, manufactures a
    // `0 → real` step the accel gate scores as a phantom hard-accel (a 22 s
    // idle OBD2 trip surfaced `hardAccelPenalty = 3.0`). Guard:
    //   1. Until the FIRST real speed lands, an RPM-only tick has no usable
    //      speed (idle needs `speed≤0.5`, accel needs the derivative), so
    //      skip persisting it rather than invent a `0`. A measured idle
    //      (`41 0D 00`) is a real `0` and starts the series cleanly.
    //   2. After that, hold-last for a later RPM-only tick (defence-in-depth;
    //      the live snapshot already holds-last).
    final hasEverReadSpeed = speedKmh != null || _lastPersistedSpeedKmh != null;
    if ((speedKmh != null || rpm != null) && hasEverReadSpeed) {
      final persistedSpeedKmh = speedKmh ?? _lastPersistedSpeedKmh!;
      if (speedKmh != null) _lastPersistedSpeedKmh = speedKmh;
      final sample = TripSample(
        timestamp: nowTs,
        speedKmh: persistedSpeedKmh,
        rpm: rpm, // #2692 C4-G — keep null (gate above still admits on speed).
        fuelRateLPerHour: fuelRate,
        throttlePercent: throttlePercent,
        engineLoadPercent: engineLoadPercent,
        coolantTempC: coolantTempC,
        // #1374 phase 1 — stamp the most recent GPS fix when the
        // provider has pushed one in. The fields stay null when the
        // feature flag is off (no Geolocator subscription was ever
        // started) or before the first fix lands. Altitude added in
        // #1935 child A for the road-grade calculator.
        latitude: snap.latestLatitude,
        longitude: snap.latestLongitude,
        altitudeM: snap.latestAltitudeM,
        // #2648 — GPS horizontal accuracy + bearing. Both already
        // round-trip through the codec ('ha' / 'be') and TripSample has
        // had the fields; the OBD2 path simply dropped them. Stamping
        // them here revives the cornering analytic (bearing) and the
        // harsh-event accuracy-gate. Null when no GPS fix has landed.
        hAccuracyM: snap.latestHAccuracyM,
        bearingDeg: snap.latestBearingDeg,
        // #2459 — the consumed-but-previously-unstored signals, stamped
        // from the snapshot latest-value getters exactly like throttle.
        // Each stays null on cars that don't expose the PID, so the
        // compact-key serialization writes zero bytes for them.
        lambda: snap.latestCommandedPhi,
        baroKpa: snap.latestBaroKpa,
        absLoadPercent: snap.latestAbsLoadPercent,
        pedalPercent: snap.latestPedalPercent,
        oilTempC: snap.latestOilTempC,
        ambientTempC: snap.latestAmbientTempC,
        // #3427 / #3429 / #3433 — the precision signals + the fuel-source
        // provenance of THIS tick's derived rate (which branch produced
        // it), so the driving-analysis export can report measured-φ /
        // ethanol coverage and the branch that dominated the trip. The
        // provenance is only stamped alongside an actual rate.
        measuredPhi: snap.latestMeasuredPhi,
        ethanolPercent: snap.latestEthanolPercent,
        fuelSource: fuelRate == null ? null : snap.lastFuelRateSource?.name,
        // #2459 — diagnostic-capture raw mixture inputs, only on the
        // slow-cadence ticks while the flag is on (else null = not
        // written). Each is independently null-safe per PID support.
        mafGramsPerSecond: captureRaw ? snap.latestMaf : null,
        // #3692 — MAP is ALWAYS persisted now (no longer only under the
        // diagnostic flag): with baro it yields boost (MAP − baro), the
        // turbo signal the consumption record was missing. Slow-cadence
        // hold-last values, compact-key null-skipped — storage stays
        // negligible on cars without the PID.
        mapKpa: snap.latestMapKpa,
        stft: captureRaw ? snap.latestStft : null,
        ltft: captureRaw ? snap.latestLtft : null,
        // #3692 — IAT (polled since #2505, now persisted) + timing
        // advance: charge temperature and knock retard both move
        // consumption on a boosted engine.
        iatC: snap.latestIatCelsius,
        timingAdvanceDeg: snap.latestTimingAdvanceDeg,
      );
      // #2653 — thread the live distance provenance so the detector
      // suppresses harsh scoring on the `virtual` dead-reckoning source.
      _recorder.onSample(sample, distanceSource: distanceSource);
      _lastSampleAt = nowTs;
      // #1925 — ping the opt-in debug recorder so a stretch of silence
      // surfaces as a data-gap event in the exported session log.
      // #1930 — pass the vehicle state so a gap records what the car
      // was doing when data stopped (driving vs engine-off).
      Obd2DebugSessionRecorder.recordData(nowTs, speedKmh: speedKmh, rpm: rpm);
      _sampleBuffer.maybeCapture(sample);
    }
    // #2304 — build the integrated summary once per tick and reuse it for
    // the fuel-litres and distance reads below. Computed after the sample
    // (if any) was fed to the recorder so it reflects this tick. Was two
    // separate `buildSummary()` calls = two TripSummary allocations per
    // 4 Hz emit.
    final summary = _recorder.buildSummary();
    if (fuelRate != null) {
      _fuelRateSeen = true;
      _fuelLitersSoFar = summary.fuelLitersConsumed ?? _fuelLitersSoFar;
    }
    // #2506 — live Speed/Distance GPS fallback. The OBD2 speed PID (0x0D)
    // always wins when present; when it's momentarily absent (the no-fuel-
    // PID Peugeot in the field report drops it intermittently) the latched
    // GPS ground-speed fills the read-out instead of dashing to "—". For
    // distance, prefer the resolver's three-tier pick (GPS track > virtual
    // integral) when it has advanced past the recorder's integrated number
    // — matching what `_finaliseSummary` already does at stop, so live and
    // persisted agree.
    final effectiveSpeedKmh = speedKmh ?? _latestGpsSpeedKmh;
    // #3431 — fold this tick into the true-instant EMA (null when no
    // fuel-rate PID is measurable; the surfaces then fall back).
    final instant = _instantEma.update(
        now: nowTs, fuelRateLPerHour: fuelRate, speedKmh: effectiveSpeedKmh);
    final resolverDistanceKm = currentDistanceKm;
    final effectiveDistanceKm = resolverDistanceKm > summary.distanceKm
        ? resolverDistanceKm
        : summary.distanceKm;
    var reading = TripLiveReading(
      speedKmh: effectiveSpeedKmh,
      rpm: rpm,
      fuelRateLPerHour: fuelRate,
      fuelLevelPercent: snap.latestFuelLevelPercent,
      // #1615 — exact OEM-PID litres when the provider layer has pushed
      // one in; null (and consumers fall back to percent×capacity) when
      // the `experimentalOemPids` flag is off or the adapter is not
      // OEM-capable.
      fuelLevelLitres: snap.latestOemFuelLevelLitres,
      engineLoadPercent: engineLoadPercent,
      // #2513 — carry the wider-range absolute load + latest GPS
      // altitude through to the baseline recorder so its fuzzy path can
      // fill the climbing/loaded bucket from a real road grade and/or a
      // load ramp. Both stay null on cars / trips that don't surface
      // them, and the recorder degrades gracefully.
      absLoadPercent: snap.latestAbsLoadPercent,
      altitudeM: snap.latestAltitudeM,
      throttlePercent: throttlePercent,
      coolantTempC: coolantTempC,
      // #2515 — surface the precision signals the snapshot already
      // latches (oil/ambient temp gate the cold-start bucket now; λ /
      // baro / MAP / fuel-trim / pedal feed PR 2's mixture-precision
      // folding + altitude stratification). All null on cars without
      // the PID, so the calibration path degrades gracefully.
      oilTempC: snap.latestOilTempC,
      ambientTempC: snap.latestAmbientTempC,
      lambda: snap.latestCommandedPhi,
      baroKpa: snap.latestBaroKpa,
      mapKpa: snap.latestMapKpa,
      stft: snap.latestStft,
      ltft: snap.latestLtft,
      pedalPercent: snap.latestPedalPercent,
      distanceKmSoFar: effectiveDistanceKm,
      fuelLitersSoFar: _fuelRateSeen ? _fuelLitersSoFar : null,
      elapsed: nowTs.difference(_startedAt ?? nowTs),
      odometerStartKm: _odometerStartKm,
      odometerNowKm: _odometerLatestKm,
      instantLPer100Km: instant?.lPer100Km,
      instantLPerHour: instant?.lPerHour,
      instantIsIdle: instant?.isIdle,
    );
    // #2506 — when NO fuel-rate PID is measurable (every tick null), fold
    // the GPS-physics estimate + coaching into the live reading so the
    // recording screen mirrors the proven post-trip
    // `Obd2GpsEstimateFallback` instead of dashing the whole drive. The
    // shared [TripGpsEstimateOverlay] folder is the same implementation the
    // GPS-only pipeline uses, so the two paths can't diverge. The fold is
    // driven by the EFFECTIVE speed (GPS latch when OBD2 0x0D is absent),
    // so the physics still runs on a car that exposes neither a fuel PID
    // nor a reliable speed PID. Skipped once any real fuel rate is seen —
    // measured data is never overwritten; a stale GPS coaching hint is then
    // cleared so `MinimalDriveSummary` swaps back to the OBD2 triplet.
    reading = _overlayGpsEstimate(
      reading,
      nowTs: nowTs,
      fuelRate: fuelRate,
      effectiveSpeedKmh: effectiveSpeedKmh,
      rpm: rpm,
      altitudeM: snap.latestAltitudeM,
    );
    _liveController.add(reading);
  }

  /// #2506 / #2565 — fold the GPS-physics live estimate + coaching into
  /// [reading] when NO fuel-rate PID is measurable. Shared by the healthy
  /// `_emit` and the degraded GPS-only path so they can't diverge. Skipped
  /// once a real fuel rate is seen (a stale coaching hint is then cleared).
  TripLiveReading _overlayGpsEstimate(
    TripLiveReading reading, {
    required DateTime nowTs,
    required double? fuelRate,
    required double? effectiveSpeedKmh,
    required double? rpm,
    required double? altitudeM,
  }) {
    final folder = _gpsEstimateFolder;
    if (fuelRate == null && !_fuelRateSeen && folder != null) {
      final overlaid = folder.overlay(
        base: reading,
        now: nowTs,
        effectiveSpeedKmh: effectiveSpeedKmh ?? 0,
        rpm: rpm,
        altitudeM: altitudeM,
      );
      _latestGpsCoachingHint = overlaid.coachingHint;
      return overlaid.reading;
    } else if (_fuelRateSeen) {
      _latestGpsCoachingHint = null;
    }
    return reading;
  }

  /// #2565 — one emit tick while in the `degradedGpsOnly` phase, delegated
  /// to the [DegradedGpsEmitter] collaborator (which builds the GPS-only
  /// sample + live reading and escalates to paused when GPS also dies).
  void _emitDegradedGpsOnly() {
    final snap = _liveSampleSnapshot;
    final reading = _degradedEmitter.emitTick(
      latestGpsSpeedKmh: _latestGpsSpeedKmh,
      latitude: snap.latestLatitude,
      longitude: snap.latestLongitude,
      altitudeM: snap.latestAltitudeM,
      // #2648 — carry accuracy + bearing through the degraded path too.
      hAccuracyM: snap.latestHAccuracyM,
      bearingDeg: snap.latestBearingDeg,
      lastGpsFixAt: _gpsEndedAt,
      startedAt: _startedAt,
      resolverDistanceKm: currentDistanceKm,
      odometerStartKm: _odometerStartKm,
      odometerLatestKm: _odometerLatestKm,
    );
    if (reading != null) _liveController.add(reading);
  }
}
