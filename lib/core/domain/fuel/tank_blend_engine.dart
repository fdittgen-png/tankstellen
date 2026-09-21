// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'fuel_grade.dart';
import 'tank_blend_event.dart';
import 'tank_blend_snapshot.dart';
import 'tank_blend_state.dart';

/// Deterministic tank blend transitions (#4275): the state is a pure fold
/// of an immutable [TankBlendEvent] log, so it can always be recomputed —
/// after a restart, a late or duplicate delivery, an edited fill-up or a
/// [TankBlendState.currentModelVersion] bump.
///
/// ## The mixing rule
///
/// A fill of `L` litres of grade `g` onto a residual `R` of shares `C`:
///
///     share_k = (L·[k = g] + R·C_k) / (L + R)
///
/// When `R` is exact this is plain volume-weighted mixing. When `R` is only
/// known to lie in `[Rmin, Rmax]`, share_k is monotone in `R`, so the
/// engine keeps the smaller endpoint as the guaranteed minimum and the
/// difference lands in the unknown slack. An unbounded `Rmax` (no capacity,
/// no evidence) takes the limit `C_k`. Unknown residuals therefore LOWER
/// confidence; they never borrow precision from a guess.
///
/// ## Consumption
///
/// Burning fuel from a mixed tank removes every grade proportionally, so it
/// never changes the shares — only the volume interval:
/// `[max(0, Vmin − Cmax), Vmax − Cmin]`. A minimum burn larger than the
/// tank's maximum is a contradiction, recorded as
/// [TankBlendAnomalyKind.consumptionExceedsVolume], never clamped silently.
///
/// ## Capacity
///
/// When [tankCapacityLitres] is known, no residual may exceed
/// `capacity − litres` and a full-tank fill pins the residual exactly;
/// violations are recorded as anomalies with the resolution documented on
/// [TankBlendAnomalyKind].
final class TankBlendEngine {
  TankBlendEngine({this.tankCapacityLitres}) {
    final cap = tankCapacityLitres;
    if (cap != null && (!cap.isFinite || cap <= 0)) {
      throw ArgumentError.value(cap, 'tankCapacityLitres');
    }
  }

  final double? tankCapacityLitres;

  static const _eps = 1e-9;
  static const _fnvOffset = 0x811c9dc5;
  static const _fnvPrime = 0x01000193;

  /// Before any evidence: nothing about the content is known, and the
  /// volume is anywhere from empty to full (or unbounded).
  TankBlendSnapshot initial() => TankBlendSnapshot(
        gradeShares: const {FuelGrade.unknown: 1.0},
        minLitres: 0,
        maxLitres: tankCapacityLitres,
        tankCapacityLitres: tankCapacityLitres,
        appliedEventIds: const [],
        logFingerprint: _fnvOffset,
      );

  /// [events] ordered canonically, with exact duplicates collapsed.
  ///
  /// Throws [ArgumentError] when two events share an id but differ in
  /// payload: one identity naming two facts is a bug in the producer, and
  /// picking either would make the fold depend on delivery order.
  static List<TankBlendEvent> canonicalLog(Iterable<TankBlendEvent> events) {
    final byId = <String, TankBlendEvent>{};
    final encoded = <String, String>{};
    for (final event in events) {
      final json = jsonEncode(event.toJson());
      final seen = encoded[event.id];
      if (seen == null) {
        byId[event.id] = event;
        encoded[event.id] = json;
      } else if (seen != json) {
        throw ArgumentError.value(event.id, 'events',
            'two different events share this id');
      }
    }
    return byId.values.toList()..sort(TankBlendEvent.compareCanonically);
  }

  /// Folds [events] from [initial] in canonical order.
  TankBlendSnapshot replay(Iterable<TankBlendEvent> events) {
    var state = initial();
    for (final event in canonicalLog(events)) {
      state = apply(state, event);
    }
    return state;
  }

  /// Continues [stored] with the tail of [events] when it is provably a
  /// prefix of the same log under the same model; otherwise replays from
  /// scratch. "Provably" means: same [TankBlendState.currentModelVersion],
  /// same capacity, the applied ids are the first ids of the canonical
  /// log, and the fingerprint over those events matches — so an edited,
  /// deleted or back-dated event always forces a full recompute.
  TankBlendSnapshot resume({
    required TankBlendSnapshot? stored,
    required Iterable<TankBlendEvent> events,
  }) {
    final log = canonicalLog(events);
    if (stored == null ||
        stored.modelVersion != TankBlendState.currentModelVersion ||
        stored.tankCapacityLitres != tankCapacityLitres ||
        stored.appliedEventIds.length > log.length) {
      return _fold(initial(), log);
    }
    final n = stored.appliedEventIds.length;
    var fingerprint = _fnvOffset;
    for (var i = 0; i < n; i++) {
      if (log[i].id != stored.appliedEventIds[i]) {
        return _fold(initial(), log);
      }
      fingerprint = _mixFingerprint(fingerprint, log[i]);
    }
    if (fingerprint != stored.logFingerprint) return _fold(initial(), log);
    return _fold(stored, log.skip(n));
  }

  /// Applies one [event]. An id already in [TankBlendSnapshot.appliedEventIds]
  /// is a no-op and returns [state] itself.
  ///
  /// Throws [ArgumentError] when [state] came from another model version or
  /// capacity — such a snapshot must be recomputed via [resume], not
  /// extended.
  TankBlendSnapshot apply(TankBlendSnapshot state, TankBlendEvent event) {
    if (state.modelVersion != TankBlendState.currentModelVersion ||
        state.tankCapacityLitres != tankCapacityLitres) {
      throw ArgumentError.value(state.modelVersion, 'state',
          'snapshot is from another model version or capacity; use resume');
    }
    if (state.appliedEventIds.contains(event.id)) return state;
    return switch (event) {
      TankFillEvent() => _applyFill(state, event),
      TankConsumptionEvent() => _applyConsumption(state, event),
    };
  }

  TankBlendSnapshot _fold(
      TankBlendSnapshot start, Iterable<TankBlendEvent> events) {
    var state = start;
    for (final event in events) {
      state = apply(state, event);
    }
    return state;
  }

  TankBlendSnapshot _applyConsumption(
      TankBlendSnapshot s, TankConsumptionEvent e) {
    final anomalies = <TankBlendAnomaly>[];
    final vMax = s.maxLitres;
    double newMin;
    double? newMax;
    if (vMax != null && vMax - e.minLitres < -_eps) {
      anomalies.add(TankBlendAnomaly(
          eventId: e.id, kind: TankBlendAnomalyKind.consumptionExceedsVolume));
      newMin = 0;
      newMax = vMax;
    } else {
      newMax = vMax == null ? null : _nonNegative(vMax - e.minLitres);
      final cMax = e.maxLitres;
      newMin = cMax == null ? 0 : _nonNegative(s.minLitres - cMax);
    }
    return _next(s, e,
        shares: s.gradeShares,
        minLitres: newMin,
        maxLitres: newMax,
        anomalies: anomalies);
  }

  TankBlendSnapshot _applyFill(TankBlendSnapshot s, TankFillEvent e) {
    final anomalies = <TankBlendAnomaly>[];
    final cap = tankCapacityLitres;
    final litres = e.litres;

    void flag(TankBlendAnomalyKind kind) =>
        anomalies.add(TankBlendAnomaly(eventId: e.id, kind: kind));

    if (cap != null && litres > cap + _eps) {
      flag(TankBlendAnomalyKind.fillExceedsCapacity);
      return _next(s, e,
          shares: {e.grade: 1.0},
          minLitres: cap,
          maxLitres: cap,
          anomalies: anomalies);
    }

    // ── Residual interval, strongest evidence first. ──
    double rMin;
    double? rMax;
    final level = e.levelBeforeLitres;
    if (e.fillsTank && cap != null) {
      rMin = rMax = _nonNegative(cap - litres);
      if (!_within(rMin, s)) {
        flag(TankBlendAnomalyKind.observationContradictsTrackedVolume);
      }
    } else if (level != null) {
      rMin = rMax = level;
      if (!_within(level, s)) {
        flag(TankBlendAnomalyKind.observationContradictsTrackedVolume);
      }
    } else {
      rMin = s.minLitres;
      rMax = s.maxLitres;
    }
    if (cap != null) {
      final ceiling = _nonNegative(cap - litres);
      if (rMin > ceiling + _eps) {
        flag(TankBlendAnomalyKind.residualExceedsCapacity);
        rMin = 0;
      }
      if (rMax == null || rMax > ceiling) rMax = ceiling;
    }

    final shares = _mix(s.gradeShares, e.grade, litres, rMin, rMax);
    final bool pinnedFull = e.fillsTank && cap != null;
    return _next(s, e,
        shares: shares,
        minLitres: pinnedFull ? cap : rMin + litres,
        maxLitres: pinnedFull ? cap : (rMax == null ? null : rMax + litres),
        anomalies: anomalies);
  }

  /// Guaranteed-minimum shares after mixing (see the class doc).
  static Map<FuelGrade, double> _mix(Map<FuelGrade, double> residual,
      FuelGrade grade, double litres, double rMin, double? rMax) {
    double shareAt(double r, double added, double residualShare) =>
        (added + r * residualShare) / (litres + r);

    // Canonical key order, NOT map order: the summation order decides the
    // last ulp of the slack, and a decoded snapshot's map order differs
    // from a live one's — resume must be bit-identical to replay.
    final keys = FuelGrade.values.where((k) =>
        k != FuelGrade.unknown && (k == grade || residual.containsKey(k)));
    final lower = <FuelGrade, double>{};
    var known = 0.0;
    for (final k in keys) {
      final added = k == grade ? litres : 0.0;
      final c = residual[k] ?? 0.0;
      final atMin = shareAt(rMin, added, c);
      final atMax = rMax == null ? c : shareAt(rMax, added, c);
      final share = (atMin < atMax ? atMin : atMax).clamp(0.0, 1.0);
      if (share <= _eps) continue;
      lower[k] = share;
      known += share;
    }
    if (known > 1) {
      // Floating-point overshoot only: every term is a convex weight.
      lower.updateAll((_, v) => v / known);
      known = 1;
    }
    final slack = 1 - known;
    if (slack > _eps || lower.isEmpty) {
      lower[FuelGrade.unknown] = lower.isEmpty ? 1.0 : slack;
    } else if (slack > 0) {
      // Fold sub-epsilon slack into the largest share so the sum stays 1.
      final top = lower.entries.reduce((a, b) => a.value >= b.value ? a : b);
      lower[top.key] = top.value + slack;
    }
    return lower;
  }

  TankBlendSnapshot _next(
    TankBlendSnapshot s,
    TankBlendEvent e, {
    required Map<FuelGrade, double> shares,
    required double minLitres,
    required double? maxLitres,
    required List<TankBlendAnomaly> anomalies,
  }) =>
      TankBlendSnapshot(
        gradeShares: shares,
        minLitres: minLitres,
        maxLitres: (maxLitres != null && maxLitres < minLitres)
            ? minLitres
            : maxLitres,
        tankCapacityLitres: tankCapacityLitres,
        appliedEventIds: [...s.appliedEventIds, e.id],
        logFingerprint: _mixFingerprint(s.logFingerprint, e),
        anomalies: [...s.anomalies, ...anomalies],
      );

  static bool _within(double litres, TankBlendSnapshot s) {
    final max = s.maxLitres;
    return litres >= s.minLitres - _eps && (max == null || litres <= max + _eps);
  }

  static double _nonNegative(double v) => v < 0 ? 0 : v;

  /// 32-bit FNV-1a, continued over the event's canonical JSON. Masked to 32
  /// bits after every step so the value is stable across 64-bit platforms.
  static int _mixFingerprint(int seed, TankBlendEvent event) {
    var hash = seed;
    for (final unit in jsonEncode(event.toJson()).codeUnits) {
      hash = ((hash ^ unit) * _fnvPrime) & 0xffffffff;
    }
    return hash;
  }
}
