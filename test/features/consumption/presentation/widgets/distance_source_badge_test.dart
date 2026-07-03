// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/distance_source_badge.dart';
import 'package:tankstellen/features/obd2/api.dart'
    show
        kDistanceSourceGps,
        kDistanceSourceReal,
        kDistanceSourceVirtual;

import '../../../../helpers/pump_app.dart';

/// #3253 — the distance-provenance chip. `TripSummary.distanceSource`
/// was persisted + exported since #800/#1979 but rendered nowhere; this
/// badge gives the km figure the same trust disclosure the fuel figures
/// already have (the ~ / maturity badge).
void main() {
  testWidgets('odometer source renders the ground-truth chip',
      (tester) async {
    await pumpApp(
      tester,
      const DistanceSourceBadge(source: kDistanceSourceReal),
    );
    expect(find.text('Odometer'), findsOneWidget);
    expect(find.byIcon(Icons.speed), findsOneWidget);
  });

  testWidgets('gps source renders the GPS-track chip', (tester) async {
    await pumpApp(
      tester,
      const DistanceSourceBadge(source: kDistanceSourceGps),
    );
    expect(find.text('GPS track'), findsOneWidget);
    expect(find.byIcon(Icons.satellite_alt), findsOneWidget);
  });

  testWidgets('virtual source renders the Estimated chip', (tester) async {
    await pumpApp(
      tester,
      const DistanceSourceBadge(source: kDistanceSourceVirtual),
    );
    expect(find.text('Estimated'), findsOneWidget);
    expect(find.byIcon(Icons.functions), findsOneWidget);
  });

  testWidgets('every variant carries an explanatory tooltip',
      (tester) async {
    for (final source in [
      kDistanceSourceReal,
      kDistanceSourceGps,
      kDistanceSourceVirtual,
    ]) {
      await pumpApp(tester, DistanceSourceBadge(source: source));
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, isNotEmpty,
          reason: 'the $source chip must explain its trust level');
    }
  });
}
