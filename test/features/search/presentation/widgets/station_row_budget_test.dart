// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4163 — the station row's structural budget.
///
/// The list is the app's main surface and its rows got materially more
/// complex: #4091's badges, #3949's value-only pills, #4133's
/// presentation split. A row is built once per visible station and again
/// on every filter change, so its widget count is the multiplier on
/// everything else on the screen.
///
/// **Structural, not timing.** A CI runner has no mid-range Android GPU,
/// so a frame-time assertion here would measure the runner. A widget
/// count is device-independent and it is what actually moves when a card
/// gains a feature — which is the regression worth catching.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/station_amenity.dart';
import 'package:tankstellen/core/perf/perf_budgets.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';

import '../../../../helpers/pump_app.dart';

/// The heaviest realistic row: brand, full address, every price, a
/// freshness stamp, an open state and amenities. A budget measured on a
/// sparse row would not protect the row users actually see.
const _fullyLoaded = Station(
  id: 'de-budget',
  name: 'Tankstelle Mitte',
  brand: 'ARAL',
  street: 'Leipziger Straße 128',
  postCode: '10117',
  place: 'Berlin',
  lat: 52.51,
  lng: 13.39,
  dist: 2.4,
  e5: 1.799,
  e10: 1.739,
  diesel: 1.659,
  isOpen: true,
  updatedAt: '2026-09-14T09:00:00Z',
  amenities: {
    StationAmenity.shop,
    StationAmenity.carWash,
    StationAmenity.toilet,
  },
);

void main() {
  testWidgets('a fully-loaded row stays inside its widget budget',
      (tester) async {
    await pumpApp(
      tester,
      const StationCard(
        station: _fullyLoaded,
        selectedFuelType: FuelType.e10,
      ),
    );

    // The CARD's own subtree, not `tester.allWidgets` — that includes
    // MaterialApp, Directionality and the rest of the harness, which the
    // row does not pay for and which would drown the signal.
    final built = tester
        .widgetList(find.descendant(
          of: find.byType(StationCard),
          matching: find.byWidgetPredicate((_) => true),
        ))
        .length;
    expect(
      built,
      lessThanOrEqualTo(kStationRowWidgetBudget.limit!),
      reason: 'the row now builds $built widgets, over the '
          '${kStationRowWidgetBudget.limit} budget. Every visible station '
          'pays this, and again on every filter change. Either simplify '
          'the row, or measure and move the budget DELIBERATELY with a '
          'new justification — do not nudge it to make this pass.',
    );
  });

  testWidgets('the budget is not slack — it tracks the real row',
      (tester) async {
    // A ceiling far above the truth is a ceiling that never fires. This
    // asserts the budget is still in the right order of magnitude, so
    // it keeps meaning something as the row evolves.
    await pumpApp(
      tester,
      const StationCard(
        station: _fullyLoaded,
        selectedFuelType: FuelType.e10,
      ),
    );
    final built = tester
        .widgetList(find.descendant(
          of: find.byType(StationCard),
          matching: find.byWidgetPredicate((_) => true),
        ))
        .length;
    expect(built, greaterThan(kStationRowWidgetBudget.limit! * 0.5),
        reason: 'the row is far below its budget — either it was '
            'simplified (lower the budget and record why) or this test '
            'stopped rendering the loaded case');
  });
}
