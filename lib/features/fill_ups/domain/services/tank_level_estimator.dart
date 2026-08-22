// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../../../../core/domain/vehicle_profile.dart';
import '../../data/obd2_fuel_level_snapshot_store.dart';
import '../entities/fill_up.dart';
import 'fill_anchored_consumption.dart';

/// What the displayed tank level is grounded on (#3647, tank level v2).
enum TankLevelSource {
  /// The most recent physical fill-up is the anchor — a full fill sets
  /// the level to capacity (100 %), a partial to its measured/derived
  /// post-fill level. No sensor reading newer than the fill exists.
  fillUp,

  /// An OBD2 fuel-level reading taken AFTER the most recent fill-up
  /// (PSA passive-CAN / OEM native litres / PID `0x2F` × capacity) is
  /// the latest ground truth and overrides the fill anchor.
  obd2Sensor,
}

/// Default L/100 km used for the range estimate when the fill history
/// has no valid tank-to-tank window yet (#3645). A defensive European
/// fleet midpoint — honest enough for a first range figure without
/// overstating accuracy.
const double _defaultAvgLPer100Km = 7.0;

/// Result of the tank-level computation (#1195, reworked by #3647).
///
/// All values are honest: `levelL` is clamped to `[0, capacityL]` so the
/// UI never shows negative fuel or "more than full" readings, and
/// `rangeKm` is null whenever no average is available.
@immutable
class TankLevelEstimate {
  /// Litres currently in the tank per the v2 model (fill anchor,
  /// sensor override), clamped to `[0, capacityL ?? infinity]`.
  final double levelL;

  /// Vehicle tank capacity in litres, when known. Null when the
  /// vehicle profile has no `tankCapacityL` set — the UI then renders
  /// the level number without a percentage bar.
  final double? capacityL;

  /// Date of the most recent physical fill-up. Null on the [unknown]
  /// sentinel.
  final DateTime? lastFillUpDate;

  /// What grounds [levelL] — the fill-up anchor or a newer OBD2
  /// sensor reading.
  final TankLevelSource source;

  /// When the sensor reading was taken. Non-null exactly when [source]
  /// is [TankLevelSource.obd2Sensor].
  final DateTime? sensorReadAt;

  /// Estimated remaining range in kilometres, from the fill-anchored
  /// LONG-RUN tank-to-tank average (#3645, up to the last 8 windows) —
  /// recording-free by construction. Since #3764 this is the SECONDARY
  /// context figure; see [rangeKmLastInterval] / [primaryRangeKm].
  final double? rangeKm;

  /// #3764 — range projected at the LAST closed plein-to-plein window's
  /// L/100 km alone ("how far does the current tank get me if I keep
  /// driving like the last one"). Null when no valid closed window
  /// exists yet — [primaryRangeKm] then falls back to [rangeKm], i.e.
  /// exactly the pre-#3764 behaviour.
  final double? rangeKmLastInterval;

  const TankLevelEstimate({
    required this.levelL,
    required this.capacityL,
    required this.lastFillUpDate,
    required this.source,
    required this.sensorReadAt,
    required this.rangeKm,
    this.rangeKmLastInterval,
  });

  /// Sentinel returned when no physical fill-ups exist for the vehicle.
  /// Callers render the "Log a fill-up to see your tank level" empty
  /// state.
  const TankLevelEstimate.unknown()
      : levelL = 0,
        capacityL = null,
        lastFillUpDate = null,
        source = TankLevelSource.fillUp,
        sensorReadAt = null,
        rangeKm = null,
        rangeKmLastInterval = null;

  /// The range figure the UI leads with (#3764): the last closed
  /// window's projection when one exists, else the long-run average
  /// (which itself falls back to the fleet default inside the
  /// estimator) — so a history without a closed interval behaves
  /// exactly as before #3764.
  double? get primaryRangeKm => rangeKmLastInterval ?? rangeKm;

  /// True when the estimator returned a real estimate rather than the
  /// [unknown] sentinel.
  bool get hasFillUp => lastFillUpDate != null;
}

/// Compute the current tank level for a vehicle — v2 model (#3647).
///
/// ## The model, per the maintainer directive (2026-08-01)
///
/// > Eine Tankfüllung mit dem Flag voll muss den Tank auf 100 % füllen.
/// > Der OBD2 soll dann den Tankinhalt tracken. Aber die Tankfüllung hat
/// > Priorität. Die Aufzeichnungen laufen separat und sollen nicht mehr
/// > bei der Berechnung des Tankinhaltes einbezogen werden.
///
/// 1. **Fill-ups anchor.** The most recent physical fill sets the
///    level: full → capacity (100 %); partial → the OBD2-measured
///    post-pump level (`fuelLevelAfterL`, #1401) when captured, else
///    `fuelLevelBeforeL + liters`, else the previous fill-chain anchor
///    plus the pumped litres (an upper bound — no consumption model
///    exists between fills any more, and the clamp keeps it inside the
///    tank).
/// 2. **The sensor tracks between fills.** A persisted OBD2 reading
///    ([sensor]) NEWER than the most recent fill overrides the anchor
///    — the car's own gauge is the ground truth once driving resumes.
///    A reading older than the fill is ignored: the fill has priority.
/// 3. **Trip recordings are not consulted at all.** The previous model
///    subtracted per-trip consumption estimates; on the reference
///    vehicle those ran 43 % above pump truth and drifted the gauge by
///    4–5 L per tank. v2 shows last known ground truth instead of a
///    simulation — a car with no sensor source simply holds the fill
///    anchor until the next fill, which is honest.
///
/// `isCorrection` entries (#1361) are synthetic book-keeping, not
/// physical fuel — they never move the level and never count as "the
/// most recent fill".
///
/// The range estimate stays recording-free: fill-anchored tank-to-tank
/// average (#3645), falling back to the 7.0 fleet default.
TankLevelEstimate estimateTankLevel({
  required VehicleProfile vehicle,
  required List<FillUp> fillUps,
  Obd2FuelLevelSnapshot? sensor,
}) {
  // Physical fills only, newest first (callers hand the list newest
  // first; corrections are filtered here so no caller can forget).
  final physical =
      fillUps.where((f) => !f.isCorrection).toList(growable: false);
  if (physical.isEmpty) {
    return const TankLevelEstimate.unknown();
  }

  final lastFill = physical.first;
  final capacityL = vehicle.tankCapacityL;
  final upperBound = capacityL ?? double.infinity;

  final anchorL = _anchorAfterFill(physical, capacityL).clamp(0.0, upperBound);

  // Sensor override — only when the reading postdates the fill (the
  // fill has priority over anything the sensor said before the pump).
  final double levelL;
  final TankLevelSource source;
  final DateTime? sensorReadAt;
  if (sensor != null && sensor.at.isAfter(lastFill.date)) {
    levelL = sensor.liters.clamp(0.0, upperBound);
    source = TankLevelSource.obd2Sensor;
    sensorReadAt = sensor.at;
  } else {
    levelL = anchorL;
    source = TankLevelSource.fillUp;
    sensorReadAt = null;
  }

  // #3645 — range from the tank-to-tank truth (pumped litres ÷ odometer
  // between full fills). Recording-free by construction; the trip
  // aggregate deliberately no longer participates (#3647).
  final avgLPer100Km =
      fillAnchoredAvgLPer100Km(fillUps)?.avgLPer100Km ?? _defaultAvgLPer100Km;
  final rangeKm = avgLPer100Km > 0 ? (levelL / avgLPer100Km) * 100.0 : null;

  // #3764 — the PRIMARY range projects at the LAST closed window's
  // consumption alone: maxWindows 1 keeps only the most recent valid
  // plein-to-plein window, i.e. "the km this reservoir conducts at the
  // last per-100 km consumption". Null (no closed window yet) → the UI
  // leads with the long-run figure above, the pre-#3764 behaviour.
  final lastWindow = fillAnchoredAvgLPer100Km(fillUps, maxWindows: 1);
  final rangeKmLastInterval =
      (lastWindow != null && lastWindow.avgLPer100Km > 0)
          ? (levelL / lastWindow.avgLPer100Km) * 100.0
          : null;

  return TankLevelEstimate(
    levelL: levelL,
    capacityL: capacityL,
    lastFillUpDate: lastFill.date,
    source: source,
    sensorReadAt: sensorReadAt,
    rangeKm: rangeKm,
    rangeKmLastInterval: rangeKmLastInterval,
  );
}

/// The level right after the most recent physical fill, walking the
/// fill chain only — no trips, no consumption model (#3647).
///
/// Full fill → capacity (or the pumped litres when no capacity is
/// configured — "the tank holds at least what was just pumped").
/// Partial → best available truth, in order: the sensor's post-pump
/// reading, the sensor's pre-pump reading + litres, or the previous
/// anchor + litres (an upper bound; the caller's clamp bounds it by
/// capacity). The chain recurses through at most the fills back to the
/// nearest full fill — everything older cannot change the answer.
double _anchorAfterFill(List<FillUp> physical, double? capacityL) {
  final fill = physical.first;

  if (fill.isFullTank) {
    return capacityL ?? fill.liters;
  }

  final after = fill.fuelLevelAfterL;
  if (after != null && after >= 0) return after;

  final before = fill.fuelLevelBeforeL;
  if (before != null && before >= 0) return before + fill.liters;

  final rest = physical.sublist(1);
  if (rest.isEmpty) {
    // Partials-only history with no sensor data: the pumped litres are
    // the only thing we know is in the tank.
    return fill.liters;
  }
  return _anchorAfterFill(rest, capacityL) + fill.liters;
}
