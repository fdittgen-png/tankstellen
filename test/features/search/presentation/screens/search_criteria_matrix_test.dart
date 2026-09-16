// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4238 / #4200 — the criteria surface proven by what a user can do, at the
// widths, text scales and pseudo-locale it ships to. State transitions, not
// widget counts. (Intent presets arrive with #4199; their cases join here.)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_mode.dart';
import 'package:tankstellen/core/domain/station_amenity.dart';
import 'package:tankstellen/core/navigation/search_fab_action_provider.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/services/location_search_provider.dart';
import 'package:tankstellen/core/services/location_search_service.dart';
import 'package:tankstellen/features/route_search/presentation/widgets/route_input.dart';
import 'package:tankstellen/features/search/presentation/screens/search_criteria_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/location_input.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_radius_slider.dart';
import 'package:tankstellen/features/search/providers/search_filters_provider.dart';
import 'package:tankstellen/features/search/providers/search_screen_ui_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';

/// No place lookups: typing into a field must never reach a network.
class _NoLookups implements LocationSearchService {
  @override
  LocationInputType detectInputType(String input, CountryConfig country) =>
      RegExp(r'^\d+$').hasMatch(input.trim())
          ? LocationInputType.zip
          : LocationInputType.city;

  /// Every other call (city lookups) answers with no places.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<List<ResolvedLocation>>.value(const []);
}

Future<ProviderContainer> _pumpCriteria(
  WidgetTester tester, {
  Size size = const Size(360, 800),
  double textScale = 1.0,
  Locale locale = const Locale('en'),
  SearchMode? mode,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final test = standardTestOverrides();
  when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
  late ProviderContainer container;
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ...test.overrides,
      selectedFuelTypeOverride(FuelType.e10),
      searchRadiusOverride(10),
      userPositionNullOverride(),
      if (mode != null) activeSearchModeOverride(mode),
      locationSearchServiceProvider.overrideWithValue(_NoLookups()),
    ].cast(),
    child: Consumer(builder: (context, ref, _) {
      container = ProviderScope.containerOf(context);
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: const SearchCriteriaScreen(),
      );
    }),
  ));
  await tester.pumpAndSettle();
  return container;
}

final _l = lookupAppLocalizations(const Locale('en'));

void main() {
  group('responsive matrix — no overflow, every essential reachable', () {
    const sizes = {
      '320×640': Size(320, 640),
      '360×800': Size(360, 800),
      '412×915': Size(412, 915),
    };
    for (final size in sizes.entries) {
      for (final scale in const [1.0, 1.3]) {
        for (final locale in const [Locale('en'), Locale('en', 'XA')]) {
          for (final mode in const [SearchMode.nearby, SearchMode.route]) {
            testWidgets(
                '${size.key} · $scale× · ${locale.toLanguageTag()} · '
                '${mode.name}', (tester) async {
              await _pumpCriteria(tester,
                  size: size.value, textScale: scale, locale: locale, mode: mode);

              expect(tester.takeException(), isNull,
                  reason: 'no RenderFlex overflow at this width/scale/locale');
              expect(find.byType(FuelTypeSelector), findsOneWidget);
              expect(find.byKey(const ValueKey('criteria-reset-button')),
                  findsOneWidget);
              if (mode == SearchMode.nearby) {
                expect(find.byKey(const ValueKey('criteria-radius-custom')),
                    findsOneWidget);
              } else {
                expect(find.byKey(const ValueKey('route-swap-endpoints')),
                    findsOneWidget);
                expect(find.byKey(const ValueKey('criteria-disabled-reason')),
                    findsOneWidget,
                    reason: 'an unavailable Search always says why');
              }
            });
          }
        }
      }
    }
  });

  group('interactions', () {
    testWidgets(
        'Nearby → Route → Nearby keeps what was typed in both modes '
        '(no silent reset)', (tester) async {
      await _pumpCriteria(tester);
      await tester.enterText(
          find.descendant(
              of: find.byType(LocationInput), matching: find.byType(TextField)),
          '34120');
      await tester.pump();

      await tester.tap(find.text(_l.criteriaModeRoute).first);
      await tester.pumpAndSettle();
      await tester.enterText(
          find
              .descendant(
                  of: find.byType(RouteInput), matching: find.byType(TextField))
              .first,
          'Montpellier');
      await tester.pump();

      await tester.tap(find.text(_l.criteriaModeNearby).first);
      await tester.pumpAndSettle();
      expect(find.text('34120'), findsOneWidget,
          reason: 'switching modes must not erase the typed location');

      await tester.tap(find.text(_l.criteriaModeRoute).first);
      await tester.pumpAndSettle();
      expect(find.text('Montpellier'), findsOneWidget,
          reason: 'nor the typed route start');
      await tester.pump(const Duration(seconds: 2)); // flush debouncers
    });

    testWidgets('swap exchanges the endpoints and Search stays honest',
        (tester) async {
      final c = await _pumpCriteria(tester, mode: SearchMode.route);
      final fields = find.descendant(
          of: find.byType(RouteInput), matching: find.byType(TextField));
      Finder reason() => find.byKey(const ValueKey('criteria-disabled-reason'));

      await tester.enterText(fields.first, 'Montpellier');
      await tester.enterText(fields.last, 'Nîmes');
      await tester.pumpAndSettle();
      expect(reason(), findsNothing,
          reason: 'both endpoints named — typed names resolve at search time');
      expect(c.read(searchFabActionControllerProvider)?.enabled, isTrue);

      await tester.tap(find.byKey(const ValueKey('route-swap-endpoints')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(fields.first).controller!.text, 'Nîmes');
      expect(tester.widget<TextField>(fields.last).controller!.text,
          'Montpellier');
      expect(c.read(searchFabActionControllerProvider)?.enabled, isTrue,
          reason: 'a swap keeps a complete route searchable');

      await tester.enterText(fields.last, '');
      await tester.pumpAndSettle();
      expect(reason(), findsOneWidget,
          reason: 'an incomplete route says why Search is unavailable');
      expect(c.read(searchFabActionControllerProvider)?.enabled, isFalse);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('one Search action follows the mode it is in', (tester) async {
      final c = await _pumpCriteria(tester);
      expect(c.read(searchFabActionControllerProvider)?.enabled, isTrue);

      await tester.tap(find.text(_l.criteriaModeRoute).first);
      await tester.pumpAndSettle();
      expect(c.read(searchFabActionControllerProvider)?.enabled, isFalse);
      expect(find.byKey(const ValueKey('criteria-disabled-reason')),
          findsOneWidget);

      await tester.tap(find.text(_l.criteriaModeNearby).first);
      await tester.pumpAndSettle();
      expect(c.read(searchFabActionControllerProvider)?.enabled, isTrue);
      expect(find.byKey(const ValueKey('criteria-disabled-reason')),
          findsNothing);
    });

    testWidgets('a radius preset writes the one radius value', (tester) async {
      final c = await _pumpCriteria(tester);
      final preset = find.byKey(const ValueKey('criteria-radius-preset-25'));
      await tester.ensureVisible(preset);
      await tester.tap(preset);
      await tester.pumpAndSettle();
      expect(c.read(searchRadiusProvider), 25.0);
      expect(tester.widget<ChoiceChip>(preset).selected, isTrue);
      expect(find.byType(Slider), findsNothing,
          reason: 'a preset value is shown once, by its chip');
    });

    testWidgets('filters keep their selection and show the count while '
        'collapsed, however often they are folded', (tester) async {
      final c = await _pumpCriteria(tester);
      c.read(selectedAmenitiesProvider.notifier).clear();
      await tester.pumpAndSettle();

      final shop = find.byKey(const ValueKey('criteria-amenity-shop'));
      Finder header() => find.textContaining('More filters');
      if (shop.evaluate().isEmpty) {
        await tester.ensureVisible(header().first);
        await tester.tap(header().first);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(shop);
      await tester.tap(shop);
      await tester.pump();

      for (var i = 0; i < 3; i++) {
        await tester.ensureVisible(header().first);
        await tester.tap(header().first);
        await tester.pumpAndSettle();
      }
      if (shop.evaluate().isNotEmpty) {
        await tester.tap(header().first);
        await tester.pumpAndSettle();
      }
      expect(shop, findsNothing, reason: 'collapsed');
      expect(find.text(_l.criteriaMoreFilters(1)), findsOneWidget,
          reason: 'the collapsed header says a filter is active');
      expect(c.read(selectedAmenitiesProvider), {StationAmenity.shop});
    });

    testWidgets('#4199 — open-now ALONE is counted, though its switch sits '
        'above the collapsible', (tester) async {
      // The header used to count `amenities.length`, so a user with
      // open-now on and no amenities saw a bare "More filters" while
      // their results were quietly narrowed — the exact failure #4166
      // introduced the counter to prevent. #4166 deliberately keeps the
      // switch ABOVE the section (it is part of the decision, not a
      // bulky refinement); counting it here does not move it.
      final c = await _pumpCriteria(tester);
      c.read(selectedAmenitiesProvider.notifier).clear();
      c.read(openOnlyFilterProvider.notifier).set(true);
      await tester.pumpAndSettle();

      expect(find.text(_l.criteriaMoreFilters(1)), findsOneWidget,
          reason: 'open-now narrows the results, so the collapsed header '
              'must say one filter is active');
    });

    testWidgets('#4199 — open-now and an amenity sum into one count',
        (tester) async {
      final c = await _pumpCriteria(tester);
      c.read(selectedAmenitiesProvider.notifier).clear();
      c.read(openOnlyFilterProvider.notifier).set(true);
      c.read(selectedAmenitiesProvider.notifier).toggle(StationAmenity.shop);
      await tester.pumpAndSettle();

      expect(find.text(_l.criteriaMoreFilters(2)), findsOneWidget,
          reason: 'every constraint that narrows the results counts once');
    });

    testWidgets('reduced motion: the custom radius control appears without '
        'animating', (tester) async {
      await _pumpCriteria(tester, reduceMotion: true);
      final custom = find.byKey(const ValueKey('criteria-radius-custom'));
      await tester.ensureVisible(custom);
      await tester.tap(custom);
      await tester.pump();
      expect(
          find.descendant(
              of: find.byType(SearchRadiusSlider),
              matching: find.byType(AnimatedSize)),
          findsNothing);
      expect(find.byType(Slider), findsOneWidget);
      final firstFrame = tester.getSize(find.byType(SearchRadiusSlider)).height;
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(SearchRadiusSlider)).height, firstFrame,
          reason: 'with animations disabled the slider is at full size on '
              'the first frame');
    });

    testWidgets('semantics name the route endpoints, swap and reset',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpCriteria(tester, mode: SearchMode.route);
      String spoken(Finder f) {
        final node = tester.getSemantics(f);
        return '${node.label} ${node.tooltip}';
      }

      expect(spoken(find.byKey(const ValueKey('route-swap-endpoints'))),
          contains(_l.criteriaSwapEndpoints));
      expect(find.bySemanticsLabel(RegExp(RegExp.escape(_l.destination))),
          findsWidgets,
          reason: 'the destination field is announced by its label');
      expect(spoken(find.byKey(const ValueKey('criteria-reset-button'))),
          contains(_l.criteriaReset));
      handle.dispose();
    });
  });
}
