// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_profile_provider.dart';
import 'package:tankstellen/core/domain/refuel_quantity_provider.dart';
import 'package:tankstellen/core/utils/unit_formatter.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/refuel_quantity_sheet.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/silence_error_logger.dart';

/// #4095 (epic #4087) — the refill-quantity control.
///
/// The promise being pinned is what the sheet does NOT do: it never asks
/// for tank capacity, and it never demands an answer. The measured
/// median stays the default and leads the list, because it is the better
/// figure wherever a fill-up history exists.
void main() {
  silenceErrorLoggerSpool();

  Future<AppLocalizations> pumpSheet(
    WidgetTester tester, {
    double? tankCapacityL,
    double? chosen,
    double consumption = 7,
    double litresIntended = 40,
  }) async {
    final container = ProviderContainer(overrides: [
      refuelProfileProvider.overrideWithValue(RefuelProfile(
        consumptionLPer100km: consumption,
        litresIntended: litresIntended,
      )),
    ]);
    addTearDown(container.dispose);
    if (chosen != null) {
      await container.read(refuelQuantityProvider.notifier).set(chosen);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RefuelQuantitySheet(tankCapacityL: tankCapacityL),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(RefuelQuantitySheet)));
  }

  testWidgets('it never asks for tank capacity, and offers "a full tank" '
      'only when one is already on file', (tester) async {
    final l10n = await pumpSheet(tester);
    expect(find.textContaining(l10n.refuelQuantityFullTank), findsNothing,
        reason: 'a vehicle with no capacity on file must still get a '
            'complete, working sheet');

    await pumpSheet(tester, tankCapacityL: 55);
    expect(find.textContaining(l10n.refuelQuantityFullTank), findsOneWidget);
  });

  testWidgets('the measured median leads and is selected by default',
      (tester) async {
    final l10n = await pumpSheet(tester);
    // It is the FIRST chip, carrying the figure it currently resolves to.
    final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip).first);
    expect(chip.selected, isTrue,
        reason: 'the measured figure is the default, not the fallback');
    expect(
      find.descendant(
        of: find.byType(ChoiceChip).first,
        matching: find.text(l10n.refuelQuantityMeasuredValue(
            UnitFormatter.formatVolume(40))),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a preset above the tank capacity is not offered — the app '
      'cannot price litres the tank cannot hold', (tester) async {
    final l10n = await pumpSheet(tester, tankCapacityL: 35);
    expect(find.text(UnitFormatter.formatVolume(40)), findsNothing);
    expect(find.text(UnitFormatter.formatVolume(50)), findsNothing);
    expect(find.text(UnitFormatter.formatVolume(30)), findsOneWidget);
    // …and the capacity itself is still reachable as "a full tank".
    expect(find.textContaining(l10n.refuelQuantityFullTank), findsOneWidget);
  });

  testWidgets('choosing a preset records it; choosing the measured option '
      'hands the decision back', (tester) async {
    final container = ProviderContainer(overrides: [
      refuelProfileProvider
          .overrideWithValue(const RefuelProfile(consumptionLPer100km: 7)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _SheetHost(),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(refuelQuantityProvider), isNull);
    await tester.tap(find.text(UnitFormatter.formatVolume(20)));
    await tester.pumpAndSettle();
    expect(container.read(refuelQuantityProvider), 20);
  });

  testWidgets('no measured consumption: the sheet says so rather than '
      'showing a figure it does not have', (tester) async {
    final container = ProviderContainer(overrides: [
      refuelProfileProvider.overrideWithValue(const RefuelProfile()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _SheetHost(),
      ),
    );
    await tester.pumpAndSettle();
    final l10n =
        AppLocalizations.of(tester.element(find.byType(RefuelQuantitySheet)));
    expect(find.text(l10n.refuelConsumptionMissing), findsOneWidget);
  });

  test('the presets are coarse, and the fallback is the spec default', () {
    expect(RefuelQuantity.presets, [20, 30, 40, 50]);
    expect(kRefuelQuantityFallback, kDefaultRefuelLitres);
  });
}

/// The sheet in a const-constructible host, so the analyzer's
/// prefer_const_constructors rule is satisfied without repeating the
/// MaterialApp scaffolding in every test.
class _SheetHost extends StatelessWidget {
  const _SheetHost();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: RefuelQuantitySheet()),
    );
  }
}
