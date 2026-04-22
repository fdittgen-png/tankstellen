import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/vehicles_sync.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Contract tests for [VehiclesSync] (#727 extract). Higher-fidelity
/// coverage of the bidirectional-merge + decode path would require
/// mocking Supabase; these tests pin the unauthenticated guard.
void main() {
  group('VehiclesSync auth guards', () {
    test('merge returns the input list unchanged when unauthenticated',
        () async {
      final local = <VehicleProfile>[
        const VehicleProfile(id: 'veh-1', name: 'Peugeot 107'),
      ];
      final result = await VehiclesSync.merge(local);
      expect(result, equals(local));
    });

    test('merge handles an empty list without errors', () async {
      final result = await VehiclesSync.merge(const <VehicleProfile>[]);
      expect(result, isEmpty);
    });

    test('delete is a no-op when unauthenticated', () async {
      await VehiclesSync.delete('veh-1');
    });
  });
}
