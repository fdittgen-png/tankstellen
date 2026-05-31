// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/theme.dart';
import 'package:tankstellen/core/theme/contrast_utils.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_connector_chips.dart';

/// #2526 — structural (no-golden) contrast guard.
///
/// Instantiates the real [AppTheme.dark] / [AppTheme.light] schemes and
/// asserts, via [ContrastUtils], that the on-colour/fill pairings the
/// #2526 fixes pinned all clear WCAG AA. This guards against re-introducing
/// a non-adaptive (hardcoded light brand-green / `primaryContainer`-fill +
/// default-`onSurface`-text) combination that collapses to ~1.1–3.6:1 in
/// dark.
void main() {
  /// Resolves a [ColorScheme] (+ a themed [BuildContext]) from a real
  /// [AppTheme] and runs [body] against it.
  Future<void> withScheme(
    WidgetTester tester,
    ThemeData theme,
    void Function(ColorScheme cs, BuildContext context) body,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        // A key tied to the brightness forces a fresh element subtree when
        // the same test pumps a second theme — otherwise the Builder is
        // reused and keeps reading the previous theme.
        key: ValueKey(theme.brightness),
        theme: theme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              body(Theme.of(context).colorScheme, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void expectAA(Color fg, Color bg, String label) {
    final ratio = ContrastUtils.contrastRatio(fg, bg);
    expect(
      ratio,
      greaterThanOrEqualTo(ContrastUtils.kMinContrastNormal),
      reason: '$label: ${ratio.toStringAsFixed(2)}:1 (need >= 4.5)',
    );
  }

  void expectAALarge(Color fg, Color bg, String label) {
    final ratio = ContrastUtils.contrastRatio(fg, bg);
    expect(
      ratio,
      greaterThanOrEqualTo(ContrastUtils.kMinContrastLarge),
      reason: '$label: ${ratio.toStringAsFixed(2)}:1 (need >= 3.0)',
    );
  }

  for (final entry in {'dark': AppTheme.dark, 'light': AppTheme.light}.entries) {
    final mode = entry.key;
    final builder = entry.value;

    group('dark-contrast guard ($mode)', () {
      testWidgets(
        'onPrimaryContainer is legible on a solid primaryContainer fill '
        '(active-profile card #1 + active preset card #2)',
        (tester) async {
          await withScheme(tester, builder(), (cs, _) {
            expectAA(
              cs.onPrimaryContainer,
              cs.primaryContainer,
              '$mode onPrimaryContainer vs primaryContainer',
            );
          });
        },
      );

      testWidgets(
        'adaptive brandGreen clears AA-large on the Card surface '
        '(first-run wizard card #3)',
        (tester) async {
          await withScheme(tester, builder(), (cs, context) {
            // The wizard `_ProfileCard` is a default `Card`, whose M3 fill
            // is `surfaceContainerLow`. The brand wordmark/border/title
            // sit on the scaffold surface.
            expectAALarge(
              DarkModeColors.brandGreen(context),
              cs.surfaceContainerLow,
              '$mode brandGreen vs Card surface',
            );
            expectAALarge(
              DarkModeColors.brandGreen(context),
              cs.surface,
              '$mode brandGreen vs scaffold surface',
            );
          });
        },
      );

      testWidgets(
        'price-flash colours clear AA-large on the surface '
        '(AnimatedPriceText #4)',
        (tester) async {
          await withScheme(tester, builder(), (cs, context) {
            expectAALarge(
              DarkModeColors.success(context),
              cs.surface,
              '$mode price-drop (success) vs surface',
            );
            expectAALarge(
              DarkModeColors.error(context),
              cs.surface,
              '$mode price-increase (error) vs surface',
            );
          });
        },
      );

      testWidgets(
        'star-rating amber/gold clears AA-large on the surface '
        '(StarRating #7)',
        (tester) async {
          await withScheme(tester, builder(), (cs, context) {
            expectAALarge(
              DarkModeColors.warning(context),
              cs.surface,
              '$mode star amber vs surface',
            );
          });
        },
      );
    });
  }

  // #2526 — the reported EV-chip regression was the *dark*-surface chip
  // text (e.g. Tesla pink `#E91E63` was 3.94:1). The brightened dark hues
  // must clear AA-large; per-connector identity is preserved. (Chip text on
  // a *light* card was never AA — those are decorative 10 px pills with a
  // tinted fill + hairline outline, out of #2526's scope.)
  testWidgets(
    'dark EV connector chip text clears AA-large on the dark surface (#5)',
    (tester) async {
      await withScheme(tester, AppTheme.dark(), (cs, context) {
        final brightness = Theme.of(context).brightness;
        for (final type in const ['CCS', 'Type 2', 'CHAdeMO', 'Tesla']) {
          expectAALarge(
            EvConnectorChips.colorFor(type, brightness: brightness),
            cs.surface,
            'dark $type chip text vs surface',
          );
        }
      });
    },
  );

  testWidgets(
    'brandGreen adapts: dark uses scheme primary, light keeps icon green',
    (tester) async {
      late Color darkBrand;
      await withScheme(tester, AppTheme.dark(), (cs, context) {
        darkBrand = DarkModeColors.brandGreen(context);
        // On dark it is the scheme's lighter primary, not the hardcoded
        // light brand green.
        expect(darkBrand, cs.primary);
        expect(darkBrand, isNot(const Color(0xFF2E7D32)));
      });

      late Color lightBrand;
      await withScheme(tester, AppTheme.light(), (_, context) {
        lightBrand = DarkModeColors.brandGreen(context);
        // On light it keeps the icon brand green.
        expect(lightBrand, const Color(0xFF2E7D32));
      });

      expect(
        darkBrand,
        isNot(equals(lightBrand)),
        reason: 'brand green must brightness-select, not stay hardcoded',
      );
    },
  );
}
