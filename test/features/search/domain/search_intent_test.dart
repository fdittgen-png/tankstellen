// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4138 — intents are presets over parameters that already exist, and
// the sheet must never show a label that no longer matches the state.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';
import 'package:tankstellen/features/search/domain/search_intent.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';

/// The state an intent produces, so detection is tested against exactly
/// what application would have written.
SearchIntentState stateFor(SearchIntent intent, {bool routeMode = false}) {
  final p = searchIntentPresets[intent]!;
  return (
    sortMode: p.sortMode ?? SortMode.distance,
    routeStrategy: p.routeStrategy ?? RouteSearchStrategyType.uniform,
    openOnly: p.openOnly ?? false,
    excludeHighway: p.excludeHighway ?? false,
    routeMode: routeMode || p.requiresRoute,
  );
}

void main() {
  group('every intent has a preset, and presets decide only what they own',
      () {
    test('the map is total over the enum', () {
      expect(searchIntentPresets.keys.toSet(), SearchIntent.values.toSet());
      for (final e in searchIntentPresets.entries) {
        expect(e.value.intent, e.key, reason: 'preset keyed under the '
            'wrong intent would apply the wrong parameters');
      }
    });

    test('bestStop ranks by effective price per litre, never by a verdict',
        () {
      // spec §3 forbids naming one station objectively best; the intent
      // picks a SORT (#4088), which is a presentation of the same list.
      expect(searchIntentPresets[SearchIntent.bestStop]!.sortMode,
          SortMode.bestValue);
      expect(searchIntentPresets[SearchIntent.bestStop]!.requiresConsumption,
          isTrue);
    });

    test('only onMyRoute is a route intent', () {
      final routeIntents = searchIntentPresets.values
          .where((p) => p.requiresRoute)
          .map((p) => p.intent);
      expect(routeIntents, [SearchIntent.onMyRoute]);
    });
  });

  group('detectIntent round-trips what apply would have written', () {
    for (final intent in SearchIntent.values) {
      test('${intent.name} is detected from its own state', () {
        expect(detectIntent(stateFor(intent)), intent);
      });
    }

    test('nearby and route intents never match in the wrong mode', () {
      // The discriminator has to be real: cheapestNearby and onMyRoute
      // share sortMode + openOnly, and differ only by mode.
      final nearbyState = stateFor(SearchIntent.cheapestNearby);
      expect(nearbyState.routeMode, isFalse);
      expect(detectIntent(nearbyState), SearchIntent.cheapestNearby);

      final routeState = stateFor(SearchIntent.onMyRoute);
      expect(routeState.routeMode, isTrue);
      expect(detectIntent(routeState), SearchIntent.onMyRoute);

      // The same parameters in the other mode must NOT keep the label.
      final nearbyInRouteMode = (
        sortMode: nearbyState.sortMode,
        routeStrategy: nearbyState.routeStrategy,
        openOnly: nearbyState.openOnly,
        excludeHighway: nearbyState.excludeHighway,
        routeMode: true,
      );
      expect(detectIntent(nearbyInRouteMode), isNot(SearchIntent.cheapestNearby));
    });
  });

  group('touching a knob deselects the intent (#4138 acceptance 3)', () {
    test('a different sort mode drops to Custom', () {
      final s = stateFor(SearchIntent.cheapestNearby);
      final changed = (
        sortMode: SortMode.rating,
        routeStrategy: s.routeStrategy,
        openOnly: s.openOnly,
        excludeHighway: s.excludeHighway,
        routeMode: s.routeMode,
      );
      expect(detectIntent(changed), isNull);
    });

    test('turning off "open now" drops to Custom', () {
      final s = stateFor(SearchIntent.cheapestNearby);
      final changed = (
        sortMode: s.sortMode,
        routeStrategy: s.routeStrategy,
        openOnly: false,
        excludeHighway: s.excludeHighway,
        routeMode: s.routeMode,
      );
      expect(detectIntent(changed), isNull);
    });

    test('a different route strategy drops the route intent to Custom', () {
      final s = stateFor(SearchIntent.onMyRoute);
      final changed = (
        sortMode: s.sortMode,
        routeStrategy: RouteSearchStrategyType.eco,
        openOnly: s.openOnly,
        excludeHighway: s.excludeHighway,
        routeMode: true,
      );
      expect(detectIntent(changed), isNull);
    });
  });

  group('an unavailable intent says why, and is never silently defaulted',
      () {
    test('bestStop without consumption is blocked, with the reason', () {
      expect(
        blockerFor(SearchIntent.bestStop,
            hasConsumption: false, hasFavourites: true, hasRoute: true),
        SearchIntentBlocker.consumptionUnknown,
      );
    });

    test('bestStop with consumption is available', () {
      expect(
        blockerFor(SearchIntent.bestStop,
            hasConsumption: true, hasFavourites: true, hasRoute: true),
        isNull,
      );
    });

    test('aFavourite needs a favourite; onMyRoute needs a route', () {
      expect(
        blockerFor(SearchIntent.aFavourite,
            hasConsumption: true, hasFavourites: false, hasRoute: true),
        SearchIntentBlocker.noFavourites,
      );
      expect(
        blockerFor(SearchIntent.onMyRoute,
            hasConsumption: true, hasFavourites: true, hasRoute: false),
        SearchIntentBlocker.noRoute,
      );
    });

    test('the intents with no prerequisites are always available', () {
      for (final intent in [SearchIntent.cheapestNearby, SearchIntent.fastest]) {
        expect(
          blockerFor(intent,
              hasConsumption: false, hasFavourites: false, hasRoute: false),
          isNull,
          reason: '${intent.name} depends on nothing the app might lack',
        );
      }
    });
  });
}
