import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/fill_ups_sync.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Contract tests for [FillUpsSync] (#727 extract). Higher-fidelity
/// tests of the merge + decode path would require mocking Supabase;
/// these pin the unauthenticated guard for both `merge` and `delete`.
void main() {
  group('FillUpsSync auth guards', () {
    test('merge returns the input list unchanged when unauthenticated',
        () async {
      final local = <FillUp>[
        FillUp(
          id: 'f-1',
          vehicleId: 'veh-1',
          date: DateTime(2026, 4, 22),
          liters: 5.0,
          totalCost: 9.95,
          odometerKm: 123456,
          fuelType: FuelType.e5,
        ),
      ];
      final result = await FillUpsSync.merge(local);
      expect(result, equals(local));
    });

    test('merge handles an empty list without errors', () async {
      final result = await FillUpsSync.merge(const <FillUp>[]);
      expect(result, isEmpty);
    });

    test('delete is a no-op when unauthenticated', () async {
      await FillUpsSync.delete('f-1');
    });
  });
}
