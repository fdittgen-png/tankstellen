// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/cluster_badge.dart';

/// Unit + widget tests for the "Clustered + cheapest-labelled" density-cluster
/// badge (#2939): the cheapest-of resolution and that the badge surfaces the
/// CHEAPEST member price + the member count.
void main() {
  group('ClusterBadge.cheapestOf', () {
    test('returns the smallest positive price among members', () {
      expect(ClusterBadge.cheapestOf([1.799, 1.659, 1.999]), 1.659);
    });

    test('skips null and non-positive prices', () {
      expect(ClusterBadge.cheapestOf([null, 0, -1, 1.729, null]), 1.729);
    });

    test('returns null when no member has a usable price', () {
      expect(ClusterBadge.cheapestOf([null, 0, -2]), isNull);
    });
  });

  group('ClusterBadge.build', () {
    Future<void> pump(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: child))),
      );
    }

    testWidgets('shows the cheapest member price and the member count',
        (tester) async {
      await pump(
        tester,
        Builder(
          builder: (context) => ClusterBadge.build(
            context,
            cheapest: 1.659,
            count: 7,
            minPrice: 1.659,
            maxPrice: 1.999,
          ),
        ),
      );

      // The compact price formatter renders the 3-decimal figure (en locale
      // uses a dot; assert via a tolerant predicate over the badge text).
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      expect(
        texts.any((t) => t.contains('1') && t.contains('659')),
        isTrue,
        reason: 'badge must surface the cheapest member price (1.659), '
            'got: $texts',
      );
      // The count rolls up with the language-neutral multiplier.
      expect(find.text('×7'), findsOneWidget);
    });

    testWidgets('renders the "--" placeholder when no member has a price',
        (tester) async {
      await pump(
        tester,
        Builder(
          builder: (context) => ClusterBadge.build(
            context,
            cheapest: null,
            count: 3,
            minPrice: 0,
            maxPrice: 0,
          ),
        ),
      );

      expect(find.text('--'), findsOneWidget);
      expect(find.text('×3'), findsOneWidget);
    });
  });
}
