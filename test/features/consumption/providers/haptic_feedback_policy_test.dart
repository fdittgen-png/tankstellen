import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/providers/haptic_feedback_policy.dart';

void main() {
  group('hapticForBandTransition (#767)', () {
    test('returns none when previous and current are identical', () {
      for (final band in ConsumptionBand.values) {
        expect(
          hapticForBandTransition(band, band),
          HapticIntensity.none,
          reason: 'no-op transition for $band should stay silent',
        );
      }
    });

    test('escalation into heavy fires a light haptic', () {
      expect(
        hapticForBandTransition(ConsumptionBand.normal, ConsumptionBand.heavy),
        HapticIntensity.light,
      );
      expect(
        hapticForBandTransition(ConsumptionBand.eco, ConsumptionBand.heavy),
        HapticIntensity.light,
      );
      expect(
        hapticForBandTransition(
          ConsumptionBand.transient,
          ConsumptionBand.heavy,
        ),
        HapticIntensity.light,
      );
    });

    test('escalation into veryHeavy fires a medium haptic', () {
      expect(
        hapticForBandTransition(
          ConsumptionBand.normal,
          ConsumptionBand.veryHeavy,
        ),
        HapticIntensity.medium,
      );
      expect(
        hapticForBandTransition(
          ConsumptionBand.eco,
          ConsumptionBand.veryHeavy,
        ),
        HapticIntensity.medium,
      );
      expect(
        hapticForBandTransition(
          ConsumptionBand.transient,
          ConsumptionBand.veryHeavy,
        ),
        HapticIntensity.medium,
      );
    });

    test('direct heavy -> veryHeavy still fires a medium haptic', () {
      expect(
        hapticForBandTransition(
          ConsumptionBand.heavy,
          ConsumptionBand.veryHeavy,
        ),
        HapticIntensity.medium,
        reason: 'entering veryHeavy is always a medium nudge',
      );
    });

    test('downgrade out of veryHeavy stays silent — positive transition', () {
      expect(
        hapticForBandTransition(
          ConsumptionBand.veryHeavy,
          ConsumptionBand.heavy,
        ),
        HapticIntensity.none,
        reason:
            'dropping from veryHeavy to heavy is an improvement; no feedback',
      );
      expect(
        hapticForBandTransition(
          ConsumptionBand.veryHeavy,
          ConsumptionBand.normal,
        ),
        HapticIntensity.none,
      );
      expect(
        hapticForBandTransition(
          ConsumptionBand.veryHeavy,
          ConsumptionBand.eco,
        ),
        HapticIntensity.none,
      );
    });

    test('downgrade out of heavy stays silent', () {
      expect(
        hapticForBandTransition(
          ConsumptionBand.heavy,
          ConsumptionBand.normal,
        ),
        HapticIntensity.none,
      );
      expect(
        hapticForBandTransition(
          ConsumptionBand.heavy,
          ConsumptionBand.eco,
        ),
        HapticIntensity.none,
      );
    });

    test('transitions between non-heavy bands stay silent', () {
      expect(
        hapticForBandTransition(ConsumptionBand.eco, ConsumptionBand.normal),
        HapticIntensity.none,
      );
      expect(
        hapticForBandTransition(ConsumptionBand.normal, ConsumptionBand.eco),
        HapticIntensity.none,
      );
      expect(
        hapticForBandTransition(
          ConsumptionBand.normal,
          ConsumptionBand.transient,
        ),
        HapticIntensity.none,
      );
      expect(
        hapticForBandTransition(
          ConsumptionBand.transient,
          ConsumptionBand.normal,
        ),
        HapticIntensity.none,
      );
    });

    test('transient -> heavy fires light (transient is neutral)', () {
      expect(
        hapticForBandTransition(
          ConsumptionBand.transient,
          ConsumptionBand.heavy,
        ),
        HapticIntensity.light,
      );
    });
  });
}
