// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// WGS84 ↔ KATEC coordinate conversion for the OPINET API (#3192).
///
/// OPINET's `aroundAll.do` endpoint takes its `x`/`y` query parameters —
/// and returns its `GIS_X_COOR`/`GIS_Y_COOR` fields — in **KATEC**, the
/// Korean Transverse-Mercator grid used by the national oil-price
/// clearing house (and by Korean map portals), *not* in WGS84 degrees.
/// Sending raw WGS84 lng/lat lands the query point meaninglessly close
/// to the projection origin, so live Korea could never return a station
/// (#3192).
///
/// KATEC is a Transverse Mercator projection on the **Bessel 1841**
/// ellipsoid with the Korean datum shift. The canonical proj4 definition
/// (mirrored by every OPINET client library) is:
///
/// ```
/// +proj=tmerc +lat_0=38 +lon_0=128 +k=0.9999 +x_0=400000 +y_0=600000
/// +ellps=bessel +units=m
/// +towgs84=-115.80,474.99,674.11,1.16,-2.31,-1.63,6.43
/// ```
///
/// This file implements that definition with the published math —
/// a 7-parameter Helmert datum shift (position-vector convention, the
/// proj `towgs84` semantics) between WGS84 and Bessel 1841, plus the
/// standard Snyder Transverse-Mercator forward/inverse series. No
/// dependency on `proj4dart` (only a transitive dep today — depending
/// on it directly would couple us to another package's version pin for
/// ~150 lines of textbook math).
///
/// Reference values are pinned in
/// `test/features/station_services/south_korea/katec_converter_test.dart`
/// against pyproj/PROJ output for the same definition (sub-metre
/// agreement required).
library;

import 'dart:math' as math;

/// A projected KATEC coordinate pair in metres.
/// `x` is the easting (OPINET `x` / `GIS_X_COOR`), `y` the northing
/// (OPINET `y` / `GIS_Y_COOR`).
class KatecPoint {
  final double x;
  final double y;
  const KatecPoint(this.x, this.y);

  @override
  String toString() => 'KatecPoint($x, $y)';
}

/// A geodetic WGS84 coordinate pair in degrees.
class Wgs84Point {
  final double lat;
  final double lng;
  const Wgs84Point(this.lat, this.lng);

  @override
  String toString() => 'Wgs84Point($lat, $lng)';
}

// ── Ellipsoids ─────────────────────────────────────────────────────────

// WGS84.
const double _aWgs = 6378137.0;
const double _fWgs = 1 / 298.257223563;

// Bessel 1841 (the KATEC ellipsoid).
const double _aBes = 6377397.155;
const double _fBes = 1 / 299.1528128;

// ── KATEC projection constants ─────────────────────────────────────────

const double _k0 = 0.9999;
final double _lat0 = _deg2rad(38.0);
final double _lon0 = _deg2rad(128.0);
const double _falseEasting = 400000.0;
const double _falseNorthing = 600000.0;

// ── towgs84 Helmert parameters (Bessel/Korea → WGS84, position vector) ──

const double _dx = -115.80;
const double _dy = 474.99;
const double _dz = 674.11;
final double _rx = _arcsec2rad(1.16);
final double _ry = _arcsec2rad(-2.31);
final double _rz = _arcsec2rad(-1.63);
const double _scale = 1 + 6.43e-6;

double _deg2rad(double d) => d * math.pi / 180.0;
double _rad2deg(double r) => r * 180.0 / math.pi;
double _arcsec2rad(double s) => s / 3600.0 * math.pi / 180.0;

/// Convert a WGS84 coordinate to the KATEC grid (metres).
KatecPoint wgs84ToKatec(double lat, double lng) {
  // 1. WGS84 geodetic → WGS84 ECEF.
  final ecefWgs = _geodeticToEcef(_deg2rad(lat), _deg2rad(lng), _aWgs, _fWgs);
  // 2. Inverse Helmert (WGS84 → Korean Bessel datum).
  final ecefBes = _helmertInverse(ecefWgs);
  // 3. ECEF → geodetic on Bessel.
  final geoBes = _ecefToGeodetic(ecefBes, _aBes, _fBes);
  // 4. Transverse-Mercator forward.
  return _tmForward(geoBes[0], geoBes[1]);
}

/// Convert a KATEC grid coordinate (metres) back to WGS84 degrees.
Wgs84Point katecToWgs84(double x, double y) {
  // 1. Transverse-Mercator inverse → geodetic on Bessel.
  final geoBes = _tmInverse(x, y);
  // 2. Geodetic → ECEF on Bessel.
  final ecefBes = _geodeticToEcef(geoBes[0], geoBes[1], _aBes, _fBes);
  // 3. Forward Helmert (Korean Bessel datum → WGS84).
  final ecefWgs = _helmertForward(ecefBes);
  // 4. ECEF → geodetic on WGS84.
  final geoWgs = _ecefToGeodetic(ecefWgs, _aWgs, _fWgs);
  return Wgs84Point(_rad2deg(geoWgs[0]), _rad2deg(geoWgs[1]));
}

// ── Datum shift ────────────────────────────────────────────────────────

/// Geodetic (rad) → ECEF for the given ellipsoid. Height is taken as 0 —
/// forecourt coordinates carry no altitude and the sub-decimetre error
/// from ignoring it is irrelevant at station-finding scale.
List<double> _geodeticToEcef(double lat, double lng, double a, double f) {
  final e2 = f * (2 - f);
  final sinLat = math.sin(lat);
  final cosLat = math.cos(lat);
  final n = a / math.sqrt(1 - e2 * sinLat * sinLat);
  return [
    n * cosLat * math.cos(lng),
    n * cosLat * math.sin(lng),
    n * (1 - e2) * sinLat,
  ];
}

/// ECEF → geodetic (rad) via Bowring's iterative method.
List<double> _ecefToGeodetic(List<double> ecef, double a, double f) {
  final x = ecef[0], y = ecef[1], z = ecef[2];
  final e2 = f * (2 - f);
  final p = math.sqrt(x * x + y * y);
  final lng = math.atan2(y, x);
  var lat = math.atan2(z, p * (1 - e2));
  for (var i = 0; i < 6; i++) {
    final sinLat = math.sin(lat);
    final n = a / math.sqrt(1 - e2 * sinLat * sinLat);
    lat = math.atan2(z + e2 * n * sinLat, p);
  }
  return [lat, lng];
}

/// Position-vector small-angle Helmert, local (Bessel) → WGS84:
/// `X' = T + s·R·X` with R built from the towgs84 rotations.
List<double> _helmertForward(List<double> v) {
  final x = v[0], y = v[1], z = v[2];
  return [
    _dx + _scale * (x - _rz * y + _ry * z),
    _dy + _scale * (_rz * x + y - _rx * z),
    _dz + _scale * (-_ry * x + _rx * y + z),
  ];
}

/// Inverse of [_helmertForward] (WGS84 → Bessel), using the transposed
/// rotation — exact to the same small-angle order as the forward form.
List<double> _helmertInverse(List<double> v) {
  final x = (v[0] - _dx) / _scale;
  final y = (v[1] - _dy) / _scale;
  final z = (v[2] - _dz) / _scale;
  return [
    x + _rz * y - _ry * z,
    -_rz * x + y + _rx * z,
    _ry * x - _rx * y + z,
  ];
}

// ── Transverse Mercator (Snyder series, Bessel ellipsoid) ──────────────

const double _e2 = _fBes * (2 - _fBes);
const double _ep2 = _e2 / (1 - _e2);

/// Meridian arc length from the equator (Snyder eq. 3-21).
double _meridianArc(double lat) {
  const e2 = _e2;
  const e4 = e2 * e2;
  const e6 = e4 * e2;
  return _aBes *
      ((1 - e2 / 4 - 3 * e4 / 64 - 5 * e6 / 256) * lat -
          (3 * e2 / 8 + 3 * e4 / 32 + 45 * e6 / 1024) * math.sin(2 * lat) +
          (15 * e4 / 256 + 45 * e6 / 1024) * math.sin(4 * lat) -
          (35 * e6 / 3072) * math.sin(6 * lat));
}

final double _m0 = _meridianArc(_lat0);

KatecPoint _tmForward(double lat, double lng) {
  final sinLat = math.sin(lat);
  final cosLat = math.cos(lat);
  final tanLat = math.tan(lat);

  final n = _aBes / math.sqrt(1 - _e2 * sinLat * sinLat);
  final t = tanLat * tanLat;
  final c = _ep2 * cosLat * cosLat;
  final aTerm = (lng - _lon0) * cosLat;
  final m = _meridianArc(lat);

  final a2 = aTerm * aTerm;
  final a3 = a2 * aTerm;
  final a4 = a3 * aTerm;
  final a5 = a4 * aTerm;
  final a6 = a5 * aTerm;

  final x = _falseEasting +
      _k0 *
          n *
          (aTerm +
              (1 - t + c) * a3 / 6 +
              (5 - 18 * t + t * t + 72 * c - 58 * _ep2) * a5 / 120);
  final y = _falseNorthing +
      _k0 *
          (m -
              _m0 +
              n *
                  tanLat *
                  (a2 / 2 +
                      (5 - t + 9 * c + 4 * c * c) * a4 / 24 +
                      (61 - 58 * t + t * t + 600 * c - 330 * _ep2) * a6 / 720));
  return KatecPoint(x, y);
}

/// TM inverse via the footpoint-latitude series (Snyder eq. 8-12…8-25).
/// Returns geodetic [lat, lng] in radians on the Bessel ellipsoid.
List<double> _tmInverse(double x, double y) {
  const e2 = _e2;
  final e1 = (1 - math.sqrt(1 - e2)) / (1 + math.sqrt(1 - e2));

  final m = _m0 + (y - _falseNorthing) / _k0;
  final mu = m /
      (_aBes * (1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256));

  final e1p2 = e1 * e1;
  final e1p3 = e1p2 * e1;
  final e1p4 = e1p3 * e1;
  final phi1 = mu +
      (3 * e1 / 2 - 27 * e1p3 / 32) * math.sin(2 * mu) +
      (21 * e1p2 / 16 - 55 * e1p4 / 32) * math.sin(4 * mu) +
      (151 * e1p3 / 96) * math.sin(6 * mu) +
      (1097 * e1p4 / 512) * math.sin(8 * mu);

  final sinPhi1 = math.sin(phi1);
  final cosPhi1 = math.cos(phi1);
  final tanPhi1 = math.tan(phi1);

  final c1 = _ep2 * cosPhi1 * cosPhi1;
  final t1 = tanPhi1 * tanPhi1;
  final n1 = _aBes / math.sqrt(1 - e2 * sinPhi1 * sinPhi1);
  final r1 = _aBes * (1 - e2) / math.pow(1 - e2 * sinPhi1 * sinPhi1, 1.5);
  final d = (x - _falseEasting) / (n1 * _k0);

  final d2 = d * d;
  final d3 = d2 * d;
  final d4 = d3 * d;
  final d5 = d4 * d;
  final d6 = d5 * d;

  final lat = phi1 -
      (n1 * tanPhi1 / r1) *
          (d2 / 2 -
              (5 + 3 * t1 + 10 * c1 - 4 * c1 * c1 - 9 * _ep2) * d4 / 24 +
              (61 +
                      90 * t1 +
                      298 * c1 +
                      45 * t1 * t1 -
                      252 * _ep2 -
                      3 * c1 * c1) *
                  d6 /
                  720);
  final lng = _lon0 +
      (d -
              (1 + 2 * t1 + c1) * d3 / 6 +
              (5 - 2 * c1 + 28 * t1 - 3 * c1 * c1 + 8 * _ep2 + 24 * t1 * t1) *
                  d5 /
                  120) /
          cosPhi1;
  return [lat, lng];
}
