// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/alerts_best_effort_note.dart';

import '../../../../helpers/pump_app.dart';

/// #3169 — the honest "alerts are best effort on iPhone" disclosure:
/// shown ONLY on iOS (where the SLA is OS-limited), never on Android
/// (whose WorkManager pipeline meets it — a caveat there would be false).
void main() {
  // NOTE: the override must be cleared INSIDE each test body — the test
  // binding's foundation-variable invariant check runs before tearDown.
  testWidgets('shows the localized best-effort copy on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pumpApp(tester, const AlertsBestEffortNote());

      final note = find.byKey(const ValueKey('alerts-best-effort-note'));
      expect(note, findsOneWidget);
      // Honest framing, not a delivery promise.
      expect(
        find.textContaining('best effort'),
        findsOneWidget,
      );
      // And the actionable part: opening the app always checks.
      expect(find.textContaining('Opening the app'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('renders nothing on Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await pumpApp(tester, const AlertsBestEffortNote());
      expect(
        find.byKey(const ValueKey('alerts-best-effort-note')),
        findsNothing,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
