// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/app_brand_glyph.dart';

import '../../helpers/pump_app.dart';

/// #4128 — the app's mark, shared between the splash and the home
/// screen's app bar.
void main() {
  group('AppBrandGlyph', () {
    testWidgets('takes its ink from the surrounding text when not told',
        (tester) async {
      // This is what makes the glyph usable as chrome: an app bar in the
      // dark or eco theme must not get the splash's fixed light green.
      await pumpApp(
        tester,
        const DefaultTextStyle(
          style: TextStyle(color: Color(0xFF123456)),
          child: AppBrandGlyph(size: 24),
        ),
      );

      expect(_inkOf(tester), const Color(0xFF123456));
    });

    testWidgets('an explicit colour wins — the splash paints on its own '
        'brand backdrop', (tester) async {
      await pumpApp(
        tester,
        const DefaultTextStyle(
          style: TextStyle(color: Color(0xFF123456)),
          child: AppBrandGlyph(size: 24, color: Color(0xFFABCDEF)),
        ),
      );

      expect(_inkOf(tester), const Color(0xFFABCDEF));
    });

    testWidgets('never announces the brand — the title beside it already '
        'does', (tester) async {
      await pumpApp(tester, const AppBrandGlyph(size: 24));

      expect(
        find.descendant(
          of: find.byType(AppBrandGlyph),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });
  });

  group('AppBrandTitle', () {
    testWidgets('shows the mark to the LEFT of the brand word',
        (tester) async {
      await pumpApp(tester, const Scaffold(appBar: _TitleBar()));

      final glyph = tester.getCenter(find.byType(AppBrandGlyph));
      final word = tester.getCenter(find.text('Sparkilo'));
      expect(glyph.dx, lessThan(word.dx));
    });

    testWidgets('keeps the header role PageScaffold hands to the caller',
        (tester) async {
      await pumpApp(tester, const Scaffold(appBar: _TitleBar()));

      final semantics = tester.widget<Semantics>(find.ancestor(
        of: find.text('Sparkilo'),
        matching: find.byType(Semantics),
      ).first);
      expect(semantics.properties.header, isTrue);
    });

    testWidgets('the mark still fits the 40 dp landscape bar', (tester) async {
      // The search screen shrinks its toolbar in landscape; a fixed glyph
      // size would overflow it.
      await pumpApp(
        tester,
        const Scaffold(appBar: _TitleBar(toolbarHeight: 40)),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AppBrandGlyph)).height,
          lessThanOrEqualTo(40));
    });
  });
}

/// The ink the mark actually resolved to.
Color _inkOf(WidgetTester tester) => (tester
        .widget<CustomPaint>(find.descendant(
          of: find.byType(AppBrandGlyph),
          matching: find.byType(CustomPaint),
        ))
        .painter! as AppBrandGlyphPainter)
    .ink;

class _TitleBar extends StatelessWidget implements PreferredSizeWidget {
  const _TitleBar({this.toolbarHeight});

  final double? toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        title: const AppBrandTitle(),
        toolbarHeight: toolbarHeight,
      );
}
