// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/app_radius.dart';
import 'package:tankstellen/core/widgets/selectable_pill.dart';

/// Structural tests for the unified [SelectablePill] (#2494) — the single
/// toggle pill that replaced the near-identical `ModeChip` (search) and
/// `RouteViewModeChip` (map) widgets.
void main() {
  group('SelectablePill', () {
    Widget buildSubject({
      bool selected = false,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SelectablePill(
            label: 'Nearby',
            icon: Icons.near_me,
            selected: selected,
            onTap: onTap ?? () {},
          ),
        ),
      );
    }

    testWidgets('renders label and icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('Nearby'), findsOneWidget);
      expect(find.byIcon(Icons.near_me), findsOneWidget);
    });

    testWidgets('selected state bolds the label and fills the background',
        (tester) async {
      await tester.pumpWidget(buildSubject(selected: true));
      await tester.pump(const Duration(milliseconds: 250));

      final textWidget = tester.widget<Text>(find.text('Nearby'));
      expect(textWidget.style?.fontWeight, FontWeight.w600);

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNot(Colors.transparent));
    });

    testWidgets('unselected state is transparent with normal weight',
        (tester) async {
      await tester.pumpWidget(buildSubject(selected: false));
      await tester.pump(const Duration(milliseconds: 250));

      final textWidget = tester.widget<Text>(find.text('Nearby'));
      expect(textWidget.style?.fontWeight, FontWeight.normal);

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent);
    });

    testWidgets('uses the canonical AppRadius.xl pill corner', (tester) async {
      await tester.pumpWidget(buildSubject());
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, AppRadius.xl);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildSubject(onTap: () => tapped = true));
      await tester.tap(find.text('Nearby'));
      expect(tapped, isTrue);
    });
  });
}
