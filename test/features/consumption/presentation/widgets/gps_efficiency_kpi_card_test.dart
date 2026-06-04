// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/gps_driving_features.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/gps_efficiency_kpi_card.dart';

import '../../../../helpers/pump_app.dart';

/// Widget coverage for [GpsEfficiencyKpiCard]'s #2795 C6 verdict bands.
///
/// Drives the REAL card off real [GpsDrivingFeatures] values: asserts the
/// per-KPI verdict badges, their colour band (good = primary, moderate =
/// tertiary, aggressive = error) mirroring DrivingScoreCard, and the
/// one-line overall interpretation (worst-band-wins).
GpsDrivingFeatures _features({
  required double rpa,
  required double pke,
  required double vapos,
  required double coast,
}) {
  return GpsDrivingFeatures(
    idleSeconds: 10,
    lowSpeedSeconds: 40,
    cruiseSeconds: 40,
    highSpeedSeconds: 10,
    accelEvents: 2,
    brakeEvents: 1,
    maxAccelG: 0.2,
    meanSpeedKmh: 45,
    distanceKm: 12,
    totalSeconds: 100,
    gradeClimbMeters: 30,
    gradeDescentMeters: 25,
    cornerLoadIntegral: 5,
    relativePositiveAcceleration: rpa,
    positiveKineticEnergy: pke,
    meanPositiveVa: vapos,
    coastShare: coast,
    climbEnergyPerKm: 50,
  );
}

Color _colorOf(WidgetTester tester, String text) {
  final widget = tester.widget<Text>(find.text(text));
  return widget.style!.color!;
}

void main() {
  testWidgets('all-efficient features → good badges + good interpretation',
      (tester) async {
    await pumpApp(
      tester,
      GpsEfficiencyKpiCard(
        features: _features(rpa: 0.10, pke: 0.15, vapos: 0.8, coast: 0.35),
      ),
    );

    // Four "Efficient" badges (RPA / PKE / VAPOS / coast).
    expect(find.text('Efficient'), findsNWidgets(4));
    expect(
      find.byKey(const Key('gps_kpi_interpretation')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Smooth, energy-light driving — this is what efficient looks like.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the labelled trace fixture bands moderate everywhere',
      (tester) async {
    // RPA 0.224 / PKE 0.331 / VAPOS 1.42 / coast 0.18 — the score-78 drive.
    await pumpApp(
      tester,
      GpsEfficiencyKpiCard(
        features: _features(rpa: 0.224, pke: 0.331, vapos: 1.42, coast: 0.18),
      ),
    );

    expect(find.text('Moderate'), findsNWidgets(4));
    expect(
      find.text(
        'Fairly typical driving — a little smoother on the throttle would '
        'save more.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a single aggressive KPI drives the overall interpretation',
      (tester) async {
    // RPA hard, the rest calm — worst-band-wins → aggressive line.
    await pumpApp(
      tester,
      GpsEfficiencyKpiCard(
        features: _features(rpa: 0.5, pke: 0.15, vapos: 0.8, coast: 0.35),
      ),
    );

    expect(find.text('Aggressive'), findsOneWidget);
    expect(
      find.text(
        'Energy-heavy driving — easing off the accelerator and coasting '
        'more would cut fuel use.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('verdict colours follow the theme bands', (tester) async {
    await pumpApp(
      tester,
      GpsEfficiencyKpiCard(
        // RPA good, PKE moderate, VAPOS aggressive.
        features: _features(rpa: 0.10, pke: 0.40, vapos: 3.5, coast: 0.35),
      ),
    );

    // Each band maps to the documented ColorScheme role.
    final ctx = tester.element(find.byType(GpsEfficiencyKpiCard));
    final themeScheme = Theme.of(ctx).colorScheme;
    expect(_colorOf(tester, 'Moderate'), themeScheme.tertiary);
    expect(_colorOf(tester, 'Aggressive'), themeScheme.error);
    // "Efficient" appears for RPA and coast → primary.
    final efficient = tester.widget<Text>(find.text('Efficient').first);
    expect(efficient.style!.color, themeScheme.primary);
  });
}
