// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';

void main() {
  group('PriceFormatter', () {
    test('formats price correctly', () {
      expect(PriceFormatter.formatPrice(1.459), contains('1,459'));
      expect(PriceFormatter.formatPrice(null), '--');
      expect(PriceFormatter.formatPrice(0), '--');
    });

    test('formats distance correctly', () {
      expect(PriceFormatter.formatDistance(2.3), contains('2,3'));
      expect(PriceFormatter.formatDistance(0.5), contains('500 m'));
      expect(PriceFormatter.formatDistance(null), '--');
    });

    // #2171 — PriceFormatter.fuelTypeName was a dead, non-localized
    // re-implementation of FuelType.displayName (it hardcoded the
    // German 'Alle', a HARD-RULE violation). Deleted; fuel display
    // names come from FuelType.displayName, covered in fuel_type_test.
  });
}
