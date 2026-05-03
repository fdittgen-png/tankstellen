import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_breadcrumb_collector.dart';

void main() {
  group('Obd2BreadcrumbCollector (#1395)', () {
    test('record appends an entry with the right branch and rate', () {
      final c = Obd2BreadcrumbCollector();
      c.record(
        branch: Obd2BranchTag.pid5E,
        fuelRateLPerHour: 4.2,
        pid5ELPerHour: 4.2,
        rpm: 2200,
        afr: 14.7,
        fuelDensityGPerL: 745,
        engineDisplacementCc: 1500,
        volumetricEfficiency: 0.85,
      );

      expect(c.entries, hasLength(1));
      expect(c.entries.first.branch, equals(Obd2BranchTag.pid5E));
      expect(c.entries.first.fuelRateLPerHour, equals(4.2));
      expect(c.entries.first.pid5ELPerHour, equals(4.2));
      expect(c.entries.first.rpm, equals(2200));
      // Recording must stamp `at` to a non-null DateTime — the
      // overlay renders this as the per-row HH:MM:SS prefix.
      expect(c.entries.first.at, isNotNull);
    });

    test('preserves insertion order across multiple records', () {
      final c = Obd2BreadcrumbCollector();
      c.record(branch: Obd2BranchTag.pid5E, fuelRateLPerHour: 1.0);
      c.record(branch: Obd2BranchTag.maf, fuelRateLPerHour: 2.0);
      c.record(branch: Obd2BranchTag.speedDensity, fuelRateLPerHour: 3.0);

      expect(
        c.entries.map((e) => e.fuelRateLPerHour).toList(),
        equals([1.0, 2.0, 3.0]),
      );
      expect(
        c.entries.map((e) => e.branch).toList(),
        equals([
          Obd2BranchTag.pid5E,
          Obd2BranchTag.maf,
          Obd2BranchTag.speedDensity,
        ]),
      );
    });

    test('ring buffer caps at maxEntries — entry 201 evicts entry 0', () {
      final c = Obd2BreadcrumbCollector();
      for (var i = 0; i < Obd2BreadcrumbCollector.maxEntries; i++) {
        c.record(
          branch: Obd2BranchTag.pid5E,
          fuelRateLPerHour: i.toDouble(),
        );
      }
      expect(c.entries, hasLength(Obd2BreadcrumbCollector.maxEntries));
      expect(c.entries.first.fuelRateLPerHour, equals(0.0));

      // One more — oldest must drop, newest must land at the end.
      c.record(branch: Obd2BranchTag.pid5E, fuelRateLPerHour: 999.0);
      expect(c.entries, hasLength(Obd2BreadcrumbCollector.maxEntries));
      expect(
        c.entries.first.fuelRateLPerHour,
        equals(1.0),
        reason: 'oldest entry must be evicted on overflow',
      );
      expect(c.entries.last.fuelRateLPerHour, equals(999.0));
    });

    test('clear empties the buffer AND resets the running counters', () {
      final c = Obd2BreadcrumbCollector();
      c.record(
        branch: Obd2BranchTag.pid5E,
        fuelRateLPerHour: 0.2,
        flag: Obd2BreadcrumbCollector.flagSuspiciousLow,
        flagDetail: 'rpm=2200',
      );
      c.record(branch: Obd2BranchTag.maf, fuelRateLPerHour: 4.0);
      expect(c.entries, isNotEmpty);
      expect(c.totalSampleCount, equals(2));
      expect(c.suspiciousSampleCount, equals(1));

      c.clear();
      expect(c.entries, isEmpty);
      expect(c.totalSampleCount, equals(0));
      expect(c.suspiciousSampleCount, equals(0));
    });

    test('entries returns an unmodifiable view', () {
      final c = Obd2BreadcrumbCollector();
      c.record(branch: Obd2BranchTag.pid5E, fuelRateLPerHour: 1.0);
      expect(
        () => c.entries.add(
          Obd2Breadcrumb(at: DateTime.now(), branch: Obd2BranchTag.maf),
        ),
        throwsUnsupportedError,
      );
    });

    group('flag tracking', () {
      test(
          'record(flag: ...) increments suspiciousSampleCount AND '
          'totalSampleCount', () {
        final c = Obd2BreadcrumbCollector();
        c.record(
          branch: Obd2BranchTag.pid5E,
          fuelRateLPerHour: 0.2,
          flag: Obd2BreadcrumbCollector.flagSuspiciousLow,
          flagDetail: 'directRate=0.20;rpm=2200',
        );
        expect(c.totalSampleCount, equals(1));
        expect(c.suspiciousSampleCount, equals(1));
      });

      test(
          'record(flag: null) increments only totalSampleCount, not '
          'suspiciousSampleCount', () {
        final c = Obd2BreadcrumbCollector();
        c.record(branch: Obd2BranchTag.pid5E, fuelRateLPerHour: 4.2);
        expect(c.totalSampleCount, equals(1));
        expect(c.suspiciousSampleCount, equals(0));
      });

      test(
          'recordFlag mutates the most-recent breadcrumb in place AND '
          'increments suspiciousSampleCount', () {
        final c = Obd2BreadcrumbCollector();
        c.record(branch: Obd2BranchTag.pid5E, fuelRateLPerHour: 4.2);
        c.recordFlag(
          Obd2BreadcrumbCollector.flag5eVsMafDivergent,
          'direct=4.20;mafDerived=2.00',
        );
        expect(c.entries, hasLength(1));
        expect(
          c.entries.first.flag,
          equals(Obd2BreadcrumbCollector.flag5eVsMafDivergent),
        );
        expect(c.suspiciousSampleCount, equals(1));
        // Must not double-count the underlying sample.
        expect(c.totalSampleCount, equals(1));
      });

      test('recordFlag is a no-op when the buffer is empty', () {
        final c = Obd2BreadcrumbCollector();
        c.recordFlag(Obd2BreadcrumbCollector.flag5eVsMafDivergent, 'x');
        expect(c.entries, isEmpty);
        expect(c.suspiciousSampleCount, equals(0));
      });

      test(
          'snapshotAndResetCounters returns the running tally AND resets '
          'the counters but preserves the entry list', () {
        final c = Obd2BreadcrumbCollector();
        c.record(branch: Obd2BranchTag.pid5E, fuelRateLPerHour: 4.0);
        c.record(
          branch: Obd2BranchTag.pid5E,
          fuelRateLPerHour: 0.2,
          flag: Obd2BreadcrumbCollector.flagSuspiciousLow,
        );
        c.record(branch: Obd2BranchTag.maf, fuelRateLPerHour: 3.0);

        final snap = c.snapshotAndResetCounters();
        expect(snap.total, equals(3));
        expect(snap.suspicious, equals(1));

        // Entry list must still be there — overlay needs the trace
        // post-trip.
        expect(c.entries, hasLength(3));
        // Counters reset for the next recording.
        expect(c.totalSampleCount, equals(0));
        expect(c.suspiciousSampleCount, equals(0));
      });
    });
  });
}
