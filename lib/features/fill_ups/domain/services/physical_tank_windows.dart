// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../../core/domain/fuel_type.dart';
import '../entities/fill_up.dart';

// Existing report/reference plausibility guards, now shared (#4469).
const _minDistanceKm = 3.0;
const _maxDistanceKm = 3000.0;
const _minConsumption = 1.0;
const _maxConsumption = 35.0;

/// Why an interval cannot serve as pump-measured consumption (#4469).
enum PhysicalWindowRejection {
  missingFullAnchor,
  invalidQuantity,
  invalidOdometer,
  ambiguousFills,
  unsupportedTankCombination,
  implausibleConsumption,
}

/// One qualified physical interval. Corrections remain available for
/// accounting, but never enter [liters] or establish a boundary.
class PhysicalTankWindow {
  const PhysicalTankWindow(
    this.opening,
    this.closing,
    this.fills,
    this.distanceKm,
    this.liters,
  );

  final FillUp opening;
  final FillUp closing;
  final List<FillUp> fills;
  final double distanceKm;
  final double liters;
  double get lPer100Km => liters / distanceKm * 100;
}

/// Qualified windows, unfinished records and reasons evidence was withheld.
class PhysicalTankWindows {
  const PhysicalTankWindows(this.closed, this.pending, this.rejections);
  final List<PhysicalTankWindow> closed;
  final List<FillUp> pending;
  final Set<PhysicalWindowRejection> rejections;
}

/// A deterministic event order shared with accounting consumers.
int comparePhysicalFills(FillUp a, FillUp b) {
  final date = a.date.compareTo(b.date);
  return date != 0 ? date : a.id.compareTo(b.id);
}

/// Reconstruct the existing full-to-full reference once for all consumers.
/// Histories with different vehicle identities are never joined. Identical
/// reimported IDs count once; conflicting copies are explicitly unqualified.
/// Same-family petrol blends remain valid aggregate measurements.
PhysicalTankWindows physicalTankWindows(
  Iterable<FillUp> fills, {
  bool liquidOnly = true,
}) {
  final unique = <String, FillUp>{};
  final rejected = <PhysicalWindowRejection>{};
  for (final f in fills) {
    final old = unique[f.id];
    if (old != null && old != f) {
      rejected.add(PhysicalWindowRejection.ambiguousFills);
    }
    unique[f.id] = f;
  }
  if (rejected.isNotEmpty) {
    return PhysicalTankWindows(const [], const [], rejected);
  }
  // Existing single-vehicle histories include legacy unassigned fills.
  // Never credit such an entry to several explicitly identified cars.
  final vehicles = unique.values.map((f) => f.vehicleId).nonNulls.toSet();
  final legacyVehicle = vehicles.length == 1 ? vehicles.single : null;
  final groups = <String?, List<FillUp>>{};
  for (final f in unique.values) {
    (groups[f.vehicleId ?? legacyVehicle] ??= []).add(f);
  }
  final closed = <PhysicalTankWindow>[];
  final pending = <FillUp>[];
  for (final group in groups.values) {
    group.sort(comparePhysicalFills);
    _walk(group, closed, pending, rejected, liquidOnly);
  }
  closed.sort((a, b) => comparePhysicalFills(a.closing, b.closing));
  pending.sort(comparePhysicalFills);
  return PhysicalTankWindows(closed, pending, rejected);
}

void _walk(
  List<FillUp> sorted,
  List<PhysicalTankWindow> closed,
  List<FillUp> pending,
  Set<PhysicalWindowRejection> rejected,
  bool liquidOnly,
) {
  FillUp? opening;
  final inside = <FillUp>[];
  // A same-time partial may sort AFTER the closing ID. Detect collisions
  // before walking, otherwise that partial disappears from a "valid" tank.
  final seenTimes = <DateTime>{};
  final ambiguousTimes = <DateTime>{};
  for (final f in sorted.where((f) => !f.isCorrection)) {
    if (!seenTimes.add(f.date)) ambiguousTimes.add(f.date);
  }
  for (final fill in sorted) {
    if (opening == null) {
      if (!fill.isCorrection && fill.isFullTank) {
        opening = fill;
        inside.clear();
      } else {
        inside.add(fill);
        rejected.add(PhysicalWindowRejection.missingFullAnchor);
      }
      continue;
    }
    inside.add(fill);
    if (fill.isCorrection || !fill.isFullTank) continue;
    final physical = [opening, ...inside.where((f) => !f.isCorrection)];
    final reason = physical.any((f) => ambiguousTimes.contains(f.date))
        ? PhysicalWindowRejection.ambiguousFills
        : _rejection(physical, liquidOnly);
    if (reason == null) {
      closed.add(
        PhysicalTankWindow(
          opening,
          fill,
          List.unmodifiable(inside),
          fill.odometerKm - opening.odometerKm,
          inside
              .where((f) => !f.isCorrection)
              .fold(0.0, (n, f) => n + f.liters),
        ),
      );
    } else {
      rejected.add(reason);
    }
    opening = fill;
    inside.clear();
  }
  pending.addAll(inside);
}

PhysicalWindowRejection? _rejection(List<FillUp> physical, bool liquidOnly) {
  if (physical.any((f) => !f.liters.isFinite || f.liters <= 0)) {
    return PhysicalWindowRejection.invalidQuantity;
  }
  final family = fuelCompatibilityFamily(physical.first.fuelType);
  if (physical.any(
    (f) =>
        f.fuelType == FuelType.all ||
        (liquidOnly &&
            (f.fuelType == FuelType.cng ||
                f.fuelType == FuelType.hydrogen ||
                f.fuelType == FuelType.electric)) ||
        fuelCompatibilityFamily(f.fuelType) != family,
  )) {
    return PhysicalWindowRejection.unsupportedTankCombination;
  }
  for (var i = 0; i < physical.length; i++) {
    final f = physical[i];
    if (!f.odometerKm.isFinite ||
        f.odometerKm <= 0 ||
        (i > 0 && f.odometerKm <= physical[i - 1].odometerKm)) {
      return PhysicalWindowRejection.invalidOdometer;
    }
    if (i > 0 && !f.date.isAfter(physical[i - 1].date)) {
      return PhysicalWindowRejection.ambiguousFills;
    }
  }
  final km = physical.last.odometerKm - physical.first.odometerKm;
  final liters = physical.skip(1).fold(0.0, (n, f) => n + f.liters);
  final rate = liters / km * 100;
  if (!liters.isFinite ||
      !km.isFinite ||
      !rate.isFinite ||
      km <= _minDistanceKm ||
      km > _maxDistanceKm ||
      rate < _minConsumption ||
      rate > _maxConsumption) {
    return PhysicalWindowRejection.implausibleConsumption;
  }
  return null;
}
