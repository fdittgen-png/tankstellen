// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_start_progress.dart';

import '../../../../helpers/pump_app.dart';

/// #3335 — the connecting card must offer a Cancel affordance so the user can
/// interrupt a stuck/slow OBD2 init and retry without restarting.
void main() {
  testWidgets('shows a Cancel button that invokes onCancel when provided',
      (tester) async {
    var cancelled = 0;
    // settle:false — the card has indefinite spin/pulse animations that
    // pumpAndSettle would wait on forever.
    await pumpApp(
      tester,
      TripStartProgress(
        stage: TripStartStage.connectingAdapter,
        onCancel: () => cancelled++,
      ),
      settle: false,
    );

    final cancel = find.byKey(const Key('trip_start_progress_cancel'));
    expect(cancel, findsOneWidget);

    await tester.tap(cancel);
    await tester.pump();
    expect(cancelled, 1);
  });

  testWidgets('hides the Cancel button when onCancel is null', (tester) async {
    await pumpApp(
      tester,
      const TripStartProgress(stage: TripStartStage.connectingAdapter),
      settle: false,
    );
    expect(find.byKey(const Key('trip_start_progress_cancel')), findsNothing);
  });
}
