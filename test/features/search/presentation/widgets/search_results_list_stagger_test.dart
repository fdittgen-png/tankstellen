// #595 — verify the staggered fade-in wraps each card in the
// search results list so the shimmer → results transition feels
// like a cascade rather than a flash.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/widgets/staggered_fade_in.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_list.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

const _s1 = Station(
  id: 'stg-1',
  name: 'A',
  brand: 'A',
  street: '1',
  postCode: '10000',
  place: 'X',
  lat: 43.45,
  lng: 3.42,
  isOpen: true,
);
const _s2 = Station(
  id: 'stg-2',
  name: 'B',
  brand: 'B',
  street: '2',
  postCode: '10000',
  place: 'X',
  lat: 43.46,
  lng: 3.43,
  isOpen: true,
);
const _s3 = Station(
  id: 'stg-3',
  name: 'C',
  brand: 'C',
  street: '3',
  postCode: '10000',
  place: 'X',
  lat: 43.47,
  lng: 3.44,
  isOpen: true,
);

void main() {
  group('SearchResultsList stagger (#595)', () {
    testWidgets('each card is wrapped in a StaggeredFadeIn', (tester) async {
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
              FuelStationResult(_s1),
              FuelStationResult(_s2),
              FuelStationResult(_s3),
            ],
            source: ServiceSource.cache,
            fetchedAt: DateTime(2026, 4, 14),
          ),
          onRefresh: () {},
        ),
        overrides: test.overrides,
      );

      // Three visible cards → three StaggeredFadeIn wrappers. The tag
      // key ensures we find our own wrappers (and would survive any
      // unrelated wrapper elsewhere in the tree).
      expect(
        find.byKey(const ValueKey('stagger-stg-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('stagger-stg-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('stagger-stg-3')),
        findsOneWidget,
      );
      expect(find.byType(StaggeredFadeIn), findsNWidgets(3));
    });
  });
}
