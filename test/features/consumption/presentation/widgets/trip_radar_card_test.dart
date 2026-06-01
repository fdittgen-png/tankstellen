// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/approach/providers/effective_approach_state_provider.dart';
import 'package:tankstellen/features/approach/providers/radar_candidate_list_provider.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_radar_card.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../../helpers/pump_app.dart';

/// #2545 — the closest-station radar card is tap-to-navigate: a tap hands
/// the station's coordinates to [NavigationUtils.openInMaps], which the OS
/// resolves to the default driving/itinéraire app. These structural tests
/// (no goldens) assert the launch URI shape on both card data paths, the
/// effective-fuel price column, and that the empty/placeholder state has NO
/// tap target.
///
/// #2633 — the fallback (polling) path is also swipe-to-page: swipe-left
/// ignores the current station and advances to the next ranked candidate;
/// swipe-right restores the last-ignored one. The swipe must never break
/// the tap-to-navigate target, and the same two actions are exposed as
/// `customSemanticsActions` for screen readers.

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

  // --- #2633: swipe-to-page on the fallback path ----------------------------
  group('TripRadarCard — swipe-to-page (#2633)', () {
    List<Object> overridesFor(List<Station> candidates, FuelType fuel) => [
          effectiveApproachStateProvider.overrideWithValue(null),
          effectiveFuelTypeProvider.overrideWithValue(fuel),
          radarCandidateListProvider.overrideWith((ref) async => candidates),
        ];

    testWidgets('swipe-LEFT ignores the current station + advances to next',
        (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: overridesFor(
          const [_pricedStation, _pricedStation2, _pricedStation3],
          FuelType.e10,
        ),
      );

      // The first ranked station leads.
      expect(find.text('Tankstelle Mitte'), findsOneWidget);
      expect(find.text(PriceFormatter.formatPrice(1.789)), findsOneWidget);

      // Swipe LEFT (endToStart) → ignore + advance to the next candidate.
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Tankstelle Nord'), findsOneWidget);
      expect(find.text(PriceFormatter.formatPrice(1.829)), findsOneWidget);
      expect(find.text('Tankstelle Mitte'), findsNothing);
    });

    testWidgets('swipe-RIGHT restores the previously-ignored station',
        (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: overridesFor(
          const [_pricedStation, _pricedStation2, _pricedStation3],
          FuelType.e10,
        ),
      );

      // Advance once: Mitte → Nord.
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tankstelle Nord'), findsOneWidget);

      // Swipe RIGHT (startToEnd) → restore the previously-ignored Mitte.
      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tankstelle Mitte'), findsOneWidget);
      expect(find.text('Tankstelle Nord'), findsNothing);
    });

    testWidgets('swipe-RIGHT with nothing ignored is a no-op',
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

      // Nothing ignored yet → swipe-right does nothing, still on Mitte.
      await tester.drag(find.byType(Dismissible), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tankstelle Mitte'), findsOneWidget);
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

      // Advance to Nord, then tap — the page-in-place must preserve the
      // tap-to-navigate target.
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tankstelle Nord'), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(fake.launchedUrls, isNotEmpty);
      final launched = fake.launchedUrls.last;
      expect(launched, startsWith('geo:'));
      // Nord's coords / brand, proving the advanced station is the tap target.
      expect(launched, contains('52.55'));
      expect(launched, contains(Uri.encodeComponent('Shell')));
    });

    testWidgets(
        'Semantics exposes the ignore/show-previous customSemanticsActions',
        (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: overridesFor(
          const [_pricedStation, _pricedStation2],
          FuelType.e10,
        ),
      );

      // Before any ignore: only the "Ignore this station" action exists.
      Semantics semantics() => tester.widgetList<Semantics>(
            find.byType(Semantics),
          ).firstWhere(
            (s) => (s.properties.customSemanticsActions ?? {})
                .keys
                .any((a) => a.label == 'Ignore this station'),
          );

      final actionsBefore =
          semantics().properties.customSemanticsActions ?? {};
      final labelsBefore = actionsBefore.keys.map((a) => a.label).toSet();
      expect(labelsBefore, contains('Ignore this station'));
      expect(labelsBefore, isNot(contains('Show previous station')));

      // After ignoring one, the "Show previous station" action appears.
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      final actionsAfter =
          semantics().properties.customSemanticsActions ?? {};
      final labelsAfter = actionsAfter.keys.map((a) => a.label).toSet();
      expect(labelsAfter, contains('Ignore this station'));
      expect(labelsAfter, contains('Show previous station'));
    });

    testWidgets(
        'exhausting the list keeps the last station + toasts "no other"',
        (tester) async {
      await pumpApp(
        tester,
        const TripRadarCard(),
        overrides: overridesFor(
          const [_pricedStation, _pricedStation2],
          FuelType.e10,
        ),
      );

      // Ignore both candidates: Mitte → Nord → exhausted.
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // The "no other station nearby" toast fires (never blanks, #2583)...
      expect(find.text('No other station nearby'), findsOneWidget);
      // ...and the stack resets so the nearest station is shown again.
      expect(find.text('Tankstelle Mitte'), findsOneWidget);
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
}
