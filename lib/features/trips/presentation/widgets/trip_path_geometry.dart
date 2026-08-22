// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'trip_detail_charts.dart';

/// Pure geometry helpers for the trip-detail map (#3316), kept out of the
/// widget so they're unit-testable without a live `FlutterMap` and so the
/// near-cap card file stays small.
///
/// Both guard the two non-finite faults that crashed the map in the field:
///   * a `NaN`/`Infinity` GPS coordinate reaching `MarkerLayer` →
///     `Crs.checkLatLng` throws; and
///   * a zero-span bounds (single point, or every fix at the SAME
///     coordinate — a stationary / sub-100 m degenerate trip) making
///     `CameraFit.bounds` compute an infinite fit-zoom that
///     `_TileLayerState._clampToNativeZoom` turns into `Infinity.toInt()` →
///     `UnsupportedError`.

/// The map polyline points paired with the source samples they came from,
/// index-aligned so the inner map can colour segments by telemetry.
class TripPathPoints {
  final List<LatLng> points;
  final List<TripDetailSample> samples;

  const TripPathPoints(this.points, this.samples);
}

/// Builds the index-aligned (point, sample) lists, dropping any fix whose
/// latitude/longitude is null OR non-finite. The recorder writes the
/// lat/lng pair atomically, but the type allows a half-set/NaN pair, so we
/// filter defensively at the read site — a non-finite `LatLng` crashes
/// flutter_map's `MarkerLayer` (`Crs.checkLatLng`).
TripPathPoints buildTripPathPoints(List<TripDetailSample> samples) {
  final points = <LatLng>[];
  final kept = <TripDetailSample>[];
  for (final s in samples) {
    final lat = s.latitude;
    final lng = s.longitude;
    if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
      points.add(LatLng(lat, lng));
      kept.add(s);
    }
  }
  return TripPathPoints(points, kept);
}

/// The polyline bounds, with any near-zero span padded by [eps] so
/// `CameraFit.bounds` always has a finite area to fit. Folds the
/// single-point and all-identical-points cases into one path. [points]
/// must be non-empty and all-finite (see [buildTripPathPoints]).
LatLngBounds tripPathBounds(List<LatLng> points, {double eps = 0.0005}) {
  // eps ≈ 50 m at the equator — a sane minimum frame for a stationary trip.
  var minLat = points.first.latitude;
  var maxLat = minLat;
  var minLng = points.first.longitude;
  var maxLng = minLng;
  for (final p in points) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }
  if (maxLat - minLat < eps) {
    minLat -= eps;
    maxLat += eps;
  }
  if (maxLng - minLng < eps) {
    minLng -= eps;
    maxLng += eps;
  }
  return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
}
