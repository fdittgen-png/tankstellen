// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/entities/trip_start_stage.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trip_start_progress.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trip_start_stage_checklist.dart';

import '../../../../helpers/pump_app.dart';

/// #4126 — the trip-start screen showed one line on an otherwise empty
/// page for the 3-12 s a connect takes. It looked identical at second
/// one and second ten, so the honest reading was that the app had hung.
void main() {
  group('TripStartStageChecklist', () {
    testWidgets('names all three steps, not just the one in flight',
        (tester) async {
      await pumpApp(
        tester,
        const TripStartStageChecklist(
          stage: TripStartStage.connectingAdapter,
        ),
      );

      expect(find.text('OBD2 adapter'), findsOneWidget);
      expect(find.text('Vehicle data'), findsOneWidget);
      expect(find.text('Recording'), findsOneWidget);
    });

    testWidgets('ticks the steps already behind us', (tester) async {
      await pumpApp(
        tester,
        const TripStartStageChecklist(
          stage: TripStartStage.readingVehicleData,
        ),
      );

      // One done, one running, one pending — which is what makes the
      // screen read as progress rather than as a stall.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });

    testWidgets('nothing is ticked on the first step', (tester) async {
      await pumpApp(
        tester,
        const TripStartStageChecklist(
          stage: TripStartStage.connectingAdapter,
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('says the wait is expected, and names the escape hatch',
        (tester) async {
      await pumpApp(
        tester,
        const TripStartStageChecklist(
          stage: TripStartStage.connectingAdapter,
        ),
      );

      // The hint points at #3678's existing Reset connection action
      // rather than inventing a new one.
      expect(find.textContaining('Reset connection'), findsOneWidget);
      expect(find.textContaining('usually takes a few seconds'),
          findsOneWidget);
    });
  });

  group('TripStartProgress', () {
    testWidgets('the connecting card carries the checklist', (tester) async {
      await pumpApp(
        tester,
        const Center(
          child: TripStartProgress(stage: TripStartStage.connectingAdapter),
        ),
        // The card's icon spin and indeterminate bar never stop, so
        // `pumpAndSettle` would wait on them forever.
        settle: false,
      );

      expect(find.byType(TripStartStageChecklist), findsOneWidget);
      // The card's own animated label stays — the ellipsised phrase for
      // the step in flight, above the noun-labelled rows.
      expect(find.text('Connecting to OBD2 adapter…'), findsOneWidget);
    });
  });
}
