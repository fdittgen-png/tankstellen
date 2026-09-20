// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4396 — the first station had to be added by long press, and nothing
/// on the screen said so.
///
/// #4363 gave the results list a comparison whose only door was a long
/// press on a row: no glyph, no label, no tooltip. Once a comparison
/// existed every row grew the explicit toggle, so the feature was
/// discoverable to everyone who had already discovered it.
///
/// The fix keeps the row's structural budget (#4163) intact — the toggle
/// still joins the row only when it is wanted — and adds a labelled entry
/// point where the results already keep their non-obvious actions: the
/// overflow menu #3926 built for exactly this class of problem. Turning
/// picking mode on reveals the same control on every row; the long press
/// stays as the accelerator it always was.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/refuel_comparison_selection.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/refuel_comparison_card.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/results_action_menu.dart';
import 'package:tankstellen/features/search/presentation/widgets/swipeable_station_card.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

const _station = Station(
  id: 'de-1',
  name: 'Tankstelle Mitte',
  brand: 'ARAL',
  street: 'Leipziger Straße 128',
  postCode: '10117',
  place: 'Berlin',
  lat: 52.51,
  lng: 13.39,
  dist: 2.4,
  e10: 1.739,
);

const _compareKey = Key('compare-de-1');

/// The row, at [size] and [textScale], with picking mode pre-set to
/// [picking]. Returns the container so a test can read or move the
/// shared state the three doors write.
Future<ProviderContainer> _pumpRow(
  WidgetTester tester, {
  bool picking = false,
  Size size = const Size(400, 800),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final std = standardTestOverrides();
  await pumpScaledApp(
    tester,
    SwipeableStationCard(
      station: _station,
      isFavorite: false,
      onTap: () {},
      onNavigate: () {},
      onIgnore: () {},
      onFavoriteTap: () {},
    ),
    textScaleFactor: textScale,
    overrides: [...std.overrides, selectedFuelTypeOverride(FuelType.e10)],
  );
  final container = ProviderScope.containerOf(
      tester.element(find.byType(SwipeableStationCard)));
  if (picking) {
    container.read(refuelComparisonPickingProvider.notifier).toggle();
    await tester.pumpAndSettle();
  }
  return container;
}

void main() {
  group('the menu entry is the visible door', () {
    /// The menu alone, so this asserts the affordance rather than the
    /// whole results screen's chrome (which
    /// `results_chrome_two_rows_test.dart` already pins).
    Future<ProviderContainer> pumpMenu(WidgetTester tester) async {
      final std = standardTestOverrides();
      await pumpApp(
        tester,
        const ResultsActionMenu(items: []),
        overrides: std.overrides,
      );
      return ProviderScope.containerOf(
          tester.element(find.byType(ResultsActionMenu)));
    }

    testWidgets('the overflow carries a LABELLED compare entry — the long '
        'press advertised nothing', (tester) async {
      await pumpMenu(tester);
      await tester.tap(find.byKey(const Key('results_action_menu')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('results_compare_stations')), findsOneWidget);
      expect(find.text('Compare stations'), findsOneWidget);
    });

    testWidgets('choosing it turns picking on, and choosing it again turns '
        'picking off', (tester) async {
      final container = await pumpMenu(tester);
      expect(container.read(refuelComparisonPickingProvider), isFalse);

      await tester.tap(find.byKey(const Key('results_action_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('results_compare_stations')));
      await tester.pumpAndSettle();
      expect(container.read(refuelComparisonPickingProvider), isTrue);

      await tester.tap(find.byKey(const Key('results_action_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('results_compare_stations')));
      await tester.pumpAndSettle();
      expect(container.read(refuelComparisonPickingProvider), isFalse);
    });

    testWidgets('the entry is ticked while picking is on, so the menu says '
        'which mode the list is in', (tester) async {
      final container = await pumpMenu(tester);
      container.read(refuelComparisonPickingProvider.notifier).toggle();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('results_action_menu')));
      await tester.pumpAndSettle();

      expect(
          find.descendant(
            of: find.byKey(const Key('results_compare_stations')),
            matching: find.byIcon(Icons.check),
          ),
          findsOneWidget);
      expect(find.text('Compare stations'), findsOneWidget,
          reason: 'the label does not change under the tick');
    });
  });

  group('picking mode reveals the row control', () {
    testWidgets('off, with an empty comparison, the row carries no control '
        '(#4163 budget unchanged)', (tester) async {
      await _pumpRow(tester);
      expect(find.byKey(_compareKey), findsNothing);
    });

    testWidgets('on, every row shows the toggle before anything is picked',
        (tester) async {
      final container = await _pumpRow(tester, picking: true);
      expect(container.read(refuelComparisonSelectionProvider), isEmpty);
      expect(find.byKey(_compareKey), findsOneWidget);
    });

    testWidgets('the revealed toggle is what adds the FIRST station',
        (tester) async {
      final container = await _pumpRow(tester, picking: true);

      await tester.tap(find.byKey(_compareKey));
      await tester.pumpAndSettle();

      expect(container.read(refuelComparisonSelectionProvider).map((s) => s.id),
          ['de-1']);
    });

    testWidgets('turning picking off keeps the comparison the driver built',
        (tester) async {
      final container = await _pumpRow(tester, picking: true);
      await tester.tap(find.byKey(_compareKey));
      await tester.pumpAndSettle();

      container.read(refuelComparisonPickingProvider.notifier).toggle();
      await tester.pumpAndSettle();

      expect(container.read(refuelComparisonSelectionProvider).map((s) => s.id),
          ['de-1'],
          reason: 'the mode is an affordance switch, not the selection');
      expect(find.byKey(_compareKey), findsOneWidget,
          reason: 'a non-empty comparison keeps every row toggled-capable');
    });

    testWidgets('the long press still adds a station with picking off',
        (tester) async {
      final container = await _pumpRow(tester);

      await tester.longPress(find.byType(SwipeableStationCard));
      await tester.pumpAndSettle();

      expect(container.read(refuelComparisonSelectionProvider).map((s) => s.id),
          ['de-1'],
          reason: 'the accelerator survives the affordance');
      expect(find.byKey(_compareKey), findsOneWidget);
    });

    testWidgets('the control renders at 320 dp and 2x text, and the row does '
        'not overflow', (tester) async {
      await _pumpRow(
        tester,
        picking: true,
        size: const Size(320, 900),
        textScale: 2.0,
      );

      expect(find.byKey(_compareKey), findsOneWidget);
      expect(tester.takeException(), isNull);
      final box = tester.getRect(find.byKey(_compareKey));
      expect(box.right, lessThanOrEqualTo(320.0),
          reason: 'the toggle must stay inside a 320 dp screen');
      expect(box.width, greaterThan(0));
    });
  });

  group('the empty comparison says what picking is for', () {
    Future<void> pumpCard(WidgetTester tester, {required bool picking}) async {
      final std = standardTestOverrides();
      await pumpApp(
        tester,
        const RefuelComparisonCard(),
        overrides: [
          ...std.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          if (picking)
            refuelComparisonPickingProvider
                .overrideWith(_AlwaysPicking.new),
        ],
      );
    }

    testWidgets('picking, with nothing picked, prompts once where the '
        'comparison will appear', (tester) async {
      await pumpCard(tester, picking: true);
      expect(find.byKey(const Key('refuel_compare_pick_prompt')),
          findsOneWidget);
    });

    testWidgets('not picking, the slot stays the zero-height item it was',
        (tester) async {
      await pumpCard(tester, picking: false);
      expect(find.byKey(const Key('refuel_compare_pick_prompt')), findsNothing);
      expect(find.text('Your comparison'), findsNothing);
    });
  });
}

/// Picking mode forced on, for the card tests that never open a menu.
class _AlwaysPicking extends RefuelComparisonPicking {
  @override
  bool build() => true;
}
