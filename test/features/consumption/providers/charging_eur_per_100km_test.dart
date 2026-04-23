import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/charging_log_store.dart';
import 'package:tankstellen/features/consumption/providers/charging_logs_provider.dart';
import 'package:tankstellen/features/consumption/providers/charging_stats_provider.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// #582 phase 2 — EUR/100 km derivation over the active vehicle's
/// charging history. The arithmetic lives in [ChargingCostCalculator]
/// (covered by its own unit tests); these tests lock in how the
/// provider composes segments out of consecutive odometer readings.
class _FixedActiveVehicle extends ActiveVehicleProfile {
  final VehicleProfile? _value;
  _FixedActiveVehicle(this._value);

  @override
  VehicleProfile? build() => _value;
}

/// In-memory charging log store — avoids Hive's Windows file-lock
/// quirks in provider tests by overriding [chargingLogStoreProvider]
/// with this implementation. Matches the real store's semantics
/// (upsert by id, oldest-first list order — though only insertion
/// order matters here; the provider sorts again before segmenting).
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

ChargingLog makeLog({
  required String id,
  required DateTime date,
  required int odometerKm,
  required double kWh,
  required double costEur,
  String vehicleId = 'ev-1',
}) =>
    ChargingLog(
      id: id,
      vehicleId: vehicleId,
      date: date,
      kWh: kWh,
      costEur: costEur,
      chargeTimeMin: 30,
      odometerKm: odometerKm,
    );

ProviderContainer _buildContainer({VehicleProfile? activeVehicle}) =>
    ProviderContainer(overrides: [
      activeVehicleProfileProvider
          .overrideWith(() => _FixedActiveVehicle(activeVehicle)),
      chargingLogStoreProvider.overrideWithValue(_FakeChargingLogStore()),
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const activeVehicle = VehicleProfile(
    id: 'ev-1',
    name: 'Zoe',
    type: VehicleType.ev,
  );

  group('chargingEurPer100KmProvider (#582 phase 2)', () {
    test('returns null when there is no active vehicle', () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(chargingEurPer100KmProvider.future);
      expect(result, isNull);
    });

    test('returns null when the vehicle has fewer than 2 logs', () async {
      final container = _buildContainer(activeVehicle: activeVehicle);
      addTearDown(container.dispose);

      await container.read(chargingLogsProvider.future);
      await container.read(chargingLogsProvider.notifier).add(
            makeLog(
              id: 'one',
              date: DateTime.utc(2026, 4, 1),
              odometerKm: 10000,
              kWh: 30,
              costEur: 12,
            ),
          );

      final result =
          await container.read(chargingEurPer100KmProvider.future);
      expect(result, isNull);
    });

    test(
        'computes cost-weighted mean EUR/100 km from consecutive odometer '
        'readings', () async {
      // Four logs across a single vehicle. Segments (second → fourth):
      //   seg 1: 10_000 → 10_200 = 200 km, cost €9
      //   seg 2: 10_200 → 10_350 = 150 km, cost €33
      //   seg 3: 10_350 → 10_400 =  50 km, cost €0
      // Totals: 400 km, €42. Weighted mean = 42 / 400 * 100 = 10.5
      final container = _buildContainer(activeVehicle: activeVehicle);
      addTearDown(container.dispose);

      await container.read(chargingLogsProvider.future);
      final notifier = container.read(chargingLogsProvider.notifier);
      await notifier.add(makeLog(
        id: 'seed',
        date: DateTime.utc(2026, 3, 31),
        odometerKm: 10000,
        kWh: 0,
        costEur: 0,
      ));
      await notifier.add(makeLog(
        id: 'a',
        date: DateTime.utc(2026, 4, 1),
        odometerKm: 10200,
        kWh: 30,
        costEur: 9,
      ));
      await notifier.add(makeLog(
        id: 'b',
        date: DateTime.utc(2026, 4, 5),
        odometerKm: 10350,
        kWh: 55,
        costEur: 33,
      ));
      await notifier.add(makeLog(
        id: 'c',
        date: DateTime.utc(2026, 4, 10),
        odometerKm: 10400,
        kWh: 35,
        costEur: 0,
      ));

      final result =
          await container.read(chargingEurPer100KmProvider.future);
      expect(result, isNotNull);
      expect(result!, closeTo(10.5, 0.001));
    });

    test('returns null when odometer never increases', () async {
      // Two logs with the same odometer — no derivable distance, so
      // the weighted mean is undefined. The provider returns null
      // rather than throwing or returning 0.0 so the UI can render
      // "—" alongside kWh/cost totals.
      final container = _buildContainer(activeVehicle: activeVehicle);
      addTearDown(container.dispose);

      await container.read(chargingLogsProvider.future);
      final notifier = container.read(chargingLogsProvider.notifier);
      await notifier.add(makeLog(
        id: 'a',
        date: DateTime.utc(2026, 4, 1),
        odometerKm: 10000,
        kWh: 20,
        costEur: 8,
      ));
      await notifier.add(makeLog(
        id: 'b',
        date: DateTime.utc(2026, 4, 2),
        odometerKm: 10000,
        kWh: 25,
        costEur: 10,
      ));

      final result =
          await container.read(chargingEurPer100KmProvider.future);
      expect(result, isNull);
    });

    test('chargingTotalKwh sums every kWh for the active vehicle',
        () async {
      final container = _buildContainer(activeVehicle: activeVehicle);
      addTearDown(container.dispose);

      await container.read(chargingLogsProvider.future);
      final notifier = container.read(chargingLogsProvider.notifier);
      await notifier.add(makeLog(
        id: 'a',
        date: DateTime.utc(2026, 4, 1),
        odometerKm: 10000,
        kWh: 10,
        costEur: 3,
      ));
      await notifier.add(makeLog(
        id: 'b',
        date: DateTime.utc(2026, 4, 2),
        odometerKm: 10100,
        kWh: 15,
        costEur: 5,
      ));

      final result = await container.read(chargingTotalKwhProvider.future);
      expect(result, 25.0);
    });

    test('chargingTotalCostEur sums every cost for the active vehicle',
        () async {
      final container = _buildContainer(activeVehicle: activeVehicle);
      addTearDown(container.dispose);

      await container.read(chargingLogsProvider.future);
      final notifier = container.read(chargingLogsProvider.notifier);
      await notifier.add(makeLog(
        id: 'a',
        date: DateTime.utc(2026, 4, 1),
        odometerKm: 10000,
        kWh: 10,
        costEur: 3.5,
      ));
      await notifier.add(makeLog(
        id: 'b',
        date: DateTime.utc(2026, 4, 2),
        odometerKm: 10100,
        kWh: 15,
        costEur: 5.25,
      ));

      final result =
          await container.read(chargingTotalCostEurProvider.future);
      expect(result, closeTo(8.75, 0.001));
    });
  });
}
