// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_services/south_korea/katec_converter.dart';

/// #3192 — WGS84 ↔ KATEC conversion for OPINET.
///
/// Reference values were produced with pyproj/PROJ 9 for the canonical
/// KATEC definition
/// `+proj=tmerc +lat_0=38 +lon_0=128 +k=0.9999 +x_0=400000 +y_0=600000
/// +ellps=bessel +towgs84=-115.80,474.99,674.11,1.16,-2.31,-1.63,6.43`
/// (recorded 2026-06-10). The Dart implementation must agree to better
/// than one metre — far below anything a 1–5 km radius search could
/// notice.
void main() {
  group('wgs84ToKatec', () {
    test('Seoul City Hall lands on the PROJ reference', () {
      // WGS84 (37.566535, 126.9779692) → KATEC (309907.46, 552077.26).
      final k = wgs84ToKatec(37.566535, 126.9779692);
      expect(k.x, closeTo(309907.46, 1.0));
      expect(k.y, closeTo(552077.26, 1.0));
    });

    test('Seoul coordinates fall in the expected KATEC range', () {
      // The KATEC grid puts Seoul roughly at x∈[290k, 340k],
      // y∈[530k, 565k] — i.e. nowhere near WGS84 degree magnitudes.
      // This is the regression #3192 guards: sending raw degrees put
      // the query point ~400 km from any Korean station.
      final cityHall = wgs84ToKatec(37.566535, 126.9779692);
      final gangnam = wgs84ToKatec(37.4979, 127.0276);
      for (final k in [cityHall, gangnam]) {
        expect(k.x, inInclusiveRange(290000, 340000));
        expect(k.y, inInclusiveRange(530000, 565000));
      }
    });

    test('Busan matches the PROJ reference', () {
      final k = wgs84ToKatec(35.1796, 129.0756);
      expect(k.x, closeTo(498164.72, 1.0));
      expect(k.y, closeTo(287275.01, 1.0));
    });

    test('Jeju matches the PROJ reference', () {
      final k = wgs84ToKatec(33.4996, 126.5312);
      expect(k.x, closeTo(263722.20, 1.0));
      expect(k.y, closeTo(101365.13, 1.0));
    });
  });

  group('katecToWgs84', () {
    test('inverts the forward conversion to sub-centimetre', () {
      const lat = 37.4997;
      const lng = 127.0287;
      final k = wgs84ToKatec(lat, lng);
      final back = katecToWgs84(k.x, k.y);
      // 1e-7 degrees ≈ 1 cm.
      expect(back.lat, closeTo(lat, 1e-6));
      expect(back.lng, closeTo(lng, 1e-6));
    });

    test('KATEC reference point converts to the WGS84 reference', () {
      // PROJ reference: KATEC (309907.46, 552077.26) is Seoul City Hall.
      final w = katecToWgs84(309907.46, 552077.26);
      expect(w.lat, closeTo(37.566535, 1e-4));
      expect(w.lng, closeTo(126.9779692, 1e-4));
    });
  });
}
