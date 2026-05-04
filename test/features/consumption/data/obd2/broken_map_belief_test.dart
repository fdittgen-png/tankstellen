import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_belief.dart';

void main() {
  group('BrokenMapBelief', () {
    test('default constructor uses neutral baseline', () {
      const belief = BrokenMapBelief();
      expect(belief.confidence, 0.0);
      expect(belief.observationCount, 0);
      expect(belief.lastUpdate, isNull);
      expect(belief.lastTrigger, BrokenMapReason.none);
    });

    test('JSON round-trip preserves every field', () {
      final ts = DateTime.utc(2026, 5, 4, 12, 30);
      final original = BrokenMapBelief(
        confidence: 0.73,
        observationCount: 12,
        lastUpdate: ts,
        lastTrigger: BrokenMapReason.idleVacuumMissing,
      );

      final json = original.toJson();
      final parsed = BrokenMapBelief.fromJson(json);

      expect(parsed.confidence, 0.73);
      expect(parsed.observationCount, 12);
      expect(parsed.lastUpdate, ts);
      expect(parsed.lastTrigger, BrokenMapReason.idleVacuumMissing);
      expect(parsed, original);
    });

    test('copyWith confidence change preserves other fields', () {
      final ts = DateTime.utc(2026, 5, 4, 12, 30);
      final original = BrokenMapBelief(
        confidence: 0.2,
        observationCount: 4,
        lastUpdate: ts,
        lastTrigger: BrokenMapReason.revDeltaMissing,
      );

      final updated = original.copyWith(confidence: 0.9);

      expect(updated.confidence, 0.9);
      expect(updated.observationCount, 4);
      expect(updated.lastUpdate, ts);
      expect(updated.lastTrigger, BrokenMapReason.revDeltaMissing);
    });

    test('every BrokenMapReason serializes to its enum name', () {
      final cases = <BrokenMapReason, String>{
        BrokenMapReason.idleVacuumMissing: 'idleVacuumMissing',
        BrokenMapReason.revDeltaMissing: 'revDeltaMissing',
        BrokenMapReason.pleinCompletDiscrepancy: 'pleinCompletDiscrepancy',
        BrokenMapReason.etaImplausible: 'etaImplausible',
        BrokenMapReason.none: 'none',
      };

      for (final entry in cases.entries) {
        final belief = BrokenMapBelief(lastTrigger: entry.key);
        final json = belief.toJson();
        expect(
          json['lastTrigger'],
          entry.value,
          reason: '${entry.key} should serialize to "${entry.value}"',
        );
        final back = BrokenMapBelief.fromJson(json);
        expect(back.lastTrigger, entry.key);
      }
    });
  });
}
