// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4138 — the intent row asks the question the user arrived with, and
// must never show a label that no longer matches the sheet's state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_profile_provider.dart';
import 'package:tankstellen/features/search/domain/search_intent.dart';
import 'package:tankstellen/features/search/presentation/widgets/criteria/intent_row.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';
import 'package:tankstellen/features/search/providers/search_screen_ui_provider.dart';

import '../../../../../helpers/mock_providers.dart';
import '../../../../../helpers/pump_app.dart';

ChoiceChip chipFor(WidgetTester tester, String name) => tester.widget<ChoiceChip>(
      find.byKey(ValueKey('criteria-intent-$name')),
    );

void main() {
  testWidgets('every intent renders, plus the Custom read-out', (tester) async {
    await pumpApp(tester, const IntentRow(routeMode: false),
        overrides: standardTestOverrides().overrides);

    for (final intent in SearchIntent.values) {
      expect(find.byKey(ValueKey('criteria-intent-${intent.name}')),
          findsOneWidget,
          reason: '${intent.name} must be offered');
    }
    expect(find.byKey(const ValueKey('criteria-intent-custom')), findsOneWidget);
  });

  testWidgets('Best stop is DISABLED with its reason when consumption is '
      'unknown — never silently defaulted to a price sort', (tester) async {
    // `refuelProfile` is `const RefuelProfile()` by default: a fresh
    // install has no measured consumption, so this is the state most
    // users meet first.
    await pumpApp(tester, const IntentRow(routeMode: false),
        overrides: standardTestOverrides().overrides);

    expect(chipFor(tester, 'bestStop').onSelected, isNull,
        reason: 'trust rule 1 — the chip stays visible and inert, so the '
            'user can see the capability and what unlocks it');
    expect(find.text('Add a fill-up first so we know your consumption'),
        findsOneWidget);
  });

  testWidgets('with a known consumption Best stop becomes selectable and '
      'the reason disappears', (tester) async {
    await pumpApp(
      tester,
      const IntentRow(routeMode: false),
      overrides: [
        ...standardTestOverrides().overrides,
        refuelProfileProvider.overrideWithValue(
          const RefuelProfile(consumptionLPer100km: 6.4),
        ),
      ],
    );

    expect(chipFor(tester, 'bestStop').onSelected, isNotNull);
    expect(find.text('Add a fill-up first so we know your consumption'),
        findsNothing);
  });

  testWidgets('tapping an intent applies its preset and selects it',
      (tester) async {
    await pumpApp(tester, const IntentRow(routeMode: false),
        overrides: standardTestOverrides().overrides);

    expect(chipFor(tester, 'cheapestNearby').selected, isFalse,
        reason: 'the default sheet state matches no intent');

    await tester.tap(find.byKey(
        const ValueKey('criteria-intent-cheapestNearby')));
    await tester.pumpAndSettle();

    expect(chipFor(tester, 'cheapestNearby').selected, isTrue);
    expect(chipFor(tester, 'custom').selected, isFalse);
  });

  testWidgets('changing a knob afterwards drops the selection to Custom '
      '(#4138 acceptance 3)', (tester) async {
    late WidgetRef captured;
    await pumpApp(
      tester,
      Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? _) {
          captured = ref;
          return const IntentRow(routeMode: false);
        },
      ),
      overrides: standardTestOverrides().overrides,
    );

    await tester.tap(find.byKey(
        const ValueKey('criteria-intent-cheapestNearby')));
    await tester.pumpAndSettle();
    expect(chipFor(tester, 'cheapestNearby').selected, isTrue);

    // The user reaches past the intent row and moves the sort control.
    captured.read(selectedSortModeProvider.notifier).set(SortMode.rating);
    await tester.pumpAndSettle();

    expect(chipFor(tester, 'cheapestNearby').selected, isFalse,
        reason: 'the sheet must never show a label that no longer '
            'describes its own state');
    expect(chipFor(tester, 'custom').selected, isTrue);
  });
}
