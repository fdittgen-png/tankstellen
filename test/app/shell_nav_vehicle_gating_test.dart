import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/shell_screen.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// The Conso bottom-nav tab used to be hidden when no vehicle was
/// configured (#893). That gate was removed in #conso-coherence —
/// the Medium use-mode profile needs to reach the consumption screen
/// to configure its first vehicle / log its first manual fill-up, and
/// the original gate created a catch-22 (vehicle added FROM the
/// consumption screen, conso hidden UNTIL a vehicle existed).
///
/// These tests lock in the new always-visible behaviour so a future
/// refactor that accidentally re-introduces vehicle-based hiding
/// trips here first.

class _EmptyVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [];
}

class _OneVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(
          id: 'car-1',
          name: 'Daily Driver',
          type: VehicleType.combustion,
        ),
      ];
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required List<Object> overrides,
  String initialLocation = '/',
}) async {
  // Force phone-size canvas so the compact bottom nav renders (not
  // NavigationRail — the rail swap triggers at >=600dp).
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShellScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, _) => const Text('SearchBody')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/map', builder: (_, _) => const Text('MapBody')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/favorites',
              builder: (_, _) => const Text('FavoritesBody'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/consumption-tab',
              builder: (_, _) => const Text('ConsumptionBody'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const Text('SettingsBody'),
            ),
          ]),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShellScreen — Conso always-visible contract', () {
    testWidgets(
      'fresh install with zero vehicles still renders all 5 tabs '
      '(including Consumption) — Medium use-mode needs the tab '
      'reachable to add its first manual fill-up',
      (tester) async {
        await _pumpShell(
          tester,
          overrides: [
            vehicleProfileListProvider.overrideWith(() => _EmptyVehicleList()),
          ],
        );

        expect(find.text('Search'), findsOneWidget);
        expect(find.text('Map'), findsOneWidget);
        expect(find.text('Favorites'), findsOneWidget);
        expect(find.text('Consumption'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.byIcon(Icons.local_gas_station_outlined),
            findsOneWidget);
      },
    );

    testWidgets(
      'one vehicle configured renders the same 5 tabs — vehicle '
      'count is no longer an input to the bottom-nav layout',
      (tester) async {
        await _pumpShell(
          tester,
          overrides: [
            vehicleProfileListProvider.overrideWith(() => _OneVehicleList()),
          ],
        );

        expect(find.text('Search'), findsOneWidget);
        expect(find.text('Map'), findsOneWidget);
        expect(find.text('Favorites'), findsOneWidget);
        expect(find.text('Consumption'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.byIcon(Icons.local_gas_station_outlined),
            findsOneWidget);
      },
    );
  });
}
