// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/pump_bracket_detector.dart';

/// Unit tests for [PumpBracketDetector] (#1619).
///
/// The detector brackets a pump operation by its fuel-level delta
/// rather than the fill-up form lifecycle. These tests pin the three
/// acceptance scenarios — normal, open-before-fuelling, save-after-
/// driving — plus the noise / threshold guards.

void main() {
  /// Feed a chronological list of fuel-level readings into a fresh
  /// detector and return it for inspection.
  PumpBracketDetector detect(List<double> readings,
      {double riseThresholdL = 2.0}) {
    final d = PumpBracketDetector(riseThresholdL: riseThresholdL);
    for (final r in readings) {
      d.observe(r);
    }
    return d;
  }

  group('PumpBracketDetector — normal case (#1619)', () {
    test('brackets the fill between the pre-fill level and the peak', () {
      // Driving in (level declines) → fill → driving away (declines).
      final d = detect([42, 40, 38, 55, 54, 50, 45]);

      expect(d.hasBracket, isTrue);
      expect(d.bracket, const PumpBracket(startL: 38, endL: 55));
      expect(d.bracket!.deltaL, 17);
    });

    test('a fill seen as one jump across an engine-off gap is bracketed', () {
      // OBD2 disconnects while the engine is off during fuelling, so
      // the fill shows up as a single reading-to-reading jump.
      final d = detect([30, 62, 60]);

      expect(d.bracket, const PumpBracket(startL: 30, endL: 62));
    });
  });

  group('PumpBracketDetector — open-before-fuelling (#1619)', () {
    test('a fill after a run of stable pre-fuel readings is still caught', () {
      // The form (and detector) opened well before the user fuelled —
      // a stretch of flat readings, then the pump operation.
      final d = detect([40, 40, 40, 40, 56, 54]);

      expect(d.bracket, const PumpBracket(startL: 40, endL: 56));
    });
  });

  group('PumpBracketDetector — save-after-driving (#1619)', () {
    test('a long post-fill decline does not contaminate the bracket', () {
      // Fill 38 → 55, then the user drives a while before saving the
      // form: the level falls steadily. The bracket must stay the
      // fill, not stretch to the post-drive level.
      final d = detect([38, 55, 50, 44, 38, 32]);

      expect(d.bracket, const PumpBracket(startL: 38, endL: 55));
    });

    test('the first genuine fill wins — a later fill never overwrites it', () {
      // Two fills in one detector lifetime (a multi-stop journey).
      final d = detect([
        40, 58, // fill 1: 40 → 58
        52, 46, // drive away
        70, 68, // fill 2: should be ignored
      ]);

      expect(d.bracket, const PumpBracket(startL: 40, endL: 58));
    });
  });

  group('PumpBracketDetector — provisional bracket', () {
    test('a fill with no decline yet still exposes a provisional bracket', () {
      // The user saves the form the instant they finish fuelling — no
      // post-fill decline has been observed.
      final d = detect([38, 55]);

      expect(d.hasBracket, isTrue);
      expect(d.bracket, const PumpBracket(startL: 38, endL: 55));
    });

    test('the provisional bracket tracks the peak as the fill climbs', () {
      // Fuelling observed gradually (engine-on slow trickle).
      final d = detect([40, 43, 47, 52]);

      expect(d.bracket, const PumpBracket(startL: 40, endL: 52));
    });
  });

  group('PumpBracketDetector — noise + threshold guards', () {
    test('coarse-PID jitter with no real fill yields no bracket', () {
      final d = detect([40, 40.4, 39.8, 40.2, 39.9, 40.1]);

      expect(d.hasBracket, isFalse);
      expect(d.bracket, isNull);
    });

    test('a sub-threshold rise is discarded as noise', () {
      // A 1.5 L bump never reaches the 2 L floor — not a fill.
      final d = detect([40, 41.5, 39]);

      expect(d.hasBracket, isFalse);
    });

    test('a real fill after a discarded sub-threshold bump is still caught',
        () {
      // The detector must reset cleanly after a noise blip.
      final d = detect([40, 41.5, 39, 60, 58]);

      expect(d.bracket, const PumpBracket(startL: 39, endL: 60));
    });

    test('an empty reading stream yields no bracket', () {
      expect(detect(const []).bracket, isNull);
    });

    test('a negative reading is ignored defensively', () {
      // A corrupt decode must not derail the bracket.
      final d = detect([38, -1, 55]);

      expect(d.bracket, const PumpBracket(startL: 38, endL: 55));
    });

    test('riseThresholdL is configurable', () {
      // With a 10 L floor, a 5 L top-up no longer counts as a fill.
      final d = detect([40, 45, 41], riseThresholdL: 10);
      expect(d.hasBracket, isFalse);
    });
  });

  group('PumpBracket', () {
    test('deltaL is endL - startL', () {
      const b = PumpBracket(startL: 12.5, endL: 48.0);
      expect(b.deltaL, 35.5);
    });

    test('value equality', () {
      expect(
        const PumpBracket(startL: 10, endL: 40),
        const PumpBracket(startL: 10, endL: 40),
      );
      expect(
        const PumpBracket(startL: 10, endL: 40),
        isNot(const PumpBracket(startL: 10, endL: 41)),
      );
    });
  });
}
