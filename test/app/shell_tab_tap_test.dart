// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/app/shell_screen.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../helpers/mock_providers.dart';

/// The REAL [ShellScreen] must honour a tab tap that lands while the
/// previous tab's slide is still running — it used to drop it silently,
/// which reads as an app that ignores the user.

class _English extends ActiveLanguage {
  @override
  AppLanguage build() => AppLanguages.all.first;
}

class _EmptySearch extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() =>
      AsyncValue.data(ServiceResult(
        data: const [],
        source: ServiceSource.cache,
        fetchedAt: DateTime(2026),
      ));
}

class _OneVehicle extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(id: 'car-1', name: 'Car', type: VehicleType.combustion),
      ];
}

class _Flags extends FeatureFlags {
  @override
  Set<Feature> build() =>
      const {Feature.obd2TripRecording, Feature.showConsumptionTab};
}

GoRoute _page(String path, String label) =>
    GoRoute(path: path, builder: (_, _) => Center(child: Text(label)));

void main() {
  testWidgets('a second tab tap during the slide is honoured, not dropped',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final test = standardTestOverrides();
    when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
    when(() => test.mockStorage.isSetupComplete).thenReturn(true);
    when(() => test.mockStorage.getActiveProfileId()).thenReturn(null);
    when(() => test.mockStorage.getAllProfiles()).thenReturn([]);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => ShellScreen(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [_page('/', 'SearchScreen')]),
            StatefulShellBranch(routes: [_page('/map', 'MapScreen')]),
            StatefulShellBranch(
                routes: [_page('/favorites', 'FavoritesScreen')]),
            StatefulShellBranch(
                routes: [_page('/consumption-tab', 'ConsumptionScreen')]),
            StatefulShellBranch(routes: [_page('/profile', 'ProfileScreen')]),
            StatefulShellBranch(
                routes: [_page('/trajets-tab', 'TrajetsScreen')]),
          ],
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...test.overrides,
        activeLanguageProvider.overrideWith(_English.new),
        userPositionNullOverride(),
        searchStateProvider.overrideWith(_EmptySearch.new),
        vehicleProfileListProvider.overrideWith(_OneVehicle.new),
        featureFlagsProvider.overrideWith(_Flags.new),
      ].cast(),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.bySemanticsLabel('Map'));
    // 100 ms into the 280 ms slide.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.bySemanticsLabel('Favorites'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('FavoritesScreen'), findsOneWidget);
    expect(find.text('MapScreen'), findsNothing);
  });
}
