// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/comparison_eligibility.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_evidence.dart';
import 'package:tankstellen/core/domain/fuel/fuel_quantity_unit.dart';

/// #4364 — the contract's own invariants, the ones #4365/#4366/#4367
/// are allowed to rely on.
void main() {
  group('an absent metric is never zero', () {
    test('unavailable carries no value at all', () {
      final m = ComparableMetric<double>.unavailable(
          ComparisonUnavailableReason.mixedCurrencies);

      expect(m.eligibility, MetricEligibility.unavailable);
      expect(m.valueOrNull, isNull);
      expect(m.figure, isNull);
      expect(m.isComparable, isFalse);
      expect(m.reason, ComparisonUnavailableReason.mixedCurrencies);
    });

    test('a comparable metric must actually carry a value', () {
      expect(
        () => ComparableMetric<double>.comparable(
            const DataValue.unknown(reason: DataUnknownReason.notMeasuredYet)),
        throwsArgumentError,
      );
    });
  });

  group('a qualification cannot be dropped', () {
    test('qualified without a qualification is rejected', () {
      expect(
        () => ComparableMetric<double>.qualified(
            const DataValue.measured(6.1),
            qualifications: const {}),
        throwsArgumentError,
      );
    });

    test('qualifiedBy downgrades a comparable metric', () {
      final m = ComparableMetric<double>.comparable(
              const DataValue.measured(6.1))
          .qualifiedBy({ComparisonQualification.uncontrolledConditions});

      expect(m.eligibility, MetricEligibility.qualified);
      expect(m.valueOrNull, 6.1);
      expect(m.qualifications,
          contains(ComparisonQualification.uncontrolledConditions));
    });

    test('qualifiedBy never promotes an unavailable metric', () {
      final m = ComparableMetric<double>.unavailable(
              ComparisonUnavailableReason.noEvidence)
          .qualifiedBy({ComparisonQualification.excludedRecords});

      expect(m.eligibility, MetricEligibility.unavailable);
      expect(m.valueOrNull, isNull);
    });
  });

  group('provenance travels with the value', () {
    test('an estimated figure keeps its DataValue basis', () {
      final m = ComparableMetric<double>.qualified(
        const DataValue.estimated(6.1, basis: DataBasis.derived),
        qualifications: const {ComparisonQualification.estimatedBasis},
      );

      expect(m.figure, isA<Estimated<double>>());
      expect((m.figure! as Estimated<double>).basis, DataBasis.derived);
    });
  });

  group('coverage', () {
    test('zero-valued exclusions are dropped, real ones counted', () {
      final coverage = ComparisonCoverage(
        tripCount: 3,
        windowCount: 2,
        coveredKm: 900,
        coveredTime: const Duration(hours: 12),
        conditionCoverage: 0,
        exclusions: const {
          ComparisonExclusion.unassignedVehicle: 1,
          ComparisonExclusion.missingPrice: 2,
          ComparisonExclusion.virtualRecord: 0,
        },
        conditionShares: const {DrivingCondition.coldStart: 0.25},
        provenance: const {EvidenceTier.measured: 3},
      );

      expect(coverage.excludedCount, 3);
      expect(coverage.exclusions.containsKey(ComparisonExclusion.virtualRecord),
          isFalse);
      expect(coverage.hasEvidence, isTrue);
      expect(coverage.toJson()['coveredSeconds'], 12 * 3600);
    });

    test('measured and estimated evidence are counted apart, never pooled',
        () {
      final coverage = ComparisonCoverage(provenance: const {
        EvidenceTier.measured: 4,
        EvidenceTier.estimated: 9,
      });

      expect(coverage.provenance[EvidenceTier.measured], 4);
      expect(coverage.provenance[EvidenceTier.estimated], 9);
    });
  });

  group('quantity units', () {
    test('the price mask names the quantity unit', () {
      expect(FuelQuantityUnit.fromPriceUnit('EUR/L'), FuelQuantityUnit.litre);
      expect(
          FuelQuantityUnit.fromPriceUnit('EUR/kg'), FuelQuantityUnit.kilogram);
      expect(FuelQuantityUnit.fromPriceUnit('EUR/kWh'),
          FuelQuantityUnit.kilowattHour);
      expect(FuelQuantityUnit.fromPriceUnit(''), FuelQuantityUnit.unknown);
    });

    test('only litre-based quantities may run through an L/100 km formula',
        () {
      expect(FuelQuantityUnit.litre.isLitreBased, isTrue);
      expect(FuelQuantityUnit.kilogram.isLitreBased, isFalse);
      expect(FuelQuantityUnit.kilowattHour.isLitreBased, isFalse);
    });

    test('mixed units share none', () {
      expect(
          commonFuelQuantityUnit(
              const [FuelQuantityUnit.litre, FuelQuantityUnit.litre]),
          FuelQuantityUnit.litre);
      expect(
          commonFuelQuantityUnit(
              const [FuelQuantityUnit.litre, FuelQuantityUnit.kilogram]),
          isNull);
      expect(commonFuelQuantityUnit(const []), isNull);
    });
  });

  test('the three money valuations are distinct, named quantities', () {
    expect(MoneyValuationBasis.values, hasLength(3));
    expect(
        MoneyValuationBasis.recordedPurchaseSpend ==
            MoneyValuationBasis.modelledConsumedFuel,
        isFalse);
  });
}
