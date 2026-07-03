// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// One smoothed instantaneous-consumption snapshot (#3431, epic #3416).
///
/// Produced by [InstantConsumptionEma.update] on every emit tick and
/// stamped onto `TripLiveReading` so the live surfaces can show a *true*
/// instantaneous figure beside the trip running average — before #3431
/// the recording screen's big number was `liveAvgLPer100Km` (litres-so-
/// far ÷ distance-so-far) mislabelled "Instant consumption".
@immutable
class InstantConsumption {
  /// EMA-smoothed fuel rate in L/h. Always present when a snapshot
  /// exists — this is the primary smoothed signal the per-distance
  /// figure is derived from.
  final double lPerHour;

  /// Smoothed instantaneous consumption in L/100 km:
  /// `lPerHour / speedKmh × 100`. Null while [isIdle] — below the idle
  /// speed threshold the per-distance figure diverges toward infinity
  /// and stops being meaningful, so consumers show [lPerHour] instead.
  final double? lPer100Km;

  /// True when the vehicle is at / near standstill (speed below the
  /// idle threshold, ~5 km/h) — the "show L/h instead" mode flag.
  final bool isIdle;

  const InstantConsumption({
    required this.lPerHour,
    required this.lPer100Km,
    required this.isIdle,
  });
}

/// Exponential-moving-average smoother for the instantaneous fuel rate
/// (#3431, epic #3416 task 6).
///
/// The raw fuel-rate PID ticks at up to 5 Hz and is noisy (injector
/// batching, tier scheduling jitter), so a raw `rate / speed` figure
/// flickers too much to read while driving. This class smooths the
/// rate with a time-constant EMA (`α = 1 − e^(−Δt/τ)`, τ ≈ 2.5 s by
/// default): a step change in the true rate reaches ~63 % of the new
/// value after one τ and ~95 % after three — fast enough to feel live,
/// slow enough to stop the number jittering.
///
/// Semantics:
/// - `fuelRateLPerHour == null` (no fuel PID this tick) → returns null
///   and leaves the EMA state untouched; a later measured tick with a
///   large Δt effectively re-seeds (α → 1) so a PID dropout cannot
///   leave a stale figure pinned on screen.
/// - `speedKmh` below [idleSpeedThresholdKmh] (or unknown) → the
///   snapshot is flagged [InstantConsumption.isIdle] and carries only
///   the smoothed L/h (the per-distance figure is meaningless at
///   standstill).
///
/// Pure state machine — no timers, no I/O; the caller supplies the
/// clock (`now`). One instance per recording (the controller is
/// constructed per trip, so no explicit reset is needed in production;
/// [reset] exists for reuse in tests).
class InstantConsumptionEma {
  InstantConsumptionEma({
    this.tau = const Duration(milliseconds: 2500),
    this.idleSpeedThresholdKmh = 5.0,
  });

  /// EMA time constant. 2.5 s per the #3431 spec (τ ≈ 2–3 s).
  final Duration tau;

  /// Below this speed the L/100 km figure diverges — the snapshot flips
  /// to idle mode and consumers render L/h. Mirrors the 5 km/h guard
  /// `formatInstantConsumption` has used since #2007.
  final double idleSpeedThresholdKmh;

  double? _emaLPerHour;
  DateTime? _lastAt;

  /// The current smoothed rate in L/h, or null before the first
  /// measured tick. Exposed for tests / diagnostics.
  double? get smoothedLPerHour => _emaLPerHour;

  /// Fold one emit tick into the EMA and return the smoothed snapshot,
  /// or null when no fuel-rate signal is measurable this tick (the
  /// caller then leaves the instant fields null and the UI falls back
  /// to its no-data rendering).
  InstantConsumption? update({
    required DateTime now,
    required double? fuelRateLPerHour,
    required double? speedKmh,
  }) {
    if (fuelRateLPerHour == null || fuelRateLPerHour < 0) return null;

    final prev = _emaLPerHour;
    final last = _lastAt;
    final double next;
    if (prev == null || last == null) {
      // First measured tick seeds the EMA at the raw value — starting
      // from 0 would fabricate a ramp-up the engine never had.
      next = fuelRateLPerHour;
    } else {
      final dtMicros = now.difference(last).inMicroseconds;
      if (dtMicros <= 0) {
        // Clock went backwards / duplicate tick — keep the state as-is
        // and re-derive the snapshot from the existing EMA.
        next = prev;
      } else {
        final dtSeconds = dtMicros / Duration.microsecondsPerSecond;
        final tauSeconds = tau.inMicroseconds / Duration.microsecondsPerSecond;
        final alpha = 1 - math.exp(-dtSeconds / tauSeconds);
        next = prev + alpha * (fuelRateLPerHour - prev);
      }
    }
    _emaLPerHour = next;
    _lastAt = now;

    final speed = speedKmh;
    final idle = speed == null || speed < idleSpeedThresholdKmh;
    return InstantConsumption(
      lPerHour: next,
      lPer100Km: idle ? null : next / speed * 100.0,
      isIdle: idle,
    );
  }

  /// Drop all state — the next [update] re-seeds from its raw value.
  void reset() {
    _emaLPerHour = null;
    _lastAt = null;
  }
}
