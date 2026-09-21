// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/export/data_exporter.dart';
import 'package:tankstellen/features/fleet/data/fleet_metrics_export.dart';
import 'package:tankstellen/features/fleet/data/fleet_metrics_reader.dart';
import 'package:tankstellen/features/fleet/domain/fleet_kpis.dart';

/// #4216 / ADR 0025 D5.2 — the fleet export, and the one thing it may
/// never contain.
void main() {
  FleetKpis kpis(List<Map<String, dynamic>> rows) =>
      FleetKpis.over(decodePeriodMetrics(rows));

  Map<String, dynamic> row({
    String id = 'veh-1',
    bool suppressed = false,
    double? km = 1500,
  }) =>
      {
        'fleet_vehicle_id': id,
        'suppressed': suppressed,
        'spend': 240.5,
        'litres': 120.0,
        'km': km,
        'co2e_kg': 372.0,
        'co2_factor_version': 'ADEME Base Carbone v23.6 (2026) WtW',
        'measured_share': 0.75,
        'sample_count': 9,
        'currency': 'EUR',
      };

  group('encodeFleetCsv refuses raw location', () {
    test('every shape a location sneaks in as is rejected', () {
      for (final column in const [
        'latitude',
        'lon',
        'startLat',
        'gps_trace',
        'route_polyline',
        'trip_id',
        'geohash',
        'last_known_position',
        'home_address',
      ]) {
        expect(
          () => encodeFleetCsv(header: ['vehicle', column], rows: const []),
          throwsArgumentError,
          reason: '"$column" must not reach a fleet export',
        );
      }
    });

    test('an ordinary aggregate column passes — the guard is not a '
        'blanket refusal', () {
      expect(
          encodeFleetCsv(
              header: const ['fleet_vehicle_id', 'spend', 'co2e_kg'],
              rows: const [
                ['veh-1', 1, 2]
              ]),
          contains('fleet_vehicle_id,spend,co2e_kg'));
    });

    test('the shipped header is clean — and stays clean, because the '
        'check runs on it', () {
      expect(
          () => encodeFleetCsv(
              header: kFleetMetricsExportHeader, rows: const []),
          returnsNormally);
      for (final column in kFleetMetricsExportHeader) {
        expect(kFleetExportForbiddenColumns.contains(column), isFalse);
      }
    });
  });

  group('fleetMetricsCsv', () {
    test('carries the aggregate columns and no journey column', () {
      final csv = fleetMetricsCsv(kpis([row()]));
      final header = csv.split('\r\n').first;
      expect(header, kFleetMetricsExportHeader.join(','));
      for (final forbidden in const ['lat', 'lon', 'gps', 'trip', 'route']) {
        expect(header.contains(forbidden), isFalse,
            reason: 'the export header must not offer $forbidden');
      }
    });

    test('a suppressed vehicle is exported AS suppressed — not '
        'dropped, not filled in', () {
      final csv = fleetMetricsCsv(kpis([
        row(),
        {'fleet_vehicle_id': 'veh-2', 'suppressed': true, 'sample_count': 2},
      ]));
      final lines = csv.split('\r\n');
      expect(lines, hasLength(4), reason: 'header + two rows + trailing');
      final hidden = lines.firstWhere((l) => l.startsWith('veh-2'));
      expect(hidden.startsWith('veh-2,true,,'), isTrue,
          reason: 'every figure empty, including the sample count: '
              '$hidden');
      final cells = hidden.split(',');
      expect(cells[kFleetMetricsExportHeader.indexOf('sample_count')],
          isEmpty,
          reason: 'the sample count the server withheld must not '
              'reappear in the file');
    });

    test('an absent figure is an empty cell, never 0 — a spreadsheet '
        'sums zeros and a reader believes the sum', () {
      final csv = fleetMetricsCsv(kpis([row(km: null)]));
      final line = csv.split('\r\n')[1];
      final cells = line.split(',');
      final kmIndex = kFleetMetricsExportHeader.indexOf('km');
      final costIndex = kFleetMetricsExportHeader.indexOf('cost_per_km');
      expect(cells[kmIndex], isEmpty);
      expect(cells[costIndex], isEmpty);
      expect(cells[kFleetMetricsExportHeader.indexOf('litres')], '120.0');
    });

    test('the CO2 figure travels in the same row as its factor '
        'version (#4219)', () {
      final csv = fleetMetricsCsv(kpis([row()]));
      final cells = csv.split('\r\n')[1].split(',');
      expect(cells[kFleetMetricsExportHeader.indexOf('co2e_kg')], '372.0');
      expect(csv, contains('ADEME Base Carbone v23.6 (2026) WtW'));
    });
  });
}
