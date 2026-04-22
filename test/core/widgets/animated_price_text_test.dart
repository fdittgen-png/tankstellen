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
