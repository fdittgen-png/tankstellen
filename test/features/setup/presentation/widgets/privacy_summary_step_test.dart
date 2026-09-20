// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4217 §5 — "no legal wall of text; details are expandable", and
// ADR 0025 D6 — this page takes no consent. Both are easy to lose
// later: a headline quietly becomes a paragraph, or somebody adds the
// fleet-sharing switch here instead of waiting for the manager slice.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/privacy_summary_step.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  const topics = <String>[
    'privacySummaryDevice',
    'privacySummarySync',
    'privacySummaryManager',
    'privacySummaryRetention',
  ];

  Future<void> pumpStep(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size surface = const Size(360, 690),
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScaledApp(
      tester,
      const PrivacySummaryStep(),
      textScaleFactor: textScale,
      locale: locale,
    );
  }

  testWidgets('the four questions are all on the page, at 360 dp',
      (tester) async {
    await pumpStep(tester);

    for (final key in topics) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the detail is behind a disclosure, not on the page',
      (tester) async {
    await pumpStep(tester);

    const detail = 'never leave this phone';
    expect(find.textContaining(detail), findsNothing);

    await tester.tap(find.byKey(const Key('privacySummaryDevice')));
    await tester.pumpAndSettle();

    expect(find.textContaining(detail), findsOneWidget);
  });

  testWidgets('it takes no consent — ADR 0025 D6 keeps the policy '
      'version where it is until the manager surfaces ship',
      (tester) async {
    await pumpStep(tester);

    expect(find.byType(Switch), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(Radio<Object>), findsNothing);
  });

  testWidgets('survives 2.0x text at 360 dp', (tester) async {
    await pumpStep(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in French', (tester) async {
    await pumpStep(tester, locale: const Locale('fr'));

    expect(find.text('Reste sur cet appareil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
