// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4363 — the results list as the third door into the shared
/// comparison.
///
/// The row is at its structural widget budget (#4163,
/// `station_row_budget_test.dart`), so it does not carry a comparison
/// button for every driver who never compares. A long press opens the
/// comparison; from then on each row shows the explicit toggle, and the
/// same rows the card costs are the ones the list marks.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/refuel_comparison_selection.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/swipeable_station_card.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  const station = Station(
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

  Future<ProviderContainer> pumpRow(WidgetTester tester) async {
    final std = standardTestOverrides();
    await pumpApp(
      tester,
      SwipeableStationCard(
        station: station,
        isFavorite: false,
        onTap: () {},
        onNavigate: () {},
        onIgnore: () {},
        onFavoriteTap: () {},
      ),
      overrides: [...std.overrides, selectedFuelTypeOverride(FuelType.e10)],
    );
    return ProviderScope.containerOf(
        tester.element(find.byType(SwipeableStationCard)));
  }

  testWidgets('a row carries no comparison control until a comparison '
      'exists', (tester) async {
    await pumpRow(tester);
    expect(find.byKey(const Key('compare-de-1')), findsNothing);
  });

  testWidgets('a long press puts the row into the shared comparison, and '
      'the row then shows the toggle', (tester) async {
    final container = await pumpRow(tester);

    await tester.longPress(find.byType(SwipeableStationCard));
    await tester.pump();

    expect(container.read(refuelComparisonSelectionProvider).map((s) => s.id),
        ['de-1']);
    expect(find.byKey(const Key('compare-de-1')), findsOneWidget);
  });

  testWidgets('the row toggle takes the station back out again',
      (tester) async {
    final container = await pumpRow(tester);
    await tester.longPress(find.byType(SwipeableStationCard));
    await tester.pump();

    await tester.tap(find.byKey(const Key('compare-de-1')));
    await tester.pump();

    expect(container.read(refuelComparisonSelectionProvider), isEmpty);
    expect(find.byKey(const Key('compare-de-1')), findsNothing,
        reason: 'the control leaves with the comparison it belonged to');
  });
}
