// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/logging/app_log.dart';
import '../../trips/api.dart' show GpsMovementWakeNudge;
// Obd2LinkSupervisorActions.wake lives in the supervisor's part extension.
import '../data/session/obd2_link_supervisor.dart';
import '../domain/vehicle_power_state.dart';
import 'obd2_reconnect_provider.dart';

/// #4383 (Epic #4195) — the movement evidence of an OBD2 recording.
///
/// While an OBD2 recording is degraded to GPS, every producer of engine
/// evidence the link supervisor listens to — rpm parses, `ATRV` voltage —
/// sits downstream of the dead link. The one proof the app still owns
/// that the vehicle is running is the recording's own GPS ground speed,
/// and until #4383 it was never published: `GpsMovementWakeNudge` was
/// wired only into the GPS-only pipeline, and
/// [Obd2VehiclePower.noteMotion] had no production caller at all. So a
/// class-1 outage (adapter dark past the engine-evidence window) held a
/// restored adapter through a 5–15 min stand-down, and a class-3 mute ELM
/// read as `asleep` at road speed and parked the owner with zero dials.
///
/// This owns exactly what the GPS-only pipeline does, at the same
/// threshold and throttle (5 supra-10 km/h samples; one nudge per 2 min):
///   * the throttled nudge reaches the ONE dial authority through its
///     existing [Obd2LinkSupervisor.wake] — no second reconnect path;
///   * every sustained-movement sample stamps [Obd2VehiclePower.noteMotion],
///     so the fused model can tell "parked, adapter asleep" from
///     "moving, link broken". Motion never maps to `engineRunning` (#3599
///     tow semantics are the model's, untouched here).
class Obd2RecordingMovementWake {
  Obd2RecordingMovementWake({
    required void Function() wake,
    Obd2VehiclePower? power,
    DateTime Function()? now,
  }) : _power = power ?? Obd2VehiclePower.instance {
    _nudge = GpsMovementWakeNudge(
      wake: wake,
      onSustainedMovement: _power.noteMotion,
      now: now,
    );
  }

  /// Production wiring: the nudge reaches the supervisor the reconnect
  /// provider owns. A missing provider graph (widget tests, the legacy
  /// path) is logged, never thrown — a wake must not take the recording
  /// path down. Mirrors `GpsOnlyRecordingPipeline`'s wake closure.
  factory Obd2RecordingMovementWake.forRef(Ref ref) =>
      Obd2RecordingMovementWake(wake: () {
        try {
          ref.read(obd2ReconnectProvider.notifier).supervisor.wake();
        } catch (e, st) {
          log.error(e, st, layer: ErrorLayer.providers, context: const {
            'where': 'Obd2RecordingPipeline: movement wake failed',
          });
        }
      });

  final Obd2VehiclePower _power;
  late final GpsMovementWakeNudge _nudge;

  /// Feed one live speed sample (km/h) from the recording — the GPS latch
  /// while degraded, the vehicle speed while live (where the nudge is a
  /// no-op: `wake()` does nothing to a ready link). Null = no reading.
  void onSpeed(double? speedKmh) {
    if (speedKmh == null) return;
    _nudge.onSpeed(speedKmh);
  }
}
