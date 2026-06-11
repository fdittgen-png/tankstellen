// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Regression test for #1771 — each row of [SearchResultsList] watches
// its favorite/rating providers inside its own per-row `Consumer`, so a
// favorite toggle or rating change rebuilds only that row instead of
// the whole list (which would also re-run the filter/sort pipeline in
// the parent build).

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_list.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

const _stationA = Station(
  id: 's1',
  name: 'Total A',
  brand: 'TOTAL',
  street: '1 rue A',
  postCode: '34120',
  place: 'Pézenas',
  lat: 43.45,
  lng: 3.42,
  isOpen: true,
);
const _stationB = Station(
  id: 's2',
  name: 'Esso B',
  brand: 'ESSO',
  street: '2 rue B',
  postCode: '34120',
  place: 'Pézenas',
  lat: 43.46,
  lng: 3.43,
  isOpen: true,
);

Future<void> _pumpList(WidgetTester tester) async {
  final test = standardTestOverrides();
  when(() => test.mockStorage.hasApiKey()).thenReturn(false);
  when(() => test.mockStorage.getApiKey()).thenReturn(null);
  when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
  when(() => test.mockStorage.getRatings()).thenReturn(<String, int>{});

  await pumpApp(
    tester,
    SearchResultsList(
      result: ServiceResult<List<SearchResultItem>>(
        data: const [
          FuelStationResult(_stationA),
          FuelStationResult(_stationB),
        ],
        source: ServiceSource.cache,
        fetchedAt: DateTime(2026, 4, 14),
      ),
      onRefresh: () {},
    ),
    overrides: test.overrides,
  );
}

void main() {
  group('SearchResultsList per-row provider scope (#1771)', () {
    testWidgets('each results row sits under its own Consumer',
        (tester) async {
      await _pumpList(tester);

      for (final id in ['s1', 's2']) {
        expect(
          find.ancestor(
            of: find.byKey(ValueKey('station-$id')),
            matching: find.byType(Consumer),
          ),
          findsOneWidget,
          reason: 'station-$id must be wrapped in a per-row Consumer so a '
              'favorite/rating change rebuilds only that row (#1771)',
        );
      }
    });
  });
}
