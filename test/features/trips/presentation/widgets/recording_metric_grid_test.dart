// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_unit.dart';
import 'package:tankstellen/features/obd2/domain/trip_live_reading.dart';
import 'package:tankstellen/features/trips/presentation/widgets/recording/recording_metric_grid.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #3916 (Epic #3914) — the compact trip-figures grid that replaced the
/// six full-width metric rows: Distance / Elapsed, Fuel used / Driving
/// score, and the consumption card spanning the last row.
Widget _harness(
  TripLiveReading? reading, {
  double width = 328,
  bool expand = false,
  double? height,
  Locale locale = const Locale('en'),
}) {
  final grid = RecordingMetricGrid(
    reading: reading,
    brokenMapOverride: null,
    unit: ConsumptionUnit.lPer100Km,
    expand: expand,
  );
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: width, height: height, child: grid),
        ),
      ),
    ),
  );
}

const _reading = TripLiveReading(
  elapsed: Duration(minutes: 12, seconds: 5),
  distanceKmSoFar: 8.25,
  fuelLitersSoFar: 0.61,
  liveDrivingScore: 82,
  speedKmh: 52,
);

void main() {
  testWidgets('renders the five figures in a 2-column grid with the '
      'consumption card on the last row', (tester) async {
    await tester.pumpWidget(_harness(_reading));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recordingTileDistance')), findsOneWidget);
    expect(find.byKey(const Key('recordingTileElapsed')), findsOneWidget);
    expect(find.byKey(const Key('recordingTileFuel')), findsOneWidget);
    expect(find.byKey(const Key('recordingTileScore')), findsOneWidget);
    expect(find.byKey(const Key('tripAvgConsumptionCard')), findsOneWidget);

    expect(find.text('8,25 km'), findsOneWidget);
    expect(find.text('12:05'), findsOneWidget);
    expect(find.text('0,61 L'), findsOneWidget);
    expect(find.text('82'), findsOneWidget);
    expect(find.text('Driving score'), findsOneWidget);
    // 0.61 L / 8.25 km = 7.4 L/100 km — the ONE average on the surface.
    expect(find.text('7.4 L/100 km'), findsOneWidget);

    // Layout: Distance left of Elapsed on the same row; Fuel below them;
    // the consumption card spans the full width under both columns.
    final distance =
        tester.getRect(find.byKey(const Key('recordingTileDistance')));
    final elapsed =
        tester.getRect(find.byKey(const Key('recordingTileElapsed')));
    final fuel = tester.getRect(find.byKey(const Key('recordingTileFuel')));
    final avg = tester.getRect(find.byKey(const Key('tripAvgConsumptionCard')));
    expect(distance.top, elapsed.top);
    expect(distance.right, lessThanOrEqualTo(elapsed.left));
    expect(fuel.top, greaterThan(distance.bottom));
    expect(avg.top, greaterThan(fuel.bottom));
    expect(avg.width, greaterThan(distance.width * 1.9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('no reading renders dashes without throwing', (tester) async {
    await tester.pumpWidget(_harness(null));
    await tester.pumpAndSettle();
    expect(find.text('—'), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('GPS-only reading shows the ~ estimate in the fuel tile',
      (tester) async {
    await tester.pumpWidget(_harness(const TripLiveReading(
      elapsed: Duration(minutes: 3),
      distanceKmSoFar: 2.0,
      gpsEstimatedFuelLitersSoFar: 0.14,
      gpsEstimatedAvgLPer100Km: 7.0,
    )));
    await tester.pumpAndSettle();
    expect(find.text('~0,14 L'), findsOneWidget);
    expect(find.text('~7.0 L/100 km'), findsOneWidget);
  });

  testWidgets('expand mode fills a fixed landscape pane with no overflow, '
      'also at 1.3x', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
        _harness(_reading, width: 420, height: 320, expand: true));
    await tester.pumpAndSettle();
    final grid = tester.getRect(find.byKey(const Key('recordingMetricGrid')));
    expect(grid.height, 320);
    expect(tester.takeException(), isNull);
  });
}
