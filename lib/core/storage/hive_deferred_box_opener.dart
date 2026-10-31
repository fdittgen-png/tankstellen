// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:hive/hive.dart';

import 'hive_cipher_loader.dart';
import 'hive_deferred_user_boxes.dart';
import 'hive_open_timing.dart';
import 'hive_schema_migration.dart';
import 'hive_trip_box_encryption.dart';
import 'hive_trip_history_index.dart';

/// Opens deferred storage without materializing trip sample payloads (#4504).
abstract final class HiveDeferredBoxOpener {
  static Future<void> open(
    Set<String> names,
    Set<String> encrypted, {
    required String tripHistoryBox,
    required String boxSchema,
    required String cacheBox,
    required int schemaVersion,
  }) async {
    final cipher = await HiveCipherLoader.loadGuarded();
    await Future.wait(
      encrypted.map((name) => HiveTripBoxEncryption.migrate(name, cipher)),
    );
    await Future.wait([
      for (final name in names)
        if (name == tripHistoryBox)
          HiveOpenTiming.timedBox(name, () async {
            final box = await Hive.openLazyBox<String>(
              name,
              encryptionCipher: cipher,
            );
            await HiveTripHistoryIndex.prepare(box);
            return box;
          }, phase: HiveOpenTiming.deferredPhase)
        else
          HiveOpenTiming.timed(
            name,
            () => Hive.openBox<String>(
              name,
              encryptionCipher: encrypted.contains(name) ? cipher : null,
            ),
            phase: HiveOpenTiming.deferredPhase,
          ),
      ...HiveDeferredUserBoxes.names.map(HiveDeferredUserBoxes.settled),
    ]);
    if (Hive.isBoxOpen(boxSchema)) {
      await HiveSchemaMigration.ensureSchemaVersions(
        boxSchema: boxSchema,
        encryptedBoxes: encrypted,
        cacheBox: cacheBox,
        currentSchemaVersion: schemaVersion,
      );
    }
  }
}
