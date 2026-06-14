// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_charts.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_path_geometry.dart';

/// #3316 — the trip-detail map threw two faces of one bug in the field:
///   * `UnsupportedError` from `_TileLayerState._clampToNativeZoom`
///     (`Infinity.toInt()`) when a degenerate trip yields a zero-span
///     bounds → infinite CameraFit zoom; and
///   * `Crs.checkLatLng` rejecting a non-finite `LatLng` in `MarkerLayer`.
/// These pure helpers sanitise the points and pad the bounds so neither
/// can reach flutter_map.
TripDetailSample _s(double? lat, double? lng) =>
    TripDetailSample(timestamp: DateTime(2026), speedKmh: 10, latitude: lat, longitude: lng);

void main() {
  group('buildTripPathPoints (#3316)', () {
    test('drops null coordinates', () {
      final r = buildTripPathPoints([_s(48.1, 11.5), _s(null, 11.6), _s(48.2, null)]);
      expect(r.points, [const LatLng(48.1, 11.5)]);
      expect(r.samples.length, 1);
    });

    test('drops NaN / Infinity coordinates (the MarkerLayer crash)', () {
      final r = buildTripPathPoints([
        _s(48.1, 11.5),
        _s(double.nan, 11.6),
        _s(48.2, double.infinity),
        _s(double.negativeInfinity, double.nan),
      ]);
      expect(r.points, [const LatLng(48.1, 11.5)]);
      expect(r.samples.length, 1);
      for (final p in r.points) {
        expect(p.latitude.isFinite && p.longitude.isFinite, isTrue);
      }
    });

    test('keeps points and samples index-aligned', () {
      final r = buildTripPathPoints([_s(1, 1), _s(double.nan, 2), _s(3, 3)]);
      expect(r.points, [const LatLng(1, 1), const LatLng(3, 3)]);
      expect(r.samples.length, 2);
    });

    test('empty / all-invalid input → empty', () {
      expect(buildTripPathPoints(const []).points, isEmpty);
      expect(buildTripPathPoints([_s(double.nan, double.nan)]).points, isEmpty);
    });
  });

  group('tripPathBounds (#3316)', () {
    test('a real multi-point span keeps its real corners', () {
      final b = tripPathBounds(const [LatLng(48.0, 11.0), LatLng(48.5, 11.5)]);
      expect(b.south, 48.0);
      expect(b.north, 48.5);
      expect(b.west, 11.0);
      expect(b.east, 11.5);
    });

    test('a single point is padded to a finite non-zero-span box', () {
      final b = tripPathBounds(const [LatLng(48.0, 11.0)]);
      expect(b.north - b.south, greaterThan(0));
      expect(b.east - b.west, greaterThan(0));
      expect(b.center.latitude, closeTo(48.0, 1e-6));
      expect(b.center.longitude, closeTo(11.0, 1e-6));
    });

    test('≥2 IDENTICAL points are padded too (the zero-span CameraFit crash)', () {
      final b = tripPathBounds(const [
        LatLng(48.0, 11.0),
        LatLng(48.0, 11.0),
        LatLng(48.0, 11.0),
      ]);
      expect(b.north - b.south, greaterThan(0),
          reason: 'zero latitude span would make CameraFit zoom infinite');
      expect(b.east - b.west, greaterThan(0));
    });

    test('a span that is zero on only ONE axis is padded on that axis', () {
      // Same longitude, different latitude → only the lng axis is degenerate.
      final b = tripPathBounds(const [LatLng(48.0, 11.0), LatLng(48.4, 11.0)]);
      expect(b.north - b.south, closeTo(0.4, 1e-9), reason: 'real lat span preserved');
      expect(b.east - b.west, greaterThan(0), reason: 'degenerate lng axis padded');
    });

    test('all corners stay finite', () {
      final b = tripPathBounds(const [LatLng(48.0, 11.0), LatLng(48.0, 11.0)]);
      expect(b.north.isFinite && b.south.isFinite, isTrue);
      expect(b.east.isFinite && b.west.isFinite, isTrue);
    });
  });
}
