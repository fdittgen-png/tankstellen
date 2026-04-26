import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/location/location_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';
import 'package:tankstellen/features/route_search/presentation/widgets/route_input.dart';
import 'package:tankstellen/features/route_search/providers/route_input_provider.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/route_search_controls.dart';
import 'package:tankstellen/features/search/providers/search_screen_ui_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// Fake [GeolocatorWrapper] whose every call throws — keeps RouteInput's
/// initState GPS attempt from blocking the test (it just shows a SnackBar
/// which we don't care about).
class _FakeGeolocatorWrapper extends GeolocatorWrapper {
  @override
  Future<bool> isLocationServiceEnabled() async => false;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.denied;
}

/// Recording [SelectedRouteStrategy] notifier — exposes `setCalls` so tests
/// can assert the strategy chip taps actually call `set(...)`.
class _RecordingSelectedRouteStrategy extends SelectedRouteStrategy {
  _RecordingSelectedRouteStrategy(this._initial);

  final RouteSearchStrategyType _initial;
  final List<RouteSearchStrategyType> setCalls = [];

  @override
  RouteSearchStrategyType build() => _initial;

  @override
  void set(RouteSearchStrategyType value) {
    setCalls.add(value);
    state = value;
  }
}

void main() {
  group('RouteSearchControls', () {
    setUpAll(() {
      registerFallbackValue(RouteSearchStrategyType.uniform);
    });

    List<Object> baseOverrides({
      RouteSearchStrategyType strategy = RouteSearchStrategyType.uniform,
      _RecordingSelectedRouteStrategy? recording,
    }) {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getActiveProfileId()).thenReturn(null);
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      return [
        ...test.overrides,
        // Stub the strategy provider with a fixed initial value (or a
        // recording stub if the caller wants to assert on `set` calls).
        selectedRouteStrategyProvider.overrideWith(
          () => recording ?? _RecordingSelectedRouteStrategy(strategy),
        ),
        // RouteInput's initState calls _useGpsForStart() which goes through
        // locationServiceProvider → geolocatorWrapperProvider. Override the
        // wrapper so the GPS attempt fails fast without hitting platform
        // channels.
        geolocatorWrapperProvider.overrideWithValue(_FakeGeolocatorWrapper()),
        locationServiceProvider.overrideWithValue(
          LocationService(_FakeGeolocatorWrapper()),
        ),
      ];
    }

    testWidgets(
        'renders RouteInput, FuelTypeSelector, and 4 strategy ChoiceChips',
        (tester) async {
      await pumpApp(
        tester,
        RouteSearchControls(onSearch: (_) {}),
        overrides: baseOverrides(),
      );

      expect(find.byType(RouteInput), findsOneWidget);
      expect(find.byType(FuelTypeSelector), findsOneWidget);

      // 4 strategy chips: Uniform / Cheapest / Balanced / Eco (#1123).
      // FuelTypeSelector also renders ChoiceChips, so we check by label,
      // not by count.
      expect(find.widgetWithText(ChoiceChip, 'Uniform'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Cheapest'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Balanced'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Eco'), findsOneWidget);
    });

    testWidgets('"Uniform" chip is selected when state == uniform',
        (tester) async {
      await pumpApp(
        tester,
        RouteSearchControls(onSearch: (_) {}),
        overrides:
            baseOverrides(strategy: RouteSearchStrategyType.uniform),
      );

      final uniformChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Uniform'));
      final cheapestChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Cheapest'));
      final balancedChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Balanced'));

      expect(uniformChip.selected, isTrue);
      expect(cheapestChip.selected, isFalse);
      expect(balancedChip.selected, isFalse);
    });

    testWidgets('"Cheapest" chip is selected when state == cheapest',
        (tester) async {
      await pumpApp(
        tester,
        RouteSearchControls(onSearch: (_) {}),
        overrides:
            baseOverrides(strategy: RouteSearchStrategyType.cheapest),
      );

      final cheapestChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Cheapest'));
      expect(cheapestChip.selected, isTrue);
    });

    testWidgets('tapping "Balanced" chip calls notifier.set(balanced)',
        (tester) async {
      final recording = _RecordingSelectedRouteStrategy(
        RouteSearchStrategyType.uniform,
      );
      await pumpApp(
        tester,
        RouteSearchControls(onSearch: (_) {}),
        overrides: baseOverrides(recording: recording),
      );

      // Sanity: Uniform starts selected.
      expect(recording.setCalls, isEmpty);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Balanced'));
      await tester.pumpAndSettle();

      expect(recording.setCalls, [RouteSearchStrategyType.balanced]);
      // After tap, the Balanced chip is now selected.
      final balancedChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Balanced'));
      expect(balancedChip.selected, isTrue);
    });

    testWidgets('tapping "Cheapest" chip calls notifier.set(cheapest)',
        (tester) async {
      final recording = _RecordingSelectedRouteStrategy(
        RouteSearchStrategyType.uniform,
      );
      await pumpApp(
        tester,
        RouteSearchControls(onSearch: (_) {}),
        overrides: baseOverrides(recording: recording),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Cheapest'));
      await tester.pumpAndSettle();

      expect(recording.setCalls, [RouteSearchStrategyType.cheapest]);
    });

    testWidgets('renders the "Saved routes" text button', (tester) async {
      await pumpApp(
        tester,
        RouteSearchControls(onSearch: (_) {}),
        overrides: baseOverrides(),
      );

      // The bookmark icon + l10n label identify the saved-routes button.
      // l10n English value is "Saved Routes".
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.text('Saved Routes'), findsOneWidget);
    });

    testWidgets('tapping "Saved routes" pushes /itineraries', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getActiveProfileId()).thenReturn(null);
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      String? landedOn;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: RouteSearchControls(onSearch: (_) {}),
            ),
          ),
          GoRoute(
            path: '/itineraries',
            builder: (_, _) {
              landedOn = '/itineraries';
              return const Scaffold(body: Text('itineraries page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Object>[
            ...test.overrides,
            selectedRouteStrategyProvider.overrideWith(
              () => _RecordingSelectedRouteStrategy(
                RouteSearchStrategyType.uniform,
              ),
            ),
            geolocatorWrapperProvider
                .overrideWithValue(_FakeGeolocatorWrapper()),
            locationServiceProvider.overrideWithValue(
              LocationService(_FakeGeolocatorWrapper()),
            ),
          ].cast(),
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Make sure the button is visible (tall column with chips above can
      // push it off-screen on tiny test surfaces).
      final savedBtn = find.widgetWithText(TextButton, 'Saved Routes');
      await tester.ensureVisible(savedBtn);
      await tester.pumpAndSettle();
      await tester.tap(savedBtn);
      await tester.pumpAndSettle();

      expect(landedOn, '/itineraries');
      expect(find.text('itineraries page'), findsOneWidget);
    });

    testWidgets(
        'tapping "Eco" chip selects eco strategy and shows the hint caption',
        (tester) async {
      // Coords trigger the savings line via routeInputControllerProvider;
      // Strasbourg → Lyon is ~400 km straight-line, well above the
      // EcoSavingsEstimator zero-clamp.
      final recording = _RecordingSelectedRouteStrategy(
        RouteSearchStrategyType.uniform,
      );
      await pumpApp(
        tester,
        RouteSearchControls(onSearch: (_) {}),
        overrides: baseOverrides(recording: recording),
      );

      // Seed start + end coords on the input controller so the savings
      // preview has something honest to compute.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RouteSearchControls)),
      );
      container.read(routeInputControllerProvider.notifier)
        ..setStartCoords(const LatLng(48.5734, 7.7521)) // Strasbourg
        ..setEndCoords(const LatLng(45.7640, 4.8357)); // Lyon

      await tester.tap(find.widgetWithText(ChoiceChip, 'Eco'));
      await tester.pumpAndSettle();

      // The notifier was driven.
      expect(recording.setCalls, [RouteSearchStrategyType.eco]);

      // Eco hint caption is now visible.
      expect(
        find.textContaining('Smarter drive', findRichText: false),
        findsOneWidget,
      );

      // Predicted-savings line renders with the litres-saved estimate.
      // Format: "≈ X.X L saved" (English ARB).
      expect(
        find.byKey(const ValueKey('ecoSavingsLine')),
        findsOneWidget,
      );
      expect(
        find.textContaining('L saved', findRichText: false),
        findsOneWidget,
      );
    });

    testWidgets('renders the "Strategy:" label', (tester) async {
      await pumpApp(
        tester,
        RouteSearchControls(onSearch: (_) {}),
        overrides: baseOverrides(),
      );

      // Hardcoded label in the widget — guards against accidental removal.
      expect(find.text('Strategy:'), findsOneWidget);
    });
  });
}
