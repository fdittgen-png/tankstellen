// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/criteria_refinements.dart';

import '../../../../helpers/pump_app.dart';

/// #4166 — collapsing the refinements is only safe if the collapsed
/// state says what is active.
void main() {
  Widget section(int count) => CriteriaRefinements(
        activeCount: count,
        children: const [Text('a refinement control')],
      );

  testWidgets('with nothing set it starts collapsed and unadorned',
      (tester) async {
    await pumpApp(tester, section(0));

    expect(find.text('More filters'), findsOneWidget);
    expect(_offstageOf(tester), isTrue);
  });

  testWidgets('an active filter is COUNTED in the collapsed header',
      (tester) async {
    // The whole design. A user whose search returns three stations
    // because two filters are on, with nothing on screen to explain it,
    // would rightly conclude the app is broken.
    await pumpApp(tester, section(2));
    expect(find.text('More filters (2)'), findsOneWidget);
  });

  testWidgets('and it opens itself when something is already set',
      (tester) async {
    await pumpApp(tester, section(2));
    expect(_offstageOf(tester), isFalse,
        reason: 'a returning user sees the filters shaping their results');
  });

  testWidgets('tapping the header toggles it', (tester) async {
    await pumpApp(tester, section(0));

    await tester.tap(find.text('More filters'));
    await tester.pumpAndSettle();
    expect(_offstageOf(tester), isFalse);

    await tester.tap(find.text('More filters'));
    await tester.pumpAndSettle();
    expect(_offstageOf(tester), isTrue);
  });

  testWidgets('collapsing keeps the controls alive, not discarded',
      (tester) async {
    // Offstage rather than a conditional child: a user who folds the
    // section away must not silently lose what they picked.
    await pumpApp(tester, section(0));
    expect(find.text('a refinement control', skipOffstage: false),
        findsOneWidget);
  });
}

/// The section's OWN Offstage — Flutter's scaffolding has others.
bool _offstageOf(WidgetTester tester) => tester
    .widget<Offstage>(find.descendant(
      of: find.byType(CriteriaRefinements),
      matching: find.byType(Offstage),
    ))
    .offstage;
