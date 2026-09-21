// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/fleet/claim_class.dart';
import 'package:tankstellen/core/domain/fleet/fleet_provenance.dart';
import 'package:tankstellen/features/fleet/domain/fleet_attention.dart';
import 'package:tankstellen/features/fleet/domain/fleet_kpis.dart';

/// #4216 / #4214 — the dashboard's arithmetic, tested where it lives.
///
/// The screens are thin over this file on purpose: "dashboard values
/// equal deterministic domain aggregations" is a property of a pure
/// function, and a widget test that re-asserted it would only prove
/// the widget read the field.
void main() {
  FleetVehicleMetrics vehicle(
    String id, {
    double? spend,
    String? currency = 'EUR',
    double? litres,
    double? km,
    double? co2,
    String? factor = 'ADEME Base Carbone v23.6 (2026) WtW',
    double? measuredShare,
    int samples = 6,
    bool estimatedLitres = false,
  }) =>
      FleetVehicleMetrics(
        fleetVehicleId: id,
        suppressed: false,
        spend: spend == null
            ? ClaimedValue<double>.notCalculated(
                reason: DataUnknownReason.notMeasuredYet,
                claim: ClaimClass.measuredFact)
            : ClaimedValue<double>.measuredFact(spend,
                source: FleetMetricSource.measuredFillUp,
                sampleCount: samples),
        currency: currency,
        litres: litres == null
            ? ClaimedValue<double>.notCalculated(
                reason: DataUnknownReason.notMeasuredYet,
                claim: ClaimClass.measuredFact)
            : estimatedLitres
                ? ClaimedValue<double>.estimate(litres,
                    basis: DataBasis.derived,
                    source: FleetMetricSource.gpsEstimated,
                    sampleCount: samples)
                : ClaimedValue<double>.measuredFact(litres,
                    source: FleetMetricSource.measuredFillUp,
                    sampleCount: samples),
        km: km == null
            ? ClaimedValue<double>.notCalculated(
                reason: DataUnknownReason.notMeasuredYet,
                claim: ClaimClass.measuredFact)
            : ClaimedValue<double>.measuredFact(km,
                source: FleetMetricSource.measuredFillUp,
                sampleCount: samples),
        co2eKg: co2 == null
            ? ClaimedValue<double>.notCalculated(
                reason: DataUnknownReason.notPublishedForThisItem,
                claim: ClaimClass.environmentalEstimate)
            : ClaimedValue<double>.unchecked(
                Estimated<double>(co2, basis: DataBasis.fleetAverage),
                claim: ClaimClass.environmentalEstimate,
                sampleCount: samples,
                provenance: const [
                  FleetMetricSource.measuredFillUp,
                  FleetMetricSource.derived,
                ],
              ),
        co2FactorVersion: co2 == null ? null : factor,
        measuredShare: measuredShare == null
            ? ClaimedValue<double>.notCalculated(
                reason: DataUnknownReason.notMeasuredYet,
                claim: ClaimClass.calculatedOperational)
            : ClaimedValue<double>.unchecked(
                Measured<double>(measuredShare),
                claim: ClaimClass.calculatedOperational,
                sampleCount: samples,
                provenance: const [
                  FleetMetricSource.measuredFillUp,
                  FleetMetricSource.derived,
                ],
              ),
        sampleCount: samples,
      );

  group('per-vehicle figures', () {
    test('cost/km and L/100 km are arithmetic over the measured facts, '
        'and stay class 2', () {
      final v = vehicle('a', spend: 200, litres: 100, km: 1000);
      expect(v.costPerKm.valueOrNull, closeTo(0.2, 1e-9));
      expect(v.lPer100Km.valueOrNull, closeTo(10, 1e-9));
      expect(v.costPerKm.claim, ClaimClass.calculatedOperational);
      expect(v.costPerKm.value, isA<Measured<double>>(),
          reason: 'measured inputs must not come out qualified');
    });

    test('an estimate can never become measured — one modelled input '
        'degrades the derivation to class 3', () {
      final v = vehicle('a', spend: 200, litres: 100, km: 1000,
          estimatedLitres: true);
      expect(v.lPer100Km.claim, ClaimClass.estimate,
          reason: '#4219: a calculated metric over an estimate IS an '
              'estimate');
      expect(v.lPer100Km.isQualified, isTrue);
      // The cost side had no estimated input, so it is untouched.
      expect(v.costPerKm.claim, ClaimClass.calculatedOperational);
    });

    test('no distance evidence means no cost/km — not a zero', () {
      final v = vehicle('a', spend: 200, litres: 100);
      expect(v.costPerKm.value, isA<Unknown<double>>());
      expect(v.costPerKm.valueOrNull, isNull);
    });

    test('a suppressed row carries the vehicle and nothing else, the '
        'sample count included (ADR 0025 D5.3)', () {
      final v = FleetVehicleMetrics.suppressedRow('a');
      expect(v.suppressed, isTrue);
      expect(v.sampleCount, 0);
      for (final figure in [v.spend, v.litres, v.km, v.co2eKg,
        v.measuredShare, v.costPerKm, v.lPer100Km]) {
        expect(figure.valueOrNull, isNull);
      }
      expect(v.currency, isNull);
      expect(v.co2FactorVersion, isNull);
    });
  });

  group('fleet roll-up', () {
    test('totals are deterministic and rest on every observation '
        'under them', () {
      final kpis = FleetKpis.over([
        vehicle('a', spend: 200, litres: 100, km: 1000, samples: 6),
        vehicle('b', spend: 100, litres: 60, km: 500, samples: 7),
      ]);
      expect(kpis.spend?.valueOrNull, closeTo(300, 1e-9));
      expect(kpis.litres.valueOrNull, closeTo(160, 1e-9));
      expect(kpis.km.valueOrNull, closeTo(1500, 1e-9));
      expect(kpis.sampleCount, 13);
      expect(kpis.spend?.sampleCount, 13,
          reason: 'a SUM rests on every observation, not on the '
              'weakest input — that rule is for a ratio');
      expect(kpis.costPerKm.valueOrNull, closeTo(0.2, 1e-9));
      // Determinism: the same rows produce the same figures.
      final again = FleetKpis.over([
        vehicle('a', spend: 200, litres: 100, km: 1000, samples: 6),
        vehicle('b', spend: 100, litres: 60, km: 500, samples: 7),
      ]);
      expect(again.spend?.valueOrNull, kpis.spend?.valueOrNull);
      expect(again.costPerKm.valueOrNull, kpis.costPerKm.valueOrNull);
    });

    test('provenance survives the sum: one estimated vehicle makes the '
        'fleet total an estimate', () {
      final kpis = FleetKpis.over([
        vehicle('a', litres: 100, km: 1000),
        vehicle('b', litres: 60, km: 500, estimatedLitres: true),
      ]);
      expect(kpis.litres.isQualified, isTrue,
          reason: 'measured litres pooled with modelled litres are not '
              'measured litres');
      expect(kpis.litres.provenance, contains(FleetMetricSource.derived));
      expect(kpis.litres.provenance,
          contains(FleetMetricSource.gpsEstimated));
    });

    test('more than one currency yields NO total — the breakdown '
        'instead (SavingsLedger\'s rule)', () {
      final kpis = FleetKpis.over([
        vehicle('a', spend: 200, litres: 100, km: 1000),
        vehicle('b', spend: 90, currency: 'GBP', litres: 50, km: 400),
      ]);
      expect(kpis.isSingleCurrency, isFalse);
      expect(kpis.spend, isNull);
      expect(kpis.currency, isNull);
      expect(kpis.costPerKm.valueOrNull, isNull,
          reason: 'a cost per km built on a cross-currency total would '
              'be true in no currency');
      expect(kpis.spendByCurrency.keys, containsAll(['EUR', 'GBP']));
      expect(kpis.spendByCurrency['GBP']?.valueOrNull, closeTo(90, 1e-9));
    });

    test('one vehicle without odometer evidence does not erase the '
        'distance the rest measured', () {
      final kpis = FleetKpis.over([
        vehicle('a', spend: 100, litres: 50, km: 500),
        vehicle('b', spend: 100, litres: 50),
      ]);
      expect(kpis.km.valueOrNull, closeTo(500, 1e-9));
      expect(kpis.spend?.valueOrNull, closeTo(200, 1e-9));
    });

    test('an absent figure is Unknown, never 0', () {
      final kpis = FleetKpis.over([vehicle('a', spend: 100)]);
      expect(kpis.km.value, isA<Unknown<double>>());
      expect(kpis.lPer100Km.valueOrNull, isNull);
      expect(FleetKpis.over(const []).litres.value, isA<Unknown<double>>());
    });

    test('measured coverage is weighted by litres, not by vehicle', () {
      final kpis = FleetKpis.over([
        vehicle('van', litres: 900, km: 5000, measuredShare: 1),
        vehicle('car', litres: 100, km: 800, measuredShare: 0),
      ]);
      expect(kpis.measuredShare.valueOrNull, closeTo(0.9, 1e-9),
          reason: 'a per-vehicle mean would have said 0.5 and flattered '
              'the fleet');
    });

    test('CO2e sums only under ONE factor version; two methodologies '
        'are never added (#4216)', () {
      final same = FleetKpis.over([
        vehicle('a', litres: 100, co2: 310),
        vehicle('b', litres: 50, co2: 155),
      ]);
      expect(same.co2eKg.valueOrNull, closeTo(465, 1e-9));
      expect(same.co2FactorVersion, 'ADEME Base Carbone v23.6 (2026) WtW');
      expect(same.co2eKg.claim, ClaimClass.environmentalEstimate);

      final mixed = FleetKpis.over([
        vehicle('a', litres: 100, co2: 310),
        vehicle('b', litres: 50, co2: 150, factor: 'Some Other v1 (2020) TtW'),
      ]);
      expect(mixed.co2eKg.valueOrNull, isNull);
      expect(mixed.co2FactorVersion, isNull);
    });

    test('a vehicle with no published factor leaves the fleet CO2e '
        'not calculated — never a partial sum (#4219)', () {
      final kpis = FleetKpis.over([
        vehicle('a', litres: 100, co2: 310),
        vehicle('b', litres: 50),
      ]);
      expect(kpis.co2eKg.valueOrNull, isNull,
          reason: 'a partial total presented as the period\'s emissions '
              'is exactly the undocumented substitution #4219 forbids');
    });

    test('suppressed rows are counted and contribute to nothing', () {
      final kpis = FleetKpis.over([
        vehicle('a', spend: 100, litres: 50, km: 500, samples: 8),
        FleetVehicleMetrics.suppressedRow('b'),
      ]);
      expect(kpis.suppressedCount, 1);
      expect(kpis.reported, hasLength(1));
      expect(kpis.sampleCount, 8);
      expect(kpis.spend?.valueOrNull, closeTo(100, 1e-9));
    });
  });

  group('needs attention', () {
    test('names the exceptions, fleet-wide findings first, and nobody '
        'by name', () {
      final items = fleetAttention(FleetKpis.over([
        vehicle('cheap', spend: 100, litres: 50, km: 1000, co2: 155,
            measuredShare: 1),
        vehicle('dear', spend: 400, litres: 50, km: 1000, co2: 155,
            measuredShare: 1),
        FleetVehicleMetrics.suppressedRow('hidden'),
      ]));
      expect(items.first.kind, FleetAttentionKind.rowsSuppressed);
      expect(
          items.where((i) => i.kind == FleetAttentionKind.costPerKmOutlier)
              .map((i) => i.fleetVehicleId),
          ['dear']);
    });

    test('a vehicle with no odometer evidence is flagged for THAT, not '
        'for low coverage', () {
      final items = fleetAttention(
          FleetKpis.over([vehicle('a', spend: 100, litres: 50, co2: 155)]));
      final kinds = items.map((i) => i.kind).toSet();
      expect(kinds, contains(FleetAttentionKind.noDistanceEvidence));
      expect(kinds, isNot(contains(FleetAttentionKind.lowMeasuredCoverage)));
    });

    test('a mixed-currency period is an exception a manager can act '
        'on', () {
      final items = fleetAttention(FleetKpis.over([
        vehicle('a', spend: 100, litres: 50, km: 500, co2: 155,
            measuredShare: 1),
        vehicle('b', spend: 100, currency: 'CHF', litres: 50, km: 500,
            co2: 155, measuredShare: 1),
      ]));
      expect(items.map((i) => i.kind),
          contains(FleetAttentionKind.mixedCurrency));
    });

    test('a healthy fleet has an empty list — not a placeholder', () {
      final items = fleetAttention(FleetKpis.over([
        vehicle('a', spend: 100, litres: 50, km: 1000, co2: 155,
            measuredShare: 1),
        vehicle('b', spend: 105, litres: 52, km: 1000, co2: 161,
            measuredShare: 1),
      ]));
      expect(items, isEmpty);
    });
  });
}
