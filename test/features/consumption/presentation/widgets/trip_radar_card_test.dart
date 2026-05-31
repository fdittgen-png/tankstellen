// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/approach/providers/effective_approach_state_provider.dart';
import 'package:tankstellen/features/approach/providers/nearest_station_radar_provider.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_radar_card.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../../helpers/pump_app.dart';

/// #2545 — the closest-station radar card is tap-to-navigate: a tap hands
/// the station's coordinates to [NavigationUtils.openInMaps], which the OS
/// resolves to the default driving/itinéraire app. These structural tests
/// (no goldens) assert the launch URI shape on both card data paths, the
/// effective-fuel price column, and that the empty/placeholder state has NO
/// tap target.

/// Records every launchUrl call without touching a real platform channel, so
/// we can assert the geo: URI the card built without emulator-only intent
/// resolution. Mirrors the fake in driving_station_sheet_test.dart.
class _FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final List<String> launchedUrls = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrls.add(url);
    return true;
  }
}

const _pricedStation = Station(
  id: 'radar-stn-1',
  name: 'Tankstelle Mitte',
  brand: 'Aral',
  street: 'Hauptstr',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.5,
  lng: 13.4,
  e10: 1.789,
  diesel: 1.659,
  isOpen: true,
);

const _noPriceStation = Station(
  id: 'radar-stn-2',
  name: 'Leere Tankstelle',
  brand: 'Esso',
  street: 'Nebenweg',
  postCode: '10117',
  place: 'Berlin',
  lat: 48.137,
  lng: 11.575,
  isOpen: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Deterministic price string regardless of the default active country.
    PriceFormatter.setCountry('DE');
  });

  // --- In-radius approach path (effectiveApproachStateProvider hit) ---------
  group('TripRadarCard — in-radius approach path', () {
    testWidgets('tapping the card launches a geo: URI for the station',
        (tester) async {
      final fake = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = fake;

      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: [
          effectiveApproachStateProvider.overrideWithValue(
            const ApproachInRadius(station: _pricedStation, distanceMeters: 250),
          ),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
          nearestStationRadarProvider.overrideWith((ref) async => null),
        ],
      );

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(fake.launchedUrls, isNotEmpty);
      final launched = fake.launchedUrls.single;
      expect(launched, startsWith('geo:'));
      expect(launched, contains('52.5'));
      expect(launched, contains('13.4'));
      // displayName resolves to the brand ("Aral") for a meaningful brand.
      expect(launched, contains(Uri.encodeComponent('Aral')));
    });

    testWidgets('renders the formatted price for the effective fuel',
        (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: [
          effectiveApproachStateProvider.overrideWithValue(
            const ApproachInRadius(station: _pricedStation, distanceMeters: 250),
          ),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
          nearestStationRadarProvider.overrideWith((ref) async => null),
        ],
      );

      expect(find.text(PriceFormatter.formatPrice(1.789)), findsOneWidget);
      // The diesel price must NOT show when the effective fuel is e10.
      expect(find.text(PriceFormatter.formatPrice(1.659)), findsNothing);
    });

    testWidgets('the tap affordance reuses the existing `navigate` ARB key',
        (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: [
          effectiveApproachStateProvider.overrideWithValue(
            const ApproachInRadius(station: _pricedStation, distanceMeters: 250),
          ),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
          nearestStationRadarProvider.overrideWith((ref) async => null),
        ],
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Navigate');
    });
  });

  // --- Nearest-station fallback path (nearestStationRadarProvider) ----------
  group('TripRadarCard — nearest-station fallback path', () {
    testWidgets('tapping the card launches a geo: URI + shows the price',
        (tester) async {
      final fake = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = fake;

      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: [
          // No in-radius hit → the card falls back to the nearest station.
          effectiveApproachStateProvider.overrideWithValue(null),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.diesel),
          nearestStationRadarProvider
              .overrideWith((ref) async => _pricedStation),
        ],
      );

      // The fallback carries a fully-priced station → the diesel price shows.
      expect(find.text(PriceFormatter.formatPrice(1.659)), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      final launched = fake.launchedUrls.single;
      expect(launched, startsWith('geo:'));
      expect(launched, contains('52.5'));
      expect(launched, contains('13.4'));
      expect(launched, contains(Uri.encodeComponent('Aral')));
    });

    testWidgets('renders "--" when the station has no price for the fuel',
        (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: [
          effectiveApproachStateProvider.overrideWithValue(null),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
          nearestStationRadarProvider
              .overrideWith((ref) async => _noPriceStation),
        ],
      );

      expect(find.text('--'), findsOneWidget);
    });
  });

  // --- Empty / placeholder state — NO tap target ----------------------------
  group('TripRadarCard — placeholder state', () {
    testWidgets('no station → placeholder has NO onTap (not tappable)',
        (tester) async {
      final fake = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = fake;

      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: [
          effectiveApproachStateProvider.overrideWithValue(null),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
          nearestStationRadarProvider.overrideWith((ref) async => null),
        ],
      );

      expect(find.text('No station nearby'), findsOneWidget);

      // The placeholder ListTile must carry no onTap — the navigation
      // affordance is absent on the empty state.
      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.onTap, isNull);

      // And there is no Tooltip wrapping a navigable tile.
      expect(find.byType(Tooltip), findsNothing);

      // Tapping the placeholder must launch nothing.
      await tester.tap(find.byType(ListTile));
      await tester.pump();
      expect(fake.launchedUrls, isEmpty);
    });
  });
}
