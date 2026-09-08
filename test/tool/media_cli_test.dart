// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #1017 — the only judgement the screenshot pipeline makes on its own:
// how far the second capture of a form slides up over the first.
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';

import '../../tool/media.dart';

/// A strip whose every row is distinguishable AND aperiodic — a form
/// that repeats itself every N rows genuinely overlaps at N, and the
/// detector would be right to say so.
img.Image _strip(int height, {required int seed}) {
  final random = math.Random(seed);
  final im = img.Image(width: 120, height: height);
  for (var y = 0; y < height; y++) {
    final v = 30 + random.nextInt(200);
    for (var x = 0; x < im.width; x++) {
      final on = (x + y) % 17 == 0;
      im.setPixelRgb(x, y, on ? 255 - v : v, v, (v + x) % 255);
    }
  }
  return im;
}

img.Image _flat(int height) {
  final im = img.Image(width: 120, height: height);
  img.fill(im, color: img.ColorRgb8(250, 250, 250));
  return im;
}

/// Two captures of one scrolling form: [overlap] rows are the same view.
(img.Image, img.Image) _captures({required int overlap}) {
  final whole = _strip(500, seed: 3);
  final a = img.copyCrop(whole, x: 0, y: 0, width: 120, height: 300);
  final b = img.copyCrop(whole,
      x: 0, y: 300 - overlap, width: 120, height: 500 - (300 - overlap));
  return (a, b);
}

void main() {
  test('the overlapping band is found, and it is the right one', () {
    final (a, b) = _captures(overlap: 120);
    final found = findOverlap(a, b);
    expect(found.rows, 120);
    expect(found.score, lessThan(1));
    // And it is not a coincidence: the runner-up is clearly worse.
    expect(found.runnerUp, greaterThan(found.score * 4));
  });

  test('captures that do not overlap are simply stacked', () {
    final a = _strip(200, seed: 1);
    final b = _strip(200, seed: 91);
    expect(findOverlap(a, b).rows, 0);
  });

  test('a blank band is not evidence — it matches everything', () {
    final a = _flat(200);
    final b = _flat(200);
    expect(findOverlap(a, b).rows, 0);
  });

  test('the stitch counts the overlap once and keeps both ends', () {
    final (a, b) = _captures(overlap: 120);
    final out = stitch(a, b, findOverlap(a, b).rows);
    expect(out.height, a.height + b.height - 120);
    final whole = _strip(500, seed: 3);
    for (final y in [0, 150, 299, 301, 400, 499]) {
      expect(out.getPixel(4, y).r, whole.getPixel(4, y).r, reason: 'row $y');
    }
  });

  test('a forced overlap is honoured even when the pixels disagree', () {
    final a = _strip(200, seed: 1);
    final b = _strip(200, seed: 91);
    expect(stitch(a, b, 50).height, 350);
  });
}
