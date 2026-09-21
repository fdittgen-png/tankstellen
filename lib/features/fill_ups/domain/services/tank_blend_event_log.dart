// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../../core/domain/fuel/fuel_grade.dart';
import '../../../../core/domain/fuel/tank_blend_engine.dart';
import '../../../../core/domain/fuel/tank_blend_event.dart';
import '../../../../core/domain/fuel/tank_blend_snapshot.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../trips/api.dart';
import '../correction_fill_up.dart';
import '../entities/fill_up.dart';

/// Derives [vehicleId]'s tank blend from the recorded history (#4279).
///
/// The fill-up and trip records are the source of truth and are only read.
/// Nothing is persisted: the blend is recomputed from them on every change,
/// which is what makes an edit, a delete, a restart, a late sync or a
/// duplicated record converge on the same answer — the engine folds a
/// canonical, de-duplicated log ([TankBlendEngine.canonicalLog]).
TankBlendSnapshot deriveTankBlend({
  required String vehicleId,
  required VehicleProfile? vehicle,
  required Iterable<FillUp> fillUps,
  required Iterable<TripHistoryEntry> trips,
}) =>
    tankBlendEngineFor(vehicle?.tankCapacityL).replay(tankBlendEventsFor(
      vehicleId: vehicleId,
      fillUps: fillUps,
      trips: trips,
    ));

/// The engine for a tank of [tankCapacityL] litres — unbounded when that
/// capacity is unknown, non-finite or non-positive.
TankBlendEngine tankBlendEngineFor(double? tankCapacityL) {
  final usable =
      tankCapacityL != null && tankCapacityL.isFinite && tankCapacityL > 0;
  return TankBlendEngine(tankCapacityLitres: usable ? tankCapacityL : null);
}

/// Translates [vehicleId]'s records into blend events (#4279).
///
/// ## Fills
///
/// Every physical fill becomes a [TankFillEvent] (`fill:<id>`) with its
/// grade, litres, full-tank flag and the pre-pump level when one was read
/// (`fuelLevelBeforeL`, else `fuelLevelAfterL − litres` when that is not
/// negative). The search wildcard grade becomes [FuelGrade.unknown];
/// non-liquid fills (electricity, CNG, hydrogen) and fills with no positive
/// litres put nothing in a liquid tank and are left out.
///
/// A reconciliation correction (#1361) is NOT fuel bought — it is the
/// accounting gap between recorded trip fuel and the pump. For the tank it
/// means "the recorded consumption in this window was wrong", so it
/// becomes an unmeasured consumption (`correction:<id>`).
///
/// ## Consumption between fills
///
/// No new consumption estimate is made. Each trip contributes the
/// canonical figure ([tripConsumedLitersOrNull]) only when the ECU
/// measured it ([TripFuelSourceKind.measured]); an estimated or GPS figure
/// is a model whose error is not bounded here (level v2 excludes
/// recordings for the same reason, #3647), so it becomes an unmeasured
/// drive — "unknown is not zero". Engine-off transport burned nothing and
/// is skipped.
///
/// Driving that no trip recorded is stated too: between two fills, unless
/// the recorded trip distance covers the odometer delta, a `gap:<fillId>`
/// unmeasured drive precedes the later fill; after the last fill a
/// `gap-since-last-fill` follows everything, because nothing proves the
/// car has not been driven since.
///
/// Records sharing an id are taken once (first occurrence), so a list that
/// a sync merge duplicated cannot apply the same fact twice.
List<TankBlendEvent> tankBlendEventsFor({
  required String vehicleId,
  required Iterable<FillUp> fillUps,
  required Iterable<TripHistoryEntry> trips,
}) =>
    _eventsOf(vehicleId, fillUps, trips);

/// [tankBlendEventsFor] over records the caller has ALREADY scoped to one
/// vehicle (#4322) — the ADR 0015 per-fuel comparison, whose fill list
/// also carries a single-vehicle user's unassigned fills (#3945).
List<TankBlendEvent> tankBlendEventsOf({
  required Iterable<FillUp> fillUps,
  required Iterable<TripHistoryEntry> trips,
}) =>
    _eventsOf(null, fillUps, trips);

/// A null [vehicleId] takes every record as the vehicle's own.
List<TankBlendEvent> _eventsOf(String? vehicleId, Iterable<FillUp> fillUps,
    Iterable<TripHistoryEntry> trips) {
  bool foreign(String? id) => vehicleId != null && id != vehicleId;
  final events = <TankBlendEvent>[];
  final seenFills = <String>{};
  final physical = <FillUp>[];
  for (final f in fillUps) {
    if (foreign(f.vehicleId) || !seenFills.add(f.id)) continue;
    if (isReconciliationCorrection(f)) {
      events.add(TankConsumptionEvent.unmeasured(
          id: 'correction:${f.id}', at: f.date));
      continue;
    }
    final event = _fillEvent(f);
    if (event == null) continue;
    events.add(event);
    physical.add(f);
  }

  final seenTrips = <String>{};
  final dated = <({DateTime at, String id, double km})>[];
  for (final trip in trips) {
    if (foreign(trip.vehicleId) || !seenTrips.add(trip.id)) continue;
    final summary = trip.summary;
    final at = summary.startedAt ?? summary.endedAt;
    if (at == null) continue;
    dated.add((at: at, id: trip.id, km: summary.distanceKm));
    if (isEngineOffTransport(summary)) continue;
    final litres = tripConsumedLitersOrNull(summary);
    final id = 'trip:${trip.id}';
    final measured =
        tripFuelSourceKind(summary) == TripFuelSourceKind.measured;
    events.add(measured && litres != null && litres >= 0 && litres.isFinite
        ? TankConsumptionEvent.exact(id: id, at: at, litres: litres)
        : TankConsumptionEvent.unmeasured(id: id, at: at));
  }

  if (physical.isEmpty) return events;
  // Summation order must not depend on delivery order: a last-ulp
  // difference could flip the coverage comparison below.
  dated.sort((a, b) {
    final byTime = a.at.compareTo(b.at);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  });
  physical.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  });
  for (var i = 1; i < physical.length; i++) {
    final prev = physical[i - 1];
    final next = physical[i];
    final deltaKm = next.odometerKm - prev.odometerKm;
    final recordedKm = dated
        .where((t) => t.at.isAfter(prev.date) && !t.at.isAfter(next.date))
        .fold(0.0, (sum, t) => sum + t.km);
    final covered = prev.odometerKm > 0 &&
        next.odometerKm > 0 &&
        deltaKm >= 0 &&
        recordedKm >= deltaKm;
    if (!covered) {
      events.add(TankConsumptionEvent.unmeasured(
          id: 'gap:${next.id}', at: next.date));
    }
  }
  var last = physical.last.date;
  for (final t in dated) {
    if (t.at.isAfter(last)) last = t.at;
  }
  events.add(TankConsumptionEvent.unmeasured(
      id: 'gap-since-last-fill',
      at: last.add(const Duration(microseconds: 1))));
  return events;
}

/// The blend right AFTER each physical fill of [fillUps], keyed by fill-up
/// id (#4322) — the records already scoped to one vehicle, as for
/// [tankBlendEventsOf]. One fold serves every "the tank as of fill N"
/// question, so a caller asking it per fill pays O(n), not a replay each.
/// A fill the blend leaves out (non-liquid, no litres, a correction) has
/// no entry.
Map<String, TankBlendSnapshot> tankBlendAfterEachFill({
  required double? tankCapacityL,
  required Iterable<FillUp> fillUps,
  Iterable<TripHistoryEntry> trips = const [],
}) {
  final engine = tankBlendEngineFor(tankCapacityL);
  var state = engine.initial();
  final after = <String, TankBlendSnapshot>{};
  for (final event in TankBlendEngine.canonicalLog(
      tankBlendEventsOf(fillUps: fillUps, trips: trips))) {
    state = engine.apply(state, event);
    if (event is TankFillEvent) {
      after[event.id.substring(_fillPrefix.length)] = state;
    }
  }
  return after;
}

const String _fillPrefix = 'fill:';

/// The fuel key stamped on [vehicle] as `tankFuelKey` (#3918): the grade
/// the tank holds, for the fuel-rate readers' per-fuel pump gain.
///
/// A single-fuel vehicle holds what it was last filled with. A multi-fuel
/// vehicle's tank is read from the evidence-only blend (#4322) — the grade
/// whose lead no unknown share could overturn. When the evidence leaves the
/// lead open the answer is null, never the last pump's label: the readers
/// then fall back to the ECU session key and the configured fuel, the
/// documented `pumpGainFuelKeyFor` chain. [fillUps] and [trips] are
/// already scoped to the vehicle. With no physical fill at all there is
/// nothing to say, and the current key is kept.
String? tankFuelKeyOf({
  required VehicleProfile vehicle,
  required Iterable<FillUp> fillUps,
  required Iterable<TripHistoryEntry> trips,
}) {
  final physical = fillUps.where((f) => !f.isCorrection).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  if (physical.isEmpty) return vehicle.tankFuelKey;
  if (!vehicle.multiFuelCapable) return physical.first.fuelType.apiValue;
  return deriveTankBlendOf(
    tankCapacityL: vehicle.tankCapacityL,
    fillUps: fillUps,
    trips: trips,
  ).establishedLeadingGrade?.key;
}

/// [deriveTankBlend] over records already scoped to one vehicle.
TankBlendSnapshot deriveTankBlendOf({
  required double? tankCapacityL,
  required Iterable<FillUp> fillUps,
  required Iterable<TripHistoryEntry> trips,
}) =>
    tankBlendEngineFor(tankCapacityL)
        .replay(tankBlendEventsOf(fillUps: fillUps, trips: trips));

TankFillEvent? _fillEvent(FillUp f) {
  final parsed = FuelGrade.fromKey(f.fuelType.apiValue);
  final grade = parsed == FuelGrade.wildcard ? FuelGrade.unknown : parsed;
  if (!(grade.isLiquid || grade == FuelGrade.unknown)) return null;
  if (!f.liters.isFinite || f.liters <= 0) return null;
  final before = f.fuelLevelBeforeL;
  final after = f.fuelLevelAfterL;
  double? level;
  if (before != null && before.isFinite && before >= 0) {
    level = before;
  } else if (after != null && after.isFinite && after - f.liters >= 0) {
    level = after - f.liters;
  }
  return TankFillEvent(
    id: '$_fillPrefix${f.id}',
    at: f.date,
    grade: grade,
    litres: f.liters,
    fillsTank: f.isFullTank,
    levelBeforeLitres: level,
  );
}
