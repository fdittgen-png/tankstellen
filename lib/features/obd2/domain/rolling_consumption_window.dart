// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:collection';

import 'package:flutter/foundation.dart';

/// One rolling-window consumption snapshot (#3883, Epic #3881).
@immutable
class RollingConsumption {
  /// Litres burned over the window ÷ hours spanned — the per-time figure.
  final double lPerHour;

  /// Litres over the window ÷ distance over the window × 100, or null
  /// while [isIdle] (too little distance for a per-distance figure).
  final double? lPer100Km;

  /// True when the window covered less than the minimum distance —
  /// show [lPerHour] instead.
  final bool isIdle;

  /// The wall-clock span the figures integrate over.
  final Duration span;

  const RollingConsumption({
    required this.lPerHour,
    required this.lPer100Km,
    required this.isIdle,
    required this.span,
  });
}

/// The "average consumption over the last N seconds" the driver sees on
/// the recording screen (#3883).
///
/// The EMA (`InstantConsumptionEma`) smooths the *rate*; this integrates
/// it: ∫fuelRate·dt ÷ ∫speed·dt over a sliding window, which is the
/// honest definition of "what I burned per km over the last 5 s" and is
/// what a dashboard trip computer shows. The window length is a user
/// setting; the buffer keeps [maxWindow] of ticks so the length can be
/// changed mid-trip and every length up to the maximum is answerable.
///
/// Sparse fuel-rate coverage is expected (field data: ~21 % of ticks
/// carry a fuel rate on some cars): a tick without a rate reuses the
/// last measured one for up to [rateHold]; beyond that the tick carries
/// no litres and the window goes stale (null) once no fresh rate has
/// arrived within [rateHold].
///
/// Pure — no timers, no I/O; the caller supplies the clock.
class RollingConsumptionWindow {
  RollingConsumptionWindow({
    this.maxWindow = const Duration(seconds: 30),
    this.minDistanceM = 50,
    this.rateHold = const Duration(seconds: 2),
    this.gapReset = const Duration(seconds: 5),
  });

  /// Longest window a reader may ask for; the buffer keeps this much.
  final Duration maxWindow;

  /// Below this distance over the window the per-distance figure is
  /// meaningless (standstill / creeping) → [RollingConsumption.isIdle].
  final double minDistanceM;

  /// How long the last measured fuel rate keeps answering for a tick
  /// that has none.
  final Duration rateHold;

  /// A gap between ticks longer than this (link drop, engine-off) resets
  /// the window instead of integrating across it.
  final Duration gapReset;

  final ListQueue<_Tick> _ticks = ListQueue<_Tick>();
  DateTime? _lastAt;
  double? _lastRate;
  DateTime? _lastRateAt;
  double? _lastSpeed;

  /// Ticks currently buffered. Exposed for tests.
  int get tickCount => _ticks.length;

  /// Fold one tick in. [fuelRateLPerHour] may be null (no PID this
  /// tick); [speedKmh] may be null (no speed this tick — the last one is
  /// reused). Returns nothing — call [read] for the figures.
  void add({
    required DateTime now,
    required double? fuelRateLPerHour,
    required double? speedKmh,
  }) {
    final last = _lastAt;
    if (last != null) {
      final dt = now.difference(last);
      if (dt.isNegative || dt > gapReset) {
        reset();
      }
    }
    if (fuelRateLPerHour != null && fuelRateLPerHour >= 0) {
      _lastRate = fuelRateLPerHour;
      _lastRateAt = now;
    }
    if (speedKmh != null && speedKmh >= 0) _lastSpeed = speedKmh;

    final prev = _lastAt;
    _lastAt = now;
    if (prev == null) return; // first tick — nothing to integrate yet
    final dtHours = now.difference(prev).inMicroseconds /
        Duration.microsecondsPerSecond /
        3600.0;
    final rate = _heldRate(now);
    final speed = _lastSpeed;
    _ticks.addLast(_Tick(
      at: now,
      litres: rate == null ? null : rate * dtHours,
      km: speed == null ? 0 : speed * dtHours,
      hours: dtHours,
    ));
    final cutoff = now.subtract(maxWindow);
    while (_ticks.isNotEmpty && _ticks.first.at.isBefore(cutoff)) {
      _ticks.removeFirst();
    }
  }

  double? _heldRate(DateTime now) {
    final rate = _lastRate;
    final at = _lastRateAt;
    if (rate == null || at == null) return null;
    return now.difference(at) > rateHold ? null : rate;
  }

  /// The figures over the last [window] (clamped to [maxWindow]), or
  /// null when the window holds no litres (no fuel rate within
  /// [rateHold] of any tick, or nothing buffered yet).
  RollingConsumption? read(Duration window) {
    if (_ticks.isEmpty) return null;
    final w = window > maxWindow ? maxWindow : window;
    // A tick's `at` marks the END of the interval it integrates, so a
    // tick exactly at the cutoff lies wholly before the window.
    final cutoff = _ticks.last.at.subtract(w);
    var litres = 0.0, km = 0.0, hours = 0.0;
    var anyRate = false;
    for (final t in _ticks) {
      if (!t.at.isAfter(cutoff)) continue;
      if (t.litres != null) {
        litres += t.litres!;
        anyRate = true;
      }
      km += t.km;
      hours += t.hours;
    }
    if (!anyRate || hours <= 0) return null;
    final idle = km * 1000.0 < minDistanceM;
    return RollingConsumption(
      lPerHour: litres / hours,
      lPer100Km: idle ? null : litres / km * 100.0,
      isIdle: idle,
      span: Duration(microseconds: (hours * 3600 * 1e6).round()),
    );
  }

  /// Drop every buffered tick — the next [add] starts a fresh window.
  void reset() {
    _ticks.clear();
    _lastAt = null;
    _lastRate = null;
    _lastRateAt = null;
    _lastSpeed = null;
  }
}

class _Tick {
  const _Tick({
    required this.at,
    required this.litres,
    required this.km,
    required this.hours,
  });
  final DateTime at;
  final double? litres;
  final double km;
  final double hours;
}
