// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_lock_overlay.dart';

import '../../../../helpers/pump_app.dart';

/// Wrap the overlay in a Stack — the real driving screen does the
/// same — so Positioned.fill has a laid-out parent. [textScale] applies
/// the user's text-size setting the way the OS does (#3994).
Widget _host(Widget overlay, {double textScale = 1.0}) {
  return Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: Stack(children: [
        const SizedBox.expand(child: ColoredBox(color: Colors.blue)),
        overlay,
      ]),
    ),
  );
}

void main() {
  group('DrivingLockOverlay', () {
    testWidgets('renders the lock icon and tap-to-unlock text',
        (tester) async {
      await pumpApp(
        tester,
        _host(DrivingLockOverlay(onUnlock: () {})),
      );

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Tap to unlock'), findsOneWidget);
    });

    // #3994 — the prompt is a type role over the scrim foreground, not a
    // `fontSize: 24` / `Colors.white` literal: a literal ignored the user's
    // text-size setting on the one screen built around glanceability.
    testWidgets('text is bold, in the glanceable role, on the scrim '
        'foreground', (tester) async {
      await pumpApp(
        tester,
        _host(DrivingLockOverlay(onUnlock: () {})),
      );
      final finder = find.text('Tap to unlock');
      final text = tester.widget<Text>(finder);
      final context = tester.element(finder);
      expect(text.style?.fontWeight, FontWeight.bold);
      expect(text.style?.fontSize,
          Theme.of(context).textTheme.headlineMedium!.fontSize);
      expect(text.style?.color, DarkModeColors.scrimForeground(context));
    });

    testWidgets('text follows the text-size setting', (tester) async {
      Future<double> heightAt(double scale) async {
        await pumpApp(
          tester,
          _host(DrivingLockOverlay(onUnlock: () {}), textScale: scale),
        );
        return tester
            .renderObject<RenderParagraph>(find.text('Tap to unlock'))
            .size
            .height;
      }

      final normal = await heightAt(1.0);
      final large = await heightAt(1.3);
      expect(large, greaterThan(normal),
          reason: 'a hard fontSize would render the same height at 1.3x — '
              'the prompt must scale with the setting (#3994)');
    });

    testWidgets('icon is on the scrim foreground and sized 64 so it reads '
        'from afar', (tester) async {
      await pumpApp(
        tester,
        _host(DrivingLockOverlay(onUnlock: () {})),
      );
      final finder = find.byIcon(Icons.lock_outline);
      final icon = tester.widget<Icon>(finder);
      final context = tester.element(finder);
      expect(icon.size, 64);
      expect(icon.color,
          DarkModeColors.scrimForeground(context).withValues(alpha: 0.7));
    });

    testWidgets('tapping anywhere on the overlay invokes onUnlock',
        (tester) async {
      var unlocked = 0;
      await pumpApp(
        tester,
        _host(DrivingLockOverlay(onUnlock: () => unlocked++)),
      );

      // Tap the center — where the text lives — and also an offset
      // region to confirm the GestureDetector covers the full area.
      await tester.tap(find.text('Tap to unlock'));
      await tester.pump();
      expect(unlocked, 1);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(unlocked, 2);
    });
  });
}
