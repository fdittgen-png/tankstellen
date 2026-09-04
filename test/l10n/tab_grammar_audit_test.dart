// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';
import 'package:tankstellen/core/widgets/shimmer_placeholder.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/alert_statistics_card.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/alerts_body.dart';
import 'package:tankstellen/features/alerts/providers/alert_provider.dart';
import 'package:tankstellen/features/alerts/providers/radius_alerts_provider.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/favorite_station_dismissible.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/favorites_tab.dart';
import 'package:tankstellen/features/favorites/providers/favorite_stations_provider.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/fuel_tab.dart';
import 'package:tankstellen/features/map/presentation/widgets/nearby_map_view.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trajets_tab.dart';
import 'package:tankstellen/features/trips/providers/trip_history_provider.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../fixtures/stations.dart';
import '../helpers/mock_providers.dart';
import '../helpers/never_truncates.dart';
import '../helpers/pump_app.dart';
import '../mocks/mocks.dart';
import 'tab_grammar_audit_fakes.dart';

/// #3951 (Epic #3947) — the five main tabs audited against the visual
/// grammar at 320 dp under the `en_XA` pseudo-locale AND at a 1.3x text
/// scale (the two expansion axes of `text_expansion_test.dart`). Each
/// case pumps the tab's real body widget in the state the grammar rules
/// on (the empty state, plus the one-item state where the providers can
/// be faked) and fails on any `RenderFlex` overflow.
///
/// ## Audit findings — surfaces still off the grammar (2026-09-04)
///
/// Fixed in this change (alerts + favorites are owned here):
///  * `alerts/.../alerts_body.dart` — raw `EdgeInsets` (16/8/8/4, 12/0/12/4,
///    16/4/16/8), `titleMedium` headers, `bodySmall.copyWith` hint, and the
///    0·0·0 strip + "(0)" headers at zero.
///  * `alerts/.../alert_statistics_card.dart` — raw `Card(margin: 16/8/16/4)`,
///    `titleLarge.copyWith(bold)` numbers, `bodySmall.copyWith` labels →
///    `PanelCard` + `AppText.title` / `AppText.label`.
///  * `alerts/.../alerts_last_checked_footer.dart`, `alerts_best_effort_note
///    .dart` — raw `EdgeInsets`, `bodySmall.copyWith(onSurfaceVariant)`.
///  * `alerts/.../alerts_list_tiles.dart` — `Colors.grey` paused icon.
///  * `favorites/.../favorites_loading_view.dart` — `fromLTRB(24, 32, 24,
///    16)`, `titleSmall!.copyWith`, `bodySmall?.copyWith`, `circular(2)`.
///  * `favorites/.../swipe_tutorial_banner.dart` — `Container(margin: 16/8,
///    padding: 12, circular(12))`, `bodyMedium?.copyWith`.
///  * `favorites/.../ev_favorite_card.dart` — `titleMedium?.copyWith(bold)`
///    name, `bodySmall?.copyWith(fontSize: 11)` x2, raw 2 dp gaps.
///  * `favorites/.../favorites_tab.dart` — hard-coded `'Favorites load'`.
///
/// Reported, NOT fixed (core, or the search/map and fill_ups/trips agents):
///  * `core/widgets/help_banner.dart:186-219` — the one-tip `HelpBanner`
///    measures **320 x 580 px** at 320 dp in plain English: the trailing
///    "Got it" button stays beside the text and starves the tip column (the
///    paged variant already moved it to the nav line). On the alerts tab it
///    pushes the stats strip below the fold.
///  * `search/.../station_card.dart:200` — main `Row` overflows by 2.4 px at
///    a 1.3x text scale inside the Favorites list.
///  * `favorites/.../ev_favorite_card.dart:75` — `symmetric(10, 6)` mirrors
///    `search/.../station_card.dart:199` (#2229 parity) — move together.
///    `:192` — the kW headline is `titleLarge!.copyWith(bold)`; it must take
///    the role the StationCard price gets (`AppText.display`). `Colors.amber`
///    star and `Colors.grey` dots also mirror StationCard.
///  * `core/widgets/empty_state.dart` — `titleMedium?.copyWith`, `bodyMedium
///    ?.copyWith`, `EdgeInsets.all(32)` / `symmetric(32, 24)`, hard-coded
///    `Icons.search` on the CTA.
///  * `map/.../nearby_map_view.dart:87` — `EmptyState(iconSize: 80)`; `:60`
///    a bare `Container` info bar.
///  * `fill_ups/.../fuel_tab.dart:52` — `EmptyState` without an action; the
///    header cards each carry their own margins.
///  * `trips/.../trajets_tab.dart:150,183` — `EdgeInsets.only(top: 4, ...)`.
///  * `favorites/.../favorites_tab.dart:40` — `EmptyState(iconSize: 80)` —
///    same ad-hoc size as the map; a core-level decision.
void main() {
  const pseudoLocale = Locale('en', 'XA');

  /// Pumps [child] at 320 dp under [pseudoLocale] (or plain English at a
  /// 1.3x text scale when [scaled]) and fails on any layout exception.
  Future<void> pumpTab(
    WidgetTester tester,
    Widget child, {
    required String widgetName,
    List<Object>? overrides,
    bool scaled = false,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (scaled) {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    await pumpApp(
      tester,
      child,
      locale: scaled ? const Locale('en') : pseudoLocale,
      overrides: overrides,
      settle: settle,
    );

    expect(
      tester.takeException(),
      isNull,
      reason: '$widgetName overflows at 320 dp under '
          '${scaled ? 'a 1.3x text scale' : 'the en_XA pseudo-locale'} — '
          'give the offending Row/Column a Flexible/Expanded child, allow '
          'wrapping, or shorten the layout.',
    );
  }

  /// Runs [body] once per expansion axis so every tab is pinned on both.
  void bothAxes(
    String name,
    Future<void> Function(WidgetTester tester, bool scaled) body,
  ) {
    testWidgets('$name — en_XA at 320 dp', (tester) => body(tester, false));
    testWidgets('$name — 1.3x text scale at 320 dp',
        (tester) => body(tester, true));
  }

  group('Favorites tab', () {
    bothAxes('FavoritesTab — empty state', (tester, scaled) async {
      final test = standardTestOverrides(favoriteIds: const []);
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      await pumpTab(
        tester,
        const FavoritesTab(),
        overrides: test.overrides,
        scaled: scaled,
        widgetName: 'FavoritesTab (empty)',
      );
      expect(find.byType(EmptyState), findsOneWidget);
      expectNoTextTruncates(tester, within: find.byType(EmptyState));
    });

    // en_XA only: at 1.3x the row inside `search/.../station_card.dart:200`
    // overflows by 2.4 px (search agent's file — audit finding above); the
    // favorites-owned chrome around it (swipe banner, list) is what this
    // case pins. Re-enable `bothAxes` once StationCard lands on the grammar.
    testWidgets('FavoritesTab — one favorite station — en_XA at 320 dp',
        (tester) async {
      const scaled = false;
      final test = standardTestOverrides(favoriteIds: [testStation.id]);
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
      when(() => test.mockStorage.getRatings())
          .thenReturn(const <String, int>{});
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);
      await pumpTab(
        tester,
        const FavoritesTab(),
        overrides: [
          ...test.overrides,
          favoriteStationsProvider.overrideWith(
            () => LoadedFavoriteStations([testStation]),
          ),
        ],
        scaled: scaled,
        widgetName: 'FavoritesTab (one station)',
      );
      expect(find.byType(FavoriteStationDismissible), findsOneWidget);
    });
  });

  group('Map tab', () {
    // The real map needs tiles; only the empty and loading branches of
    // `NearbyMapView` are pumped — the branches the grammar rules on.
    bothAxes('NearbyMapView — empty result', (tester, scaled) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      final empty = ServiceResult<List<SearchResultItem>>(
        data: const [],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime(2026, 3, 11, 14, 15),
      );
      await pumpTab(
        tester,
        NearbyMapView(
          searchState: AsyncValue<dynamic>.data(empty),
          selectedFuel: FuelType.e10,
          searchRadiusKm: 10,
          mapController: MapController(),
        ),
        overrides: test.overrides,
        scaled: scaled,
        widgetName: 'NearbyMapView (empty)',
      );
      expect(find.byType(EmptyState), findsOneWidget);
      expectNoTextTruncates(tester, within: find.byType(EmptyState));
    });

    bothAxes('NearbyMapView — loading', (tester, scaled) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      await pumpTab(
        tester,
        NearbyMapView(
          searchState: const AsyncValue<dynamic>.loading(),
          selectedFuel: FuelType.e10,
          searchRadiusKm: 10,
          mapController: MapController(),
        ),
        overrides: test.overrides,
        scaled: scaled,
        settle: false,
        widgetName: 'NearbyMapView (loading)',
      );
      expect(find.byType(ShimmerPane), findsOneWidget);
    });
  });

  group('Carburant tab', () {
    // The populated FuelTab needs the tank-level / inventory / stats
    // providers (Hive-backed, being restyled by the fill_ups agent); the
    // zero-data state is what the grammar rules on here.
    bothAxes('FuelTab — no fill-ups', (tester, scaled) async {
      await pumpTab(
        tester,
        Builder(
          builder: (context) => FuelTab(
            fillUps: const [],
            stats: const ConsumptionStats(
              fillUpCount: 0,
              totalLiters: 0,
              totalSpent: 0,
              totalDistanceKm: 0,
            ),
            l: AppLocalizations.of(context),
          ),
        ),
        scaled: scaled,
        widgetName: 'FuelTab (empty)',
      );
      expect(find.byType(EmptyState), findsOneWidget);
      expectNoTextTruncates(tester, within: find.byType(EmptyState));
    });
  });

  group('Trajets tab', () {
    // The populated TrajetsTab pulls the tank report + monthly insights
    // (trips agent); the zero-trip state is pumped here.
    bothAxes('TrajetsTab — no trips', (tester, scaled) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);
      await pumpTab(
        tester,
        const TrajetsTab(),
        overrides: [
          ...test.overrides,
          tripHistoryListProvider.overrideWith(
            () => FixedTripHistoryList(const []),
          ),
          vehicleProfileListProvider.overrideWith(
            () => FixedVehicleProfileList(const []),
          ),
          activeVehicleProfileProvider.overrideWith(
            () => FixedActiveVehicle(null),
          ),
        ],
        scaled: scaled,
        widgetName: 'TrajetsTab (empty)',
      );
      expect(find.byKey(const Key('trajets_empty_state')), findsOneWidget);
      expectNoTextTruncates(tester, within: find.byType(EmptyState));
    });
  });

  group('Alertes tab', () {
    bothAxes('AlertsBody — zero alerts (one empty state)',
        (tester, scaled) async {
      final test = standardTestOverrides();
      await pumpTab(
        tester,
        const AlertsBody(),
        overrides: _alertOverrides(test, alerts: const []),
        scaled: scaled,
        widgetName: 'AlertsBody (empty)',
      );
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byType(AlertStatisticsCard), findsNothing);
      // Both CTAs wrap rather than truncate at 320 dp.
      expectNoTextTruncates(tester, within: find.byType(FilledButton));
      expectNoTextTruncates(tester, within: find.byType(TextButton));
    });

    // The one-time help banner is stubbed as dismissed: the core
    // `HelpBanner` (one-tip contract) measures 320 x 580 px at 320 dp in
    // plain English — under en_XA it alone exceeds the viewport + cache
    // extent, so the ListView never builds the strip beneath it (audit
    // finding above, core-owned). Dismissed, the case pins what this issue
    // owns: the strip and both headers are back with one alert.
    bothAxes('AlertsBody — one station alert (strip + headers)',
        (tester, scaled) async {
      final test = standardTestOverrides();
      await pumpTab(
        tester,
        const AlertsBody(),
        overrides: _alertOverrides(
          test,
          alerts: [auditAlert()],
          helpBannerDismissed: true,
        ),
        scaled: scaled,
        widgetName: 'AlertsBody (one alert)',
      );
      expect(find.byType(AlertStatisticsCard), findsOneWidget);
      expect(find.text('Radius alerts (0)'), findsNothing);
    });
  });
}

List<Object> _alertOverrides(
  ({List<Object> overrides, MockStorageRepository mockStorage}) test, {
  required List<PriceAlert> alerts,
  bool helpBannerDismissed = false,
}) {
  when(() => test.mockStorage.getSetting(any())).thenReturn(null);
  if (helpBannerDismissed) {
    when(() => test.mockStorage.getSetting(StorageKeys.helpBannerAlerts))
        .thenReturn(true);
  }
  when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
  when(() => test.mockStorage.getAlerts()).thenReturn([]);
  return [
    ...test.overrides,
    alertProvider.overrideWith(() => FixedAlerts(alerts)),
    radiusAlertsProvider.overrideWith(EmptyRadiusAlerts.new),
  ];
}
