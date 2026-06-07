// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/radar_closeness.dart';

/// #2995 — unit pins for the shared Fuel Station Radar closeness helper. The
/// real radar list-card surface is exercised in `radar_closeness_bar_test.dart`
/// (the regression lock) and `radar_closeness_absolute_test.dart` (the
/// approach-radius scale lock); this file pins the arithmetic + the never-throws
/// contract the helper documents. Every radar surface — list, recording card,
/// PiP — divides against the user's approach radius via [RadarCloseness.fillFor]
/// (#2995 removed the list-only `listScaleMeters` / 15 km-cap path of #2985).

void main() {
  group('RadarCloseness.fillFor — the canonical fill fraction', () {
    test('full at the station, empty at/beyond the radius', () {
      expect(RadarCloseness.fillFor(0, 10000), 1.0);
      expect(RadarCloseness.fillFor(10000, 10000), 0.0);
      expect(RadarCloseness.fillFor(25000, 10000), 0.0); // clamped, no negative
    });

    test('the worked example: radius 10 km → 0.25 km≈0.975, 5 km=0.5, '
        '9.9 km≈0.01', () {
      expect(RadarCloseness.fillFor(250, 10000), closeTo(0.975, 1e-9));
      expect(RadarCloseness.fillFor(5000, 10000), closeTo(0.5, 1e-9));
      expect(RadarCloseness.fillFor(9900, 10000), closeTo(0.01, 1e-9));
    });

    test('the approach-radius worked examples (3 km scale): 2.5 km≈0.17, '
        '1.5 km=0.5, 5 km (beyond reach)=0', () {
      // The 3 km approach radius all three surfaces share (#2995). A 2.5 km
      // forecourt reads ~0.17, NOT the ~0.83 the removed 15 km list scale gave.
      expect(RadarCloseness.fillFor(2500, 3000), closeTo(0.1667, 1e-3));
      expect(RadarCloseness.fillFor(1500, 3000), closeTo(0.5, 1e-9));
      expect(RadarCloseness.fillFor(5000, 3000), 0.0); // past the radius → empty
    });

    test('clamps to 1 at/under the station (no overflow)', () {
      expect(RadarCloseness.fillFor(-50, 10000), 1.0);
    });
  });

  // The helper documents "Never throws" — pin the fault paths so a degenerate
  // input (the kind that produced the recurring divide-by-zero / NaN scaling
  // bugs) returns normally instead of blowing up the card build (#2995).
  group('RadarCloseness — never-throws contract (#2995)', () {
    test('fillFor returns normally on a degenerate / non-finite radius', () {
      expect(() => RadarCloseness.fillFor(100, 0), returnsNormally);
      expect(() => RadarCloseness.fillFor(100, -1), returnsNormally);
      expect(() => RadarCloseness.fillFor(100, double.nan), returnsNormally);
      expect(() => RadarCloseness.fillFor(100, double.infinity), returnsNormally);
      // …and the value is the safe "empty" sentinel, not a NaN/negative.
      expect(RadarCloseness.fillFor(100, 0), 0.0);
      expect(RadarCloseness.fillFor(100, double.nan), 0.0);
      expect(RadarCloseness.fillFor(100, double.infinity), 0.0);
    });
  });
}
