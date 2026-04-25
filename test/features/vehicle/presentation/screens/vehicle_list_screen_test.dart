import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/widgets/help_banner.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/vehicle_list_screen.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_card.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests covering [VehicleListScreen] (Refs #561 — was zero
/// coverage). Drives the screen through a real [GoRouter] so navigation
/// assertions exercise the actual `context.push` plumbing rather than a
/// hand-rolled stub, and uses a real [VehicleProfileRepository] backed by
/// an in-memory fake [SettingsStorage] so the notifier providers behave
/// exactly as in production.
void main() {
  group('VehicleListScreen (Refs #561)', () {
    testWidgets(
        'empty list renders HelpBanner + empty state and no vehicle cards',
        (tester) async {
      await _pumpListScreen(tester, vehicles: const []);

      expect(find.byType(HelpBanner), findsOneWidget);
      expect(find.byType(VehicleCard), findsNothing);
      // _EmptyState is private; assert via its distinctive icon + copy.
      expect(find.byIcon(Icons.directions_car), findsOneWidget);
      expect(
        find.textContaining('Add your car to filter by connector'),
        findsOneWidget,
      );
    });

    testWidgets('non-empty list renders HelpBanner + one card per vehicle',
        (tester) async {
      await _pumpListScreen(
        tester,
        vehicles: const [
          VehicleProfile(id: 'v1', name: 'Model 3', type: VehicleType.ev),
          VehicleProfile(
              id: 'v2', name: 'Golf', type: VehicleType.combustion),
        ],
      );

      expect(find.byType(HelpBanner), findsOneWidget);
      expect(find.byType(VehicleCard), findsNWidgets(2));
      expect(find.text('Model 3'), findsOneWidget);
      expect(find.text('Golf'), findsOneWidget);
    });

    testWidgets('active vehicle card renders with isActive=true',
        (tester) async {
      await _pumpListScreen(
        tester,
        vehicles: const [
          VehicleProfile(id: 'v1', name: 'Model 3', type: VehicleType.ev),
          VehicleProfile(
              id: 'v2', name: 'Golf', type: VehicleType.combustion),
        ],
        activeId: 'v2',
      );

      final cards = tester
          .widgetList<VehicleCard>(find.byType(VehicleCard))
          .toList();
      expect(cards, hasLength(2));
      final modelThree =
          cards.firstWhere((c) => c.vehicle.id == 'v1');
      final golf = cards.firstWhere((c) => c.vehicle.id == 'v2');
      expect(modelThree.isActive, isFalse);
      expect(golf.isActive, isTrue);
    });

    testWidgets('tapping a card pushes /vehicles/edit with the vehicle id',
        (tester) async {
      final harness = await _pumpListScreen(
        tester,
        vehicles: const [
          VehicleProfile(id: 'v1', name: 'Model 3', type: VehicleType.ev),
        ],
      );

      await tester.tap(find.byType(VehicleCard));
      await tester.pumpAndSettle();

      expect(harness.lastRoute, '/vehicles/edit');
      expect(harness.lastExtra, 'v1');
    });

    testWidgets(
        'popup → Set active calls activeVehicleProfileProvider.setActive',
        (tester) async {
      final harness = await _pumpListScreen(
        tester,
        vehicles: const [
          VehicleProfile(id: 'v1', name: 'Model 3', type: VehicleType.ev),
          VehicleProfile(
              id: 'v2', name: 'Golf', type: VehicleType.combustion),
        ],
        activeId: 'v1',
      );

      // Open the popup on the non-active card (Golf) — the "Set active"
      // entry only renders for non-active vehicles.
      final popups = find.byIcon(Icons.more_vert);
      expect(popups, findsNWidgets(2));
      await tester.tap(popups.last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set active'));
      await tester.pumpAndSettle();

      expect(
        harness.container.read(activeVehicleProfileProvider)?.id,
        'v2',
      );
    });

    testWidgets('popup → Delete opens a confirm dialog', (tester) async {
      await _pumpListScreen(
        tester,
        vehicles: const [
          VehicleProfile(id: 'v1', name: 'Model 3', type: VehicleType.ev),
        ],
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete vehicle?'), findsOneWidget);
      // Cancel button leaves state untouched.
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
        'FAB renders and pushes /vehicles/edit with no extra (add new)',
        (tester) async {
      final harness = await _pumpListScreen(
        tester,
        vehicles: const [
          VehicleProfile(id: 'v1', name: 'Model 3', type: VehicleType.ev),
        ],
      );

      final fab = find.widgetWithText(FloatingActionButton, 'Add vehicle');
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(harness.lastRoute, '/vehicles/edit');
      expect(harness.lastExtra, isNull);
    });

    testWidgets('PageScaffold title is the localized vehicles title',
        (tester) async {
      await _pumpListScreen(tester, vehicles: const []);

      final scaffold =
          tester.widget<PageScaffold>(find.byType(PageScaffold));
      expect(scaffold.title, 'My vehicles');
    });
  });
}

// ---------------------------------------------------------------------------
// Test harness
// ---------------------------------------------------------------------------

class _Harness {
  String? lastRoute;
  Object? lastExtra;
  late ProviderContainer container;
}

Future<_Harness> _pumpListScreen(
  WidgetTester tester, {
  required List<VehicleProfile> vehicles,
  String? activeId,
}) async {
  // Tall canvas so the FAB and ListView fit comfortably in one frame.
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final harness = _Harness();
  final settings = _FakeSettings();
  final repo = VehicleProfileRepository(settings);
  for (final v in vehicles) {
    await repo.save(v);
  }
  if (activeId != null) {
    await repo.setActive(activeId);
  }

  final router = GoRouter(
    initialLocation: '/vehicles',
    routes: [
      GoRoute(
        path: '/vehicles',
        builder: (_, _) => const VehicleListScreen(),
      ),
      GoRoute(
        path: '/vehicles/edit',
        builder: (context, state) {
          harness.lastRoute = '/vehicles/edit';
          harness.lastExtra = state.extra;
          return const Scaffold(body: Text('edit-vehicle-stub'));
        },
      ),
    ],
  );

  final scope = ProviderScope(
    overrides: [
      settingsStorageProvider.overrideWithValue(settings),
      vehicleProfileRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
  );

  await tester.pumpWidget(scope);
  await tester.pumpAndSettle();

  // Capture the runtime ProviderContainer so tests can read provider
  // state directly (e.g. assert setActive landed on v2).
  final element = tester.element(find.byType(VehicleListScreen));
  harness.container = ProviderScope.containerOf(element);
  return harness;
}

class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
