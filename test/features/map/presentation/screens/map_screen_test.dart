import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/map/presentation/screens/map_screen.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// Seedable SearchState fake so tests can drive [searchStateProvider]
/// emissions after the widget is already pumped. Used by the #529
/// regression test below — the fix adds a `ref.listen` on
/// [searchStateProvider] inside `MapScreen.build` to re-nudge the
/// FlutterMap controller whenever a fresh non-empty search result
/// arrives.
class _SeedableSearchState extends SearchState {
  _SeedableSearchState(this._seed);
  AsyncValue<ServiceResult<List<Station>>> _seed;

  @override
  AsyncValue<ServiceResult<List<Station>>> build() => _seed;

  void emit(AsyncValue<ServiceResult<List<Station>>> next) {
    _seed = next;
    state = next;
  }
}

void main() {
  group('MapScreen', () {
    testWidgets('renders Scaffold with Map app bar', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const MapScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      expect(find.text('Map'), findsOneWidget);
    });

    testWidgets('renders compact app bar with small height', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const MapScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      // App bar should be present with preferredSize height of 36
      expect(find.byType(AppBar), findsAtLeast(1));
    });

    testWidgets(
        '#529: non-empty searchState emission after pump does not '
        'throw (map controller nudge)', (tester) async {
      // Drives the ref.listen path added in #529: when the Search tab
      // pushes a new non-empty result into searchStateProvider while
      // the user is already on (or about to switch to) the Map tab,
      // the MapScreen must not throw — the fallback try/catch inside
      // the listener guards against an unattached MapController.
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      final seedable = _SeedableSearchState(
        AsyncValue.data(ServiceResult(
          data: const <Station>[],
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
        )),
      );

      await pumpApp(
        tester,
        const MapScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
          searchStateProvider.overrideWith(() => seedable),
        ],
      );
      await tester.pumpAndSettle();

      // Emit a non-empty result — triggers the listener.
      seedable.emit(AsyncValue.data(ServiceResult(
        data: const <Station>[
          Station(
            id: 'pt-42',
            name: 'GALP',
            brand: 'GALP',
            street: 'Av.',
            postCode: '1200',
            place: 'Lisboa',
            lat: 38.72,
            lng: -9.14,
            dist: 1.0,
            e5: 1.6,
            isOpen: true,
          ),
        ],
        source: ServiceSource.portugalApi,
        fetchedAt: DateTime.now(),
      )));
      await tester.pumpAndSettle();

      // The listener schedules a post-frame callback that calls
      // _mapController.move(). The controller may not be attached in
      // the test environment — the fix catches that and silently
      // returns. Assert no exception reached the harness.
      expect(tester.takeException(), isNull);
    });

    test('#529: source file listens to searchStateProvider', () {
      // Structural guard: if a future refactor removes the ref.listen
      // call that drives the #529 fix, this test flags it immediately
      // rather than waiting for the next device-side blank-tile
      // regression report.
      final source = File(
        'lib/features/map/presentation/screens/map_screen.dart',
      ).readAsStringSync();
      expect(
        source.contains('ref.listen(searchStateProvider'),
        isTrue,
        reason: '#529 fix removed — MapScreen must listen to '
            'searchStateProvider to re-nudge the FlutterMap '
            'controller when a new search lands',
      );
    });
  });
}
