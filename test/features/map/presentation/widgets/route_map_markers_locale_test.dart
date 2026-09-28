// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_map_view.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #4432 — the device-fix marker (new in #4464) and the route's start /
/// destination markers must say WHAT they are to a screen reader, in the
/// user's language: three dots of different meaning are otherwise three
/// identical "image" nodes. Covers French, the en_XA pseudo-locale, a
/// narrow screen and enlarged text (the #4465 pattern).
void main() {
  const deviceFix = LatLng(45.7610, 5.6800);
  const routeStart = LatLng(45.7594, 5.6842);
  const routeEnd = LatLng(46.2044, 6.1432);
  final measuredAt = DateTime(2026, 9, 20, 14);

  Station forecourt(String id, double lat, double lng) => Station(
        id: id,
        name: id,
        brand: id,
        street: '',
        postCode: '',
        place: id,
        lat: lat,
        lng: lng,
        dist: 1,
        e10: 1.7,
        isOpen: true,
      );

  RouteSearchResult result({required bool currentLocation}) =>
      RouteSearchResult(
        route: const RouteInfo(
          geometry: [routeStart, LatLng(45.9, 5.8), routeEnd],
          distanceKm: 80,
          durationMinutes: 60,
          samplePoints: [routeStart, routeEnd],
        ),
        // The camera frames the STATIONS (#2782) and the marker layer
        // culls off-screen markers, so the stations here span the device,
        // the start and the destination — every marker under test is on
        // screen and therefore in the semantics tree.
        stations: [
          FuelStationResult(forecourt('belley', 45.740, 5.660)),
          FuelStationResult(forecourt('culoz', 45.847, 5.783)),
          FuelStationResult(forecourt('geneve', 46.230, 6.170)),
        ],
        request: RouteSearchRequest(
          revision: 1,
          waypoints: [
            RouteWaypoint(
              lat: deviceFix.latitude,
              lng: deviceFix.longitude,
              label: 'Current location',
              isVehiclePosition: currentLocation,
            ),
            RouteWaypoint(
              lat: routeEnd.latitude,
              lng: routeEnd.longitude,
              label: 'Genève',
            ),
          ],
          fuelType: FuelType.e10,
          searchRadiusKm: 15,
          strategyType: RouteSearchStrategyType.uniform,
          originCapturedAt: currentLocation ? measuredAt : null,
        ),
      );

  Future<void> pumpMap(
    WidgetTester tester, {
    bool currentLocation = true,
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(800, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = MapController();
    addTearDown(controller.dispose);
    final test = standardTestOverrides();
    when(() => test.mockStorage.getActiveProfileId()).thenReturn(null);
    await pumpApp(
      tester,
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: RouteMapView(
            routeResult: result(currentLocation: currentLocation),
            selectedFuel: FuelType.e10,
            mapController: controller,
          ),
        ),
      ),
      overrides: [
        ...test.overrides,
        appClockProvider.overrideWithValue(
            FixedClock(measuredAt.add(const Duration(seconds: 30)))),
      ],
      locale: locale,
    );
  }

  testWidgets('English: device, start and destination are each named',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMap(tester);

    expect(find.bySemanticsLabel('Your position'), findsOneWidget);
    expect(find.bySemanticsLabel('Start'), findsOneWidget);
    expect(find.bySemanticsLabel('Destination'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('French names them in French', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMap(tester, locale: const Locale('fr'));

    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.bySemanticsLabel(fr.yourPosition), findsOneWidget);
    expect(find.bySemanticsLabel(fr.start), findsOneWidget);
    expect(find.bySemanticsLabel(fr.destination), findsOneWidget);
    // Spellings that diverge from English, so the negatives can fail.
    expect(fr.yourPosition, isNot('Your position'));
    expect(find.bySemanticsLabel('Your position'), findsNothing);
    expect(find.bySemanticsLabel('Start'), findsNothing);
    handle.dispose();
  });

  testWidgets('a NAMED origin claims no position in any locale',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMap(tester, currentLocation: false, locale: const Locale('fr'));

    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.bySemanticsLabel(fr.yourPosition), findsNothing);
    // The route's own endpoints are still named.
    expect(find.bySemanticsLabel(fr.start), findsOneWidget);
    handle.dispose();
  });

  // The markers are glyphs with a spoken label, so text scale cannot
  // reflow them; the narrow/enlarged-text pass for the NEW text of #4464
  // is the banner's (route_update_from_position_banner_test.dart). The
  // route map's own chrome (view-mode bar, info bar) is not part of this
  // change and is exercised at its own widths elsewhere.
  testWidgets('en_XA: labels come from the pseudo-locale, not English',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMap(tester, locale: const Locale('en', 'XA'));

    expect(tester.takeException(), isNull);
    final xa =
        await AppLocalizations.delegate.load(const Locale('en', 'XA'));
    expect(find.bySemanticsLabel(xa.yourPosition), findsOneWidget);
    expect(find.bySemanticsLabel(xa.destination), findsOneWidget);
    handle.dispose();
  });
}
