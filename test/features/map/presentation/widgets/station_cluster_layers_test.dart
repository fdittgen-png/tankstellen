// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';
import 'package:tankstellen/core/theme/price_band_colors.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_cluster_layers.dart';

void main() {
  group('countClusterDecoration (#2975 — brand-themed cluster bubble)', () {
    testWidgets(
        'the count-cluster bubble uses the brand price-band ramp, NOT the '
        'plugin default primaryContainer', (tester) async {
      late BoxDecoration decoration;
      late ColorScheme scheme;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              decoration = countClusterDecoration(context);
              scheme = Theme.of(context).colorScheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // The fill is the canonical cheap-band brand green (at 94% alpha),
      // matching ClusterBadge — proving the count cluster shares the one
      // map colour language.
      expect(
        decoration.color,
        PriceBandColors.cheap.withValues(alpha: 0.94),
      );
      // It is explicitly NOT the old plugin-default primaryContainer.
      expect(decoration.color, isNot(scheme.primaryContainer));
      // Round bubble, white hairline, one drop shadow — the ClusterBadge
      // grammar.
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.boxShadow, hasLength(1));
      expect((decoration.border as Border).top.color,
          Colors.white.withValues(alpha: 0.85));
    });

    testWidgets('the shadow comes from the dark-mode map-overlay token',
        (tester) async {
      // The bubble shadow must be exactly the shared map-overlay shadow token
      // (the same one the legend / zoom buttons use), not a hard-coded colour
      // — so it adapts to dark mode like the rest of the map chrome.
      late Color shadow;
      late Color token;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            shadow = countClusterDecoration(context).boxShadow!.first.color;
            token = DarkModeColors.mapOverlayShadow(context);
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(shadow, token);
    });
  });
}
