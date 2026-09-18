// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/core/domain/fleet/fleet_provenance.dart';

/// #4212 — every fleet metric names its source class, and the mapping
/// from ADR 0022's consumption source classes is total and honest: a
/// pump-gained MAF litre is an OBD *estimate*, never `obd_measured`.
void main() {
  group('FleetMetricSource', () {
    test('carries the #4212 wire vocabulary and round-trips it', () {
      const expected = {
        FleetMetricSource.measuredFillUp: 'measured_fill_up',
        FleetMetricSource.obdMeasured: 'obd_measured',
        FleetMetricSource.obdEstimated: 'obd_estimated',
        FleetMetricSource.gpsEstimated: 'gps_estimated',
        FleetMetricSource.imported: 'imported',
        FleetMetricSource.derived: 'derived',
      };
      expect(FleetMetricSource.values.toSet(), expected.keys.toSet(),
          reason: 'a new source class must be added to this table');
      for (final e in expected.entries) {
        expect(e.key.wireName, e.value);
        expect(FleetMetricSource.fromWireName(e.value), e.key);
      }
      expect(FleetMetricSource.fromWireName('made_up'), isNull);
      expect(FleetMetricSource.fromWireName(''), isNull);
    });

    test('only the two observed classes count as measured', () {
      final measured =
          FleetMetricSource.values.where((s) => s.isMeasured).toSet();
      expect(measured, {
        FleetMetricSource.measuredFillUp,
        FleetMetricSource.obdMeasured,
      });
      final estimates =
          FleetMetricSource.values.where((s) => s.isEstimate).toSet();
      expect(estimates, {
        FleetMetricSource.obdEstimated,
        FleetMetricSource.gpsEstimated,
      });
      // Asserted by a third party, not observed: neither measured nor an
      // estimate. It becomes a measured fact only after confirmation.
      expect(FleetMetricSource.imported.isMeasured, isFalse);
      expect(FleetMetricSource.imported.isEstimate, isFalse);
      expect(FleetMetricSource.derived.isMeasured, isFalse);
    });
  });

  group('mapping from ConsumptionSourceClass (ADR 0022)', () {
    test('is total: every consumption class maps, and none is measured '
        'unless the ECU reported the litre', () {
      const expected = {
        ConsumptionSourceClass.measured: FleetMetricSource.obdMeasured,
        ConsumptionSourceClass.estimated: FleetMetricSource.obdEstimated,
        ConsumptionSourceClass.gpsOnly: FleetMetricSource.gpsEstimated,
        ConsumptionSourceClass.none: null,
      };
      expect(ConsumptionSourceClass.values.toSet(), expected.keys.toSet(),
          reason: 'a fifth consumption class must be mapped here');
      for (final e in expected.entries) {
        expect(FleetMetricSource.fromConsumptionSourceClass(e.key), e.value);
      }
    });

    test('the pump-gained MAF class never becomes obd_measured', () {
      final mapped = FleetMetricSource.fromConsumptionSourceClass(
          ConsumptionSourceClass.estimated);
      expect(mapped, isNotNull);
      expect(mapped!.isMeasured, isFalse);
      expect(mapped.isEstimate, isTrue);
    });

    test('measured-ness agrees with the source class predicate', () {
      for (final c in ConsumptionSourceClass.values) {
        final mapped = FleetMetricSource.fromConsumptionSourceClass(c);
        expect(mapped?.isMeasured ?? false, c.isMeasured,
            reason: '$c: fleet provenance must not disagree with ADR 0022');
      }
    });
  });
}
