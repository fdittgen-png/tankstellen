import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/shell_screen.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #893 — the Conso bottom-nav tab is only visible once the user has
/// configured at least one vehicle. Fresh installs see 4 tabs; adding
/// a vehicle grows the nav to 5; deleting the last vehicle collapses
/// it back to 4 (and if Conso was the active tab, selection snaps
/// to Search).

class _EmptyVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [];
}

class _MutableVehicleList extends VehicleProfileList {
  final List<VehicleProfile> initial;
  _MutableVehicleList(this.initial);

  @override
  List<VehicleProfile> build() => List<VehicleProfile>.from(initial);

  void setAll(List<VehicleProfile> next) {
    state = List<VehicleProfile>.from(next);
  }
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

  group('ShellScreen bottom-nav vehicle gating (#893)', () {
    testWidgets(
        'fresh install with zero vehicles renders exactly 4 tabs, no '
        'Consumption label or icon', (tester) async {
      await _pumpShell(
        tester,
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _EmptyVehicleList()),
        ],
      );

      // The four canonical destinations remain; Consumption is gone.
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Consumption'), findsNothing);

      // The fuel-station icons (outlined / filled) only belong to the
      // Consumption nav item — neither should be in the tree.
      expect(find.byIcon(Icons.local_gas_station), findsNothing);
      expect(find.byIcon(Icons.local_gas_station_outlined), findsNothing);

      // Double-check by counting Semantics buttons the nav exposes.
      expect(find.bySemanticsLabel('Search'), findsOneWidget);
      expect(find.bySemanticsLabel('Map'), findsOneWidget);
      expect(find.bySemanticsLabel('Favorites'), findsOneWidget);
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      expect(find.bySemanticsLabel('Consumption'), findsNothing);
    });

    testWidgets('one vehicle configured renders 5 tabs including Consumption',
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
      // The Consumption icon should now be visible in the nav bar.
      expect(
        find.byIcon(Icons.local_gas_station_outlined),
        findsOneWidget,
      );
    });

    testWidgets(
        'Settings still routes to its branch when Conso is hidden — '
        'tapping it on a 4-tab nav shows SettingsBody, not the '
        'ConsumptionBody that sits at the same display slot',
        (tester) async {
      await _pumpShell(
        tester,
        overrides: [
          vehicleProfileListProvider.overrideWith(() => _EmptyVehicleList()),
        ],
      );

      await tester.tap(find.text('Settings'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('SettingsBody'), findsOneWidget);
      expect(find.text('ConsumptionBody'), findsNothing);
    });

    testWidgets(
        'deleting the last vehicle while Conso is selected snaps the '
        'nav back to 4 tabs and selection to Search', (tester) async {
      final vehicles = _MutableVehicleList(const [
        VehicleProfile(
          id: 'car-1',
          name: 'Daily Driver',
          type: VehicleType.combustion,
        ),
      ]);

      await _pumpShell(
        tester,
        overrides: [
          vehicleProfileListProvider.overrideWith(() => vehicles),
        ],
        initialLocation: '/consumption-tab',
      );

      // Start with 5 tabs and Conso showing.
      expect(find.text('Consumption'), findsOneWidget);
      expect(find.text('ConsumptionBody'), findsOneWidget);

      // User deletes their last vehicle in Settings.
      vehicles.setAll(const []);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Conso tab is gone from the bottom nav.
      expect(find.text('Consumption'), findsNothing);
      expect(find.byIcon(Icons.local_gas_station), findsNothing);
      expect(find.byIcon(Icons.local_gas_station_outlined), findsNothing);

      // Remaining tabs are still 4.
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Selection snapped to Search — SearchBody is what the user now
      // sees. The Conso branch is hidden; we don't want a stranded
      // "nothing highlighted" state.
      expect(find.text('SearchBody'), findsOneWidget);
      expect(find.text('ConsumptionBody'), findsNothing);
    });
  });
}
