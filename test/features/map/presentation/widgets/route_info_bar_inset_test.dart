// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/shell_bottom_inset.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_info_bar.dart';

import '../../../../helpers/pump_app.dart';

/// #4147 — the route summary carries controls, so it clears the chrome
/// the map is allowed to paint behind.
///
/// Branch bodies draw behind the shell's bottom bar (#4084 / #4096) and the
/// bar's height arrives as `MediaQuery.padding.bottom`. A map may paint
/// there. A bar with buttons may not: in the field its two actions landed
/// on the Android gesture strip, where a tap competes with system
/// navigation.
void main() {
  const inset = 48.0;

  Widget bar() => RouteInfoBar(
        distanceKm: 740,
        durationMinutes: 457,
        stationCountLabel: '16',
        onSaveRoute: () {},
        onOpenInMaps: () {},
      );

  testWidgets('its content clears the system inset', (tester) async {
    await pumpApp(
      tester,
      Builder(builder: (context) {
        // Copy the ambient MediaQuery so the screen SIZE stays real and
        // only the inset is simulated.
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(padding: const EdgeInsets.only(bottom: inset)),
          child: Column(
            children: [const Spacer(), ShellBottomInset(child: bar())],
          ),
        );
      }),
    );

    final barBottom = tester.getBottomLeft(find.byType(RouteInfoBar)).dy;
    final insetBottom =
        tester.getBottomLeft(find.byType(ShellBottomInset)).dy;

    // The whole point: the reserved strip below the bar IS the inset, so
    // the buttons never sit where system navigation lives.
    expect(insetBottom - barBottom, closeTo(inset, 0.5));
  });

  testWidgets('both actions meet the 48 dp minimum target', (tester) async {
    await pumpApp(tester, ShellBottomInset(child: bar()));

    // A sub-minimum target ADJACENT to a system gesture zone is how a tap
    // meant for "save route" becomes a system back.
    for (final icon in [Icons.bookmark_add_outlined, Icons.navigation]) {
      final button = find.ancestor(
        of: find.byIcon(icon),
        matching: find.byType(IconButton),
      );
      if (button.evaluate().isEmpty) continue;
      final size = tester.getSize(button.first);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('with no inset it adds nothing', (tester) async {
    // The widget must not invent space on a device with no gesture strip.
    await pumpApp(
      tester,
      MediaQuery(
        data: const MediaQueryData(),
        child: Column(children: [const Spacer(), ShellBottomInset(child: bar())]),
      ),
    );

    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(ShellBottomInset),
        matching: find.byType(Padding),
      ).first,
    );
    expect(padding.padding, EdgeInsets.zero);
  });
}
