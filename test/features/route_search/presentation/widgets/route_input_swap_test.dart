// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/location_search_provider.dart';
import 'package:tankstellen/core/services/location_search_service.dart';
import 'package:tankstellen/features/route_search/presentation/widgets/route_input.dart';
import 'package:tankstellen/features/route_search/providers/route_input_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #3927 (Epic #3925) — "same trip, the other way round" used to mean
/// re-typing both endpoints. The swap button exchanges the two fields'
/// text AND their resolved coordinates in one tap.
class _MockSearchService extends Mock implements LocationSearchService {}

void main() {
  late _MockSearchService searchService;

  setUp(() {
    searchService = _MockSearchService();
    when(
      () => searchService.searchCities(any()),
    ).thenAnswer((_) async => const <ResolvedLocation>[]);
  });

  testWidgets('swap exchanges the start and destination text', (tester) async {
    final test = standardTestOverrides();

    await pumpApp(
      tester,
      RouteInput(onSearch: (_) {}),
      overrides: [
        ...test.overrides,
        locationSearchServiceProvider.overrideWithValue(searchService),
      ],
      settle: false,
    );
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'Lyon');
    await tester.enterText(fields.last, 'Marseille');
    // Let the autocomplete debounce fire so no timer outlives the test.
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const ValueKey('route-swap-endpoints')));
    await tester.pump();

    expect(
      tester.widget<TextField>(fields.first).controller?.text,
      'Marseille',
    );
    expect(tester.widget<TextField>(fields.last).controller?.text, 'Lyon');
  });

  testWidgets('swap exchanges the resolved coordinates too', (tester) async {
    late ProviderContainer container;
    final test = standardTestOverrides();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...test.overrides,
          locationSearchServiceProvider.overrideWithValue(searchService),
        ].cast(),
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: RouteInput(onSearch: (_) {})),
            );
          },
        ),
      ),
    );
    await tester.pump();

    // The controller is auto-dispose and RouteInput only ever `read`s it —
    // in the app the criteria screen watches it. Hold a subscription so the
    // seeded coordinates survive to the tap.
    final sub = container.listen(
      routeInputControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    final notifier = container.read(routeInputControllerProvider.notifier);
    notifier.setStartCoords(const LatLng(45.75, 4.85)); // Lyon
    notifier.setEndCoords(const LatLng(43.30, 5.37)); // Marseille
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('route-swap-endpoints')));
    await tester.pump();

    final state = container.read(routeInputControllerProvider);
    expect(state.startCoords, const LatLng(43.30, 5.37));
    expect(state.endCoords, const LatLng(45.75, 4.85));
  });
}
