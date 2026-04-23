import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/charging_log_store.dart';
import 'package:tankstellen/features/consumption/providers/charging_logs_provider.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/log_charging_bottom_sheet.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// In-memory stand-in for [ChargingLogStore]. Overriding the store
/// provider keeps the widget tests away from Hive's filesystem lock
/// — Windows serialises settings.lock across test isolates, which
/// bites widget tests that spin up and tear down providers faster
/// than the OS releases the file.
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

class _FixedActiveVehicle extends ActiveVehicleProfile {
  final VehicleProfile? _value;
  _FixedActiveVehicle(this._value);

  @override
  VehicleProfile? build() => _value;
}

/// Pumps a host screen that opens the bottom sheet via the public
/// [LogChargingBottomSheet.show] launcher — i.e. the same call the
/// real EV detail screen will use. Returns the test's Riverpod
/// container so individual tests can inspect post-save state.
Future<ProviderContainer> _pumpHost(
  WidgetTester tester, {
  String? stationName,
  VehicleProfile? activeVehicle,
  required _FakeChargingLogStore store,
}) async {
  final container = ProviderContainer(overrides: [
    chargingLogStoreProvider.overrideWithValue(store),
    activeVehicleProfileProvider
        .overrideWith(() => _FixedActiveVehicle(activeVehicle)),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => LogChargingBottomSheet.show(
                  context,
                  stationName: stationName,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LogChargingBottomSheet (#582 phase 2)', () {
    testWidgets('opens with the station name pre-filled',
        (tester) async {
      await _pumpHost(
        tester,
        stationName: 'IONITY Rest Stop',
        store: _FakeChargingLogStore(),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(
        find.byKey(const Key('charging_log_station_name')),
      );
      expect(field.controller?.text, 'IONITY Rest Stop');
    });

    testWidgets(
        'saving valid input writes the log through chargingLogsProvider',
        (tester) async {
      final store = _FakeChargingLogStore();
      final container = await _pumpHost(
        tester,
        stationName: 'Total Energies',
        activeVehicle: const VehicleProfile(
          id: 'ev-1',
          name: 'Zoe',
          type: VehicleType.ev,
        ),
        store: store,
      );
      // Hydrate the logs provider so it's subscribed to store writes.
      await container.read(chargingLogsProvider.future);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('charging_log_kwh')),
        '42.5',
      );
      await tester.enterText(
        find.byKey(const Key('charging_log_cost')),
        '17.20',
      );
      await tester.enterText(
        find.byKey(const Key('charging_log_time')),
        '30',
      );
      await tester.enterText(
        find.byKey(const Key('charging_log_odometer')),
        '32000',
      );
      await tester.tap(find.byKey(const Key('charging_log_save')));
      await tester.pumpAndSettle();

      // Sheet dismissed.
      expect(find.byKey(const Key('charging_log_save')), findsNothing);

      // The log is readable through the provider the consumption
      // screen will subscribe to — proves the full save path works.
      final logs = await container.read(chargingLogsProvider.future);
      expect(logs, hasLength(1));
      final saved = logs.single;
      expect(saved.kWh, 42.5);
      expect(saved.costEur, 17.20);
      expect(saved.chargeTimeMin, 30);
      expect(saved.odometerKm, 32000);
      expect(saved.vehicleId, 'ev-1');
      expect(saved.stationName, 'Total Energies');
    });

    testWidgets('validation blocks save when kWh is missing',
        (tester) async {
      final store = _FakeChargingLogStore();
      await _pumpHost(tester, store: store);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('charging_log_cost')),
        '15',
      );
      await tester.tap(find.byKey(const Key('charging_log_save')));
      await tester.pumpAndSettle();

      expect(find.text('Enter the kWh delivered'), findsOneWidget);
      // Sheet still visible — save was blocked.
      expect(find.byKey(const Key('charging_log_save')), findsOneWidget);
    });

    testWidgets('validation blocks save when cost is missing',
        (tester) async {
      final store = _FakeChargingLogStore();
      await _pumpHost(tester, store: store);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('charging_log_kwh')),
        '40',
      );
      await tester.tap(find.byKey(const Key('charging_log_save')));
      await tester.pumpAndSettle();

      expect(find.text('Enter the amount paid'), findsOneWidget);
      expect(find.byKey(const Key('charging_log_save')), findsOneWidget);
    });

    testWidgets('Cancel closes the sheet without writing anything',
        (tester) async {
      final store = _FakeChargingLogStore();
      final container = await _pumpHost(tester, store: store);
      await container.read(chargingLogsProvider.future);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('charging_log_save')), findsNothing);
      final logs = await container.read(chargingLogsProvider.future);
      expect(logs, isEmpty);
    });
  });
}
