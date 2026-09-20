// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/fleet/claim_class.dart';
import 'package:tankstellen/core/domain/fleet/emission_factor_registry.dart';
import 'package:tankstellen/core/domain/fleet/fleet_provenance.dart';
import 'package:tankstellen/core/domain/fleet/fleet_refuel_policy.dart';
import 'package:tankstellen/core/domain/fleet/vehicle_choice_comparison.dart';
import 'package:tankstellen/core/domain/fuel/behaviour_metric.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_evidence.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_profile.dart';
import 'package:tankstellen/core/domain/fuel/fuel_context.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';

/// #4214 (F6) — comparing the assigned vehicles for one planned journey.
///
/// The two rules that cannot bend: an estimate is never promoted to a
/// measured fact, and a CO2e figure without a published factor is "not
/// calculated" — never zero, never a neighbour's factor.
void main() {
  ClaimedValue<double> price(double perLitre) => ClaimedValue.estimate(
        perLitre,
        basis: DataBasis.fleetAverage,
        source: FleetMetricSource.imported,
      );

  ConsumptionEstimate measuredEcu(double lPer100Km) => ConsumptionEstimate(
        litresPer100Km: DataValue.measured(lPer100Km),
        sourceClass: ConsumptionSourceClass.measured,
      );

  ConsumptionEstimate gpsOnly(double lPer100Km) => ConsumptionEstimate(
        litresPer100Km:
            DataValue.estimated(lPer100Km, basis: DataBasis.derived),
        sourceClass: ConsumptionSourceClass.gpsOnly,
      );

  FuelBehaviourProfile behaviourWith({
    required FuelContext context,
    required BehaviourMetric adjusted,
    required BehaviourMetric absolute,
  }) =>
      FuelBehaviourProfile(
        contexts: {
          context: FuelContextBehaviour(
            context: context,
            lPer100Km: absolute,
            residualRatio:
                const BehaviourMetric.insufficient(InsufficientReason.noEvidence),
            conditionAdjustedLPer100Km: adjusted,
            costPerKm:
                const BehaviourMetric.insufficient(InsufficientReason.noEvidence),
            costPer100Km:
                const BehaviourMetric.insufficient(InsufficientReason.noEvidence),
            rangeKm: const BehaviourMetric.insufficient(
                InsufficientReason.capacityUnknown),
            co2eKgPerKm: const BehaviourMetric.insufficient(
                InsufficientReason.noCo2eFactor),
            co2eFactor: null,
            provenance: const <EvidenceTier, int>{},
            exclusions: const <EvidenceExclusion, int>{},
            tripDistanceKm: 900,
            windowDistanceKm: 0,
            residualCoverage: 0,
            conditionShares: const <DrivingCondition, double>{},
          ),
        },
        typicalExpectedLPer100Km:
            const BehaviourMetric.insufficient(InsufficientReason.noEvidence),
        unattributed: const <EvidenceTier, int>{},
        consumptionVersions: const <ConsumptionModelVersion>[],
        blendModelVersion: 1,
      );

  group('determinism', () {
    test('the same inputs produce an equal comparison', () {
      final vehicles = [
        FleetVehicleOption(
          vehicleId: 'v1',
          fuelKey: 'diesel',
          consumption: measuredEcu(6.2),
          pricePerLitre: price(1.72),
          usableFuelLitres: 40,
        ),
        FleetVehicleOption(
          vehicleId: 'v2',
          fuelKey: 'e10',
          consumption: gpsOnly(7.4),
          pricePerLitre: price(1.81),
          usableFuelLitres: 12,
        ),
      ];

      final a = compareVehicleChoices(
          plannedDistanceKm: 240, vehicles: vehicles);
      final b = compareVehicleChoices(
          plannedDistanceKm: 240, vehicles: vehicles);

      expect(b.outcomes, a.outcomes);
      expect(b.excluded, a.excluded);
      expect([for (final o in a.outcomes) o.vehicleId], ['v1', 'v2']);
    });
  });

  group('an estimate is never promoted to measured', () {
    test('a GPS-only figure stays an estimate and never renders as '
        'measured', () {
      final result = compareVehicleChoices(
        plannedDistanceKm: 100,
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'e10',
            consumption: gpsOnly(7.0),
            pricePerLitre: price(1.80),
          ),
        ],
      );

      final o = result.outcomes.single;
      expect(o.litresPer100Km.claim, ClaimClass.estimate);
      expect(o.litresPer100Km.rendersAsMeasured, isFalse);
      expect(o.litresPer100Km.isQualified, isTrue);
      expect(o.litresPer100Km.provenance,
          contains(FleetMetricSource.gpsEstimated));
      expect(o.costPerKm.claim, ClaimClass.estimate,
          reason: 'cost built on an estimate is an estimate, not class 2');
      expect(o.costPerKm.rendersAsMeasured, isFalse);
    });

    test('a native ECU figure is a measured fact and its cost is '
        'calculated-operational', () {
      final result = compareVehicleChoices(
        plannedDistanceKm: 100,
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'diesel',
            consumption: measuredEcu(6.0),
            pricePerLitre: ClaimedValue.measuredFact(
              1.70,
              source: FleetMetricSource.measuredFillUp,
            ),
          ),
        ],
      );

      final o = result.outcomes.single;
      expect(o.litresPer100Km.claim, ClaimClass.measuredFact);
      expect(o.litresPer100Km.rendersAsMeasured, isTrue);
      expect(o.costPerKm.claim, ClaimClass.calculatedOperational);
      expect(o.costPerKm.valueOrNull, closeTo(6.0 / 100 * 1.70, 1e-9));
      expect(o.costForJourney.valueOrNull, closeTo(6.0 * 1.70, 1e-9));
    });

    test('a stale measured figure is qualified, not a measured fact', () {
      final result = compareVehicleChoices(
        plannedDistanceKm: 100,
        vehicles: const [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'diesel',
            consumption: ConsumptionEstimate(
              litresPer100Km:
                  DataValue.stale(6.0, age: Duration(days: 400)),
              sourceClass: ConsumptionSourceClass.measured,
            ),
          ),
        ],
      );

      expect(result.outcomes.single.litresPer100Km.claim, ClaimClass.estimate);
    });

    test('no consumption at all is stated, not defaulted', () {
      final result = compareVehicleChoices(
        plannedDistanceKm: 100,
        vehicles: const [
          FleetVehicleOption(vehicleId: 'v1', fuelKey: 'diesel'),
        ],
      );

      final o = result.outcomes.single;
      expect(o.litresPer100Km.valueOrNull, isNull);
      expect(o.litresPer100Km.value,
          isA<Unknown<double>>().having((u) => u.reason, 'reason',
              DataUnknownReason.notMeasuredYet));
      expect(o.costPerKm.valueOrNull, isNull);
      expect(o.co2eKgPerKm.valueOrNull, isNull);
      expect(o.feasibility, RangeFeasibility.unknown);
    });
  });

  group('consumption from a FuelBehaviourProfile (#4276)', () {
    test('the condition-adjusted figure is preferred and is an estimate', () {
      final context = FuelContext.pure(FuelGrade.e10);
      final result = compareVehicleChoices(
        plannedDistanceKm: 100,
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'e10',
            behaviour: behaviourWith(
              context: context,
              adjusted: const BehaviourMetric.known(
                value: 7.2,
                standardError: 0.1,
                lower: 7.0,
                upper: 7.4,
                sampleCount: 9,
                basis: MetricBasis.derived,
              ),
              absolute: const BehaviourMetric.known(
                value: 8.8,
                standardError: 0.2,
                lower: 8.4,
                upper: 9.2,
                sampleCount: 9,
                basis: MetricBasis.referenceWindows,
              ),
            ),
            behaviourContext: context,
          ),
        ],
      );

      final o = result.outcomes.single;
      expect(o.litresPer100Km.valueOrNull, 7.2);
      expect(o.litresPer100Km.claim, ClaimClass.estimate);
      expect(o.litresPer100Km.sampleCount, 9);
    });

    test('a pump-window figure with no adjusted value is '
        'calculated-operational over measured fill-ups', () {
      final context = FuelContext.pure(FuelGrade.diesel);
      final result = compareVehicleChoices(
        plannedDistanceKm: 100,
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'diesel',
            behaviour: behaviourWith(
              context: context,
              adjusted: const BehaviourMetric.insufficient(
                  InsufficientReason.noEvidence),
              absolute: const BehaviourMetric.known(
                value: 6.4,
                standardError: 0.1,
                lower: 6.2,
                upper: 6.6,
                sampleCount: 4,
                basis: MetricBasis.referenceWindows,
              ),
            ),
            behaviourContext: context,
          ),
        ],
      );

      final o = result.outcomes.single;
      expect(o.litresPer100Km.valueOrNull, 6.4);
      expect(o.litresPer100Km.claim, ClaimClass.calculatedOperational);
      expect(o.litresPer100Km.provenance,
          contains(FleetMetricSource.measuredFillUp));
    });
  });

  group('CO2e', () {
    test('a published per-litre factor produces a class-5 estimate', () {
      final result = compareVehicleChoices(
        plannedDistanceKm: 200,
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'diesel',
            consumption: measuredEcu(6.0),
          ),
        ],
      );

      final o = result.outcomes.single;
      expect(o.co2eFactor, isNotNull);
      expect(o.co2eFactor!.scope, EmissionScope.wellToWheel);
      expect(o.co2eKgPerKm.claim, ClaimClass.environmentalEstimate);
      expect(o.co2eKgPerKm.isQualified, isTrue);
      // ADEME Base Carbone v23.6 well-to-wheel diesel, 3.10 kg CO2e/L
      // (#4392 replaced the JEC 2.65 this test was written against —
      // JEC publishes nothing per litre, which is why it was replaced).
      expect(o.co2eKgPerKm.valueOrNull, closeTo(6.0 / 100 * 3.10, 1e-9));
    });

    test('no factor means NOT CALCULATED — never zero', () {
      final result = compareVehicleChoices(
        plannedDistanceKm: 200,
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'hydrogen',
            consumption: measuredEcu(1.2),
          ),
        ],
      );

      final o = result.outcomes.single;
      expect(o.co2eFactor, isNull);
      expect(o.co2eKgPerKm.valueOrNull, isNull);
      expect(o.co2eKgPerKm.valueOrNull, isNot(0));
      expect(o.co2eKgPerKm.claim, ClaimClass.environmentalEstimate);
      expect(
        o.co2eKgPerKm.value,
        isA<Unknown<double>>().having((u) => u.reason, 'reason',
            DataUnknownReason.notPublishedForThisItem),
      );
    });

    test('a factor in the wrong unit is refused rather than misapplied', () {
      final result = compareVehicleChoices(
        plannedDistanceKm: 200,
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'cng',
            consumption: measuredEcu(5.0),
          ),
        ],
      );

      final o = result.outcomes.single;
      expect(o.co2eFactor, isNull,
          reason: 'the CNG factor is per kilogram; litres cannot use it');
      expect(o.co2eKgPerKm.valueOrNull, isNull);
    });

    test('a tank-to-wheel report uses the TtW factor, not the WtW one', () {
      // This test used to assert `isNull`, because the JEC seed
      // published only a well-to-wheel figure. #4392 re-sourced every
      // volume fuel to ADEME Base Carbone v23.6, which publishes BOTH
      // boundaries — so asking for tank-to-wheel now answers, and the
      // thing worth pinning is that it answers with the RIGHT boundary
      // rather than silently reusing the well-to-wheel number.
      final result = compareVehicleChoices(
        plannedDistanceKm: 200,
        scope: EmissionScope.tankToWheel,
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'diesel',
            consumption: measuredEcu(6.0),
          ),
        ],
      );

      final o = result.outcomes.single;
      expect(o.co2eFactor, isNotNull);
      expect(o.co2eFactor!.scope, EmissionScope.tankToWheel);
      // ADEME TtW diesel 2.49 kg CO2e/L — strictly below the 3.10 WtW
      // figure, which is what makes the boundary mix-up detectable.
      expect(o.co2eKgPerKm.valueOrNull, closeTo(6.0 / 100 * 2.49, 1e-9));
      expect(o.co2eKgPerKm.valueOrNull,
          lessThan(6.0 / 100 * 3.10),
          reason: 'tank-to-wheel excludes the upstream pathway, so it '
              'must come out below well-to-wheel');
    });

    test('a scope the source does not publish is still NOT CALCULATED', () {
      // The guarantee the old TtW test was really protecting: a scope
      // with no published factor yields Unknown, never a number. ADEME
      // publishes no factor at all for hydrogen (the app measures no kg
      // of H2), so it is the honest fixture for "absent".
      final result = compareVehicleChoices(
        plannedDistanceKm: 200,
        scope: EmissionScope.tankToWheel,
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'hydrogen',
            consumption: measuredEcu(1.2),
          ),
        ],
      );

      final o = result.outcomes.single;
      expect(o.co2eFactor, isNull);
      expect(o.co2eKgPerKm.valueOrNull, isNull,
          reason: 'never zero — #4219 forbids substituting an '
              'undocumented factor');
    });
  });

  group('range feasibility', () {
    test('enough fuel for the planned distance is sufficient', () {
      final result = compareVehicleChoices(
        plannedDistanceKm: 200,
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'diesel',
            consumption: measuredEcu(6.0),
            usableFuelLitres: 30,
          ),
        ],
      );

      final o = result.outcomes.single;
      expect(o.rangeKm.valueOrNull, closeTo(500, 1e-9));
      expect(o.feasibility, RangeFeasibility.sufficient);
    });

    test('too little fuel means a refuel is required, not a failure', () {
      final result = compareVehicleChoices(
        plannedDistanceKm: 600,
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'diesel',
            consumption: measuredEcu(6.0),
            usableFuelLitres: 30,
          ),
        ],
      );

      expect(result.outcomes.single.feasibility,
          RangeFeasibility.refuelRequired);
    });

    test('an unknown tank level leaves feasibility unknown', () {
      final result = compareVehicleChoices(
        plannedDistanceKm: 600,
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'diesel',
            consumption: measuredEcu(6.0),
          ),
        ],
      );

      final o = result.outcomes.single;
      expect(o.feasibility, RangeFeasibility.unknown);
      expect(
        o.rangeKm.value,
        isA<Unknown<double>>().having((u) => u.reason, 'reason',
            DataUnknownReason.missingVehicleData),
      );
    });
  });

  group('fleet policy', () {
    test('a vehicle whose fuel is not approved is excluded with the '
        'named reason', () {
      final result = compareVehicleChoices(
        plannedDistanceKm: 100,
        policy: const FleetRefuelPolicy(approvedFuelKeys: {'diesel'}),
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'diesel',
            consumption: measuredEcu(6.0),
          ),
          FleetVehicleOption(
            vehicleId: 'v2',
            fuelKey: 'e85',
            consumption: measuredEcu(9.0),
          ),
        ],
      );

      expect([for (final o in result.outcomes) o.vehicleId], ['v1']);
      expect(result.excluded.keys, ['v2']);
      expect(result.excluded['v2']!.reason,
          PolicyExclusionReason.fuelNotApproved);
    });

    test('an empty policy compares every assigned vehicle', () {
      final result = compareVehicleChoices(
        plannedDistanceKm: 100,
        vehicles: [
          FleetVehicleOption(
            vehicleId: 'v1',
            fuelKey: 'e85',
            consumption: measuredEcu(9.0),
          ),
        ],
      );

      expect(result.excluded, isEmpty);
      expect(result.outcomes, hasLength(1));
    });
  });

  test('a non-positive planned distance is rejected', () {
    expect(
      () => compareVehicleChoices(plannedDistanceKm: 0, vehicles: const []),
      throwsArgumentError,
    );
  });
}
