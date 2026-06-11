// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/gps_matrix_maturity_badge.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_avg_consumption_card.dart';
import 'package:tankstellen/core/domain/gps_calibration_matrix.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #2391 — GPS-only live Average-consumption card + maturity badge on
/// the trip-recording screen (Epic #2385).
///
/// Covers the card's three honest display modes plus the warm-up
/// graceful-placeholder path and the maturity-tier transitions:
///
///  * GPS-only with a running estimate → `~X.X L/100 km` + the right
///    maturity badge for the active vehicle's calibration state.
///  * Too-few-samples (no estimate yet) → muted `—`, no badge.
///  * OBD2 trip (measured) → real average, no `~`, no badge — no
///    regression of the measured path.
///  * Maturity transitions cold → warming → converged track the
///    matrix's fill-up reconciliation count + residual variance.
void main() {
  Widget harness({
    required TripLiveReading? live,
    String? brokenMapOverride,
    GpsCalibrationMatrix? matrix,
    Locale? locale,
    double? cardWidth,
  }) {
    final card = TripAvgConsumptionCard(
      live: live,
      brokenMapOverride: brokenMapOverride,
    );
    return ProviderScope(
      overrides: [
        activeVehicleProfileProvider.overrideWith(
          () => _FixedActiveVehicle(
            VehicleProfile(
              id: 'veh-a',
              name: 'Test',
              gpsCalibration: matrix,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            // #2764 — pin a realistically narrow card width so the wide
            // trailing Row (tooltip + badge + value) competes with the
            // label for space, reproducing the per-letter wrap if the
            // label ever loses its Expanded/ellipsis.
            child: cardWidth == null
                ? card
                : SizedBox(width: cardWidth, child: card),
          ),
        ),
      ),
    );
  }

  Text valueText(WidgetTester tester) => tester.widget<Text>(
        find.byKey(const Key('tripAvgConsumptionValue')),
      );

  group('TripAvgConsumptionCard (#2391)', () {
    testWidgets(
        'GPS-only with a running estimate → ~X.X L/100 km + maturity badge',
        (tester) async {
      await tester.pumpWidget(harness(
        // No measured fuel → liveAvgLPer100Km is null; the GPS running
        // average is the only consumption signal.
        live: const TripLiveReading(
          elapsed: Duration(minutes: 5),
          distanceKmSoFar: 10.0,
          gpsEstimatedAvgLPer100Km: 6.4,
        ),
        // 0 reconciliations → cold tier.
        matrix: const GpsCalibrationMatrix(),
      ));
      await tester.pumpAndSettle();

      expect(valueText(tester).data, '~6.4 L/100 km',
          reason: 'GPS estimate must carry a leading ~ (ADR 0012).');
      expect(find.byType(GpsMatrixMaturityBadge), findsOneWidget,
          reason: 'GPS estimate must show the calibration-maturity badge.');
      expect(find.byKey(const Key('tripAvgEstimateTooltip')), findsOneWidget,
          reason: 'GPS estimate must carry the explanatory ~ tooltip.');
    });

    testWidgets('too-few-samples (no estimate yet) → muted — and no badge',
        (tester) async {
      await tester.pumpWidget(harness(
        // Estimator still warming up: neither measured nor estimated.
        live: const TripLiveReading(
          elapsed: Duration(seconds: 3),
          distanceKmSoFar: 0.02,
        ),
        matrix: const GpsCalibrationMatrix(),
      ));
      await tester.pumpAndSettle();

      expect(valueText(tester).data, '—');
      expect(find.byType(GpsMatrixMaturityBadge), findsNothing);
      expect(find.byKey(const Key('tripAvgEstimateTooltip')), findsNothing);
    });

    testWidgets('OBD2 trip (measured) → real average, no ~, no maturity badge',
        (tester) async {
      await tester.pumpWidget(harness(
        // 0.83 L over 10 km = 8.3 L/100 km (measured fuel-rate path).
        live: const TripLiveReading(
          elapsed: Duration(minutes: 5),
          distanceKmSoFar: 10.0,
          fuelLitersSoFar: 0.83,
          // Even if a GPS estimate were present, measured wins.
          gpsEstimatedAvgLPer100Km: 6.4,
        ),
        matrix: const GpsCalibrationMatrix(),
      ));
      await tester.pumpAndSettle();

      expect(valueText(tester).data, '8.3 L/100 km',
          reason: 'Measured average must NOT carry a ~ prefix.');
      expect(valueText(tester).data, isNot(contains('~')));
      expect(find.byType(GpsMatrixMaturityBadge), findsNothing,
          reason: 'Measured data carries full confidence — no maturity badge.');
      expect(find.byKey(const Key('tripAvgEstimateTooltip')), findsNothing);
    });

    testWidgets(
        'broken-MAP override wins over both branches, no ~, no maturity badge',
        (tester) async {
      await tester.pumpWidget(harness(
        live: const TripLiveReading(
          elapsed: Duration(minutes: 5),
          distanceKmSoFar: 10.0,
          gpsEstimatedAvgLPer100Km: 6.4,
        ),
        brokenMapOverride: '7.0 L/100 km',
        matrix: const GpsCalibrationMatrix(),
      ));
      await tester.pumpAndSettle();

      expect(valueText(tester).data, '7.0 L/100 km');
      expect(valueText(tester).data, isNot(contains('~')));
      expect(find.byType(GpsMatrixMaturityBadge), findsNothing);
    });

    // Maturity transitions cold → warming → converged. One fresh widget
    // tree per tier (a fresh ProviderScope each time) so the active-
    // vehicle override is re-evaluated cleanly per case.
    const estimateLive = TripLiveReading(
      elapsed: Duration(minutes: 5),
      distanceKmSoFar: 10.0,
      gpsEstimatedAvgLPer100Km: 6.4,
    );

    testWidgets('maturity badge: cold tier (<3 reconciliations)',
        (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(harness(
        live: estimateLive,
        matrix: const GpsCalibrationMatrix(fillUpReconciliationCount: 1),
      ));
      await tester.pumpAndSettle();
      expect(find.text(l.gpsMatrixMaturityCold), findsOneWidget);
    });

    testWidgets('maturity badge: warming tier (3–7, variance ≤ 1.5)',
        (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(harness(
        live: estimateLive,
        matrix: const GpsCalibrationMatrix(
          fillUpReconciliationCount: 5,
          residualVariance: 1.0,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text(l.gpsMatrixMaturityWarming), findsOneWidget);
    });

    testWidgets('maturity badge: converged tier (8+, variance ≤ 0.5)',
        (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(harness(
        live: estimateLive,
        matrix: const GpsCalibrationMatrix(
          fillUpReconciliationCount: 10,
          residualVariance: 0.3,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text(l.gpsMatrixMaturityConverged), findsOneWidget);
    });
  });

  // #2764 — the label must keep its flexible space + ellipsize on a
  // single line even when the wide trailing Row (tooltip + maturity
  // badge + value) is present. The old ListTile title/trailing split
  // gave the trailing its full intrinsic width, squeezing 'Moyenne' to
  // ~1 char per line. A narrow card width forces the competition.
  group('label single-line, no per-letter wrap (#2764)', () {
    // A GPS-estimate reading → the WIDEST trailing (tooltip + badge +
    // ~value); the worst case for the label's remaining space.
    const wideTrailingLive = TripLiveReading(
      elapsed: Duration(minutes: 5),
      distanceKmSoFar: 10.0,
      gpsEstimatedAvgLPer100Km: 6.4,
    );

    Finder labelFinder(String text) => find.descendant(
          of: find.byKey(const Key('tripAvgConsumptionCard')),
          matching: find.text(text),
        );

    // Visual line count of a Text: distinct box `top` offsets over the
    // full string. A single ellipsized line ⇒ 1; the #2764 per-letter
    // wrap ⇒ one per character.
    int renderedLineCount(WidgetTester tester, Finder f, String text) {
      final para = tester.renderObject<RenderParagraph>(f);
      final boxes = para.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length),
      );
      final tops = boxes.map((b) => b.top.round()).toSet();
      return tops.isEmpty ? 1 : tops.length;
    }

    // The structural contract that PREVENTS the per-letter wrap: the
    // label lives inside an Expanded (so it claims the flexible space
    // rather than being squeezed by the wide trailing) and is single-
    // line + ellipsizing. This is the direct regression guard — the old
    // ListTile title/trailing split had neither.
    void expectLabelIsExpandedSingleLineEllipsis(
        WidgetTester tester, Finder labelText) {
      final textWidget = tester.widget<Text>(labelText);
      expect(textWidget.maxLines, 1,
          reason: 'label must be capped to a single line (#2764)');
      expect(textWidget.overflow, TextOverflow.ellipsis,
          reason: 'label must ellipsize, never wrap per character (#2764)');
      expect(
        find.ancestor(of: labelText, matching: find.byType(Expanded)),
        findsOneWidget,
        reason: 'label must sit in an Expanded so the wide trailing '
            "(tooltip + badge + value) can't squeeze it to ~1 char.",
      );
    }

    testWidgets('FR "Moyenne" is a single-line, ellipsizing, Expanded label '
        'beside the full trailing', (tester) async {
      await tester.pumpWidget(harness(
        live: wideTrailingLive,
        matrix: const GpsCalibrationMatrix(),
        locale: const Locale('fr'),
        // Bounded but roomy enough that the wide value Text doesn't
        // overflow — the structural assertions below are what guard the
        // bug, not a pixel-precise squeeze.
        cardWidth: 600,
      ));
      await tester.pumpAndSettle();

      final label = labelFinder('Moyenne');
      expect(label, findsOneWidget, reason: 'FR label resolves to "Moyenne".');
      expectLabelIsExpandedSingleLineEllipsis(tester, label);
      expect(renderedLineCount(tester, label, 'Moyenne'), 1,
          reason: 'The label renders on ONE line, not one letter per line.');

      // The value + maturity badge must still be present alongside it.
      expect(find.byKey(const Key('tripAvgConsumptionValue')), findsOneWidget);
      expect(valueText(tester).data, '~6.4 L/100 km');
      expect(find.byType(GpsMatrixMaturityBadge), findsOneWidget);
    });

    testWidgets('en_XA pseudo-locale (text expansion) keeps the label single '
        'line', (tester) async {
      await tester.pumpWidget(harness(
        live: wideTrailingLive,
        matrix: const GpsCalibrationMatrix(),
        // The #1699 expansion pseudo-locale stresses the label width.
        locale: const Locale('en', 'XA'),
        cardWidth: 600,
      ));
      await tester.pumpAndSettle();

      final l = await AppLocalizations.delegate.load(const Locale('en', 'XA'));
      final labelText = l.tripMetricAvgConsumption;
      final label = labelFinder(labelText);
      expect(label, findsOneWidget);
      expectLabelIsExpandedSingleLineEllipsis(tester, label);
      expect(renderedLineCount(tester, label, labelText), 1,
          reason: 'Even the expanded pseudo-locale label stays on one line '
              'rather than wrapping per character.');
      expect(find.byKey(const Key('tripAvgConsumptionValue')), findsOneWidget);
      expect(find.byType(GpsMatrixMaturityBadge), findsOneWidget);
    });
  });
}

class _FixedActiveVehicle extends ActiveVehicleProfile {
  _FixedActiveVehicle(this._vehicle);
  final VehicleProfile _vehicle;

  @override
  VehicleProfile? build() => _vehicle;
}
