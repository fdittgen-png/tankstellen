// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3882 — chart visibility comes from the stored column set (`cols` of the
// v2 meta row) when it is known: an O(1) lookup instead of ten scans over
// the samples, and the same answer the scans would give.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trip_detail_charts.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trip_detail_charts_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

final _samples = [
  for (var i = 0; i < 20; i++)
    TripDetailSample(
      timestamp: DateTime(2026, 8, 30, 8, 0, i),
      speedKmh: 40.0 + i,
      rpm: 1800.0 + i,
      coolantTempC: 85,
    ),
];

void main() {
  testWidgets('without a column set the section scans the samples',
      (tester) async {
    await tester.pumpWidget(_host(TripDetailChartsSection(samples: _samples)));
    final l = AppLocalizations.of(tester.element(find.byType(ExpansionTile)));
    expect(find.text(l.trajetDetailChartRpm, skipOffstage: false), findsOneWidget);
    expect(find.text(l.trajetDetailChartCoolant, skipOffstage: false),
        findsOneWidget);
    expect(find.text(l.trajetDetailChartFuelRate, skipOffstage: false),
        findsNothing);
  });

  testWidgets('with a column set the stored columns decide, not the scan',
      (tester) async {
    // The samples carry RPM + coolant, but the stored column set says the
    // trip has fuel rate + altitude only → the set wins (it is the truth
    // for the whole trip; the samples may be a downsampled slice).
    await tester.pumpWidget(_host(TripDetailChartsSection(
      samples: _samples,
      columnsPresent: const {'s', 'f', 'al'},
    )));
    final l = AppLocalizations.of(tester.element(find.byType(ExpansionTile)));
    expect(find.text(l.trajetDetailChartRpm, skipOffstage: false), findsNothing);
    expect(find.text(l.trajetDetailChartCoolant, skipOffstage: false),
        findsNothing);
    expect(find.text(l.trajetDetailChartFuelRate, skipOffstage: false),
        findsOneWidget);
    expect(
        find.text(l.trajetDetailChartAltitudeRelative, skipOffstage: false),
        findsOneWidget);
  });
}
