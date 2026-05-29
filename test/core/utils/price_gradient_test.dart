// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_gradient.dart';

void main() {
  group('normalizedPrice (#2196)', () {
    test('maps min/mid/max to 0 / 0.5 / 1', () {
      expect(normalizedPrice(1.0, 1.0, 3.0), 0.0);
      expect(normalizedPrice(2.0, 1.0, 3.0), closeTo(0.5, 1e-9));
      expect(normalizedPrice(3.0, 1.0, 3.0), 1.0);
    });

    test('clamps out-of-range values', () {
      expect(normalizedPrice(0.0, 1.0, 3.0), 0.0);
      expect(normalizedPrice(9.0, 1.0, 3.0), 1.0);
    });

    test('degenerate range (max <= min) returns 0', () {
      expect(normalizedPrice(2.0, 3.0, 3.0), 0.0);
      expect(normalizedPrice(2.0, 5.0, 3.0), 0.0);
    });
  });

  group('priceGradientColor (#2196)', () {
    const stops = [Colors.green, Colors.yellow, Colors.orange, Colors.red];

    test('null price returns nullColor', () {
      expect(
        priceGradientColor(null, 1.0, 3.0,
            stops: stops, nullColor: Colors.grey, flatColor: Colors.green),
        Colors.grey,
      );
    });

    test('degenerate range returns flatColor', () {
      expect(
        priceGradientColor(2.0, 3.0, 3.0,
            stops: stops, nullColor: Colors.grey, flatColor: Colors.green),
        Colors.green,
      );
    });

    test('cheapest is greenest, most expensive is reddest', () {
      final cheap = priceGradientColor(1.0, 1.0, 3.0,
          stops: stops, nullColor: Colors.grey, flatColor: Colors.green);
      final dear = priceGradientColor(3.0, 1.0, 3.0,
          stops: stops, nullColor: Colors.grey, flatColor: Colors.green);
      // green channel dominates at the cheap end, red at the dear end.
      expect(cheap.g, greaterThan(cheap.r));
      expect(dear.r, greaterThan(dear.g));
    });

    test('respects a custom palette (driving bright colours)', () {
      const driving = [
        Color(0xFF4CAF50),
        Color(0xFFFFEB3B),
        Color(0xFFFF9800),
        Color(0xFFF44336),
      ];
      final c = priceGradientColor(1.0, 1.0, 3.0,
          stops: driving,
          nullColor: Colors.grey.shade400,
          flatColor: const Color(0xFF4CAF50));
      expect(c, const Color(0xFF4CAF50)); // t=0 → first stop exactly
    });
  });
}
