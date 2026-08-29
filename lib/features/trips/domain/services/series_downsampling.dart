// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

/// #3878 — rendering-side downsampling. Storage keeps every sample; the
/// widgets draw a bounded number of points.
///
/// * [lttbIndices] — Largest-Triangle-Three-Buckets (Steinarsson 2013), the
///   standard for time-series charts: keeps the visually significant
///   points (peaks, troughs) while reducing n → threshold. O(n).
/// * [douglasPeuckerIndices] — Ramer–Douglas–Peucker polyline
///   simplification for the map track, with a metre tolerance on an
///   equirectangular projection. O(n log n) typical.
///
/// Both return INDICES into the input so a caller can keep any parallel
/// data (the sample behind the point) aligned.

/// LTTB over `(x[i], y[i])`; returns ascending indices, length ≤ [threshold]
/// (all indices when `n ≤ threshold` or `threshold < 3`).
List<int> lttbIndices({
  required int length,
  required double Function(int i) x,
  required double Function(int i) y,
  required int threshold,
}) {
  final n = length;
  if (threshold < 3 || n <= threshold) {
    return List<int>.generate(n, (i) => i, growable: false);
  }
  final out = <int>[0];
  final bucketSize = (n - 2) / (threshold - 2);
  var a = 0;
  for (var b = 0; b < threshold - 2; b++) {
    // Average of the NEXT bucket (the triangle's far vertex).
    var nextStart = ((b + 1) * bucketSize).floor() + 1;
    var nextEnd = ((b + 2) * bucketSize).floor() + 1;
    if (nextEnd > n) nextEnd = n;
    if (nextStart >= nextEnd) nextStart = nextEnd - 1;
    var avgX = 0.0, avgY = 0.0;
    for (var i = nextStart; i < nextEnd; i++) {
      avgX += x(i);
      avgY += y(i);
    }
    final cnt = nextEnd - nextStart;
    avgX /= cnt;
    avgY /= cnt;
    // This bucket: pick the point forming the largest triangle with
    // (a) and the next bucket's average.
    final start = (b * bucketSize).floor() + 1;
    var end = ((b + 1) * bucketSize).floor() + 1;
    if (end > n - 1) end = n - 1;
    final ax = x(a), ay = y(a);
    var best = start;
    var bestArea = -1.0;
    for (var i = start; i < end; i++) {
      final area =
          ((ax - avgX) * (y(i) - ay) - (ax - x(i)) * (avgY - ay)).abs();
      if (area > bestArea) {
        bestArea = area;
        best = i;
      }
    }
    out.add(best);
    a = best;
  }
  out.add(n - 1);
  return out;
}

/// Douglas–Peucker over lat/lng (degrees) with [toleranceM] metres;
/// returns ascending indices (always the first and the last).
List<int> douglasPeuckerIndices({
  required int length,
  required double Function(int i) lat,
  required double Function(int i) lng,
  double toleranceM = 5,
}) {
  if (length < 3) return List<int>.generate(length, (i) => i);
  // Equirectangular projection around the mid-latitude: metres per
  // degree, good to <1 % over a trip-sized extent.
  final midLat = (lat(0) + lat(length - 1)) / 2 * math.pi / 180;
  const mPerDegLat = 111320.0;
  final mPerDegLng = 111320.0 * math.cos(midLat);
  double px(int i) => lng(i) * mPerDegLng;
  double py(int i) => lat(i) * mPerDegLat;

  final keep = List<bool>.filled(length, false)
    ..[0] = true
    ..[length - 1] = true;
  final stack = <(int, int)>[(0, length - 1)];
  while (stack.isNotEmpty) {
    final (s, e) = stack.removeLast();
    if (e - s < 2) continue;
    final sx = px(s), sy = py(s), ex = px(e), ey = py(e);
    final dx = ex - sx, dy = ey - sy;
    final len2 = dx * dx + dy * dy;
    var maxD = -1.0;
    var maxI = s;
    for (var i = s + 1; i < e; i++) {
      final x = px(i), y = py(i);
      double d;
      if (len2 == 0) {
        d = math.sqrt((x - sx) * (x - sx) + (y - sy) * (y - sy));
      } else {
        // Perpendicular distance to the segment line.
        d = ((dy * x - dx * y + ex * sy - ey * sx)).abs() / math.sqrt(len2);
      }
      if (d > maxD) {
        maxD = d;
        maxI = i;
      }
    }
    if (maxD > toleranceM) {
      keep[maxI] = true;
      stack
        ..add((s, maxI))
        ..add((maxI, e));
    }
  }
  return [for (var i = 0; i < length; i++) if (keep[i]) i];
}

/// Convenience: the elements of [items] at [indices].
List<T> pickIndices<T>(List<T> items, List<int> indices) =>
    [for (final i in indices) items[i]];
