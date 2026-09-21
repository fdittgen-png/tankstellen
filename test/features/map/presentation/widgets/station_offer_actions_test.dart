// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4348 — the capability action contract, rendered.
///
/// Recorded Luxembourg decree centroids and Denmark brand-feed stations
/// come out of their REAL services (`recorded_country_search.dart`); a
/// recorded Tankerkönig Berlin station is the control. Each surface is
/// pumped as production builds it, and the maps launch goes through the
/// injected [NavigationUtils.launcher] so the test sees exactly which
/// destination — if any — the OS would have been handed.
///
/// Mutation proof: flip `kLuCapability.coordinates` to true and the
/// Luxembourg cases here fail (a Navigate button, a swipe, a FAB appear).
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_profile_provider.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/widgets/service_status_banner.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/core/utils/navigation_utils.dart';
import 'package:tankstellen/core/widgets/favorite_dismissible.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_station_sheet.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_sheet.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/decision_header.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_directions_fab.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/silence_error_logger.dart';
import '../../../station_services/support/recorded_country_search.dart';

void main() {
  silenceErrorLoggerSpool();

  late Station luReference;
  late Station deStation;
  late List<Station> dk;
  final launched = <Uri>[];

  String fixture(String name) =>
      File('test/fixtures/$name').readAsStringSync();

  setUpAll(() async {
    luReference = (await searchLuxembourgStations(
      essenceBody: fixture('lu_lustat_essence_slice.json'),
      dieselBody: fixture('lu_lustat_diesel_slice.json'),
      params: const SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 50),
    ))
        .first;
    deStation = (await searchGermanyStations(
      fixture('de_tankerkoenig_list_slice.json'),
      params: const SearchParams(lat: 52.52, lng: 13.405, radiusKm: 3),
    ))
        .first;
    dk = await searchDenmarkStations(
      okBody: fixture('dk_ok_prices_slice.json'),
      shellBody: fixture('dk_shell_prices_slice.json'),
      params: const SearchParams(lat: 55.4, lng: 11.5, radiusKm: 200),
    );
  });

  setUp(() {
    launched.clear();
    NavigationUtils.launcher = (uri, mode) async {
      launched.add(uri);
      return true;
    };
  });
  tearDown(NavigationUtils.resetLauncher);

  Future<AppLocalizations> pumpSheet(WidgetTester tester, Station s) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appClockProvider
            .overrideWithValue(FixedClock(DateTime(2026, 9, 16, 12))),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StationMapSheet(station: s, fuelType: FuelType.diesel),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(StationMapSheet)));
  }

  group('map sheet', () {
    testWidgets('a Luxembourg reference price keeps its price and offers no '
        'Navigate — it says why instead', (tester) async {
      final l10n = await pumpSheet(tester, luReference);
      expect(find.widgetWithText(FilledButton, l10n.navigate), findsNothing);
      expect(find.text(l10n.stationReferencePriceNotice), findsOneWidget);
      expect(find.textContaining('1,782'), findsOneWidget,
          reason: 'the recorded LUSTAT diesel decree price stays visible');
      expect(launched, isEmpty);
    });

    testWidgets('a recorded Berlin station navigates to its own coordinates',
        (tester) async {
      final l10n = await pumpSheet(tester, deStation);
      expect(find.text(l10n.stationReferencePriceNotice), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, l10n.navigate));
      await tester.pump();
      expect(launched, hasLength(1));
      expect(launched.single.path, '${deStation.lat},${deStation.lng}');
    });
  });

  group('driving sheet', () {
    Future<AppLocalizations> pumpDriving(WidgetTester tester, Station s) async {
      await pumpApp(
          tester, DrivingStationSheet(station: s, fuelType: FuelType.diesel));
      return AppLocalizations.of(
          tester.element(find.byType(DrivingStationSheet)));
    }

    testWidgets('no in-car Navigate button towards a reference point',
        (tester) async {
      final l10n = await pumpDriving(tester, luReference);
      expect(find.text(l10n.navigate), findsNothing);
    });

    testWidgets('a real station keeps it, and it launches', (tester) async {
      final l10n = await pumpDriving(tester, deStation);
      await tester.tap(find.text(l10n.navigate));
      await tester.pump();
      expect(launched.single.path, '${deStation.lat},${deStation.lng}');
    });
  });

  group('station detail / deep link FAB', () {
    test('a reference point gets no directions FAB, a station does', () {
      expect(StationDirectionsFab.forStation(luReference), isNull);
      expect(StationDirectionsFab.forStation(deStation), isNotNull);
    });
  });

  group('favorites swipe', () {
    Future<void> pumpFavorite(WidgetTester tester, Station s) => pumpApp(
          tester,
          FavoriteDismissible<Object>(
            dismissKey: 'fav-${s.id}',
            label: s.name,
            latitude: s.lat,
            longitude: s.lng,
            stationId: s.id,
            captureHandle: Object.new,
            removeFavorite: (_) async {},
            undoRemove: (_) {},
            child: const SizedBox(height: 80, child: Text('row')),
          ),
        );

    testWidgets('a reference-price favorite can be removed but not swiped '
        'towards', (tester) async {
      await pumpFavorite(tester, luReference);
      expect(tester.widget<Dismissible>(find.byType(Dismissible)).direction,
          DismissDirection.endToStart);
      await tester.fling(find.text('row'), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();
      expect(launched, isEmpty);
    });

    testWidgets('a real station favorite swipes right into the maps app',
        (tester) async {
      await pumpFavorite(tester, deStation);
      expect(tester.widget<Dismissible>(find.byType(Dismissible)).direction,
          DismissDirection.horizontal);
      // The production swipe callback, invoked directly: a fling animates
      // the background through widths its label row cannot fit.
      final keep = await tester
          .widget<Dismissible>(find.byType(Dismissible))
          .confirmDismiss!(DismissDirection.startToEnd);
      expect(keep, isFalse, reason: 'navigating never removes the favorite');
      expect(launched.single.path, '${deStation.lat},${deStation.lng}');
    });
  });

  group('decision header — partial coverage (Denmark)', () {
    testWidgets('picks drawn from a brand-only source are qualified',
        (tester) async {
      final items = <SearchResultItem>[
        for (final s in dk.take(3)) FuelStationResult(s),
      ];
      await pumpApp(
        tester,
        DecisionHeader(items: items),
        overrides: [
          refuelProfileProvider.overrideWithValue(const RefuelProfile()),
          selectedFuelTypeOverride(FuelType.e10),
        ],
      );
      final l10n =
          AppLocalizations.of(tester.element(find.byType(DecisionHeader)));
      expect(find.text(l10n.decisionPartialCoverageNote), findsOneWidget);
    });
  });

  group('unavailable provider screen', () {
    testWidgets('names the structural state and never blames the connection',
        (tester) async {
      await pumpApp(
        tester,
        ServiceChainErrorWidget(
          error: const ProviderUnavailableException('AU'),
          onRetry: () {},
        ),
      );
      final l10n = AppLocalizations.of(
          tester.element(find.byType(ServiceChainErrorWidget)));
      expect(find.text(l10n.errorTitleProviderUnavailable), findsOneWidget);
      expect(find.text(l10n.errorProviderUnavailable), findsOneWidget);
      expect(find.text(l10n.errorHintConnection), findsNothing);
      expect(find.text(l10n.reportThisIssue), findsNothing,
          reason: 'a declared-dead provider is not a bug to file');
    });
  });
}
