// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/fleet/claim_class.dart';
import 'package:tankstellen/core/sync/sync_transport.dart' show JsonRow;
import 'package:tankstellen/features/fleet/data/fleet_metrics_reader.dart';

import 'fake_fleet_review_transport.dart';

/// #4216 — the boundary between `fleet_period_metrics` and the domain.
void main() {
  JsonRow row({
    String id = 'veh-1',
    bool suppressed = false,
    Object? spend = 240.5,
    Object? litres = 120.0,
    Object? km = 1500.0,
    Object? co2 = 372.0,
    String? version = 'ADEME Base Carbone v23.6 (2026) WtW',
    Object? share = 0.75,
    Object? samples = 9,
    String? currency = 'EUR',
  }) =>
      {
        'fleet_vehicle_id': id,
        'suppressed': suppressed,
        'spend': spend,
        'litres': litres,
        'km': km,
        'cost_per_km': 0.1603,
        'l_per_100km': 8.0,
        'co2e_kg': co2,
        'co2_factor_version': version,
        'measured_share': share,
        'sample_count': samples,
        'currency': currency,
      };

  group('decodePeriodMetrics', () {
    test('a reported row arrives with each figure under its claim '
        'class (#4219)', () {
      final v = decodePeriodMetrics([row()]).single;
      expect(v.fleetVehicleId, 'veh-1');
      expect(v.spend.claim, ClaimClass.measuredFact);
      expect(v.spend.valueOrNull, closeTo(240.5, 1e-9));
      expect(v.litres.claim, ClaimClass.measuredFact);
      expect(v.km.claim, ClaimClass.measuredFact);
      expect(v.co2eKg.claim, ClaimClass.environmentalEstimate);
      expect(v.co2eKg.value, isA<Estimated<double>>(),
          reason: 'a class-average factor knows nothing about THIS '
              'vehicle, so the figure is modelled');
      expect(v.measuredShare.claim, ClaimClass.calculatedOperational);
      expect(v.sampleCount, 9);
      expect(v.currency, 'EUR');
    });

    test('a suppressed row yields the vehicle and nothing else — the '
        'sample count the server withheld is not reconstructed', () {
      final v = decodePeriodMetrics([
        {
          'fleet_vehicle_id': 'veh-2',
          'suppressed': true,
          'sample_count': 3,
          'spend': 99.0,
        }
      ]).single;
      expect(v.suppressed, isTrue);
      expect(v.sampleCount, 0);
      expect(v.spend.valueOrNull, isNull,
          reason: 'a client that read past `suppressed` would undo the '
              'threshold the server applied');
    });

    test('a CO2e number with no factor version is dropped to "not '
        'calculated" (#4219 belt)', () {
      final v = decodePeriodMetrics([row(version: null)]).single;
      expect(v.co2eKg.valueOrNull, isNull);
      expect(v.co2FactorVersion, isNull);
    });

    test('absences stay absent, with their reason', () {
      final v = decodePeriodMetrics([row(km: null, co2: null)]).single;
      expect(v.km.value, isA<Unknown<double>>());
      expect(v.co2eKg.value, isA<Unknown<double>>());
      expect(v.costPerKm.valueOrNull, isNull);
    });

    test('numeric columns survive arriving as strings — PostgREST '
        'serialises `numeric` either way', () {
      final v = decodePeriodMetrics(
          [row(spend: '240.5', km: '1500', samples: '9')]).single;
      expect(v.spend.valueOrNull, closeTo(240.5, 1e-9));
      expect(v.km.valueOrNull, closeTo(1500, 1e-9));
      expect(v.sampleCount, 9);
    });

    test('a row with no vehicle id is skipped rather than '
        'half-decoded', () {
      expect(decodePeriodMetrics([
        {'suppressed': false, 'spend': 1.0},
        row(),
      ]), hasLength(1));
    });
  });

  group('FleetMetricsReader', () {
    test('reads the period and rolls it up', () async {
      final wire = FakeFleetReviewTransport()..metricsRows = [row()];
      final kpis = await FleetMetricsReader(transport: wire).read(
        orgId: 'org-1',
        from: DateTime.utc(2026, 6),
        to: DateTime.utc(2026, 9),
      );
      expect(kpis, isNotNull);
      expect(kpis!.spend?.valueOrNull, closeTo(240.5, 1e-9));
      expect(wire.metricsCalls.single.orgId, 'org-1');
    });

    test('a wire fault reads as "could not ask", NOT as an empty '
        'fleet', () async {
      final wire = FakeFleetReviewTransport()
        ..metricsRows = [row()]
        ..failure = Exception('offline');
      final kpis = await FleetMetricsReader(transport: wire)
          .read(orgId: 'org-1', from: DateTime.utc(2026), to: DateTime.utc(2027));
      expect(kpis, isNull,
          reason: 'an empty FleetKpis would tell the manager their '
              'fleet bought no fuel');
    });

    test('a non-manager is refused by the server, and that is a null '
        'too — never a silent empty dashboard', () async {
      final wire = FakeFleetReviewTransport(isManager: false)
        ..metricsRows = [row()];
      final kpis = await FleetMetricsReader(transport: wire)
          .read(orgId: 'org-1', from: DateTime.utc(2026), to: DateTime.utc(2027));
      expect(kpis, isNull);
    });

    test('an organisation with no expenses in the window IS an empty '
        'roll-up — the other state', () async {
      final wire = FakeFleetReviewTransport();
      final kpis = await FleetMetricsReader(transport: wire)
          .read(orgId: 'org-1', from: DateTime.utc(2026), to: DateTime.utc(2027));
      expect(kpis, isNotNull);
      expect(kpis!.vehicles, isEmpty);
    });

    test('an export is audited, and a refused audit means no export '
        '(ADR 0025 D5.4)', () async {
      final wire = FakeFleetReviewTransport();
      final reader = FleetMetricsReader(transport: wire);
      expect(await reader.logExport(orgId: 'org-1', kind: 'csv'), isTrue);
      expect(wire.exportCalls.single.kind, 'csv');

      wire.exportAudited = false;
      expect(await reader.logExport(orgId: 'org-1', kind: 'csv'), isFalse);

      wire.failure = Exception('offline');
      expect(await reader.logExport(orgId: 'org-1', kind: 'csv'), isFalse,
          reason: 'a trail the server did not write is not a trail');
    });

    test('with no transport at all nothing is read and nothing is '
        'claimed to be audited', () async {
      const reader = FleetMetricsReader();
      expect(
          await reader.read(
              orgId: 'o', from: DateTime.utc(2026), to: DateTime.utc(2027)),
          isNull);
      expect(await reader.logExport(orgId: 'o', kind: 'csv'), isFalse);
    });
  });
}
