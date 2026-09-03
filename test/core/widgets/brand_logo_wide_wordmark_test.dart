// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/brand_logo.dart';

import '../../helpers/pump_app.dart';

/// #3940 — Commons hosts wordmarks, not emblems, and several are very
/// wide. Letterboxed into a square slot they collapse to an unreadable
/// strip, which would make the "real logo" worse for recognition than
/// the monogram it replaced. The card therefore lets a bundled logo
/// spend width; surfaces that reserve a fixed square in their own
/// measurements keep the square.
void main() {
  testWidgets('a bundled logo may grow wider than its height on the card',
      (tester) async {
    await pumpApp(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: BrandLogo(brand: 'Intermarché', size: 34, maxWidthFactor: 2),
      ),
    );
    await tester.pumpAndSettle();

    final box = tester.getRect(find.byType(BrandLogo));
    expect(box.height, 34, reason: 'height is what stays fixed');
    expect(box.width, greaterThanOrEqualTo(34));
    expect(box.width, lessThanOrEqualTo(68),
        reason: 'never wider than maxWidthFactor squares');
  });

  testWidgets('the default stays exactly square, so callers that reserve '
      'a square in their metrics are unaffected', (tester) async {
    await pumpApp(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: BrandLogo(brand: 'Intermarché', size: 48),
      ),
    );
    await tester.pumpAndSettle();

    final box = tester.getRect(find.byType(BrandLogo));
    expect(box.width, 48);
    expect(box.height, 48);
  });
}
