import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/contrast_utils.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';

void main() {
  // Material 3 dark theme typical surface color
  const darkSurface = Color(0xFF1C1B1F);
  // Material 3 light theme typical surface color
  const lightSurface = Color(0xFFFFFBFE);

  Widget buildThemed({
    required Brightness brightness,
    required Widget child,
  }) {
    final theme = brightness == Brightness.light
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.light, // force theme application
      home: child,
    );
  }

  group('DarkModeColors — dark mode WCAG AA contrast', () {
    testWidgets('success color meets AA large (3:1) on dark surface', (tester) async {
      late Color successColor;
      await tester.pumpWidget(buildThemed(
        brightness: Brightness.dark,
        child: Builder(builder: (context) {
          successColor = DarkModeColors.success(context);
          return const SizedBox();
        }),
      ));
      final ratio = ContrastUtils.contrastRatio(successColor, darkSurface);
      expect(ratio, greaterThanOrEqualTo(ContrastUtils.kMinContrastLarge),
          reason: 'success on dark surface: ratio=$ratio (need >= 3.0)');
    });

    testWidgets('error color meets AA large (3:1) on dark surface', (tester) async {
      late Color errorColor;
      await tester.pumpWidget(buildThemed(
        brightness: Brightness.dark,
        child: Builder(builder: (context) {
          errorColor = DarkModeColors.error(context);
          return const SizedBox();
        }),
      ));
      final ratio = ContrastUtils.contrastRatio(errorColor, darkSurface);
      expect(ratio, greaterThanOrEqualTo(ContrastUtils.kMinContrastLarge),
          reason: 'error on dark surface: ratio=$ratio (need >= 3.0)');
    });

    testWidgets('warning color meets AA large (3:1) on dark surface', (tester) async {
      late Color warningColor;
      await tester.pumpWidget(buildThemed(
        brightness: Brightness.dark,
        child: Builder(builder: (context) {
          warningColor = DarkModeColors.warning(context);
          return const SizedBox();
        }),
      ));
      final ratio = ContrastUtils.contrastRatio(warningColor, darkSurface);
      expect(ratio, greaterThanOrEqualTo(ContrastUtils.kMinContrastLarge),
          reason: 'warning on dark surface: ratio=$ratio (need >= 3.0)');
    });
  });

  group('DarkModeColors — light mode WCAG AA contrast', () {
    testWidgets('success color meets AA large (3:1) on light surface', (tester) async {
      late Color successColor;
      await tester.pumpWidget(buildThemed(
        brightness: Brightness.light,
        child: Builder(builder: (context) {
          successColor = DarkModeColors.success(context);
          return const SizedBox();
        }),
      ));
      final ratio = ContrastUtils.contrastRatio(successColor, lightSurface);
      expect(ratio, greaterThanOrEqualTo(ContrastUtils.kMinContrastLarge),
          reason: 'success on light surface: ratio=$ratio (need >= 3.0)');
    });

    testWidgets('error color meets AA (4.5:1) on light surface', (tester) async {
      late Color errorColor;
      await tester.pumpWidget(buildThemed(
        brightness: Brightness.light,
        child: Builder(builder: (context) {
          errorColor = DarkModeColors.error(context);
          return const SizedBox();
        }),
      ));
      final ratio = ContrastUtils.contrastRatio(errorColor, lightSurface);
      expect(ratio, greaterThanOrEqualTo(ContrastUtils.kMinContrastNormal),
          reason: 'error on light surface: ratio=$ratio (need >= 4.5)');
    });

    testWidgets('warning color meets AA large (3:1) on light surface', (tester) async {
      late Color warningColor;
      await tester.pumpWidget(buildThemed(
        brightness: Brightness.light,
        child: Builder(builder: (context) {
          warningColor = DarkModeColors.warning(context);
          return const SizedBox();
        }),
      ));
      final ratio = ContrastUtils.contrastRatio(warningColor, lightSurface);
      expect(ratio, greaterThanOrEqualTo(ContrastUtils.kMinContrastLarge),
          reason: 'warning on light surface: ratio=$ratio (need >= 3.0)');
    });
  });

  group('DarkModeColors — mode switching', () {
    testWidgets('success returns different color in dark vs light theme', (tester) async {
      late Color lightSuccess;
      late Color darkSuccess;

      await tester.pumpWidget(buildThemed(
        brightness: Brightness.light,
        child: Builder(builder: (context) {
          lightSuccess = DarkModeColors.success(context);
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildThemed(
        brightness: Brightness.dark,
        child: Builder(builder: (context) {
          darkSuccess = DarkModeColors.success(context);
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();

      expect(lightSuccess, isNot(equals(darkSuccess)),
          reason: 'Success color should adapt to brightness');
    });

    testWidgets('mapOverlay adapts to dark theme', (tester) async {
      late Color darkOverlay;

      await tester.pumpWidget(buildThemed(
        brightness: Brightness.dark,
        child: Builder(builder: (context) {
          darkOverlay = DarkModeColors.mapOverlay(context);
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();

      // In dark mode, mapOverlay should NOT be white
      expect(darkOverlay, isNot(equals(Colors.white.withValues(alpha: 0.9))),
          reason: 'Map overlay in dark mode should not be white');
    });
  });

  group('Hardcoded color regression — demonstrating the problem', () {
    test('Colors.grey is not appropriate for text — fails AA normal on white', () {
      final ratioOnWhite = ContrastUtils.contrastRatio(Colors.grey, lightSurface);
      expect(ratioOnWhite, lessThan(ContrastUtils.kMinContrastNormal),
          reason: 'Colors.grey on white: ${ratioOnWhite.toStringAsFixed(1)}:1');
    });

    test('Colors.green on white fails AA normal text', () {
      final ratio = ContrastUtils.contrastRatio(Colors.green, lightSurface);
      expect(ratio, lessThan(ContrastUtils.kMinContrastNormal),
          reason: 'Colors.green on white: ${ratio.toStringAsFixed(1)}:1');
    });
  });
}
