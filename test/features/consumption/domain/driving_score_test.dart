import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/driving_score.dart';

DrivingScore _make({
  int score = 80,
  double idle = 5,
  double hardAccel = 2,
  double hardBrake = 2,
  double highRpm = 3,
  double fullThrottle = 0,
}) {
  return DrivingScore(
    score: score,
    idlingPenalty: idle,
    hardAccelPenalty: hardAccel,
    hardBrakePenalty: hardBrake,
    highRpmPenalty: highRpm,
    fullThrottlePenalty: fullThrottle,
  );
}

void main() {
  group('DrivingScore construction', () {
    test('const constructor exposes all 6 fields verbatim', () {
      const score = DrivingScore(
        score: 73,
        idlingPenalty: 4.5,
        hardAccelPenalty: 6.25,
        hardBrakePenalty: 8.0,
        highRpmPenalty: 7.5,
        fullThrottlePenalty: 0.75,
      );

      expect(score.score, 73);
      expect(score.idlingPenalty, 4.5);
      expect(score.hardAccelPenalty, 6.25);
      expect(score.hardBrakePenalty, 8.0);
      expect(score.highRpmPenalty, 7.5);
      expect(score.fullThrottlePenalty, 0.75);
    });

    test('DrivingScore.perfect is 100 with all penalties at 0.0', () {
      expect(DrivingScore.perfect.score, 100);
      expect(DrivingScore.perfect.idlingPenalty, 0.0);
      expect(DrivingScore.perfect.hardAccelPenalty, 0.0);
      expect(DrivingScore.perfect.hardBrakePenalty, 0.0);
      expect(DrivingScore.perfect.highRpmPenalty, 0.0);
      expect(DrivingScore.perfect.fullThrottlePenalty, 0.0);
    });

    test('DrivingScore.perfect is a const-time singleton', () {
      // Two references to the static const should be the same instance,
      // confirming the `const` constructor is canonicalised.
      const a = DrivingScore.perfect;
      const b = DrivingScore.perfect;
      expect(identical(a, b), isTrue);
    });
  });

  group('DrivingScore equality', () {
    test('is reflexive: a == a (perfect sentinel)', () {
      expect(DrivingScore.perfect == DrivingScore.perfect, isTrue);
    });

    test('is reflexive: a == a (hand-rolled instance)', () {
      final a = _make();
      expect(a == a, isTrue);
    });

    test('is symmetric: if a == b then b == a', () {
      final a = _make();
      final b = _make();
      expect(a == b, isTrue);
      expect(b == a, isTrue);
    });

    test('two instances with identical field values are equal', () {
      final a = _make();
      final b = _make();
      expect(a, equals(b));
    });

    test('differs when score differs', () {
      final a = _make(score: 80);
      final b = _make(score: 81);
      expect(a == b, isFalse);
    });

    test('differs when idlingPenalty differs', () {
      final a = _make(idle: 5);
      final b = _make(idle: 6);
      expect(a == b, isFalse);
    });

    test('differs when hardAccelPenalty differs', () {
      final a = _make(hardAccel: 2);
      final b = _make(hardAccel: 4);
      expect(a == b, isFalse);
    });

    test('differs when hardBrakePenalty differs', () {
      final a = _make(hardBrake: 2);
      final b = _make(hardBrake: 7);
      expect(a == b, isFalse);
    });

    test('differs when highRpmPenalty differs', () {
      final a = _make(highRpm: 3);
      final b = _make(highRpm: 9);
      expect(a == b, isFalse);
    });

    test('differs when fullThrottlePenalty differs', () {
      final a = _make(fullThrottle: 0);
      final b = _make(fullThrottle: 5);
      expect(a == b, isFalse);
    });

    test('short-circuits on identical(a, a)', () {
      final a = _make();
      // identical-instance comparison hits the `identical(this, other)` arm
      // of operator== first, so this is true even before any field check.
      expect(identical(a, a), isTrue);
      expect(a == a, isTrue);
    });

    test('returns false when compared against a non-DrivingScore', () {
      final a = _make();
      // ignore: unrelated_type_equality_checks
      expect(a == Object(), isFalse);
    });
  });

  group('DrivingScore hashCode', () {
    test('is equal for two equal scores', () {
      final a = _make();
      final b = _make();
      expect(a.hashCode, b.hashCode);
    });

    test('is equal for the perfect sentinel and a manually-built equivalent',
        () {
      const manual = DrivingScore(
        score: 100,
        idlingPenalty: 0,
        hardAccelPenalty: 0,
        hardBrakePenalty: 0,
        highRpmPenalty: 0,
        fullThrottlePenalty: 0,
      );
      expect(manual, equals(DrivingScore.perfect));
      expect(manual.hashCode, DrivingScore.perfect.hashCode);
    });

    test('computes a non-zero value for typical inputs (smoke)', () {
      final a = _make();
      // Object.hash returns a non-zero value for typical non-zero inputs;
      // the contract only requires equal-objects-equal-hashes, but a
      // non-zero result confirms the override actually ran.
      expect(a.hashCode, isNot(0));
    });
  });

  group('DrivingScore toString', () {
    test('includes the score value', () {
      final s = _make(score: 80);
      expect(s.toString(), contains('score: 80'));
    });

    test('formats idlingPenalty to 1 decimal place', () {
      final s = _make(idle: 5);
      expect(s.toString(), contains('idling: 5.0'));
    });

    test('formats hardAccelPenalty to 1 decimal place', () {
      final s = _make(hardAccel: 2.25);
      expect(s.toString(), contains('hardAccel: 2.3'));
    });

    test('formats hardBrakePenalty to 1 decimal place', () {
      final s = _make(hardBrake: 7.5);
      expect(s.toString(), contains('hardBrake: 7.5'));
    });

    test('formats highRpmPenalty to 1 decimal place', () {
      final s = _make(highRpm: 9);
      expect(s.toString(), contains('highRpm: 9.0'));
    });

    test('formats fullThrottlePenalty to 1 decimal place', () {
      final s = _make(fullThrottle: 4.5);
      expect(s.toString(), contains('fullThrottle: 4.5'));
    });

    test('starts with the class name prefix', () {
      final s = _make();
      expect(s.toString(), startsWith('DrivingScore('));
    });
  });
}
