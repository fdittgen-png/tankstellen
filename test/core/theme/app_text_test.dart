// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/theme.dart';
import 'package:tankstellen/core/theme/app_text.dart';

/// #3948 (Epic #3947) — the four type roles are the whole point of the
/// grammar: a screen names a role, never a size, and the roles are
/// strictly ordered so the eye lands on the display number first.
void main() {
  Future<BuildContext> contextUnder(WidgetTester tester, ThemeData theme) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return captured;
  }

  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
    ('eco', AppTheme.eco()),
  ]) {
    group('AppText roles under AppTheme.$name', () {
      testWidgets('are strictly ordered display > title > body >= label', (
        tester,
      ) async {
        final context = await contextUnder(tester, theme);
        final display = AppText.display(context).fontSize!;
        final title = AppText.title(context).fontSize!;
        final body = AppText.body(context).fontSize!;
        final label = AppText.label(context).fontSize!;
        expect(display, greaterThan(title));
        expect(title, greaterThan(body));
        expect(body, greaterThanOrEqualTo(label));
      });

      testWidgets('display and unit carry tabular figures', (tester) async {
        final context = await contextUnder(tester, theme);
        expect(
          AppText.display(context).fontFeatures,
          contains(AppText.tabularFigures),
        );
        expect(
          AppText.unit(context).fontFeatures,
          contains(AppText.tabularFigures),
        );
      });

      testWidgets('display and title are semibold, body is not', (
        tester,
      ) async {
        final context = await contextUnder(tester, theme);
        expect(AppText.display(context).fontWeight, FontWeight.w600);
        expect(AppText.title(context).fontWeight, FontWeight.w600);
        expect(AppText.body(context).fontWeight, isNot(FontWeight.w600));
      });

      testWidgets('label and unit are muted onSurfaceVariant; the rest '
          'onSurface', (tester) async {
        final context = await contextUnder(tester, theme);
        final cs = Theme.of(context).colorScheme;
        expect(AppText.label(context).color, cs.onSurfaceVariant);
        expect(AppText.unit(context).color, cs.onSurfaceVariant);
        expect(AppText.display(context).color, cs.onSurface);
        expect(AppText.title(context).color, cs.onSurface);
        expect(AppText.body(context).color, cs.onSurface);
      });

      testWidgets('unit is smaller than display but larger than label so it '
          'survives beside a 36 sp number', (tester) async {
        final context = await contextUnder(tester, theme);
        final unit = AppText.unit(context).fontSize!;
        expect(unit, lessThan(AppText.display(context).fontSize!));
        expect(unit, greaterThan(AppText.label(context).fontSize!));
      });
    });
  }

  testWidgets('tabular figures are not duplicated when the base style '
      'already carries them', (tester) async {
    final theme = ThemeData(
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 36,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
    final context = await contextUnder(tester, theme);
    final tnum = AppText.display(context)
        .fontFeatures!
        .where((f) => f.feature == 'tnum');
    expect(tnum, hasLength(1));
  });
}
