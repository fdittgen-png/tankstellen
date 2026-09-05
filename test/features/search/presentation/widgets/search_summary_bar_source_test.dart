// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_mode.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/domain/route_search_result.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/summary_chip.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_summary_bar.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// Records every launchUrl call without touching the real platform channel
/// (#2373). Mixes in [MockPlatformInterfaceMixin] so the verify-token guard
/// on [UrlLauncherPlatform.instance] accepts the assignment in test builds.
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

const _route = RouteInfo(
  geometry: [LatLng(43.6, 3.9), LatLng(41.4, 2.2)],
  distanceKm: 340.0,
  durationMinutes: 210.0,
  samplePoints: [LatLng(43.6, 3.9)],
);

const _frStation = Station(
  id: 'fr-1',
  name: 'Pezenas',
  brand: 'TOTAL',
  street: 'Avenue de la Gare',
  postCode: '34120',
  place: 'Pezenas',
  lat: 43.46,
  lng: 3.42,
  dist: 1.0,
  e10: 1.79,
);

const _esStation = Station(
  id: 'es-1',
  name: 'Figueres',
  brand: 'REPSOL',
  street: 'Carrer Nord',
  postCode: '17600',
  place: 'Figueres',
  lat: 42.27,
  lng: 2.96,
  dist: 90.0,
  e10: 1.59,
);

/// #3955 — the open-data credit is the summary band's LEADING segment.
void main() {
  late _FakeUrlLauncher launcher;

  setUp(() {
    launcher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  Future<void> pumpBand(WidgetTester tester, {List<Object> extra = const []}) async {
    final test = standardTestOverrides(country: Countries.france);
    when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
    await pumpApp(
      tester,
      const SearchSummaryBar(),
      overrides: [
        ...test.overrides,
        selectedFuelTypeOverride(FuelType.e10),
        searchRadiusOverride(10),
        ...extra,
      ],
    );
  }

  group('SearchSummaryBar data-source segment (#3955)', () {
    testWidgets('leads the band: the flag + provider pill is the first chip',
        (tester) async {
      await pumpBand(tester);

      final chips = tester.widgetList<SummaryChip>(find.byType(SummaryChip));
      expect(chips.first.key, const Key('search_summary_source'));
      expect(find.text(Countries.france.flag), findsOneWidget);
      expect(find.text(Countries.france.apiProvider!), findsOneWidget);
      // The source pill sits left of the fuel pill on the same band.
      final source = tester.getTopLeft(find.byKey(const Key('search_summary_source')));
      final fuel = tester.getTopLeft(find.byKey(const Key('search_summary_fuel')));
      expect(source.dx, lessThan(fuel.dx));
    });

    testWidgets('tapping the pill opens the registry policy.sourceUrl, not '
        'the criteria sheet', (tester) async {
      await pumpBand(tester);

      await tester.tap(find.byKey(const Key('search_summary_source')));
      await tester.pumpAndSettle();

      final expected = CountryServiceRegistry.policyFor('FR')!.sourceUrl;
      expect(expected, isNotEmpty);
      expect(launcher.launchedUrls, [expected]);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('the tooltip and screen-reader label carry the source and '
        'the licence', (tester) async {
      await pumpBand(tester);

      final policy = CountryServiceRegistry.policyFor('FR')!;
      final tooltip = tester.widget<Tooltip>(
        find.ancestor(
          of: find.text(Countries.france.apiProvider!),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, contains(policy.attribution));
      expect(tooltip.message, contains(policy.license));
    });

    testWidgets('a cross-border route credits EVERY producing country in one '
        'pill (#2622)', (tester) async {
      await pumpBand(
        tester,
        extra: [
          activeSearchModeOverride(SearchMode.route),
          routeSegmentSearchParamOverride(50),
          routeSearchStateOverride(
            const AsyncValue<RouteSearchResult?>.data(
              RouteSearchResult(
                route: _route,
                stations: [
                  FuelStationResult(_frStation),
                  FuelStationResult(_esStation),
                ],
              ),
            ),
          ),
        ],
      );

      final fr = CountryServiceRegistry.policyFor('FR')!.attribution;
      final es = CountryServiceRegistry.policyFor('ES')!.attribution;
      final pill = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('search_summary_source')),
          matching: find.textContaining(fr),
        ),
      );
      expect(pill.data, contains(es));
      expect(find.byIcon(Icons.open_in_new), findsNothing);
      // The band still opens the criteria sheet: the joined credit is not
      // a link, so a tap on it is the band's tap.
    });

    testWidgets('a key-gated country gets no credit pill (its notice is the '
        'demo banner)', (tester) async {
      final test = standardTestOverrides(); // Germany — key-gated
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
        ],
      );
      expect(find.byKey(const Key('search_summary_source')), findsNothing);
    });

    testWidgets('the band is one full-width strip at 320 dp — not a partial '
        'band ending with the last chip', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Loose constraints, like the AnimatedSize the search screen wraps
      // the band in: the band must still claim the whole width.
      final test = standardTestOverrides(country: Countries.france);
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      await pumpApp(
        tester,
        const Align(
          alignment: Alignment.topCenter,
          child: SearchSummaryBar(),
        ),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
        ],
      );

      final band = tester.getRect(find.byType(SearchSummaryBar));
      expect(band.width, 320);
      expect(tester.takeException(), isNull);
    });
  });
}
