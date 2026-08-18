// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/info_card.dart';

void main() {
  group('InfoCard', () {
    Future<void> pumpCard(WidgetTester tester, InfoCard card) {
      return tester.pumpWidget(
        MaterialApp(home: Scaffold(body: card)),
      );
    }

    testWidgets('renders icon, title, and optional body inside a Card',
        (tester) async {
      await pumpCard(
        tester,
        const InfoCard(
          icon: Icons.info_outline,
          title: 'Title',
          body: 'Body text',
        ),
      );
      expect(find.byType(Card), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Body text'), findsOneWidget);
    });

    testWidgets('omits the body row when body is null and renders children',
        (tester) async {
      await pumpCard(
        tester,
        const InfoCard(
          icon: Icons.link,
          title: 'Header only',
          children: [SizedBox(height: 12), Text('Extra child')],
        ),
      );
      expect(find.text('Header only'), findsOneWidget);
      expect(find.text('Extra child'), findsOneWidget);
    });

    testWidgets('expandTitle wraps the title in an Expanded', (tester) async {
      await pumpCard(
        tester,
        const InfoCard(
          icon: Icons.verified_user,
          title: 'Long title',
          expandTitle: true,
        ),
      );
      expect(
        find.ancestor(
          of: find.text('Long title'),
          matching: find.byType(Expanded),
        ),
        findsOneWidget,
      );
    });
  });
}
