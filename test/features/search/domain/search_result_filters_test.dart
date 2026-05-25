// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/search_result_filters.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

import '../../../fixtures/charging_stations.dart';

/// Pins `applyEvFilters` (#1784) — the EV-only connector-type and
/// minimum-power filters for the unified results list.
void main() {
  EVStationResult ev(
    String id,
    List<EvConnector> connectors,
  ) =>
      EVStationResult(
        testChargingStation.copyWith(id: id, connectors: connectors),
      );

  EvConnector connector(ConnectorType type, double kw) => EvConnector(
        id: '$type-$kw',
        type: type,
        maxPowerKw: kw,
      );

  // Ionity: a 350 kW CCS rapid + a 22 kW Type 2.
  final ionity = ev('ocm-ionity', [
    connector(ConnectorType.ccs, 350),
    connector(ConnectorType.type2, 22),
  ]);
  // A slow 11 kW AC-only Type 2 station.
  final slowAc = ev('ocm-slow', [connector(ConnectorType.type2, 11)]);
  // A 50 kW CHAdeMO station.
  final chademo = ev('ocm-chademo', [connector(ConnectorType.chademo, 50)]);

  List<String> idsOf(List<EVStationResult> r) => r.map((e) => e.id).toList();

  group('applyEvFilters — connector type', () {
    test('empty connector set is a no-op', () {
      final out = applyEvFilters([ionity, slowAc, chademo],
          connectorTypes: const {}, minPowerKw: 0);
      expect(idsOf(out), ['ocm-ionity', 'ocm-slow', 'ocm-chademo']);
    });

    test('keeps only stations offering the selected connector', () {
      final out = applyEvFilters([ionity, slowAc, chademo],
          connectorTypes: {ConnectorType.ccs}, minPowerKw: 0);
      expect(idsOf(out), ['ocm-ionity']);
    });

    test('multiple connectors are OR-matched', () {
      final out = applyEvFilters([ionity, slowAc, chademo],
          connectorTypes: {ConnectorType.ccs, ConnectorType.chademo},
          minPowerKw: 0);
      expect(idsOf(out), ['ocm-ionity', 'ocm-chademo']);
    });

    test('a station passes if ANY of its connectors matches', () {
      // Ionity has both CCS and Type 2 — selecting Type 2 keeps it.
      final out = applyEvFilters([ionity, slowAc],
          connectorTypes: {ConnectorType.type2}, minPowerKw: 0);
      expect(idsOf(out), ['ocm-ionity', 'ocm-slow']);
    });
  });

  group('applyEvFilters — minimum power', () {
    test('minPowerKw 0 is a no-op', () {
      final out = applyEvFilters([ionity, slowAc, chademo],
          connectorTypes: const {}, minPowerKw: 0);
      expect(out, hasLength(3));
    });

    test('filters on the station max power across all connectors', () {
      final out = applyEvFilters([ionity, slowAc, chademo],
          connectorTypes: const {}, minPowerKw: 100);
      // Ionity's 350 kW CCS clears 100; slow (11) and chademo (50) do not.
      expect(idsOf(out), ['ocm-ionity']);
    });

    test('boundary — a station exactly at the threshold passes', () {
      final out = applyEvFilters([chademo],
          connectorTypes: const {}, minPowerKw: 50);
      expect(idsOf(out), ['ocm-chademo']);
    });
  });

  group('applyEvFilters — combined', () {
    test('connector and power filters compose (AND across the two)', () {
      final out = applyEvFilters([ionity, slowAc, chademo],
          connectorTypes: {ConnectorType.ccs, ConnectorType.chademo},
          minPowerKw: 100);
      // ccs|chademo leaves ionity + chademo; ≥100 kW drops chademo (50).
      expect(idsOf(out), ['ocm-ionity']);
    });

    test('empty input list stays empty', () {
      expect(
        applyEvFilters(const [],
            connectorTypes: {ConnectorType.ccs}, minPowerKw: 50),
        isEmpty,
      );
    });
  });
}
