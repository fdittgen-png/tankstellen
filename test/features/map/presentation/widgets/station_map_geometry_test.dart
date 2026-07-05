// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_geometry.dart';

/// Regression coverage for the #3488 NaN-camera bug.
///
/// Symptom: the fuel-station search "took a lot of time" — really the
/// results map re-threw `LatLng is not finite: LatLng(NaN, NaN)` on
/// EVERY tile-update event (50 identical throws in the field log), from
/// `TileRangeCalculator`. Two failure modes wore the one symptom:
///
///   * Mode A — a **zero-span** `LatLngBounds` (a single station, OR
///     >=2 stations at IDENTICAL coordinates: a chain returning a
///     duplicate) reached `CameraFit.bounds`, which then computed an
///     **infinite fit-zoom** → the camera projected to `LatLng(NaN,NaN)`.
///     The old per-site `_boundsOf*` helpers only epsilon-padded the
///     `length == 1` case, so co-located duplicates slipped through.
///   * Mode B — a non-finite station coordinate flowed into the centroid
///     / bounds and propagated NaN into the camera.
///
/// These tests reproduce the mechanism directly: `CameraFit.bounds(...)`
/// over the geometry helper's output must always yield a FINITE camera.
void main() {
  // A camera to fit against — size and starting position are irrelevant
  // to the fit math; only the resulting centre/zoom finiteness matters.
  MapCamera fitCameraTo(LatLngBounds bounds) {
    final base = MapCamera(
      crs: const Epsg3857(),
      center: const LatLng(0, 0),
      zoom: 3,
      rotation: 0,
      nonRotatedSize: const Size(400, 800),
    );
    return CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(32),
    ).fit(base);
  }

  void expectFiniteCamera(LatLngBounds bounds) {
    final camera = fitCameraTo(bounds);
    expect(camera.center.latitude.isFinite, isTrue,
        reason: 'camera latitude must be finite');
    expect(camera.center.longitude.isFinite, isTrue,
        reason: 'camera longitude must be finite');
    expect(camera.zoom.isFinite, isTrue, reason: 'camera zoom must be finite');
  }

  Station stationAt(String id, double lat, double lng) => Station(
        id: id,
        name: id,
        brand: 'Brand',
        street: 'Street',
        houseNumber: '1',
        postCode: '00000',
        place: 'Place',
        lat: lat,
        lng: lng,
        dist: 1.0,
        isOpen: true,
      );

  group('centerOf — NaN-safe centroid (#3488)', () {
    test('empty list returns the finite fallback, never NaN', () {
      final c = StationMapGeometry.centerOf(const []);
      expect(c.latitude.isFinite, isTrue);
      expect(c.longitude.isFinite, isTrue);
      expect(c, StationMapGeometry.fallbackCenter);
    });

    test('a station with non-finite coords is skipped', () {
      final c = StationMapGeometry.centerOf([
        stationAt('nan', double.nan, double.nan),
        stationAt('ok', 48.0, 2.0),
      ]);
      expect(c.latitude, closeTo(48.0, 1e-9));
      expect(c.longitude, closeTo(2.0, 1e-9));
    });

    test('all-non-finite input falls back finite, never NaN', () {
      final c = StationMapGeometry.centerOf([
        stationAt('a', double.nan, 2.0),
        stationAt('b', 48.0, double.infinity),
      ]);
      expect(c.latitude.isFinite, isTrue);
      expect(c.longitude.isFinite, isTrue);
      expect(c, StationMapGeometry.fallbackCenter);
    });

    test('normal input still averages correctly', () {
      final c = StationMapGeometry.centerOf([
        stationAt('a', 48.0, 2.0),
        stationAt('b', 50.0, 4.0),
      ]);
      expect(c.latitude, closeTo(49.0, 1e-9));
      expect(c.longitude, closeTo(3.0, 1e-9));
    });
  });

  group('boundsOfPoints — never degenerate for CameraFit (#3488)', () {
    test('Mode A: >=2 IDENTICAL points → non-zero span → finite camera', () {
      // The field trigger: duplicate/co-located stations.
      final bounds = StationMapGeometry.boundsOfPoints(const [
        LatLng(48.8566, 2.3522),
        LatLng(48.8566, 2.3522),
        LatLng(48.8566, 2.3522),
      ]);
      expect(bounds.north, greaterThan(bounds.south));
      expect(bounds.east, greaterThan(bounds.west));
      expectFiniteCamera(bounds);
    });

    test('single point → epsilon box → finite camera', () {
      final bounds =
          StationMapGeometry.boundsOfPoints(const [LatLng(45.0, 5.0)]);
      expect(bounds.north, greaterThan(bounds.south));
      expect(bounds.east, greaterThan(bounds.west));
      expectFiniteCamera(bounds);
    });

    test('empty input → finite fallback box → finite camera', () {
      final bounds = StationMapGeometry.boundsOfPoints(const []);
      expect(bounds.north, greaterThan(bounds.south));
      expect(bounds.east, greaterThan(bounds.west));
      expectFiniteCamera(bounds);
    });

    test('Mode B: non-finite points dropped, degenerate remainder padded', () {
      final bounds = StationMapGeometry.boundsOfPoints(const [
        LatLng(double.nan, double.nan),
        LatLng(48.0, 2.0),
        LatLng(double.infinity, 2.0),
      ]);
      expect(bounds.north, greaterThan(bounds.south));
      expect(bounds.east, greaterThan(bounds.west));
      expectFiniteCamera(bounds);
    });

    test('all-non-finite input → fallback box → finite camera', () {
      final bounds = StationMapGeometry.boundsOfPoints(const [
        LatLng(double.nan, 1.0),
        LatLng(2.0, double.infinity),
      ]);
      expect(bounds.north, greaterThan(bounds.south));
      expect(bounds.east, greaterThan(bounds.west));
      expectFiniteCamera(bounds);
    });

    test('two DISTINCT points keep their real span (not over-padded)', () {
      final bounds = StationMapGeometry.boundsOfPoints(const [
        LatLng(48.0, 2.0),
        LatLng(49.0, 3.0),
      ]);
      expect(bounds.south, closeTo(48.0, 1e-9));
      expect(bounds.north, closeTo(49.0, 1e-9));
      expect(bounds.west, closeTo(2.0, 1e-9));
      expect(bounds.east, closeTo(3.0, 1e-9));
      expectFiniteCamera(bounds);
    });
  });

  group('boundsForRadius — finite even at zero / non-finite input (#3488)', () {
    test('zero radius → padded, non-degenerate, finite camera', () {
      final bounds =
          StationMapGeometry.boundsForRadius(const LatLng(48.0, 2.0), 0);
      expect(bounds.north, greaterThan(bounds.south));
      expect(bounds.east, greaterThan(bounds.west));
      expectFiniteCamera(bounds);
    });

    test('non-finite centre falls back to a finite box', () {
      final bounds = StationMapGeometry.boundsForRadius(
        const LatLng(double.nan, double.nan),
        5,
      );
      expect(bounds.north.isFinite, isTrue);
      expect(bounds.south.isFinite, isTrue);
      expectFiniteCamera(bounds);
    });
  });
}
