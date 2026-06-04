// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/gps_driving_features.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/gps_road_usage_card.dart';

import '../../../../helpers/pump_app.dart';

/// Widget coverage for [GpsRoadUsageCard] (#2796 C7) — the GPS-only
/// "how you used the road" panel that replaces the dead throttle/RPM
/// card on dongle-less trips.
///
/// Drives the REAL widget off real [GpsDrivingFeatures] aggregates (no
/// fake that echoes the inputs): asserts the localized title + section
/// labels, the four speed-band + three movement-phase rows, the
/// whole-percent share formatting, the proportional bar flex, and the
/// coasting-praise threshold (shown only when coast share is high).
GpsDrivingFeatures _features({
  double idleSeconds = 10,
  double lowSpeedSeconds = 30,
  double cruiseSeconds = 50,
  double highSpeedSeconds = 10,
  double accelShare = 0.30,
  double steadyShare = 0.55,
  double coastShare = 0.15,
}) {
  return GpsDrivingFeatures(
    idleSeconds: idleSeconds,
    lowSpeedSeconds: lowSpeedSeconds,
    cruiseSeconds: cruiseSeconds,
    highSpeedSeconds: highSpeedSeconds,
    accelEvents: 0,
    brakeEvents: 0,
    maxAccelG: 0,
    meanSpeedKmh: 40,
    distanceKm: 10,
    totalSeconds: idleSeconds + lowSpeedSeconds + cruiseSeconds + highSpeedSeconds,
    gradeClimbMeters: 0,
    gradeDescentMeters: 0,
    cornerLoadIntegral: 0,
    accelShare: accelShare,
    steadyShare: steadyShare,
    coastShare: coastShare,
  );
}

void main() {
  group('GpsRoadUsageCard — title + sections', () {
    testWidgets('renders the localized title and both section headers',
        (tester) async {
      await pumpApp(tester, GpsRoadUsageCard(features: _features()));

      expect(find.text('How you used the road'), findsOneWidget);
      expect(find.text('Where you spent your time'), findsOneWidget);
      expect(find.text('How you moved'), findsOneWidget);
      expect(find.text('From your GPS track'), findsOneWidget);
    });

    testWidgets('renders all four speed-band labels', (tester) async {
      await pumpApp(tester, GpsRoadUsageCard(features: _features()));

      expect(find.text('Stopped (<5 km/h)'), findsOneWidget);
      expect(find.text('Town (5–50 km/h)'), findsOneWidget);
      expect(find.text('Cruise (50–110 km/h)'), findsOneWidget);
      expect(find.text('Fast (≥110 km/h)'), findsOneWidget);
    });

    testWidgets('renders all three movement-phase labels', (tester) async {
      await pumpApp(tester, GpsRoadUsageCard(features: _features()));

      expect(find.text('Accelerating'), findsOneWidget);
      expect(find.text('Holding speed'), findsOneWidget);
      expect(find.text('Coasting'), findsOneWidget);
    });
  });

  group('GpsRoadUsageCard — share formatting', () {
    testWidgets('formats speed-band shares as whole-number percent',
        (tester) async {
      // 100 total seconds → idle 10 % / low 30 % / cruise 50 % / high 10 %.
      await pumpApp(tester, GpsRoadUsageCard(features: _features()));

      // Cruise band 50 % and accel phase 30 % both render their percent.
      expect(find.text('50%'), findsWidgets);
      expect(find.text('30%'), findsWidgets);
      expect(find.textContaining('.0%'), findsNothing);
    });
  });

  group('GpsRoadUsageCard — coasting praise threshold', () {
    testWidgets('hides the coasting praise when coast share is below 25 %',
        (tester) async {
      await pumpApp(
        tester,
        GpsRoadUsageCard(features: _features(coastShare: 0.15)),
      );

      expect(find.byKey(const Key('gps_road_use_coast_praise')), findsNothing);
    });

    testWidgets('shows the coasting praise when coast share is high',
        (tester) async {
      await pumpApp(
        tester,
        GpsRoadUsageCard(
          features: _features(
            accelShare: 0.25,
            steadyShare: 0.40,
            coastShare: 0.35,
          ),
        ),
      );

      expect(
        find.byKey(const Key('gps_road_use_coast_praise')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Lots of coasting — letting the car roll instead of braking '
          'saves fuel. Nice.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the praise exactly at the 25 % boundary',
        (tester) async {
      await pumpApp(
        tester,
        GpsRoadUsageCard(
          features: _features(
            accelShare: 0.30,
            steadyShare: 0.45,
            coastShare: kGpsRoadUseCoastPraiseThreshold,
          ),
        ),
      );

      expect(
        find.byKey(const Key('gps_road_use_coast_praise')),
        findsOneWidget,
      );
    });
  });

  group('GpsRoadUsageCard — proportional bar flex', () {
    testWidgets('a larger-share band gets more Flexible flex', (tester) async {
      // cruise 50 % vs idle 10 % — cruise must occupy more flex.
      await pumpApp(tester, GpsRoadUsageCard(features: _features()));

      final cruiseFlex = _filledFlex(tester, 'Cruise (50–110 km/h)');
      final idleFlex = _filledFlex(tester, 'Stopped (<5 km/h)');
      expect(cruiseFlex, greaterThan(idleFlex));
    });
  });
}

/// Walk up from the [label] text to the enclosing share row and return
/// the flex of the FIRST [Flexible] (the filled portion of the bar).
int _filledFlex(WidgetTester tester, String label) {
  final textFinder = find.text(label);
  expect(textFinder, findsOneWidget,
      reason: 'Expected the bar row labelled `$label` on screen.');
  final paddingFinder =
      find.ancestor(of: textFinder, matching: find.byType(Padding));
  final flexibles = find.descendant(
    of: paddingFinder.first,
    matching: find.byType(Flexible),
  );
  return tester.widgetList<Flexible>(flexibles).first.flex;
}
