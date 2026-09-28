// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/location/location_service.dart';
import 'package:tankstellen/core/services/location_search_provider.dart';
import 'package:tankstellen/core/services/location_search_service.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/presentation/widgets/route_input.dart';
import 'package:tankstellen/features/route_search/providers/route_input_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';

/// #4432 — Swap moves the complete endpoint, intent included.
///
/// Swapping used to hand the destination slot the start's COORDINATE
/// and nothing else: `setStartCoords` / `setEndCoords` clear the
/// current-location intent, so "from Geneva to where I am" silently
/// became "from Geneva to wherever GPS was sampled when I tapped the
/// button" — the #4432 stale-origin bug, moved to the other end.
class _MockSearchService extends Mock implements LocationSearchService {}

class _MockLocationService extends Mock implements LocationService {}

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

class _StepClock implements AppClock {
  _StepClock(this.instant);
  DateTime instant;
  @override
  DateTime now() => instant;
}

void main() {
  const aLat = 45.5636, aLng = 5.4456; // where GPS was first read
  const bLat = 45.7594, bLng = 5.6842; // where the device is at search time
  const geneva = LatLng(46.2044, 6.1432);

  late _MockSearchService searchService;
  late _MockLocationService locationService;
  late _StepClock clock;
  late GlobalKey<RouteInputWidgetState> key;
  late ProviderContainer container;
  List<RouteWaypoint>? captured;

  setUp(() {
    searchService = _MockSearchService();
    locationService = _MockLocationService();
    clock = _StepClock(DateTime(2026, 3, 11, 14, 30));
    captured = null;
    key = GlobalKey<RouteInputWidgetState>();
    when(() => searchService.searchCities(any()))
        .thenAnswer((_) async => const <ResolvedLocation>[]);
    when(() => locationService.getCurrentPosition())
        .thenAnswer((_) async => _fix(aLat, aLng, clock.instant));
  });

  Future<void> pumpInput(WidgetTester tester) async {
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
                body: RouteInput(key: key, onSearch: (w, _) => captured = w),
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
    // Post-frame reset + the initial GPS read (the start becomes the
    // current location at A).
    await tester.pump();
    await tester.pump();
  }

  /// Name Geneva as the destination, then swap.
  Future<void> genevaThenSwap(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).last, 'Genève');
    await tester.pump(const Duration(seconds: 1));
    container
        .read(routeInputControllerProvider.notifier)
        .setEndCoords(geneva);
    await tester.tap(find.byKey(const ValueKey('route-swap-endpoints')));
    await tester.pump();
  }

  testWidgets(
      'swapping a current-location start moves the INTENT into the '
      'destination slot, not just the coordinate', (tester) async {
    await pumpInput(tester);
    expect(container.read(routeInputControllerProvider).startIsCurrentLocation,
        isTrue);

    await genevaThenSwap(tester);

    final state = container.read(routeInputControllerProvider);
    expect(state.endIsCurrentLocation, isTrue);
    expect(state.endCapturedAt, DateTime(2026, 3, 11, 14, 30));
    expect(state.endCoords, const LatLng(aLat, aLng));
    expect(state.startIsCurrentLocation, isFalse);
    expect(state.startCoords, geneva);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller?.text,
      'Current location',
    );
  });

  testWidgets(
      'a search after the swap re-reads GPS for the DESTINATION and marks '
      'it as the vehicle position; the named start stays fixed',
      (tester) async {
    await pumpInput(tester);
    await genevaThenSwap(tester);

    clock.instant = clock.instant.add(const Duration(minutes: 20));
    when(() => locationService.getCurrentPosition())
        .thenAnswer((_) async => _fix(bLat, bLng, clock.instant));
    await key.currentState!.resolveAndSearch();
    await tester.pump();

    final waypoints = captured!;
    expect(waypoints.first.lat, closeTo(geneva.latitude, 1e-6));
    expect(waypoints.first.isVehiclePosition, isFalse);
    expect(waypoints.last.lat, closeTo(bLat, 1e-6),
        reason: 'the destination is where the device is NOW, not at A');
    expect(waypoints.last.lng, closeTo(bLng, 1e-6));
    expect(waypoints.last.isVehiclePosition, isTrue);
  });

  testWidgets('swapping back restores the current-location START',
      (tester) async {
    await pumpInput(tester);
    await genevaThenSwap(tester);
    await tester.tap(find.byKey(const ValueKey('route-swap-endpoints')));
    await tester.pump();

    final state = container.read(routeInputControllerProvider);
    expect(state.startIsCurrentLocation, isTrue);
    expect(state.startCapturedAt, DateTime(2026, 3, 11, 14, 30));
    expect(state.endIsCurrentLocation, isFalse);
    expect(state.endCoords, geneva);

    clock.instant = clock.instant.add(const Duration(minutes: 20));
    when(() => locationService.getCurrentPosition())
        .thenAnswer((_) async => _fix(bLat, bLng, clock.instant));
    await key.currentState!.resolveAndSearch();
    await tester.pump();
    expect(captured!.first.lat, closeTo(bLat, 1e-6));
    expect(captured!.first.isVehiclePosition, isTrue);
    expect(captured!.last.isVehiclePosition, isFalse);
  });
}
