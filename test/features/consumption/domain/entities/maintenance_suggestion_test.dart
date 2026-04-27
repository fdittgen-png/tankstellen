import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/maintenance_suggestion.dart';

MaintenanceSuggestion _makeSuggestion({
  MaintenanceSignal signal = MaintenanceSignal.idleRpmCreep,
  double confidence = 0.6,
  double observedDelta = 4.5,
  int sampleTripCount = 12,
  DateTime? computedAt,
}) {
  return MaintenanceSuggestion(
    signal: signal,
    confidence: confidence,
    observedDelta: observedDelta,
    sampleTripCount: sampleTripCount,
    computedAt: computedAt ?? DateTime.utc(2026, 4, 10, 9),
  );
}

void main() {
  group('MaintenanceSignal enum', () {
    test('has exactly 2 values', () {
      expect(MaintenanceSignal.values, hasLength(2));
      expect(
        MaintenanceSignal.values,
        containsAll(<MaintenanceSignal>[
          MaintenanceSignal.idleRpmCreep,
          MaintenanceSignal.mafDeviation,
        ]),
      );
    });
  });

  group('MaintenanceSuggestion construction', () {
    test('const constructor exposes all 5 fields verbatim', () {
      final computedAt = DateTime.utc(2026, 4, 10, 9);
      final suggestion = MaintenanceSuggestion(
        signal: MaintenanceSignal.mafDeviation,
        confidence: 0.85,
        observedDelta: 7.25,
        sampleTripCount: 17,
        computedAt: computedAt,
      );

      expect(suggestion.signal, MaintenanceSignal.mafDeviation);
      expect(suggestion.confidence, 0.85);
      expect(suggestion.observedDelta, 7.25);
      expect(suggestion.sampleTripCount, 17);
      expect(suggestion.computedAt, computedAt);
    });
  });

  group('MaintenanceSuggestion equality', () {
    test('is reflexive: a == a', () {
      final a = _makeSuggestion();
      expect(a == a, isTrue);
    });

    test('is symmetric: if a == b then b == a', () {
      final a = _makeSuggestion();
      final b = _makeSuggestion();
      expect(a == b, isTrue);
      expect(b == a, isTrue);
    });

    test('two instances with identical field values are equal', () {
      final a = _makeSuggestion();
      final b = _makeSuggestion();
      expect(a, equals(b));
    });

    test('differs when signal differs', () {
      final a = _makeSuggestion(signal: MaintenanceSignal.idleRpmCreep);
      final b = _makeSuggestion(signal: MaintenanceSignal.mafDeviation);
      expect(a == b, isFalse);
    });

    test('differs when confidence differs', () {
      final a = _makeSuggestion(confidence: 0.5);
      final b = _makeSuggestion(confidence: 0.9);
      expect(a == b, isFalse);
    });

    test('differs when observedDelta differs', () {
      final a = _makeSuggestion(observedDelta: 4.5);
      final b = _makeSuggestion(observedDelta: 9.0);
      expect(a == b, isFalse);
    });

    test('differs when sampleTripCount differs', () {
      final a = _makeSuggestion(sampleTripCount: 12);
      final b = _makeSuggestion(sampleTripCount: 18);
      expect(a == b, isFalse);
    });

    test('differs when computedAt differs', () {
      final a = _makeSuggestion(computedAt: DateTime.utc(2026, 4, 10));
      final b = _makeSuggestion(computedAt: DateTime.utc(2026, 4, 11));
      expect(a == b, isFalse);
    });

    test('short-circuits on identical(a, a)', () {
      final a = _makeSuggestion();
      // identical-instance comparison hits the `identical(this, other)` arm
      // of operator== first, so this is true even before any field check.
      expect(identical(a, a), isTrue);
      expect(a == a, isTrue);
    });

    test('returns false when compared against a non-MaintenanceSuggestion',
        () {
      final a = _makeSuggestion();
      // ignore: unrelated_type_equality_checks
      expect(a == Object(), isFalse);
    });
  });

  group('MaintenanceSuggestion hashCode', () {
    test('is equal for two equal suggestions', () {
      final a = _makeSuggestion();
      final b = _makeSuggestion();
      expect(a.hashCode, b.hashCode);
    });

    test('computes a non-zero value for typical inputs (smoke)', () {
      final a = _makeSuggestion();
      // Object.hash never returns 0 for typical inputs; the contract only
      // requires equal-objects-equal-hashes, but a non-zero result confirms
      // the override actually ran.
      expect(a.hashCode, isNot(0));
    });
  });
}
