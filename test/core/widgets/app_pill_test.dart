// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/app_radius.dart';
import 'package:tankstellen/core/widgets/app_pill.dart';

/// Structural tests for the static [AppPill] (#2494) — the canonical
/// connector / amenity / count badge shape.
void main() {
  group('AppPill', () {
    testWidgets('renders label and optional icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppPill(label: 'Shop', icon: Icons.store),
        ),
      ));
      expect(find.text('Shop'), findsOneWidget);
      expect(find.byIcon(Icons.store), findsOneWidget);
    });

    testWidgets('renders label-only when no icon is given', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AppPill(label: '+3')),
      ));
      expect(find.text('+3'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('uses the canonical AppRadius.sm corner', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AppPill(label: 'WC')),
      ));
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('WC'),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, AppRadius.sm);
    });

    testWidgets('honours background + foreground overrides', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppPill(
            label: 'CCS',
            icon: Icons.ev_station,
            background: Color(0xFF4FC3F7),
            foreground: Color(0xFF000000),
          ),
        ),
      ));
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('CCS'),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF4FC3F7));
    });
  });
}
