// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../data/obd2/trip_recording_controller.dart';
import '../domain/cold_start_baselines.dart';
import '../domain/driving_coaching.dart' show DrivingCoachingHint;
import '../domain/entities/trip_start_stage.dart';
import '../domain/situation_classifier.dart';
import 'trip_recording_phase.dart';

/// Immutable snapshot the UI observes.
@immutable
class TripRecordingState {
  final TripRecordingPhase phase;
  final TripLiveReading? live;
  final DrivingSituation situation;
  final ConsumptionBand band;

  /// How far live consumption deviates from the situation's baseline
  /// as a signed fraction (e.g. -0.08 = 8 % below baseline). Null
  /// when the car doesn't report fuel rate or a live L/100 km can't
  /// be computed (idle uses L/h — caller formats it differently).
  final double? liveDeltaFraction;

  /// Why the controller flipped into [TripRecordingPhase.pausedDueToDrop]
  /// (#1330 phase 3). Null in any other phase. Drives the pause-banner
  /// copy: "OBD2 connection lost" for transport errors, "OBD2 adapter
  /// connected but not returning data" for silent failure.
  final TripDropReason? dropReason;

  /// GPS-only live coaching hint (#2058) — derived from the rolling
  /// window of the last ~5 s of GPS samples on every recorder emit.
  /// Null when the trajet has OBD2 fuel-rate data (the standard
  /// `coachingHint` path takes over) or when no hint applies.
  /// Drives the three GPS-derived tiles in `MinimalDriveSummary`.
  final DrivingCoachingHint? gpsCoachingHint;

  /// #2274 concern 2 — which beat of the connect+prime sequence the
  /// start flow is on, surfaced while [phase] is
  /// [TripRecordingPhase.connecting] so the recording screen renders the
  /// inline [TripStartProgress] in place of the live metrics. Null in
  /// every other phase.
  final TripStartStage? connectStage;

  const TripRecordingState({
    this.phase = TripRecordingPhase.idle,
    this.live,
    this.situation = DrivingSituation.idle,
    this.band = ConsumptionBand.normal,
    this.liveDeltaFraction,
    this.dropReason,
    this.gpsCoachingHint,
    this.connectStage,
  });

  TripRecordingState copyWith({
    TripRecordingPhase? phase,
    TripLiveReading? live,
    DrivingSituation? situation,
    ConsumptionBand? band,
    double? liveDeltaFraction,
    bool clearDelta = false,
    TripDropReason? dropReason,
    bool clearDropReason = false,
    DrivingCoachingHint? gpsCoachingHint,
    bool clearGpsCoachingHint = false,
    TripStartStage? connectStage,
    bool clearConnectStage = false,
  }) =>
      TripRecordingState(
        phase: phase ?? this.phase,
        live: live ?? this.live,
        situation: situation ?? this.situation,
        band: band ?? this.band,
        liveDeltaFraction: clearDelta
            ? null
            : (liveDeltaFraction ?? this.liveDeltaFraction),
        dropReason: clearDropReason
            ? null
            : (dropReason ?? this.dropReason),
        gpsCoachingHint: clearGpsCoachingHint
            ? null
            : (gpsCoachingHint ?? this.gpsCoachingHint),
        connectStage: clearConnectStage
            ? null
            : (connectStage ?? this.connectStage),
      );

  bool get isActive =>
      phase == TripRecordingPhase.recording ||
      phase == TripRecordingPhase.paused ||
      phase == TripRecordingPhase.pausedDueToDrop;

  /// #2274 concern 2 — true while the start-now-connect-later flow is
  /// reaching the adapter and priming the recorder, before the first
  /// live sample lands. Distinct from [isActive] (no trip exists yet).
  bool get isConnecting => phase == TripRecordingPhase.connecting;
}
