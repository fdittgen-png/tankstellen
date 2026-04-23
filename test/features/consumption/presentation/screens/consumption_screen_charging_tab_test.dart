import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/data/charging_log_store.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/charging_log_card.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_card.dart';
import 'package:tankstellen/features/consumption/providers/charging_logs_provider.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

class _FixedFillUpList extends FillUpList {
  final List<FillUp> _value;
  _FixedFillUpList(this._value);

  @override
  List<FillUp> build() => _value;
}

class _FixedActiveVehicle extends ActiveVehicleProfile {
  final VehicleProfile? _value;
  _FixedActiveVehicle(this._value);

  @override
  VehicleProfile? build() => _value;
}

/// In-memory stand-in for [ChargingLogStore] — the widget tests stay
/// clear of Hive's Windows file-lock quirks this way, while still
/// driving the real [ChargingLogs] notifier end-to-end.
class _FakeChargingLogStore implements ChargingLogStore {
  final List<ChargingLog> _items = [];

  @override
  Future<List<ChargingLog>> list() async =>
      List<ChargingLog>.from(_items);

  @override
  Future<List<ChargingLog>> listForVehicle(String vehicleId) async =>
      _items.where((l) => l.vehicleId == vehicleId).toList();

  @override
  Future<void> upsert(ChargingLog log) async {
    _items.removeWhere((e) => e.id == log.id);
    _items.add(log);
  }

  @override
  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

/// Pumps the consumption screen inside a minimal GoRouter + overridden
/// providers. Uses [UncontrolledProviderScope] so the test can seed
/// the container with a fake charging-log store.
Future<void> _pump(
  WidgetTester tester, {
  List<FillUp> fillUps = const [],
  VehicleProfile? activeVehicle,
  required _FakeChargingLogStore chargingStore,
}) async {
  final router = GoRouter(
    initialLocation: '/consumption',
    routes: [
      GoRoute(
        path: '/consumption',
        builder: (_, _) => const ConsumptionScreen(),
      ),
      GoRoute(path: '/consumption/add', builder: (_, _) => const SizedBox()),
      GoRoute(
        path: '/consumption/pick-station',
        builder: (_, _) => const SizedBox(),
      ),
      GoRoute(path: '/carbon', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/trip-history', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/vehicles/edit', builder: (_, _) => const SizedBox()),
    ],
  );
  final container = ProviderContainer(overrides: [
    fillUpListProvider.overrideWith(() => _FixedFillUpList(fillUps)),
    activeVehicleProfileProvider
        .overrideWith(() => _FixedActiveVehicle(activeVehicle)),
    chargingLogStoreProvider.overrideWithValue(chargingStore),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FillUp sampleFillUp() => FillUp(
        id: 'f1',
        date: DateTime.utc(2026, 4, 10),
        liters: 40,
        totalCost: 60,
        odometerKm: 10000,
        fuelType: FuelType.diesel,
        stationName: 'Total',
      );

  ChargingLog makeLog({
    required String id,
    required DateTime date,
    double kWh = 42,
    double costEur = 17,
    int odometer = 32000,
    String vehicleId = 'ev-1',
  }) =>
      ChargingLog(
        id: id,
        vehicleId: vehicleId,
        date: date,
        kWh: kWh,
        costEur: costEur,
        chargeTimeMin: 30,
        odometerKm: odometer,
        stationName: 'TestCharger',
      );

  group('ConsumptionScreen charging tab (#582 phase 2)', () {
    testWidgets('defaults to the fuel tab with the fuel list visible',
        (tester) async {
      await _pump(
        tester,
        fillUps: [sampleFillUp()],
        chargingStore: _FakeChargingLogStore(),
      );

      expect(find.byType(FillUpCard), findsOneWidget);
      expect(find.byType(ChargingLogCard), findsNothing);
      expect(find.byKey(const Key('consumption_tab_toggle')), findsOneWidget);
    });

    testWidgets('empty charging tab renders the empty-state message',
        (tester) async {
      await _pump(
        tester,
        fillUps: [sampleFillUp()],
        activeVehicle: const VehicleProfile(
          id: 'ev-1',
          name: 'Zoe',
          type: VehicleType.ev,
        ),
        chargingStore: _FakeChargingLogStore(),
      );
      await tester.tap(find.text('Charging'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No charging sessions yet'),
        findsOneWidget,
      );
      expect(find.byType(ChargingLogCard), findsNothing);
    });

    testWidgets(
        'charging tab lists persisted logs newest-first with kWh and cost',
        (tester) async {
      final store = _FakeChargingLogStore();
      await store.upsert(
        makeLog(
          id: 'oldest',
          date: DateTime.utc(2026, 4, 1),
          kWh: 10,
          costEur: 4,
        ),
      );
      await store.upsert(
        makeLog(
          id: 'middle',
          date: DateTime.utc(2026, 4, 5),
          kWh: 22,
          costEur: 9,
        ),
      );
      await store.upsert(
        makeLog(
          id: 'newest',
          date: DateTime.utc(2026, 4, 10),
          kWh: 33,
          costEur: 12,
        ),
      );

      await _pump(
        tester,
        activeVehicle: const VehicleProfile(
          id: 'ev-1',
          name: 'Zoe',
          type: VehicleType.ev,
        ),
        chargingStore: store,
      );
      await tester.tap(find.text('Charging'));
      await tester.pumpAndSettle();

      final cards = tester.widgetList<ChargingLogCard>(
        find.byType(ChargingLogCard),
      );
      expect(cards.length, 3,
          reason: 'All three persisted logs should render as cards.');
      expect(cards.first.log.id, 'newest');
      expect(cards.last.log.id, 'oldest');

      expect(find.textContaining('33.0 kWh'), findsOneWidget);
      expect(find.textContaining('12.00'), findsOneWidget);
    });

    testWidgets('tapping Charging reveals the Add-charging FAB',
        (tester) async {
      await _pump(
        tester,
        activeVehicle: const VehicleProfile(
          id: 'ev-1',
          name: 'Zoe',
          type: VehicleType.ev,
        ),
        chargingStore: _FakeChargingLogStore(),
      );
      expect(find.byKey(const Key('add_charging_log')), findsNothing);

      await tester.tap(find.text('Charging'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_charging_log')), findsOneWidget);
    });

    testWidgets('switching back to Fuel restores the fuel FAB and list',
        (tester) async {
      await _pump(
        tester,
        fillUps: [sampleFillUp()],
        activeVehicle: const VehicleProfile(
          id: 'ev-1',
          name: 'Zoe',
          type: VehicleType.ev,
        ),
        chargingStore: _FakeChargingLogStore(),
      );
      await tester.tap(find.text('Charging'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fuel'));
      await tester.pumpAndSettle();

      expect(find.byType(FillUpCard), findsOneWidget);
      expect(find.byType(ChargingLogCard), findsNothing);
      expect(find.text('Add fill-up'), findsOneWidget);
    });
  });
}
