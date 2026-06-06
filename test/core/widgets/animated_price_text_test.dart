// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/animated_price_text.dart';

void main() {
  group('AnimatedPriceText', () {
    testWidgets('renders child unchanged when price does not change',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AnimatedPriceText(
            price: 1.599,
            child: Text('1.599'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Re-pump with the same price. The controller must stay idle.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AnimatedPriceText(
            price: 1.599,
            child: Text('1.599'),
          ),
        ),
      ));
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse,
          reason: 'Identical price rebuilds should not kick the bounce '
              'controller.');
    });

    testWidgets('animates when price drops (new < old)', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AnimatedPriceText(
            price: 1.699,
            child: Text('1.699'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AnimatedPriceText(
            price: 1.499,
            child: Text('1.499'),
          ),
        ),
      ));
      await tester.pump();

      expect(tester.hasRunningAnimations, isTrue,
          reason: 'Price drop must trigger the 500 ms bounce.');

      await tester.pumpAndSettle();
    });

    testWidgets('animates when price increases (new > old)', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AnimatedPriceText(
            price: 1.499,
            child: Text('1.499'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AnimatedPriceText(
            price: 1.699,
            child: Text('1.699'),
          ),
        ),
      ));
      await tester.pump();

      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets(
        '#2972 — reduced motion: a price change does NOT kick the controller; '
        'child renders at end-state', (tester) async {
      Widget host(double price) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: Scaffold(
                body: AnimatedPriceText(
                  price: price,
                  child: Text(price.toStringAsFixed(3)),
                ),
              ),
            ),
          );

      await tester.pumpWidget(host(1.699));
      await tester.pumpAndSettle();

      // A real price DROP that would normally fire the 500 ms bounce.
      await tester.pumpWidget(host(1.499));
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse,
          reason: 'With OS reduced-motion on, the flash must be skipped — no '
              'running controller.');
      // The new price is still shown (end-state), just without the flash.
      expect(find.text('1.499'), findsOneWidget);
    });

    testWidgets('does not animate when old or new price is null',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AnimatedPriceText(
            price: null,
            child: Text('—'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AnimatedPriceText(
            price: 1.599,
            child: Text('1.599'),
          ),
        ),
      ));
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse,
          reason: 'Going from null → priced is a fresh render, not a '
              'change worth flashing.');
    });
  });
}
