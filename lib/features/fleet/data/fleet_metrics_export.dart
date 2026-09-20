// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/export/data_exporter.dart' show encodeFleetCsv;
import '../domain/fleet_kpis.dart';

/// The columns a fleet period export carries (#4216).
///
/// Every one is an aggregate of the organisation's own expense rows.
/// There is no employee column, no station, no timestamp of a purchase
/// and — checked by `encodeFleetCsv`, not by memory — nothing that
/// resolves to a place (ADR 0025 D5.2).
const List<String> kFleetMetricsExportHeader = [
  'fleet_vehicle_id',
  'suppressed',
  'spend',
  'currency',
  'litres',
  'km',
  'cost_per_km',
  'l_per_100km',
  'co2e_kg',
  'co2_factor_version',
  'measured_share',
  'sample_count',
];

/// Render [kpis] as the CSV a manager takes away (#4216).
///
/// Two rules the shape encodes:
///
///  * a **suppressed** row is exported as a suppressed row — the
///    vehicle id and `suppressed = true`, every figure empty. Dropping
///    it would make the file look like a smaller fleet; filling it in
///    would defeat the threshold that produced it (D5.3);
///  * an **absent** figure is an empty cell, never a `0`. A
///    spreadsheet sums zeros and a reader believes the sum; there is
///    no honest number to put there, so there is no number.
///
/// The CO2 column travels with `co2_factor_version` in the same row, so
/// a figure lifted out of this file still names the source behind it
/// (#4219).
///
/// Throws [ArgumentError] if a forbidden column ever reaches the
/// header — see `encodeFleetCsv`. That cannot happen with
/// [kFleetMetricsExportHeader] as written, which is the point: the
/// guard is there for the edit that comes later.
String fleetMetricsCsv(FleetKpis kpis) => encodeFleetCsv(
      header: kFleetMetricsExportHeader,
      rows: [
        for (final v in kpis.vehicles)
          [
            v.fleetVehicleId,
            v.suppressed,
            v.spend.valueOrNull,
            v.currency,
            v.litres.valueOrNull,
            v.km.valueOrNull,
            v.costPerKm.valueOrNull,
            v.lPer100Km.valueOrNull,
            v.co2eKg.valueOrNull,
            v.co2FactorVersion,
            v.measuredShare.valueOrNull,
            v.suppressed ? null : v.sampleCount,
          ],
      ],
    );
