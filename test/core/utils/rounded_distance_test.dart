// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/geo_utils.dart';

/// #3983 — the one definition of "distance rounded to 0.1 km" that five
/// parsers and the service mixin used to carry as private copies.
void main() {
  test('rounds the haversine distance to one decimal', () {
    // Munich Marienplatz -> Munich Hbf: ~1.2 km
    final d = roundedDistanceKm(48.1374, 11.5755, 48.1402, 11.5600);
    expect(d, closeTo(1.2, 0.05));
    expect((d * 10).roundToDouble() / 10, d, reason: 'one decimal exactly');
  });

  test('zero distance is 0.0', () {
    expect(roundedDistanceKm(48.0, 11.0, 48.0, 11.0), 0.0);
  });
}
