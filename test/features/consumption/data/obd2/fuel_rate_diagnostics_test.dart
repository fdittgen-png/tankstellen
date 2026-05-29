// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/fuel_rate_diagnostics.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_breadcrumb_collector.dart';

/// Focused unit tests for the fuel-rate diagnostic collaborator
/// extracted out of `Obd2Service.readFuelRateLPerHour` (#2191). The
/// end-to-end breadcrumb behaviour is still asserted through the
/// service in `obd2_service_test.dart`; this isolates the separable
/// diagnostics — the two sanity bounds and the branch breadcrumbs —
/// from the BLE round-trips.
void main() {
  group('FuelRateDiagnostics (#2191)', () {
    /// Builds a diagnostics collaborator with petrol constants and
    /// caller-controllable RPM / MAF reads.
    FuelRateDiagnostics build({
      required Obd2BreadcrumbRecorder? collector,
      double? rpm,
      bool mafSupported = false,
      double? maf,
    }) {
      return FuelRateDiagnostics(
        collector: collector,
        afr: 14.7,
        fuelDensityGPerL: 745,
        engineDisplacementCc: 1500,
        volumetricEfficiency: 0.85,
        readRpm: () async => rpm,
        isMafSupported: () => mafSupported,
        readMaf: () async => maf,
      );
    }

    test('recordPid5E stamps a 5E breadcrumb with rate + constants', () async {
      final c = Obd2BreadcrumbCollector();
      await build(collector: c).recordPid5E(4.0);

      expect(c.entries, hasLength(1));
      final crumb = c.entries.first;
      expect(crumb.branch, equals(Obd2BranchTag.pid5E));
      expect(crumb.fuelRateLPerHour, closeTo(4.0, 0.01));
      expect(crumb.pid5ELPerHour, closeTo(4.0, 0.01));
      expect(crumb.afr, closeTo(14.7, 0.01));
      expect(crumb.fuelDensityGPerL, closeTo(745, 0.5));
      expect(crumb.flag, isNull);
    });

    test(
        'sanity bound A: directRate < 0.3 at RPM > 1500 flags '
        'suspicious-low', () async {
      final c = Obd2BreadcrumbCollector();
      await build(collector: c, rpm: 2176).recordPid5E(0.2);

      expect(c.entries, hasLength(1));
      expect(
        c.entries.first.flag,
        equals(Obd2BreadcrumbCollector.flagSuspiciousLow),
      );
      expect(c.entries.first.rpm, closeTo(2176, 0.5));
      expect(c.suspiciousSampleCount, equals(1));
    });

    test(
        'sanity bound A: directRate < 0.3 at idle RPM does NOT flag',
        () async {
      final c = Obd2BreadcrumbCollector();
      await build(collector: c, rpm: 800).recordPid5E(0.2);

      expect(c.entries.first.flag, isNull);
      expect(c.suspiciousSampleCount, equals(0));
    });

    test(
        'sanity bound A: a healthy rate never reads RPM (no flag)',
        () async {
      var rpmReads = 0;
      final c = Obd2BreadcrumbCollector();
      final diag = FuelRateDiagnostics(
        collector: c,
        afr: 14.7,
        fuelDensityGPerL: 745,
        engineDisplacementCc: 1500,
        volumetricEfficiency: 0.85,
        readRpm: () async {
          rpmReads++;
          return 2200;
        },
        isMafSupported: () => false,
        readMaf: () async => null,
      );

      await diag.recordPid5E(4.0);

      // Above the 0.3 L/h floor — the RPM read is skipped entirely.
      expect(rpmReads, equals(0));
      expect(c.entries.first.flag, isNull);
    });

    test(
        'sanity bound B: 5E vs MAF divergence > 50 % flags '
        '5e-vs-maf-divergent', () async {
      final c = Obd2BreadcrumbCollector();
      // MAF 10.24 g/s → derived ≈ 3.367 L/h. |16-3.37|/3.37 ≈ 3.7.
      await build(collector: c, mafSupported: true, maf: 10.24)
          .recordPid5E(16.0);

      expect(c.entries, hasLength(1));
      expect(
        c.entries.first.flag,
        equals(Obd2BreadcrumbCollector.flag5eVsMafDivergent),
      );
      expect(c.suspiciousSampleCount, equals(1));
    });

    test(
        'sanity bound B: 5E vs MAF within 50 % does NOT flag', () async {
      final c = Obd2BreadcrumbCollector();
      // MAF 10.24 g/s → derived ≈ 3.367 L/h; 3.4 is well inside ±50 %.
      await build(collector: c, mafSupported: true, maf: 10.24)
          .recordPid5E(3.4);

      expect(c.entries, hasLength(1));
      expect(c.entries.first.flag, isNull);
      expect(c.suspiciousSampleCount, equals(0));
    });

    test('sanity bound B: skipped entirely when MAF unsupported', () async {
      var mafReads = 0;
      final c = Obd2BreadcrumbCollector();
      final diag = FuelRateDiagnostics(
        collector: c,
        afr: 14.7,
        fuelDensityGPerL: 745,
        engineDisplacementCc: 1500,
        volumetricEfficiency: 0.85,
        readRpm: () async => null,
        isMafSupported: () => false,
        readMaf: () async {
          mafReads++;
          return 10.24;
        },
      );

      await diag.recordPid5E(16.0);

      expect(mafReads, equals(0));
      expect(c.entries.first.flag, isNull);
    });

    test('recordMaf stamps a MAF breadcrumb', () {
      final c = Obd2BreadcrumbCollector();
      build(collector: c).recordMaf(corrected: 3.2, maf: 10.24);

      expect(c.entries, hasLength(1));
      expect(c.entries.first.branch, equals(Obd2BranchTag.maf));
      expect(c.entries.first.fuelRateLPerHour, closeTo(3.2, 0.01));
      expect(c.entries.first.mafGramsPerSecond, closeTo(10.24, 0.01));
    });

    test('recordSpeedDensity stamps a speed-density breadcrumb', () {
      final c = Obd2BreadcrumbCollector();
      build(collector: c).recordSpeedDensity(
        corrected: 2.5,
        mapKpa: 65,
        iatCelsius: 30,
        rpm: 2500,
      );

      expect(c.entries, hasLength(1));
      final crumb = c.entries.first;
      expect(crumb.branch, equals(Obd2BranchTag.speedDensity));
      expect(crumb.fuelRateLPerHour, closeTo(2.5, 0.01));
      expect(crumb.mapKpa, closeTo(65, 0.01));
      expect(crumb.iatCelsius, closeTo(30, 0.01));
      expect(crumb.rpm, closeTo(2500, 0.01));
    });

    test('recordNoBranch stamps a none breadcrumb with partial inputs', () {
      final c = Obd2BreadcrumbCollector();
      build(collector: c).recordNoBranch(mapKpa: 65, iatCelsius: null, rpm: 0);

      expect(c.entries, hasLength(1));
      expect(c.entries.first.branch, equals(Obd2BranchTag.none));
      expect(c.entries.first.mapKpa, closeTo(65, 0.01));
      expect(c.entries.first.iatCelsius, isNull);
    });

    test('null collector — every emit method is a no-op', () async {
      final diag = build(collector: null, rpm: 2200, mafSupported: true,
          maf: 10.24);

      // None of these should throw; nothing is recorded anywhere.
      await diag.recordPid5E(0.2);
      diag.recordMaf(corrected: 3.2, maf: 10.24);
      diag.recordSpeedDensity(
          corrected: 2.5, mapKpa: 65, iatCelsius: 30, rpm: 2500);
      diag.recordNoBranch();
    });
  });
}
