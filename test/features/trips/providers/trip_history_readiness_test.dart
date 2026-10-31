// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_trip_history_index.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/data/trip_history_store_v2.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/providers/trip_history_provider.dart';
import '../../../helpers/hive_temp_dir.dart';
import '../../../helpers/silence_error_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  silenceErrorLoggerSpool();

  test(
    'offline early reader sees saved trips when lazy metadata becomes ready',
    () async {
      final dir = await Directory.systemTemp.createTemp('trip_ready_');
      Hive.init(dir.path);
      final container = ProviderContainer();
      addTearDown(() async {
        container.dispose();
        await closeHiveAndDeleteTemp(dir);
      });
      final seen = <List<TripHistoryEntry>>[];
      container.listen(
        tripHistoryListProvider,
        (_, value) => seen.add(value),
        fireImmediately: true,
      );
      expect(seen.single, isEmpty);
      final box = await Hive.openLazyBox<String>(HiveBoxes.obd2TripHistory);
      const entry = TripHistoryEntry(
        id: 'offline',
        vehicleId: null,
        summary: TripSummary(
          distanceKm: 12,
          maxRpm: 2000,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
        ),
      );
      await box.putAll(encodeTripRowsV2(entry.toJson()));
      await HiveTripHistoryIndex.prepare(box);
      await container.pump();
      expect(container.read(tripHistoryRepositoryProvider), isNotNull);
      expect(
        seen.last.single.id,
        'offline',
        reason:
            'readiness must invalidate the cached null without a sync event',
      );
    },
  );
}
