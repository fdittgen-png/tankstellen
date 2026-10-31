// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/fill_ups/providers/tank_report_provider.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fuel_behaviour_evidence_log.dart';
import 'package:tankstellen/features/trips/api.dart';
import 'package:tankstellen/features/vehicle/api.dart';

import '../../../helpers/fake_settings_storage.dart';
import '../fixtures/physical_tank_fixtures.dart';

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

class _EmptyTrips extends TripHistoryList {
  @override
  List<TripHistoryEntry> build() => const [];
}

void main() {
  test(
    'real save/edit/delete/import and restart rederive qualified truth',
    () async {
      final storage = FakeSettingsStorage();
      ProviderContainer open() => ProviderContainer(
        overrides: [
          settingsStorageProvider.overrideWithValue(storage),
          activeVehicleProfileProvider.overrideWith(_NoActiveVehicle.new),
          tripHistoryListProvider.overrideWith(_EmptyTrips.new),
          pumpGainLearnerProvider.overrideWithValue(null),
        ],
      );
      final container = open();
      addTearDown(container.dispose);
      final report = container.listen(tankReportProvider, (_, _) {});
      final stats = container.listen(consumptionStatsProvider, (_, _) {});
      final notifier = container.read(fillUpListProvider.notifier);
      final opening = physicalFill('a', 1, 40, 10000);
      final closing = physicalFill('b', 8, 27.2, 10597);
      final partial = physicalFill('p', 3, 15, 10250, full: false);
      await notifier.add(opening);
      await notifier.add(closing);
      expect(report.read().latest!.liters, 27.2);
      await notifier.mergeFrom([partial, partial]);
      expect(report.read().latest!.liters, 42.2);
      expect(stats.read().avgConsumptionL100km, closeTo(7.0686767169, 1e-9));
      await notifier.applyReconciliation(
        physicalFill('synthetic', 4, 6, 10300, correction: true),
      );
      expect(report.read().latest!.liters, 42.2);
      expect(container.read(fillUpListProvider).length, 4);
      await notifier.update(opening.copyWith(isFullTank: false));
      expect(report.read().latest, isNull);
      expect(stats.read().avgConsumptionL100km, isNull);
      expect(
        fillWindowEvidenceFor(
          vehicleId: 'car',
          fillUps: container.read(fillUpListProvider),
        ),
        isEmpty,
      );
      await notifier.update(opening);
      await notifier.remove('p');
      expect(report.read().latest!.liters, 27.2);
      await notifier.mergeFrom([partial]);
      final restored = open();
      addTearDown(restored.dispose);
      expect(restored.read(tankReportProvider).latest!.distanceKm, 597);
      expect(restored.read(tankReportProvider).latest!.liters, 42.2);
      final evidence = fillWindowEvidenceFor(
        vehicleId: 'car',
        fillUps: restored.read(fillUpListProvider),
      );
      expect(evidence.single.litres, 42.2);
      expect(evidence.single.distanceKm, 597);
      expect(
        restored.read(tripHistoryListProvider),
        isEmpty,
        reason: 'physical correction does not fabricate or rewrite telemetry',
      );
      await notifier.remove('b');
      expect(report.read().latest, isNull);
      expect(stats.read().avgConsumptionL100km, isNull);
    },
  );
}
