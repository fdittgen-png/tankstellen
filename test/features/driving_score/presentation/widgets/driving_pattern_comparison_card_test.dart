// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4366 acceptance 9 — the surface. Structural assertions only (no
// golden PNG): the figures, their exposure, the stated reason where a
// dimension is unsupported, the localization and the accessible labels.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/comparison_eligibility.dart';
import 'package:tankstellen/features/driving_score/data/driving_pattern_aggregator.dart';
import 'package:tankstellen/features/driving_score/domain/driving_pattern_comparison.dart';
import 'package:tankstellen/features/driving_score/presentation/widgets/driving_pattern_comparison_card.dart';
import 'package:tankstellen/features/trips/api.dart';

import '../../../../helpers/pump_app.dart';

final _asOf = DateTime.utc(2026, 9, 20, 12);

TripHistoryEntry _trip(String id, String vehicleId, {double km = 100}) =>
    TripHistoryEntry(
      id: id,
      vehicleId: vehicleId,
      sampleCount: 600,
      columnsPresent: const {'s', 'ct'},
      summary: TripSummary(
        distanceKm: km,
        maxRpm: 3000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: DateTime.utc(2026, 9, 5, 8),
        endedAt: DateTime.utc(2026, 9, 5, 9),
      ),
    );

/// Vehicle A drives calmly on GPS only; vehicle B is OBD-equipped, pulls
/// harder and idles.
Future<DrivingPatternComparison> _comparison([bool empty = false]) =>
    aggregateDrivingPatterns(
      selectedVehicleIds: const ['a', 'b'],
      summaries: [_trip('a1', 'a'), _trip('b1', 'b')],
      asOf: _asOf,
      loadTotals: (entry) {
        if (empty) return null;
        return entry.id == 'a1'
            ? DrivingPatternTotals(
                events: const {DrivingEventCounter.hardAccelEvents: 2},
                exposure: const {
                  DrivingExposureBasis.movingDistanceKm: 100,
                  DrivingExposureBasis.movingSeconds: 3600,
                })
            : DrivingPatternTotals(
                events: const {DrivingEventCounter.hardAccelEvents: 20},
                seconds: const {DrivingDurationCounter.longIdleSeconds: 360},
                exposure: const {
                  DrivingExposureBasis.movingDistanceKm: 100,
                  DrivingExposureBasis.movingSeconds: 3600,
                  DrivingExposureBasis.engineKnownSeconds: 3600,
                });
      },
    );

const _names = {'a': 'Estate', 'b': 'Van'};

/// The card lives inside the host's scrollable, exactly as a section
/// card is meant to (its margin default assumes the host owns spacing).
Future<void> _pumpCard(
  WidgetTester tester,
  DrivingPatternComparison comparison, {
  Locale locale = const Locale('en'),
}) =>
    pumpApp(
      tester,
      SingleChildScrollView(
        child: DrivingPatternComparisonCard(
            comparison: comparison, vehicleNames: _names),
      ),
      locale: locale,
    );

void main() {
  testWidgets('a useful comparison renders each vehicle\'s rate with the '
      'exposure it rests on', (tester) async {
    final comparison = (await tester.runAsync(_comparison))!;
    await _pumpCard(tester, comparison);

    expect(find.text('Driving patterns'), findsOneWidget);
    expect(find.text('Hard accelerations'), findsOneWidget);
    expect(find.text('Estate'), findsWidgets);
    expect(find.text('Van'), findsWidgets);
    expect(find.text('2.0 per 100 km'), findsOneWidget);
    expect(find.text('20.0 per 100 km'), findsOneWidget);
    expect(find.text('2 events over 100 km · 1 trips'), findsOneWidget,
        reason: 'the rate is traceable to its numerator and denominator');
    expect(find.textContaining('Largest observed differences'),
        findsOneWidget);
  });

  testWidgets('insufficient evidence says so instead of showing zeros',
      (tester) async {
    final comparison = (await tester.runAsync(() => _comparison(true)))!;
    await _pumpCard(tester, comparison);

    expect(find.text('Not enough recorded driving to compare patterns yet.'),
        findsOneWidget);
    expect(find.textContaining('per 100 km'), findsNothing);
    expect(find.text('0.0 per 100 km'), findsNothing);
  });

  testWidgets('a partially supported dimension states the reason for the '
      'vehicle that cannot support it', (tester) async {
    final comparison = (await tester.runAsync(_comparison))!;
    await _pumpCard(tester, comparison);

    // Idling is supported by the OBD vehicle only; the GPS-only one gets
    // a reason, not a flattering zero.
    expect(find.text('Engine idling'), findsOneWidget);
    expect(find.text('Not recorded — these trips carry no such signal'),
        findsWidgets);
    expect(find.text('10.0 %'), findsOneWidget);
  });

  testWidgets('a context-dependent dimension carries the not-a-penalty note '
      'and the refusals are always shown', (tester) async {
    final comparison = (await tester.runAsync(_comparison))!;
    await _pumpCard(tester, comparison);

    expect(
        find.textContaining(
            'expected consumption per trip is not recorded'),
        findsOneWidget);
    expect(find.textContaining('No litres and no money are attributed'),
        findsOneWidget);
  });

  testWidgets('the card is localized', (tester) async {
    final comparison = (await tester.runAsync(_comparison))!;
    await _pumpCard(tester, comparison, locale: const Locale('de'));

    expect(find.text('Fahrverhalten'), findsOneWidget);
    expect(find.text('Starke Beschleunigungen'), findsOneWidget);
    expect(find.text('Driving patterns'), findsNothing);
  });

  testWidgets('every figure and every refusal carries an accessible label',
      (tester) async {
    final comparison = (await tester.runAsync(_comparison))!;
    await _pumpCard(tester, comparison);

    expect(
      find.bySemanticsLabel('Hard accelerations for Van: 20.0 per 100 km, '
          '20 events over 100 km · 1 trips'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Engine idling for Estate: Not recorded — these '
          'trips carry no such signal'),
      findsOneWidget,
    );
  });

  testWidgets('an unmatched comparison says so rather than implying a '
      'matched subset', (tester) async {
    final comparison = (await tester.runAsync(() => aggregateDrivingPatterns(
          selectedVehicleIds: const ['a', 'b'],
          summaries: [_trip('a1', 'a', km: 3), _trip('b1', 'b', km: 300)],
          asOf: _asOf,
          loadTotals: (entry) => DrivingPatternTotals(
              events: const {DrivingEventCounter.hardAccelEvents: 2},
              exposure: const {DrivingExposureBasis.movingDistanceKm: 100}),
        )))!;
    expect(comparison.matching.isMatched, isFalse);

    await _pumpCard(tester, comparison);
    expect(find.textContaining('No trip conditions in common'), findsOneWidget);
    expect(find.textContaining('Matched on:'), findsNothing);
    expect(
        comparison.subjects.first
            .measure(DrivingMeasureId.hardAccelRate)!
            .metric
            .qualifications,
        contains(ComparisonQualification.uncontrolledConditions));
  });
}
