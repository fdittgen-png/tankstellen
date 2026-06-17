// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/alerts_sync.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

/// Contract tests for [AlertsSync] (#727 extract). The real bidirectional
/// merge talks to Supabase; a pure unit test can only exercise the
/// unauthenticated guard (client null → input passed through). Higher-
/// fidelity coverage lives in
/// `test/core/data/supabase_sync_repository_test.dart` at the
/// repository layer (preserved unchanged across this refactor).
void main() {
  group('AlertsSync auth guards', () {
    test('merge returns the input list unchanged when unauthenticated',
        () async {
      final local = [
        PriceAlert(
          id: 'a1',
          stationId: 'st-1',
          stationName: 'Shell Pomerols',
          fuelType: FuelType.e10,
          targetPrice: 1.75,
          isActive: true,
          createdAt: DateTime(2026, 4, 21),
        ),
      ];
      final result = await AlertsSync.merge(local);
      expect(result, equals(local));
    });

    test('merge handles an empty list without errors', () async {
      final result = await AlertsSync.merge(const <PriceAlert>[]);
      expect(result, isEmpty);
    });

    test('#3370 — a non-UUID (legacy) alert is KEPT local-only, never dropped',
        () async {
      final uuidAlert = PriceAlert(
        id: '11111111-1111-4111-8111-111111111111',
        stationId: 'st-1',
        stationName: 'UUID Station',
        fuelType: FuelType.e10,
        targetPrice: 1.70,
        createdAt: DateTime(2026, 4, 21),
      );
      final legacy = PriceAlert(
        id: 'st-2_e10_1718000000000', // old composite id — not a uuid
        stationId: 'st-2',
        stationName: 'Legacy Station',
        fuelType: FuelType.e10,
        targetPrice: 1.65,
        createdAt: DateTime(2026, 4, 21),
      );
      final result = await AlertsSync.merge([uuidAlert, legacy]);
      // Both survive the merge — the legacy non-UUID alert can't sync to the
      // uuid column, but it must stay visible on this device (#3370).
      expect(result.map((a) => a.id), containsAll([uuidAlert.id, legacy.id]));
    });
  });
}
