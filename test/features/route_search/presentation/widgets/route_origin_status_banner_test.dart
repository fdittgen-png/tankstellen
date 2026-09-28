// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

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
import 'package:tankstellen/features/route_search/domain/route_origin.dart';
import 'package:tankstellen/features/route_search/presentation/widgets/route_input.dart';
import 'package:tankstellen/features/route_search/presentation/widgets/route_origin_status_banner.dart';
import 'package:tankstellen/features/route_search/providers/route_input_provider.dart';
import 'package:tankstellen/features/route_search/providers/route_origin_status_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';

/// #4432 — the route start's GPS acquisition has a visible, localized
/// state. Before, a cold lock showed nothing and every failure became a
/// transient "GPS error" snackbar, while a stale fix could sit in the
/// field as an unqualified "Current location". Each state here must say
/// its OWN thing and offer a way forward (retry, or type a start).
///
/// Driven through the real [RouteInput]: its initial GPS read is the
/// production path the banner reports on.
class _MockSearchService extends Mock implements LocationSearchService {}

class _MockLocationService extends Mock implements LocationService {}

Position _fix(DateTime at, {double accuracy = 10}) => Position(
      latitude: 45.7594,
      longitude: 5.6842,
      timestamp: at,
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  final now = DateTime(2026, 3, 11, 14, 30);
  late _MockLocationService location;
  late _MockSearchService search;

  setUp(() {
    location = _MockLocationService();
    search = _MockSearchService();
    when(() => search.searchCities(any()))
        .thenAnswer((_) async => const <ResolvedLocation>[]);
  });

  Future<void> pumpInput(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    late ProviderContainer container;
    final test = standardTestOverrides();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...test.overrides,
          locationSearchServiceProvider.overrideWithValue(search),
          locationServiceProvider.overrideWithValue(location),
          appClockProvider.overrideWithValue(FixedClock(now)),
        ].cast(),
        child: Consumer(builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: RouteInput(onSearch: (_, _) {})),
          );
        }),
      ),
    );
    final sub = container.listen(routeInputControllerProvider, (_, _) {},
        fireImmediately: true);
    addTearDown(sub.close);
    await tester.pump(); // post-frame reset + GPS read starts
    await tester.pump(); // GPS read settles
  }

  Finder statusKey(String name) =>
      find.byKey(ValueKey('route-origin-status-$name'));
  final retry = find.byKey(const ValueKey('route-origin-retry'));
  final enterAddress = find.byKey(const ValueKey('route-origin-enter-address'));

  testWidgets('acquisition in progress says so and offers manual entry',
      (tester) async {
    when(() => location.getCurrentPosition())
        .thenAnswer((_) => Completer<Position>().future);
    await pumpInput(tester);

    expect(statusKey('locating'), findsOneWidget);
    expect(find.text('Finding your position…'), findsOneWidget);
    expect(find.byIcon(Icons.location_searching), findsOneWidget);
    expect(enterAddress, findsOneWidget);
    expect(retry, findsNothing, reason: 'nothing to retry while acquiring');
  });

  // One case per failure: what the location service does, and the
  // sentence the driver must read.
  final cases = <String, (void Function(_MockLocationService), String)>{
    'permissionDenied': (
      (l) => when(() => l.getCurrentPosition()).thenThrow(
            const LocationException(
              message: 'Location permission denied.',
              reason: LocationFailureReason.permissionDenied,
            ),
          ),
      'Location access is not allowed. Allow it in the system settings, '
          'or enter a start address.',
    ),
    'serviceDisabled': (
      (l) => when(() => l.getCurrentPosition()).thenThrow(
            const LocationException(
              message: 'Location services are disabled.',
              reason: LocationFailureReason.serviceDisabled,
            ),
          ),
      'Location services are turned off. Turn them on, or enter a start '
          'address.',
    ),
    'timeout': (
      (l) => when(() => l.getCurrentPosition())
          .thenThrow(TimeoutException('30 s')),
      'Your position could not be found in time.',
    ),
    'staleFix': (
      (l) => when(() => l.getCurrentPosition()).thenAnswer(
          (_) async => _fix(now.subtract(const Duration(minutes: 12)))),
      'The last position fix is 12 min old, so it may not be where you '
          'are now.',
    ),
    'poorAccuracy': (
      (l) => when(() => l.getCurrentPosition()).thenAnswer((_) async =>
          _fix(now, accuracy: kRouteOriginMaxAccuracyMeters + 250)),
      'Your position is too imprecise to start a route from.',
    ),
  };

  for (final MapEntry(key: name, value: (arrange, message))
      in cases.entries) {
    testWidgets('$name renders its own message with retry + manual entry',
        (tester) async {
      arrange(location);
      await pumpInput(tester);

      expect(statusKey(name), findsOneWidget);
      expect(find.text(message), findsOneWidget);
      expect(retry, findsOneWidget);
      expect(enterAddress, findsOneWidget);
    });
  }

  test('every state has a DISTINCT sentence', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final sentences = {
      RouteOriginStatusBanner.messageFor(
          l10n, const RouteOriginStatus.locating()),
      for (final f in RouteOriginFailure.values)
        RouteOriginStatusBanner.messageFor(
            l10n, RouteOriginStatus.failed(f, age: const Duration(minutes: 4))),
    };
    expect(sentences, hasLength(RouteOriginFailure.values.length + 1));
  });

  testWidgets('a stale fix is labelled as the previous position, not as '
      '"Current location"', (tester) async {
    when(() => location.getCurrentPosition()).thenAnswer(
        (_) async => _fix(now.subtract(const Duration(minutes: 12))));
    await pumpInput(tester);

    expect(find.text('Current location'), findsNothing);
    expect(find.text('Current position (12 min ago)'), findsOneWidget);
  });

  testWidgets('retry re-reads GPS and a fresh fix clears the state',
      (tester) async {
    when(() => location.getCurrentPosition())
        .thenThrow(TimeoutException('30 s'));
    await pumpInput(tester);
    expect(statusKey('timeout'), findsOneWidget);

    when(() => location.getCurrentPosition())
        .thenAnswer((_) async => _fix(now));
    await tester.tap(retry);
    await tester.pump();
    await tester.pump();

    verify(() => location.getCurrentPosition()).called(2);
    expect(statusKey('timeout'), findsNothing);
    expect(retry, findsNothing);
    expect(find.text('Current location'), findsOneWidget);
  });

  testWidgets('enter address clears the start for typing and the state',
      (tester) async {
    when(() => location.getCurrentPosition()).thenAnswer(
        (_) async => _fix(now.subtract(const Duration(minutes: 12))));
    await pumpInput(tester);
    expect(find.text('Current position (12 min ago)'), findsOneWidget);

    await tester.tap(enterAddress);
    await tester.pump();

    expect(statusKey('staleFix'), findsNothing);
    expect(find.text('Current position (12 min ago)'), findsNothing);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(RouteInput)));
    final state = container.read(routeInputControllerProvider);
    expect(state.startCoords, isNull);
    expect(state.startIsCurrentLocation, isFalse);
  });

  testWidgets('the state is localized — French', (tester) async {
    when(() => location.getCurrentPosition()).thenThrow(
      const LocationException(
        message: 'Location services are disabled.',
        reason: LocationFailureReason.serviceDisabled,
      ),
    );
    await pumpInput(tester, locale: const Locale('fr'));

    expect(
      find.text('Les services de localisation sont désactivés. Activez-les, '
          'ou saisissez une adresse de départ.'),
      findsOneWidget,
    );
    expect(find.text('Saisir une adresse'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
