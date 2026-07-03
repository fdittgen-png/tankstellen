// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/fuel_event_attribution.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fuel_breakdown_card.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #3432 (epic #3416) — the "where your fuel went" card renders one row
/// per attributed class, the coasting saving as a positive row, and
/// self-hides when nothing was attributed.
Widget _harness(FuelAttribution attribution, {double? totalTripLiters}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: FuelBreakdownCard(
        attribution: attribution,
        totalTripLiters: totalTripLiters,
      ),
    ),
  );
}

FuelEvent _event(FuelEventType type, int startSecond, int seconds,
    double liters) {
  final start = DateTime.utc(2026, 7, 1, 8).add(Duration(seconds: startSecond));
  return FuelEvent(
    type: type,
    start: start,
    end: start.add(Duration(seconds: seconds)),
    liters: liters,
  );
}

void main() {
  group('FuelBreakdownCard (#3432)', () {
    testWidgets('renders the per-class rows, the saving row and the '
        'remainder', (tester) async {
      final attribution = FuelAttribution(
        events: [
          _event(FuelEventType.idle, 0, 120, 0.2),
          _event(FuelEventType.harshAccel, 200, 6, 0.1),
          _event(FuelEventType.highRpmCruise, 400, 90, 0.3),
          _event(FuelEventType.coasting, 600, 200, 0.1),
        ],
        totalSeconds: 1800,
      );
      await tester
          .pumpWidget(_harness(attribution, totalTripLiters: 1.5));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fuel_breakdown_card')), findsOneWidget);
      expect(find.text('Where your fuel went'), findsOneWidget);
      expect(find.byKey(const ValueKey('fuel_breakdown_row_idle')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('fuel_breakdown_row_harshAccel')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('fuel_breakdown_row_highRpmCruise')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('fuel_breakdown_row_coastingSaved')),
          findsOneWidget);
      // Remainder: 1.5 − (0.2 + 0.1 + 0.3) = 0.9 → plain "0.9 L".
      expect(find.byKey(const ValueKey('fuel_breakdown_row_efficient')),
          findsOneWidget);
      expect(find.text('0.9 L'), findsOneWidget);
      // Saving badge carries the minus sign, waste rows the plus.
      expect(find.text('−0.1 L'), findsOneWidget);
      expect(find.text('+0.2 L'), findsOneWidget);
    });

    testWidgets('self-hides when nothing was attributed', (tester) async {
      await tester.pumpWidget(
          _harness(FuelAttribution.empty, totalTripLiters: 1.5));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fuel_breakdown_card')), findsNothing);
    });

    testWidgets('below-noise-floor classes are dropped', (tester) async {
      final attribution = FuelAttribution(
        events: [
          _event(FuelEventType.idle, 0, 10, 0.01), // < 0.05 L floor
        ],
        totalSeconds: 600,
      );
      await tester.pumpWidget(_harness(attribution, totalTripLiters: 1.0));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fuel_breakdown_card')), findsNothing);
    });
  });
}
