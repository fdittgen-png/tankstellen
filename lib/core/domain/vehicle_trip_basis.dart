// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// What ONE vehicle brings to a proposed journey, and what the journey
/// itself is (#4367, Epic #4358 work package H).
///
/// ## Why the inputs are split in two
///
/// Comparing vehicles over the same trip is only honest when everything
/// that is NOT the vehicle is identical. So the journey — origin and
/// destination, the road distance and duration they imply, the
/// comparison currency, the departure assumption, the driver's extra
/// km/minute limits and the selected objective — lives in
/// [VehicleTripJourney], built once and handed to every column
/// unchanged. Everything that IS the vehicle — its compatible fuel, its
/// own capacity, its own current level, its own reserve and its own
/// consumption evidence — lives in [VehicleTripBasis], one per column.
///
/// The split is what makes rule 5 of the issue checkable by shape: a
/// current level or a reserve cannot be "copied from the active vehicle
/// into every column", because the level and the reserve are fields of
/// the per-vehicle basis and the active vehicle has no privileged
/// position in this file at all.
///
/// ## Equal litres is not an equal starting condition
///
/// [VehicleTripBasis.quantityUnit] carries #4364's unit, so a kg or kWh
/// vehicle is refused rather than relabelled: nothing here divides a
/// kilowatt-hour by 100 km and calls the result litres. The refusal is
/// a [ComparisonUnavailableReason], and the metrics that remain valid
/// for such a vehicle are still shown by the builder.
///
/// ## One request builder, two callers
///
/// [tripPlanRequestFor] is the ONLY place a [RefuelPlanRequest] is
/// assembled from a journey and a vehicle. The single-vehicle station
/// planner (`refuelPlanProvider`) and the multi-vehicle comparison both
/// go through it, which is what makes "the same inputs give the same
/// result in single-vehicle planning and in comparison" a property of
/// the code rather than a coincidence two call sites have to maintain.
library;

import 'package:meta/meta.dart';

import 'comparison_eligibility.dart';
import 'fuel/fuel_quantity_unit.dart';
import 'fuel_type.dart';
import 'refuel_itinerary.dart';
import 'refuel_plan.dart';
import 'vehicle_comparison_key.dart';

/// Where one planning input came from.
///
/// Distinct from [ComparableMetric]'s eligibility axis: this says who
/// produced the number, not whether it may be compared. A manual entry
/// is explicitly allowed as a planning input (#4367) — and explicitly
/// labelled, so no silent fallback can produce a supposedly measured
/// winner.
enum TripInputSource {
  /// Derived from the driver's own records — closed fill windows, the
  /// fill-anchored tank level.
  measured,

  /// Typed by the driver for this comparison. Usable, and always shown
  /// as their own assumption rather than as a measurement.
  manual,

  /// Modelled or taken from a catalogue figure.
  estimated,

  /// No value at all. Never silently replaced by a plausible one.
  unknown,
}

/// The driver's own override of one vehicle's planning inputs.
///
/// Every field is null by default: an assumption that was never made
/// changes nothing. Applying one is [VehicleTripBasis.withAssumption],
/// and it marks exactly the fields it replaced as
/// [TripInputSource.manual].
@immutable
final class VehicleTripAssumption {
  const VehicleTripAssumption({
    this.consumptionLPer100km,
    this.startLitres,
    this.reserveLitres,
  });

  static const VehicleTripAssumption none = VehicleTripAssumption();

  final double? consumptionLPer100km;
  final double? startLitres;
  final double? reserveLitres;

  bool get isEmpty =>
      consumptionLPer100km == null &&
      startLitres == null &&
      reserveLitres == null;

  /// A stable identity, so a changed assumption is a changed key.
  String get signature => '${consumptionLPer100km ?? '*'}'
      '/${startLitres ?? '*'}/${reserveLitres ?? '*'}';

  VehicleTripAssumption copyWith({
    double? consumptionLPer100km,
    double? startLitres,
    double? reserveLitres,
  }) =>
      VehicleTripAssumption(
        consumptionLPer100km:
            consumptionLPer100km ?? this.consumptionLPer100km,
        startLitres: startLitres ?? this.startLitres,
        reserveLitres: reserveLitres ?? this.reserveLitres,
      );

  @override
  bool operator ==(Object other) =>
      other is VehicleTripAssumption &&
      other.consumptionLPer100km == consumptionLPer100km &&
      other.startLitres == startLitres &&
      other.reserveLitres == reserveLitres;

  @override
  int get hashCode =>
      Object.hash(consumptionLPer100km, startLitres, reserveLitres);
}

/// One vehicle's own contribution to the forecast.
@immutable
final class VehicleTripBasis {
  const VehicleTripBasis({
    required this.vehicleId,
    required this.vehicleName,
    required this.fuel,
    this.capacityL,
    this.startLitres,
    this.reserveLitres = kDefaultReserveLitres,
    this.consumptionLPer100km,
    this.consumptionSource = TripInputSource.unknown,
    this.levelSource = TripInputSource.unknown,
    this.reserveSource = TripInputSource.estimated,
    this.qualifications = const {},
  });

  final String vehicleId;

  /// The name the driver gave the car — carried so a plan column can
  /// identify the actual vehicle without a surface reaching back into
  /// the vehicle feature for it.
  final String vehicleName;

  /// The grade THIS vehicle takes. Each column is priced from its own
  /// fuel's offers; a station that does not sell it is not a candidate.
  /// Null when the profile declares none — then nothing is planned for
  /// it, and no other vehicle's fuel is borrowed to fill the hole.
  final FuelType? fuel;

  /// The unit [fuel] is sold in (#4364), read from the ONE table that
  /// owns it. A non-litre unit makes the litre arithmetic unavailable
  /// rather than relabelled.
  FuelQuantityUnit get quantityUnit {
    final grade = fuel;
    return grade == null
        ? FuelQuantityUnit.unknown
        : FuelQuantityUnit.fromPriceUnit(grade.unit);
  }

  final double? capacityL;

  /// What is in THIS tank now. Never the active vehicle's level.
  final double? startLitres;

  /// Litres this vehicle refuses to dip below.
  final double reserveLitres;

  final double? consumptionLPer100km;

  final TripInputSource consumptionSource;
  final TripInputSource levelSource;
  final TripInputSource reserveSource;

  /// Caveats the evidence already carried, forwarded to every figure
  /// derived from it (#4364/#4366) — a stale or uncontrolled
  /// consumption stays stale and uncontrolled in the forecast.
  final Set<ComparisonQualification> qualifications;

  /// Whether the driver typed any part of this basis themselves.
  bool get isManual =>
      consumptionSource == TripInputSource.manual ||
      levelSource == TripInputSource.manual ||
      reserveSource == TripInputSource.manual;

  /// Whether any part of it is a model rather than a measurement.
  bool get isEstimated =>
      consumptionSource == TripInputSource.estimated ||
      levelSource == TripInputSource.estimated;

  /// Why this vehicle cannot be planned for at all, or null.
  ///
  /// Ordered so the most specific answer wins: an unsupported unit is a
  /// statement about the vehicle, a missing input is a statement about
  /// the records.
  ComparisonUnavailableReason? get blocker {
    if (fuel == null) return ComparisonUnavailableReason.noEvidence;
    if (!quantityUnit.isLitreBased) {
      return ComparisonUnavailableReason.unsupportedUnit;
    }
    final consumption = consumptionLPer100km;
    final capacity = capacityL;
    final start = startLitres;
    if (consumption == null || consumption <= 0 || !consumption.isFinite) {
      return ComparisonUnavailableReason.noEvidence;
    }
    if (capacity == null || capacity <= 0 || !capacity.isFinite) {
      return ComparisonUnavailableReason.noEvidence;
    }
    if (start == null || start < 0 || !start.isFinite) {
      return ComparisonUnavailableReason.noEvidence;
    }
    if (!reserveLitres.isFinite ||
        reserveLitres < 0 ||
        reserveLitres >= capacity) {
      return ComparisonUnavailableReason.noEvidence;
    }
    return null;
  }

  bool get isPlannable => blocker == null;

  /// This basis with [assumption] applied. Only the fields the driver
  /// actually supplied change, and each of them becomes
  /// [TripInputSource.manual] — the label is not optional.
  VehicleTripBasis withAssumption(VehicleTripAssumption assumption) {
    if (assumption.isEmpty) return this;
    return VehicleTripBasis(
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      fuel: fuel,
      capacityL: capacityL,
      startLitres: assumption.startLitres ?? startLitres,
      reserveLitres: assumption.reserveLitres ?? reserveLitres,
      consumptionLPer100km:
          assumption.consumptionLPer100km ?? consumptionLPer100km,
      consumptionSource: assumption.consumptionLPer100km != null
          ? TripInputSource.manual
          : consumptionSource,
      levelSource: assumption.startLitres != null
          ? TripInputSource.manual
          : levelSource,
      reserveSource: assumption.reserveLitres != null
          ? TripInputSource.manual
          : reserveSource,
      qualifications: qualifications,
    );
  }

  /// A stable identity for caching: every field a plan depends on.
  String get signature => '$vehicleId/${fuel?.apiValue ?? '*'}'
      '/${quantityUnit.name}'
      '/${capacityL ?? '*'}/${startLitres ?? '*'}/$reserveLitres'
      '/${consumptionLPer100km ?? '*'}/${consumptionSource.name}'
      '/${levelSource.name}/${reserveSource.name}';
}

/// The proposed journey, identical for every compared vehicle.
@immutable
final class VehicleTripJourney {
  const VehicleTripJourney({
    required this.routeKm,
    required this.drivingMinutes,
    required this.currencyCode,
    required this.departAt,
    this.limits = TravelLimits.none,
    this.objective = RefuelObjective.lowestCost,
    this.routeRevision = 0,
  });

  /// The polyline's own length — the same measurement the stop
  /// positions are projected onto.
  final double routeKm;

  final double drivingMinutes;

  /// The ONE currency every column's money is denominated in (#4361).
  final String currencyCode;

  /// When the driver intends to leave. Injected through the `AppClock`
  /// seam; this layer reads no wall clock.
  final DateTime departAt;

  final TravelLimits limits;

  /// Which plan of each vehicle's set the columns are compared on.
  final RefuelObjective objective;

  /// Changes whenever the route itself does, so a recomputed route is a
  /// different question even between the same two points.
  final int routeRevision;

  bool get isComputable =>
      routeKm.isFinite && routeKm > 0 && drivingMinutes.isFinite;

  String get signature => '$routeKm/$drivingMinutes/$currencyCode'
      '/${departAt.toIso8601String()}/${limits.maxExtraKm ?? '*'}'
      '/${limits.maxExtraMinutes ?? '*'}/${objective.name}/$routeRevision';
}

/// What identifies ONE same-trip comparison.
///
/// Reuses #4365's [VehicleComparisonKey] for the vehicle half — the same
/// normalisation, so `[b,a]` and `[a,b]` are one question — and adds the
/// journey and the per-vehicle assumptions, because the same cars over a
/// different road, or under a different typed consumption, is a
/// different answer and must never be served from the same cache slot.
@immutable
final class VehicleTripComparisonKey {
  const VehicleTripComparisonKey({
    required this.vehicles,
    required this.journey,
    this.basisSignature = '',
  });

  final VehicleComparisonKey vehicles;
  final VehicleTripJourney journey;

  /// The per-vehicle bases and assumptions this answer was built from.
  final String basisSignature;

  bool get isComparable => vehicles.isComparable;

  String get signature =>
      '${vehicles.signature}|${journey.signature}|$basisSignature';

  @override
  bool operator ==(Object other) =>
      other is VehicleTripComparisonKey && other.signature == signature;

  @override
  int get hashCode => signature.hashCode;

  @override
  String toString() => 'VehicleTripComparisonKey($signature)';
}

/// The one assembly of a [RefuelPlanRequest] from a journey and a
/// vehicle. See the library doc for why there is exactly one.
///
/// Returns null when [basis] cannot be planned for — the caller says
/// what is missing rather than planning with an invented input.
RefuelPlanRequest? tripPlanRequestFor(
  VehicleTripJourney journey,
  VehicleTripBasis basis,
  List<PlanCandidate> candidates,
) {
  if (!journey.isComputable || !basis.isPlannable) return null;
  return RefuelPlanRequest(
    routeKm: journey.routeKm,
    drivingMinutes: journey.drivingMinutes,
    tankCapacityL: basis.capacityL!,
    startLitres: basis.startLitres!,
    consumptionLPer100km: basis.consumptionLPer100km!,
    candidates: candidates,
    reserveLitres: basis.reserveLitres,
    currencyCode: journey.currencyCode,
    limits: journey.limits,
  );
}
