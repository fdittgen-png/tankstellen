// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/location/location_service.dart';
import 'package:tankstellen/core/services/location_search_provider.dart';
import 'package:tankstellen/core/services/location_search_service.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/presentation/widgets/route_input.dart';
import 'package:tankstellen/features/route_search/providers/route_input_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';

/// #4432 — the reported scenario at the widget seam.
///
/// The driver taps the GPS button near La Tour-du-Pin (A), drives 50 km
/// to Belley (B), then asks for stations to Geneva (C). Before the fix
/// the route was drawn from A, because the origin was a snapshot the
/// field labelled "Position actuelle". These pin that the origin is
/// renewed at search time, that it is marked as the vehicle's own
/// position, and that a refusal degrades to the stored fix WITH its age
/// on screen instead of an unqualified "current location".
class _MockSearchService extends Mock implements LocationSearchService {}

class _MockLocationService extends Mock implements LocationService {}

/// A fix measured at [at] — the timestamp is what decides freshness
/// (#4432), so every test says explicitly when its sample was taken.
Position _fix(double lat, double lng, DateTime at) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: at,
      accuracy: 8,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

/// A clock the test advances by hand, so "how old is the stored fix" is
/// a pinned number rather than the wall clock.
class _StepClock implements AppClock {
  _StepClock(this.instant);
  DateTime instant;
  @override
  DateTime now() => instant;
}

void main() {
  const aLat = 45.5636, aLng = 5.4456; // La Tour-du-Pin — where GPS was read
  const bLat = 45.7594, bLng = 5.6842; // Belley — where the vehicle is now

  late _MockSearchService searchService;
  late _MockLocationService locationService;
  late _StepClock clock;
  late GlobalKey<RouteInputWidgetState> key;
  List<RouteWaypoint>? captured;
  DateTime? capturedAt;

  setUp(() {
    searchService = _MockSearchService();
    locationService = _MockLocationService();
    clock = _StepClock(DateTime(2026, 3, 11, 14, 30));
    captured = null;
    capturedAt = null;
    key = GlobalKey<RouteInputWidgetState>();
    when(() => searchService.searchCities(any())).thenAnswer(
      (_) async => const <ResolvedLocation>[
        ResolvedLocation(name: 'Genève', lat: 46.2044, lng: 6.1432),
      ],
    );
  });

  /// Pump the widget with a live subscription on the (auto-dispose)
  /// route-input controller — without one the seeded origin is disposed
  /// between reads and the widget never sees its own GPS fix.
  Future<void> pumpInput(WidgetTester tester) async {
    late ProviderContainer container;
    final test = standardTestOverrides();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...test.overrides,
          locationSearchServiceProvider.overrideWithValue(searchService),
          locationServiceProvider.overrideWithValue(locationService),
          appClockProvider.overrideWithValue(clock),
        ].cast(),
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: RouteInput(key: key, onSearch: (w, at) {
                  captured = w;
                  capturedAt = at;
                }),
              ),
            );
          },
        ),
      ),
    );
    final sub = container.listen(
      routeInputControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    // Post-frame reset + the initial GPS read.
    await tester.pump();
    await tester.pump();
  }

  Future<void> searchTo(WidgetTester tester, String destination) async {
    await tester.enterText(find.byType(TextField).last, destination);
    // Flush the autocomplete debounce so no timer outlives the test.
    await tester.pump(const Duration(seconds: 1));
    await key.currentState!.resolveAndSearch();
    await tester.pump();
  }

  testWidgets(
      'origin captured at A, vehicle now at B — the search routes from B',
      (tester) async {
    when(() => locationService.getCurrentPosition())
        .thenAnswer((_) async => _fix(aLat, aLng, clock.instant));
    await pumpInput(tester);

    // 50 km and 37 minutes later, the driver asks for the search.
    clock.instant = clock.instant.add(const Duration(minutes: 37));
    when(() => locationService.getCurrentPosition())
        .thenAnswer((_) async => _fix(bLat, bLng, clock.instant));
    await searchTo(tester, 'Genève');

    expect(captured, isNotNull);
    final waypoints = captured!;
    expect(waypoints.first.lat, closeTo(bLat, 0.0001));
    expect(waypoints.first.lng, closeTo(bLng, 0.0001));
    // ...and NOT from where GPS was last sampled.
    expect(waypoints.first.lat, isNot(closeTo(aLat, 0.0001)));
    // The corridor may therefore run from the driver onward.
    expect(waypoints.first.isVehiclePosition, isTrue);
    expect(waypoints.last.isVehiclePosition, isFalse);
    // A renewed origin IS current, so it carries no age qualification…
    expect(find.text('Current location'), findsOneWidget);
    // …and the stamp that travels with the search is the NEW fix's.
    expect(capturedAt, DateTime(2026, 3, 11, 15, 7));
  });

  testWidgets(
      'GPS refused at search time falls back to the stored fix and the '
      'field states its age', (tester) async {
    when(() => locationService.getCurrentPosition())
        .thenAnswer((_) async => _fix(aLat, aLng, clock.instant));
    await pumpInput(tester);
    expect(find.text('Current location'), findsOneWidget);

    clock.instant = clock.instant.add(const Duration(minutes: 37));
    when(() => locationService.getCurrentPosition()).thenThrow(
      const LocationException(message: 'Location permission denied.'),
    );
    await searchTo(tester, 'Genève');

    // It still searches — a refused fix must not hang or abort the trip.
    expect(captured, isNotNull);
    expect(captured!.first.lat, closeTo(aLat, 0.0001));
    // ...but nothing on screen calls that coordinate "Current location".
    expect(find.text('Current location'), findsNothing);
    expect(find.text('Current position (37 min ago)'), findsOneWidget);
    // The MEASUREMENT time travels with the search, so a later refresh
    // can judge the origin's age instead of assuming it is current.
    expect(capturedAt, DateTime(2026, 3, 11, 14, 30));
  });

  testWidgets('#2872 — a degenerate refresh never becomes the origin',
      (tester) async {
    when(() => locationService.getCurrentPosition())
        .thenAnswer((_) async => _fix(aLat, aLng, clock.instant));
    await pumpInput(tester);

    clock.instant = clock.instant.add(const Duration(minutes: 3));
    // One axis never acquired — the Gulf-of-Guinea shape.
    when(() => locationService.getCurrentPosition())
        .thenAnswer((_) async => _fix(bLat, 0, clock.instant));
    await searchTo(tester, 'Genève');

    expect(captured, isNotNull);
    final waypoints = captured!;
    expect(waypoints.first.lng, closeTo(aLng, 0.0001));
    expect(waypoints.first.lng, isNot(0));
    expect(find.text('Current position (3 min ago)'), findsOneWidget);
  });

  testWidgets('a typed origin is never marked as the vehicle position',
      (tester) async {
    // No GPS at all — the driver types both endpoints.
    when(() => locationService.getCurrentPosition()).thenThrow(
      const LocationException(message: 'Location services are disabled.'),
    );
    await pumpInput(tester);

    await tester.enterText(find.byType(TextField).first, 'Lyon');
    await searchTo(tester, 'Genève');

    expect(captured, isNotNull);
    expect(captured!.first.isVehiclePosition, isFalse);
  });
}
