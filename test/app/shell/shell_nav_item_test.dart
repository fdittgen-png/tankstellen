import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/shell_nav_item.dart';

/// Tests the `ShellNavItem` data class plus the `ShellBounceIcon`
/// stateless animated widget under `lib/app/shell/`.
///
/// `ShellNavItem` is a const data carrier — verify the constructor
/// stores fields verbatim and that two instances are independent.
///
/// `ShellBounceIcon` drives a 3-segment `TweenSequence` (40/30/30) on a
/// shared `AnimationController`. The bounce starts at 1.0, peaks at
/// 1.25 (end of the first segment, t=0.4), dips to 0.95, then settles
/// back to 1.0. We probe controller values 0.0, 0.4, and 1.0 to lock
/// in those landmarks, and confirm the inner `Icon` reflects the
/// supplied IconData/size/color.
void main() {
  group('ShellNavItem', () {
    test('stores constructor params on the matching fields', () {
      const item = ShellNavItem(
        Icons.search_outlined,
        Icons.search,
        'Search',
      );

      expect(item.outlinedIcon, Icons.search_outlined);
      expect(item.filledIcon, Icons.search);
      expect(item.label, 'Search');
    });

    test('multiple instances are independent', () {
      const a = ShellNavItem(
        Icons.map_outlined,
        Icons.map,
        'Map',
      );
      const b = ShellNavItem(
        Icons.favorite_outline,
        Icons.favorite,
        'Favorites',
      );

      expect(a.outlinedIcon, Icons.map_outlined);
      expect(a.label, 'Map');
      expect(b.outlinedIcon, Icons.favorite_outline);
      expect(b.label, 'Favorites');
      // The two instances must not share state — sanity-check that
      // `a` did not get mutated by constructing `b`.
      expect(a.filledIcon, isNot(b.filledIcon));
    });
  });

  group('ShellBounceIcon', () {
    /// Pumps the bounce icon under a minimal Directionality wrapper —
    /// no MaterialApp / l10n is required because the widget reads no
    /// localised strings.
    Future<void> pumpBounceIcon(
      WidgetTester tester, {
      required AnimationController controller,
      bool selected = false,
      IconData icon = Icons.search,
      double iconSize = 24.0,
      Color color = const Color(0xFF112233),
    }) {
      return tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ShellBounceIcon(
            controller: controller,
            selected: selected,
            icon: icon,
            iconSize: iconSize,
            color: color,
          ),
        ),
      );
    }

    /// Reads the X-axis scale factor off the inner `Transform`. The
    /// widget always renders exactly one `Transform` because there is
    /// only one `Transform.scale` in the tree.
    double readScale(WidgetTester tester) {
      final transform = tester.widget<Transform>(find.byType(Transform));
      return transform.transform.entry(0, 0);
    }

    testWidgets('renders an Icon with the supplied data, size and color',
        (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      const expectedColor = Color(0xFFAA00FF);
      await pumpBounceIcon(
        tester,
        controller: controller,
        icon: Icons.local_gas_station,
        iconSize: 32.0,
        color: expectedColor,
      );

      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, Icons.local_gas_station);
      expect(iconWidget.size, 32.0);
      expect(iconWidget.color, expectedColor);
    });

    testWidgets('scale is 1.0 at controller value 0.0 (start of first tween)',
        (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      await pumpBounceIcon(tester, controller: controller);

      controller.value = 0.0;
      await tester.pump();

      expect(readScale(tester), closeTo(1.0, 0.001));
    });

    testWidgets('scale is 1.0 at controller value 1.0 (end of last tween)',
        (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      await pumpBounceIcon(tester, controller: controller);

      controller.value = 1.0;
      await tester.pump();

      // The bounce returns to baseline at the end of the third
      // segment.
      expect(readScale(tester), closeTo(1.0, 0.001));
    });

    testWidgets('scale peaks at 1.25 at controller value 0.4 '
        '(end of first segment, weight=40)', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      await pumpBounceIcon(tester, controller: controller);

      controller.value = 0.4;
      await tester.pump();

      // 0.4 lands exactly on the boundary between the 40-weight and
      // 30-weight segments — the easeOut tween reaches its endpoint
      // 1.25 at this point.
      expect(readScale(tester), closeTo(1.25, 0.001));
    });

    testWidgets('AnimatedBuilder rebuilds when the controller value changes',
        (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      await pumpBounceIcon(tester, controller: controller);

      controller.value = 0.0;
      await tester.pump();
      final initialScale = readScale(tester);

      controller.value = 0.4;
      await tester.pump();
      final peakScale = readScale(tester);

      // Sanity — pumping after a controller change must rebuild the
      // Transform with the new scale; if AnimatedBuilder were not
      // wired up, both reads would match.
      expect(initialScale, closeTo(1.0, 0.001));
      expect(peakScale, closeTo(1.25, 0.001));
      expect(peakScale, isNot(closeTo(initialScale, 0.001)));
    });
  });
}
