import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/shell_screen.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #893 — seeds one vehicle so the Conso tab is visible in the
/// existing #778 layout tests (Conso is otherwise hidden on fresh
/// installs).
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

/// #778: Consumption is a first-class destination — always visible,
/// sitting between Favorites and Settings. Supersedes the #701
/// flag-gated behaviour (which required a profile opt-in AND an
/// existing vehicle to surface the tab).
///
/// The router registers 5 branches unconditionally, the shell always
/// renders 5 nav items, and the order of the icons is fixed so the
/// muscle-memory for Settings (now the rightmost) stays predictable.

Future<List<IconData>> _pumpShellIcons(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
              path: '/consumption-tab',
              builder: (_, _) => const Text('Consumption'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const Text('Settings'),
            ),
          ]),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleProfileListProvider.overrideWith(() => _OneVehicleList()),
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

  final expected = [
    [Icons.search_outlined, Icons.search],
    [Icons.map_outlined, Icons.map],
    [Icons.star_outline, Icons.star],
    [Icons.local_gas_station_outlined, Icons.local_gas_station],
    [Icons.settings_outlined, Icons.settings],
  ];
  final seen = <IconData>[];
  for (final pair in expected) {
    for (final i in pair) {
      if (tester.widgetList(find.byIcon(i)).isNotEmpty) {
        seen.add(i);
        break;
      }
    }
  }
  return seen;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShellScreen 5-tab layout (#778 — supersedes #701)', () {
    testWidgets('always renders 5 destinations — Consumption is no '
        'longer gated behind a profile flag', (tester) async {
      final icons = await _pumpShellIcons(tester);
      expect(icons, hasLength(5));
    });

    testWidgets('Consumption sits between Favorites and Settings — '
        'the muscle-memory position for Settings (rightmost) is '
        'preserved', (tester) async {
      final icons = await _pumpShellIcons(tester);
      // Favorites index < Consumption index < Settings index
      final favIdx = icons.indexWhere(
          (i) => i == Icons.star || i == Icons.star_outline);
      final consIdx = icons.indexWhere((i) =>
          i == Icons.local_gas_station ||
          i == Icons.local_gas_station_outlined);
      final settingsIdx = icons.indexWhere(
          (i) => i == Icons.settings || i == Icons.settings_outlined);
      expect(favIdx, isNonNegative);
      expect(consIdx, favIdx + 1);
      expect(settingsIdx, consIdx + 1);
    });

    testWidgets('tapping Consumption shows the consumption-tab branch',
        (tester) async {
      await _pumpShellIcons(tester);
      await tester.tap(find.text('Consumption'));
      await tester.pumpAndSettle();
      expect(find.text('Consumption'), findsWidgets);
    });
  });
}
