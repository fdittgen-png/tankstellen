// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/approach/providers/effective_approach_state_provider.dart';
import 'package:tankstellen/features/approach/providers/fuel_station_radar_provider.dart';
import 'package:tankstellen/features/approach/providers/radar_candidate_list_provider.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/proximity_fill_bar.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_radar_card.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #2545 — the closest-station radar card is tap-to-navigate: a tap hands
/// the station's coordinates to [NavigationUtils.openInMaps], which the OS
/// resolves to the default driving/itinéraire app. These structural tests
/// (no goldens) assert the launch URI shape on both card data paths, the
/// effective-fuel price column, and that the empty/placeholder state has NO
/// tap target.
///
/// #2661 — the fallback (polling) path is swipe-to-page DISTANCE pagination:
/// swipe-LEFT pages to the NEARER station (toward index 0, the nearest);
/// swipe-RIGHT pages to the FARTHER station. Both clamp at the ends (no-op),
/// the swipe must never break the tap-to-navigate target, and the same two
/// actions are exposed as `customSemanticsActions` for screen readers.

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

/// Feeds a fixed profile into [activeProfileProvider] so the proximity bar's
/// indicated radius (`approachRadiusKm`) is deterministic without booting the
/// Hive-backed profile repository (#2661).
class _StubActiveProfile extends ActiveProfile {
  _StubActiveProfile(this._profile);
  final UserProfile? _profile;
  @override
  UserProfile? build() => _profile;
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

const _pricedStation2 = Station(
  id: 'radar-stn-2',
  name: 'Tankstelle Nord',
  brand: 'Shell',
  street: 'Nordweg',
  postCode: '10119',
  place: 'Berlin',
  lat: 52.55,
  lng: 13.41,
  e10: 1.829,
  diesel: 1.699,
  isOpen: true,
);

const _pricedStation3 = Station(
  id: 'radar-stn-3',
  name: 'Tankstelle Süd',
  brand: 'Total',
  street: 'Südweg',
  postCode: '10961',
  place: 'Berlin',
  lat: 52.49,
  lng: 13.39,
  e10: 1.759,
  diesel: 1.649,
  isOpen: true,
);

const _noPriceStation = Station(
  id: 'radar-stn-x',
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
          radarCandidateListProvider.overrideWith((ref) async => const []),
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
          radarCandidateListProvider.overrideWith((ref) async => const []),
        ],
      );

      expect(find.text(PriceFormatter.formatPrice(1.789)), findsOneWidget);
      // The diesel price must NOT show when the effective fuel is e10.
      expect(find.text(PriceFormatter.formatPrice(1.659)), findsNothing);
    });

    testWidgets(
        '#3257 pt2 — the lead discloses its price freshness (updatedAt) '
        'like the search cards do', (tester) async {
      // A corridor-cached lead can carry a price up to 1 h stale in polled
      // countries; the card must disclose the upstream timestamp.
      const staleLead = Station(
        id: 'radar-stn-stale',
        name: 'Tankstelle Alt',
        brand: 'Aral',
        street: 'Hauptstr',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.5,
        lng: 13.4,
        e10: 1.789,
        isOpen: true,
        updatedAt: '10:30',
      );
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: [
          effectiveApproachStateProvider.overrideWithValue(
            const ApproachInRadius(station: staleLead, distanceMeters: 250),
          ),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
          radarCandidateListProvider.overrideWith((ref) async => const []),
        ],
      );

      // The `stationUpdatedLabel` disclosure joins the fuel/distance
      // subtitle row ("E10 · 250 m · Updated 10:30").
      expect(find.textContaining('Updated 10:30'), findsOneWidget);
    });

    testWidgets(
        '#3257 pt2 — no freshness row when the country API sends no '
        'updatedAt (search-card parity)', (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: [
          effectiveApproachStateProvider.overrideWithValue(
            const ApproachInRadius(station: _pricedStation, distanceMeters: 250),
          ),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
          radarCandidateListProvider.overrideWith((ref) async => const []),
        ],
      );

      expect(find.textContaining('Updated'), findsNothing);
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
          radarCandidateListProvider.overrideWith((ref) async => const []),
        ],
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Navigate');
    });

    testWidgets('the in-radius target is NOT wrapped in a Dismissible',
        (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: [
          effectiveApproachStateProvider.overrideWithValue(
            const ApproachInRadius(station: _pricedStation, distanceMeters: 250),
          ),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
          radarCandidateListProvider.overrideWith((ref) async => const []),
        ],
      );

      // The locked in-radius target is single — no swipe page-set.
      expect(find.byType(Dismissible), findsNothing);
    });
  });

  // --- Nearest-station fallback path (radarCandidateListProvider) -----------
  group('TripRadarCard — nearest-station fallback path', () {
    testWidgets('tapping the card launches a geo: URI + shows the price',
        (tester) async {
      final fake = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = fake;

      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: [
          // No in-radius hit → the card falls back to the ranked list.
          effectiveApproachStateProvider.overrideWithValue(null),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.diesel),
          radarCandidateListProvider
              .overrideWith((ref) async => const [_pricedStation]),
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
      // The provider filters to priced stations, but a single unpriced
      // station in the list still renders "--" on its row.
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: [
          effectiveApproachStateProvider.overrideWithValue(null),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
          radarCandidateListProvider
              .overrideWith((ref) async => const [_noPriceStation]),
        ],
      );

      expect(find.text('--'), findsOneWidget);
    });
  });

  // --- #2661: swipe-to-page distance pagination on the fallback path --------
  group('TripRadarCard — swipe-to-page distance pagination (#2661)', () {
    List<Object> overridesFor(List<Station> candidates, FuelType fuel) => [
          effectiveApproachStateProvider.overrideWithValue(null),
          effectiveFuelTypeProvider.overrideWithValue(fuel),
          radarCandidateListProvider.overrideWith((ref) async => candidates),
        ];

    testWidgets('swipe-RIGHT pages to the FARTHER station (index + 1)',
        (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: overridesFor(
          const [_pricedStation, _pricedStation2, _pricedStation3],
          FuelType.e10,
        ),
      );

      // The nearest (index 0) station leads.
      expect(find.text('Tankstelle Mitte'), findsOneWidget);
      expect(find.text(PriceFormatter.formatPrice(1.789)), findsOneWidget);

      // Swipe RIGHT (startToEnd) → farther → the next candidate.
      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Tankstelle Nord'), findsOneWidget);
      expect(find.text(PriceFormatter.formatPrice(1.829)), findsOneWidget);
      expect(find.text('Tankstelle Mitte'), findsNothing);
    });

    testWidgets('swipe-LEFT pages back to the NEARER station (index - 1)',
        (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: overridesFor(
          const [_pricedStation, _pricedStation2, _pricedStation3],
          FuelType.e10,
        ),
      );

      // Advance once (right → farther): Mitte → Nord.
      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tankstelle Nord'), findsOneWidget);

      // Swipe LEFT (endToStart) → nearer → back to Mitte.
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tankstelle Mitte'), findsOneWidget);
      expect(find.text('Tankstelle Nord'), findsNothing);
    });

    testWidgets('swipe-LEFT at the nearest (index 0) is a no-op',
        (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: overridesFor(
          const [_pricedStation, _pricedStation2],
          FuelType.e10,
        ),
      );

      expect(find.text('Tankstelle Mitte'), findsOneWidget);

      // Already nearest → swipe-left clamps to 0, still Mitte.
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tankstelle Mitte'), findsOneWidget);
    });

    testWidgets('swipe-RIGHT at the farthest end clamps (no-op)',
        (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: overridesFor(
          const [_pricedStation, _pricedStation2],
          FuelType.e10,
        ),
      );

      // Page to the farthest (Nord), then a further right-swipe is a no-op —
      // never blank (#2661).
      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tankstelle Nord'), findsOneWidget);

      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tankstelle Nord'), findsOneWidget);
    });

    testWidgets('tap STILL launches the geo: URI after a swipe',
        (tester) async {
      final fake = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = fake;

      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: overridesFor(
          const [_pricedStation, _pricedStation2, _pricedStation3],
          FuelType.e10,
        ),
      );

      // Page to Nord (right → farther), then tap — the page-in-place must
      // preserve the tap-to-navigate target.
      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tankstelle Nord'), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(fake.launchedUrls, isNotEmpty);
      final launched = fake.launchedUrls.last;
      expect(launched, startsWith('geo:'));
      // Nord's coords / brand, proving the paged station is the tap target.
      expect(launched, contains('52.55'));
      expect(launched, contains(Uri.encodeComponent('Shell')));
    });

    testWidgets(
        'Semantics exposes the nearer/farther customSemanticsActions',
        (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: overridesFor(
          const [_pricedStation, _pricedStation2],
          FuelType.e10,
        ),
      );

      // Both pagination actions are always available (clamped no-ops at the
      // ends) — simpler than the conditional restore.
      Semantics semantics() => tester.widgetList<Semantics>(
            find.byType(Semantics),
          ).firstWhere(
            (s) => (s.properties.customSemanticsActions ?? {})
                .keys
                .any((a) => a.label == 'Nearer station'),
          );

      final actions = semantics().properties.customSemanticsActions ?? {};
      final labels = actions.keys.map((a) => a.label).toSet();
      expect(labels, contains('Nearer station'));
      expect(labels, contains('Farther station'));
    });
  });

  // --- #2661: corporate-green proximity fill bar ----------------------------
  group('TripRadarCard — proximity fill bar (#2661)', () {
    testWidgets(
        'renders the fill bar with fill = 1 - d/r when a profile radius is set',
        (tester) async {
      // 1 km radar radius; the candidate sits 0.4 km away (dist field) →
      // fill = 1 - 400/1000 = 0.6.
      const near = Station(
        id: 'radar-near',
        name: 'Nahe Tankstelle',
        brand: 'Aral',
        street: 'Weg',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.5,
        lng: 13.4,
        e10: 1.789,
        isOpen: true,
        dist: 0.4,
      );
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: [
          effectiveApproachStateProvider.overrideWithValue(null),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
          radarCandidateListProvider.overrideWith((ref) async => const [near]),
          activeProfileProvider.overrideWith(
            () => _StubActiveProfile(
              const UserProfile(id: 'p1', name: 'Test', approachRadiusKm: 1.0),
            ),
          ),
        ],
      );

      final bar = tester.widget<ProximityFillBar>(find.byType(ProximityFillBar));
      expect(bar.radiusMeters, 1000.0);
      expect(bar.distanceMeters, 400.0);
      expect(
        ProximityFillBar.fillFor(bar.distanceMeters, bar.radiusMeters!),
        closeTo(0.6, 1e-9),
      );
    });

    test('fill is 0 at the radius edge and 1 at the station', () {
      // Pure math guard — no widget pump needed.
      expect(ProximityFillBar.fillFor(1000, 1000), 0.0);
      expect(ProximityFillBar.fillFor(0, 1000), 1.0);
      // Beyond the edge clamps to 0; negative distance clamps to 1.
      expect(ProximityFillBar.fillFor(2000, 1000), 0.0);
      expect(ProximityFillBar.fillFor(250, 1000), closeTo(0.75, 1e-9));
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
          radarCandidateListProvider.overrideWith((ref) async => const []),
        ],
      );

      expect(find.text('No station nearby'), findsOneWidget);

      // The placeholder ListTile must carry no onTap — the navigation
      // affordance is absent on the empty state.
      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.onTap, isNull);

      // And there is no Tooltip wrapping a navigable tile.
      expect(find.byType(Tooltip), findsNothing);
      // The empty list is NOT swipeable.
      expect(find.byType(Dismissible), findsNothing);

      // Tapping the placeholder must launch nothing.
      await tester.tap(find.byType(ListTile));
      await tester.pump();
      expect(fake.launchedUrls, isEmpty);
    });
  });

  // --- #2583: retain last station during rescan (colour-only) ----------------
  group('TripRadarCard — rescan retention + scanning tint (#2583)', () {
    testWidgets(
        'a reload KEEPS the last station (no "Scanning…") + shows the '
        'scanning tint on the leading icon', (tester) async {
      // Drive a genuine reload via `container.invalidate`: while the widget
      // still watches it the FutureProvider re-runs, going AsyncLoading
      // carrying its previous value. Under skipLoadingOnReload that routes
      // the retained list back through `data:` while `isLoading` flips
      // true (the colour-only scan signal). A short async gate keeps the
      // re-run pending across a single pump so the in-flight frame is
      // observable.
      final gate = Completer<void>();
      var firstRun = true;
      final container = ProviderContainer(
        overrides: [
          effectiveApproachStateProvider.overrideWithValue(null),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.diesel),
          radarCandidateListProvider.overrideWith((ref) async {
            if (firstRun) {
              firstRun = false;
              return const [_pricedStation];
            }
            // The reload waits on the gate so the loading frame is visible.
            await gate.future;
            return const [_pricedStation];
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: TripRadarCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // First scan resolved: the station row is up (the diesel price shows).
      expect(find.text(PriceFormatter.formatPrice(1.659)), findsOneWidget);
      expect(find.text('Scanning for nearby stations'), findsNothing);

      // Trigger a reload — invalidate so the FutureProvider re-runs
      // (AsyncLoading carrying the previous value); the gated body keeps it
      // pending across this pump.
      container.invalidate(radarCandidateListProvider);
      // Force the lazy re-computation to materialise now (the gated body
      // keeps it pending) so the in-flight loading frame is deterministic.
      expect(
        container.read(radarCandidateListProvider).isLoading,
        isTrue,
        reason: 'invalidate puts the provider into a reload (carrying value)',
      );
      await tester.pump(); // let the reload propagate (do NOT settle yet)

      // During the in-flight rescan the row STILL shows the last station —
      // never the "Scanning…" placeholder — and the leading icon is tinted
      // to the primary "scanning" accent (colour-only signal).
      expect(find.text('Scanning for nearby stations'), findsNothing);
      expect(find.text(PriceFormatter.formatPrice(1.659)), findsOneWidget);

      final theme = Theme.of(tester.element(find.byType(ListTile)));
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.byIcon(Icons.local_gas_station),
        ),
      );
      expect(icon.color, theme.colorScheme.primary,
          reason: 'in-flight rescan tints the leading icon (colour signal)');

      // Let the gated reload complete; the tint clears but the station stays.
      gate.complete();
      await tester.pumpAndSettle();
      final settledIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.byIcon(Icons.local_gas_station),
        ),
      );
      expect(settledIcon.color, isNull,
          reason: 'no tint once the rescan completes');
      expect(find.text(PriceFormatter.formatPrice(1.659)), findsOneWidget);
    });

    testWidgets(
        'first-ever load (no prior value) still shows the "Scanning…" '
        'placeholder', (tester) async {
      // A never-completing future keeps the AsyncValue in its FIRST loading
      // state (no retained value) — the genuine cold start.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectiveApproachStateProvider.overrideWithValue(null),
            effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
            radarCandidateListProvider.overrideWith(
              (ref) => Completer<List<Station>>().future,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: TripRadarCard()),
          ),
        ),
      );
      await tester.pump(); // single pump — the future never completes

      expect(find.text('Scanning for nearby stations'), findsOneWidget);
      // The cold-start placeholder is not tappable.
      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.onTap, isNull);
    });

    testWidgets(
        'a completed scan with NO priced station renders "No station '
        'nearby"', (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: [
          effectiveApproachStateProvider.overrideWithValue(null),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
          // Provider already filters to priced-for-fuel; empty models "no
          // priced station in range".
          radarCandidateListProvider.overrideWith((ref) async => const []),
        ],
      );

      expect(find.text('No station nearby'), findsOneWidget);
      expect(find.text('Scanning for nearby stations'), findsNothing);
    });
  });

  // --- #2965: in-radius superset merge rescues the truncated nearest ---------
  group('TripRadarCard — dense-corridor in-radius merge (#2965)', () {
    // End-to-end through the REAL radarCandidateListProvider + the REAL FR
    // fuelStationRadarProvider: the wide corridor + 15 km near-merge return a
    // far, location-only row (the `limit:50` cap truncated the nearest out), so
    // the corridor-only path is empty → "No station nearby". The candidate
    // list's #2965 in-radius search at the 1 km radar radius returns the 269 m
    // priced station, which the card must then list.
    //
    // RED on master (card shows "No station nearby"); GREEN after the merge.
    testWidgets(
        'shows the 269 m station, NOT "No station nearby", when the corridor '
        'row-cap truncated the nearest out', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeCountryOverride(Countries.byCode('FR')!),
            stationServiceProvider.overrideWithValue(_RadiusKeyedService()),
            effectiveApproachStateProvider.overrideWithValue(
              ApproachPolling(
                gps: _pos(lat: 48.0, lng: 2.0),
                nextPollIn: const Duration(seconds: 5),
              ),
            ),
            effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
            activeProfileProvider.overrideWith(
              () => _StubActiveProfile(
                const UserProfile(
                  id: 'p1',
                  name: 'Test',
                  approachRadiusKm: 1.0,
                ),
              ),
            ),
          ].cast(),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: TripRadarCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // RED on master: the corridor-only candidate list is empty → placeholder.
      expect(find.text('No station nearby'), findsNothing,
          reason: '#2965 — the in-radius merge lists the nearest priced '
              'station instead of the empty placeholder');
      // GREEN: the 269 m station + its e10 price render.
      expect(find.text('Station NEAR'), findsOneWidget);
      expect(find.text(PriceFormatter.formatPrice(1.60)), findsOneWidget);
    });
  });
}

Position _pos({required double lat, required double lng}) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 5, 1, 9),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 12,
      speedAccuracy: 0,
    );

/// Radius-keyed service mirroring the provider test: the wide corridor + near-
/// merge return a far, location-only row (the `limit:50` cap truncated the
/// nearest); the tight in-radius search returns the 269 m priced station.
class _RadiusKeyedService implements StationService {
  static Station _far() => const Station(
        id: 'FAR_55KM',
        name: 'Station FAR',
        brand: 'TEST',
        street: '',
        postCode: '',
        place: '',
        lat: 48.5,
        lng: 2.0,
        isOpen: true,
      );

  static Station _near() => const Station(
        id: 'NEAR_269M',
        name: 'Station NEAR',
        brand: 'TEST',
        street: '',
        postCode: '',
        place: '',
        lat: 48.002416, // ~269 m north of the fix
        lng: 2.0,
        e10: 1.60,
        isOpen: true,
      );

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    final corridorSlice = params.radiusKm >= kCorridorNearMergeRadiusKm;
    return ServiceResult(
      data: corridorSlice ? [_far()] : [_near()],
      source: ServiceSource.cache,
      fetchedAt: DateTime(2026),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) =>
      throw UnimplementedError();
}
