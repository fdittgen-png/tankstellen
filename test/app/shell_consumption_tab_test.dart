import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/shell_screen.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #701: bottom-nav renders the 5th "Consumption" tab only when the
/// profile flag is on AND the user has at least one vehicle.
///
/// The router registers 5 branches unconditionally, so state survives
/// flag toggles — we test the shell's NAV UI visibility only.

class _FixedProfile extends ActiveProfile {
  _FixedProfile(this._profile);
  final UserProfile? _profile;
  @override
  UserProfile? build() => _profile;
}

class _FixedVehicles extends VehicleProfileList {
  _FixedVehicles(this._list);
  final List<VehicleProfile> _list;
  @override
  List<VehicleProfile> build() => _list;
}

Future<int> _pumpShellNavCount(
  WidgetTester tester, {
  required UserProfile? profile,
  required List<VehicleProfile> vehicles,
}) async {
  // Portrait mobile viewport — labels render under icons only in
  // portrait (the shell hides them in landscape).
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // Minimal router with 5 branches (matches production shape).
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShellScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, _) => const Text('Search')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/map', builder: (_, _) => const Text('Map')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/favorites',
              builder: (_, _) => const Text('Favorites'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const Text('Settings'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/consumption-tab',
              builder: (_, _) => const Text('Consumption'),
            ),
          ]),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeProfileProvider.overrideWith(() => _FixedProfile(profile)),
        vehicleProfileListProvider.overrideWith(() => _FixedVehicles(vehicles)),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Count destinations via either the outlined OR filled icon per
  // slot — the selected tab renders the filled variant so looking
  // only at outlined would under-count.
  final iconPairs = [
    [Icons.search_outlined, Icons.search],
    [Icons.map_outlined, Icons.map],
    [Icons.star_outline, Icons.star],
    [Icons.settings_outlined, Icons.settings],
    [Icons.local_gas_station_outlined, Icons.local_gas_station],
  ];
  return iconPairs.where((pair) {
    return pair.any((i) => tester.widgetList(find.byIcon(i)).isNotEmpty);
  }).length;
}

UserProfile _profile({required bool flag}) => UserProfile(
      id: 'p',
      name: 'p',
      preferredFuelType: FuelType.e10,
      showConsumptionTab: flag,
    );

const _vehicle = VehicleProfile(
  id: 'v1',
  name: 'Golf',
  type: VehicleType.combustion,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShellScreen 5th Consumption tab (#701)', () {
    testWidgets('default profile (flag off) → 4 nav items', (tester) async {
      final count = await _pumpShellNavCount(
        tester,
        profile: _profile(flag: false),
        vehicles: const [_vehicle],
      );
      expect(count, 4);
    });

    testWidgets('flag on AND vehicle configured → 5 nav items',
        (tester) async {
      final count = await _pumpShellNavCount(
        tester,
        profile: _profile(flag: true),
        vehicles: const [_vehicle],
      );
      expect(count, 5);
    });

    testWidgets('flag on but no vehicle configured → 4 nav items '
        '(consumption is vehicle-centric)', (tester) async {
      final count = await _pumpShellNavCount(
        tester,
        profile: _profile(flag: true),
        vehicles: const [],
      );
      expect(count, 4);
    });

    testWidgets('no profile at all → 4 nav items (flag treated as false)',
        (tester) async {
      final count = await _pumpShellNavCount(
        tester,
        profile: null,
        vehicles: const [_vehicle],
      );
      expect(count, 4);
    });
  });
}
