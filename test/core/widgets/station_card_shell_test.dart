// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/theme.dart';
import 'package:tankstellen/core/theme/app_radius.dart';
import 'package:tankstellen/core/theme/spacing.dart';
import 'package:tankstellen/core/widgets/station_card_shell.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('StationCardShell (#2493)', () {
    testWidgets('owns the canonical card frame: margin, radius, clip', (
      tester,
    ) async {
      await pumpApp(tester, const StationCardShell(child: Text('body')));

      final card = tester.widget<Card>(find.byType(Card));
      // #3948 — the grammar's surface margin (12 / 8).
      // #4091 — the list gutter, half a standalone surface's.
      expect(card.margin, Spacing.listCardMargin);
      expect(card.clipBehavior, Clip.antiAlias);
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, AppRadius.lg);
      expect(find.text('body'), findsOneWidget);
    });

    for (final (name, theme) in [
      ('light', AppTheme.light()),
      ('dark', AppTheme.dark()),
      ('eco', AppTheme.eco()),
    ]) {
      testWidgets(
          '#4094 — a LIST ROW under $name: no fill, no outline, no '
          'elevation; one hairline separator underneath', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(body: StationCardShell(child: Text('x'))),
          ),
        );
        await tester.pumpAndSettle();
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, 0, reason: 'nothing floats but the selection');
        expect(card.color, Colors.transparent,
            reason: 'a fill AND an outline AND a gap is three boundaries '
                'per row; the hairline is one');
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.side, BorderSide.none);

        // The one boundary: a line UNDER the row, so two neighbours share
        // it instead of each drawing their own ring.
        final decorated = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(InkWell),
            matching: find.byType(DecoratedBox),
          ),
        );
        final border = (decorated.decoration as BoxDecoration).border! as Border;
        expect(border.bottom.color, theme.colorScheme.outlineVariant);
        expect(border.left, BorderSide.none);
      });

      testWidgets('#4094 — the SELECTED row is the only one that floats, '
          'under $name', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: StationCardShell(selected: true, child: Text('x')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = tester.widget<Card>(find.byType(Card));
        // Elevation is the whole signal, so it costs no colour beyond the
        // surface a floating thing needs to sit on.
        expect(card.elevation, 2);
        expect(card.color, theme.colorScheme.surfaceContainerHigh);
        final decorated = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(InkWell),
            matching: find.byType(DecoratedBox),
          ),
        );
        final border = (decorated.decoration as BoxDecoration).border! as Border;
        expect(border.bottom, BorderSide.none,
            reason: 'a floating row is already separated');
      });
    }

    testWidgets('draws a left stripe in the requested colour and width', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const StationCardShell(
          stripeColor: Color(0xFF123456),
          stripeWidth: 6,
          child: Text('body'),
        ),
      );

      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(StationCardShell),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final border = (box.decoration as BoxDecoration).border! as Border;
      expect(border.left.color, const Color(0xFF123456));
      expect(border.left.width, 6);
    });

    testWidgets('draws NO left stripe when stripeColor is null — #4091 '
        'spends the accent only where it means something', (tester) async {
      await pumpApp(tester, const StationCardShell(child: Text('body')));
      final decorated = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(DecoratedBox),
        ),
      );
      final border = (decorated.decoration as BoxDecoration).border! as Border;
      expect(border.left, BorderSide.none);
      expect(border.right, BorderSide.none);
      expect(border.top, BorderSide.none);
    });

    testWidgets('#4094 — the last row of a list suppresses its separator',
        (tester) async {
      await pumpApp(
        tester,
        const StationCardShell(separator: false, child: Text('body')),
      );
      final decorated = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(DecoratedBox),
        ),
      );
      final border = (decorated.decoration as BoxDecoration).border! as Border;
      expect(border.bottom, BorderSide.none);
    });

    testWidgets('forwards taps through the InkWell', (tester) async {
      var taps = 0;
      await pumpApp(
        tester,
        StationCardShell(onTap: () => taps++, child: const Text('body')),
      );
      await tester.tap(find.text('body'));
      expect(taps, 1);
    });
  });
}
