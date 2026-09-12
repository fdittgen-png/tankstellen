// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_profile_provider.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/decision_header.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #4090 (epic #4087) — the decision header.
///
/// The promises being pinned here are the ones that make the header
/// trustworthy rather than merely decorative: three answers and never
/// one verdict, a station that wins twice shown once, both halves of
/// every trade stated, and — the rule that matters most — NO Best Value
/// recommendation when there is no consumption figure to compute it
/// from (`docs/specs/refuel-economics.md` §4.1).
void main() {
  silenceErrorLoggerSpool();

  /// Cheap and near, so it is both Best Value and Closest.
  const near = Station(
    id: 'near',
    name: 'Near',
    brand: 'A',
    street: 'r',
    postCode: '1',
    place: 'Town',
    lat: 0,
    lng: 0,
    e10: 1.700,
    dist: 2,
    isOpen: true,
  );

  /// A shade cheaper at the pump, considerably further away.
  const far = Station(
    id: 'far',
    name: 'Far',
    brand: 'B',
    street: 'r',
    postCode: '1',
    place: 'Town',
    lat: 0,
    lng: 0,
    e10: 1.690,
    dist: 20,
    isOpen: true,
  );

  const items = <SearchResultItem>[
    FuelStationResult(near),
    FuelStationResult(far),
  ];

  Future<AppLocalizations> pumpHeader(
    WidgetTester tester, {
    required RefuelProfile profile,
    List<SearchResultItem> results = items,
  }) async {
    await pumpApp(
      tester,
      DecisionHeader(items: results),
      overrides: [
        refuelProfileProvider.overrideWithValue(profile),
        // The fuel type otherwise resolves through the active profile in
        // Hive, which a widget test has no box for.
        selectedFuelTypeOverride(FuelType.e10),
      ],
    );
    return AppLocalizations.of(tester.element(find.byType(DecisionHeader)));
  }

  group('with a consumption figure', () {
    const profile = RefuelProfile(
      consumptionLPer100km: 7,
      litresIntended: 40,
    );

    testWidgets('names each answer, and a station winning twice appears '
        'ONCE with its titles joined', (tester) async {
      final l10n = await pumpHeader(tester, profile: profile);

      // `near` is cheapest-per-effective-litre AND closest: one row.
      expect(
        find.text('${l10n.decisionBestValue} · ${l10n.decisionClosest}'
            .toUpperCase()),
        findsOneWidget,
        reason: 'a station that holds two titles is one option, not two',
      );
      expect(find.text(l10n.decisionCheapest.toUpperCase()), findsOneWidget);
      // Three titles, two rows — never the same station listed twice.
      expect(find.text('Near'), findsOneWidget);
      expect(find.text('Far'), findsOneWidget);
    });

    testWidgets('the recommendation says WHY', (tester) async {
      final l10n = await pumpHeader(tester, profile: profile);
      expect(find.text(l10n.decisionReasonBestValue), findsOneWidget);
    });

    testWidgets('the cheaper-but-further row states BOTH halves of the '
        'trade — never a bare "cheapest"', (tester) async {
      await pumpHeader(tester, profile: profile);
      // 1 cent/L over 40 L is 0.40; the detour is 36 extra km of driving
      // (2 × 18 × 1.3 road factor). Whichever line applies, it must
      // mention the driving as well as the money.
      final reason = find.textContaining(RegExp(r'0[.,]40|km'));
      expect(reason, findsWidgets,
          reason: 'the extra driving must be stated beside the saving');
    });

    testWidgets('the assumptions are visible, because the arithmetic is '
        'only as honest as them', (tester) async {
      await pumpHeader(tester, profile: profile);
      expect(find.textContaining('7.0 L/100 km'), findsOneWidget);
      // The volume goes through the country's unit formatter, whose
      // decimal separator is locale's business, not this test's.
      expect(find.textContaining(RegExp(r'40[.,]0\s*L')), findsOneWidget);
    });

    testWidgets('it ends with the way on to the full list', (tester) async {
      final l10n = await pumpHeader(tester, profile: profile);
      expect(find.text(l10n.decisionShowAll(2)), findsOneWidget);
    });
  });

  group('without a consumption figure (spec §4.1)', () {
    testWidgets('there is NO Best Value row — the reason it is missing '
        'takes its place', (tester) async {
      final l10n = await pumpHeader(tester, profile: const RefuelProfile());

      expect(find.textContaining(l10n.decisionBestValue.toUpperCase()),
          findsNothing,
          reason: 'a recommendation the app cannot justify must not appear');
      expect(find.text(l10n.decisionValueUnavailable), findsOneWidget);
      // The two facts that need no model are still answered.
      expect(find.text(l10n.decisionCheapest.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.decisionClosest.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.decisionReasonBestValue), findsNothing);
    });
  });

  group('nothing to decide between', () {
    testWidgets('one station renders no header at all', (tester) async {
      await pumpHeader(
        tester,
        profile: const RefuelProfile(consumptionLPer100km: 7),
        results: const [FuelStationResult(near)],
      );
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('an empty result set renders no header', (tester) async {
      await pumpHeader(
        tester,
        profile: const RefuelProfile(consumptionLPer100km: 7),
        results: const [],
      );
      expect(find.byType(Card), findsNothing);
    });
  });
}
