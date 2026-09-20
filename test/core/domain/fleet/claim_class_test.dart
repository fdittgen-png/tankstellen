// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/fleet/claim_class.dart';
import 'package:tankstellen/core/domain/fleet/fleet_provenance.dart';

/// #4219 — a fleet number declares what it is, and the type makes the
/// two forbidden moves impossible: an estimate can never render as
/// measured, and a missing input can never become a numeric claim.
void main() {
  final measuredLitres = ClaimedValue<double>.measuredFact(40.0,
      source: FleetMetricSource.measuredFillUp);
  final measuredKm = ClaimedValue<double>.measuredFact(500.0,
      source: FleetMetricSource.obdMeasured, sampleCount: 3);
  final estimatedLitres = ClaimedValue<double>.estimate(41.5,
      basis: DataBasis.derived, source: FleetMetricSource.gpsEstimated);

  group('the six claim classes', () {
    test('are exactly #4219\'s list, in its order', () {
      expect(ClaimClass.values, const [
        ClaimClass.measuredFact,
        ClaimClass.calculatedOperational,
        ClaimClass.estimate,
        ClaimClass.accountingCandidate,
        ClaimClass.environmentalEstimate,
        ClaimClass.personalDataInference,
      ]);
    });

    test('classes 3 and 5 are always rendered qualified', () {
      final qualified =
          ClaimClass.values.where((c) => c.alwaysQualified).toSet();
      expect(qualified,
          {ClaimClass.estimate, ClaimClass.environmentalEstimate});
      expect(ClaimClass.accountingCandidate.requiresConfirmation, isTrue);
      expect(ClaimClass.personalDataInference.isPersonalData, isTrue);
      expect(ClaimClass.measuredFact.requiresConfirmation, isFalse);
    });
  });

  group('a measured fact is a measured fact', () {
    test('requires an observed value AND an observed source', () {
      expect(measuredLitres.claim, ClaimClass.measuredFact);
      expect(measuredLitres.rendersAsMeasured, isTrue);
      expect(measuredLitres.isQualified, isFalse);
      expect(measuredLitres.valueOrNull, 40.0);
    });

    test('refuses an estimating source', () {
      expect(
        () => ClaimedValue<double>(const DataValue.measured(40.0),
            claim: ClaimClass.measuredFact,
            provenance: const [FleetMetricSource.gpsEstimated]),
        throwsArgumentError,
      );
      expect(
        () => ClaimedValue<double>.measuredFact(40.0,
            source: FleetMetricSource.obdEstimated),
        throwsArgumentError,
      );
    });

    test('refuses a modelled value', () {
      expect(
        () => ClaimedValue<double>(
            const DataValue.estimated(40.0, basis: DataBasis.fleetAverage),
            claim: ClaimClass.measuredFact,
            provenance: const [FleetMetricSource.measuredFillUp]),
        throwsArgumentError,
      );
    });

    test('refuses an import that nobody confirmed, accepts a confirmed one',
        () {
      expect(
        () => ClaimedValue<double>(const DataValue.measured(40.0),
            claim: ClaimClass.measuredFact,
            provenance: const [FleetMetricSource.imported]),
        throwsArgumentError,
      );
      final confirmed = ClaimedValue<double>(const DataValue.measured(40.0),
          claim: ClaimClass.measuredFact,
          provenance: const [
            FleetMetricSource.imported,
            FleetMetricSource.measuredFillUp,
          ]);
      expect(confirmed.rendersAsMeasured, isTrue);
      expect(confirmed.provenance, contains(FleetMetricSource.imported));
    });

    test('refuses an empty provenance for a known value', () {
      expect(
        () => ClaimedValue<double>(const DataValue.measured(1.0),
            claim: ClaimClass.calculatedOperational),
        throwsArgumentError,
      );
    });
  });

  group('map keeps the class and the provenance', () {
    test('on a measured fact', () {
      final ml = measuredLitres.map((l) => l * 1000);
      expect(ml.claim, ClaimClass.measuredFact);
      expect(ml.value, const DataValue.measured(40000.0));
      expect(ml.provenance, measuredLitres.provenance);
      expect(ml.sampleCount, measuredLitres.sampleCount);
    });

    test('on an estimate — it stays an estimate', () {
      final doubled = estimatedLitres.map((l) => l * 2);
      expect(doubled.claim, ClaimClass.estimate);
      expect(doubled.rendersAsMeasured, isFalse);
      expect(doubled.isQualified, isTrue);
    });

    test('on an unknown — it stays unknown with its reason', () {
      final missing = ClaimedValue<double>.notCalculated(
          reason: DataUnknownReason.notMeasuredYet,
          claim: ClaimClass.calculatedOperational);
      final mapped = missing.map((v) => v + 1);
      expect(mapped.value,
          const DataValue<double>.unknown(reason: DataUnknownReason.notMeasuredYet));
      expect(mapped.valueOrNull, isNull);
    });
  });

  group('derive — calculated metrics inherit the weakest input', () {
    double costPerKm(List<Object?> v) => (v[0]! as double) / (v[1]! as double);

    test('measured inputs give a calculated operational metric', () {
      final out = ClaimedValue.derive<double>(
          [measuredLitres, measuredKm], costPerKm,
          claim: ClaimClass.calculatedOperational);
      expect(out.claim, ClaimClass.calculatedOperational);
      expect(out.value, const DataValue.measured(0.08));
      expect(out.isQualified, isFalse);
      // The weakest evidence count travels, not the sum.
      expect(out.sampleCount, 1);
      expect(out.provenance, const [
        FleetMetricSource.measuredFillUp,
        FleetMetricSource.obdMeasured,
        FleetMetricSource.derived,
      ]);
    });

    test('one estimated input degrades the result to an estimate', () {
      final out = ClaimedValue.derive<double>(
          [estimatedLitres, measuredKm], costPerKm,
          claim: ClaimClass.calculatedOperational);
      expect(out.claim, ClaimClass.estimate,
          reason: 'calculatedOperational over an estimate is an estimate');
      expect(out.value,
          const DataValue.estimated(0.083, basis: DataBasis.derived));
      expect(out.rendersAsMeasured, isFalse);
      expect(out.isQualified, isTrue);
    });

    test('a stale input is qualified too', () {
      final stale = ClaimedValue<double>(
          const DataValue.stale(500.0, age: Duration(days: 40)),
          claim: ClaimClass.measuredFact,
          provenance: const [FleetMetricSource.obdMeasured]);
      // A stale value is still an observation, so the fact stands …
      expect(stale.claim, ClaimClass.measuredFact);
      // … but anything built on it is qualified.
      final out = ClaimedValue.derive<double>(
          [measuredLitres, stale], costPerKm,
          claim: ClaimClass.calculatedOperational);
      expect(out.claim, ClaimClass.estimate);
      expect(out.value, isA<Estimated<double>>());
    });

    test('a derivation can never be requested as a measured fact', () {
      expect(
        () => ClaimedValue.derive<double>(
            [measuredLitres, measuredKm], costPerKm,
            claim: ClaimClass.measuredFact),
        throwsArgumentError,
      );
    });

    test('refuses an empty input list', () {
      expect(
        () => ClaimedValue.derive<double>(const [], (_) => 1.0,
            claim: ClaimClass.calculatedOperational),
        throwsArgumentError,
      );
    });

    test('an unknown input yields an unknown result with the reason, '
        'and the compute function never runs', () {
      final noFactor = ClaimedValue<double>.notCalculated(
          reason: DataUnknownReason.notPublishedForThisItem,
          claim: ClaimClass.environmentalEstimate);
      var ran = false;
      final out = ClaimedValue.derive<double>(
        [measuredLitres, noFactor],
        (_) {
          ran = true;
          return 1.0;
        },
        claim: ClaimClass.environmentalEstimate,
      );
      expect(ran, isFalse);
      expect(out.value,
          const DataValue<double>.unknown(
              reason: DataUnknownReason.notPublishedForThisItem));
      expect(out.valueOrNull, isNull, reason: 'no numeric claim, ever');
      expect(out.claim, ClaimClass.environmentalEstimate);
      expect(out.sampleCount, 0);
    });

    test('accounting and environmental classes keep their class but '
        'carry the qualified value', () {
      final acc = ClaimedValue.derive<double>(
          [estimatedLitres], (v) => (v[0]! as double) * 1.8,
          claim: ClaimClass.accountingCandidate);
      expect(acc.claim, ClaimClass.accountingCandidate);
      expect(acc.isQualified, isTrue);
      expect(acc.requiresConfirmation, isTrue);
    });
  });

  group('value semantics', () {
    test('equal fields are equal', () {
      final a = ClaimedValue<double>.measuredFact(1.0,
          source: FleetMetricSource.measuredFillUp);
      final b = ClaimedValue<double>.measuredFact(1.0,
          source: FleetMetricSource.measuredFillUp);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('measuredFact'));
    });

    test('a negative sample count is refused', () {
      expect(
        () => ClaimedValue<double>(const DataValue.measured(1.0),
            claim: ClaimClass.measuredFact,
            sampleCount: -1,
            provenance: const [FleetMetricSource.measuredFillUp]),
        throwsArgumentError,
      );
    });
  });
}
