// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_cipher_loader.dart';
import 'package:tankstellen/core/storage/hive_deferred_box_opener.dart';
import 'package:tankstellen/core/storage/hive_deferred_user_boxes.dart';
import 'package:tankstellen/core/storage/hive_trip_box_encryption.dart';
import 'package:tankstellen/core/storage/hive_trip_history_index.dart';
import 'package:tankstellen/core/storage/local_data_eraser.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/data/trip_history_store_v2.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/domain/trip_verdict.dart';

import '../../../helpers/hive_temp_dir.dart';
import '../../../helpers/silence_error_logger.dart';

class _CountingCipher extends HiveAesCipher {
  _CountingCipher() : super(List.generate(32, (i) => i));
  int decryptions = 0;
  @override
  int decrypt(
    Uint8List input,
    int offset,
    int length,
    Uint8List output,
    int outOffset,
  ) {
    decryptions++;
    return super.decrypt(input, offset, length, output, outOffset);
  }
}

TripHistoryEntry _entry(String id, {int count = 650, int day = 1}) =>
    TripHistoryEntry(
      id: id,
      vehicleId: 'vehicle',
      summary: TripSummary(
        distanceKm: 12,
        maxRpm: 2200,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: DateTime(2026, 1, day),
      ),
      samples: [
        for (var i = 0; i < count; i++)
          TripSample(
            timestamp: DateTime(2026, 1, day).add(Duration(seconds: i)),
            speedKmh: 40.0 + i % 20,
            fuelRateLPerHour: 3.0,
          ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  silenceErrorLoggerSpool();
  late Directory dir;
  late _CountingCipher cipher;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('trip_lazy_');
    Hive.init(dir.path);
    cipher = _CountingCipher();
    HiveCipherLoader.cipherLoader = () async => cipher;
    HiveDeferredUserBoxes.arm(cipher);
    final schema = await Hive.openBox<int>(HiveBoxes.boxSchema);
    await schema.put(
      HiveTripBoxEncryption.encryptedMarkerKey(HiveBoxes.obd2TripHistory),
      1,
    );
  });

  tearDown(() async {
    HiveCipherLoader.resetCipherLoaderForTest();
    HiveDeferredUserBoxes.resetForTest();
    await closeHiveAndDeleteTemp(dir);
  });

  Future<TripHistoryRepository> reopen(Map<String, String> rows) async {
    final box = await Hive.openBox<String>(
      HiveBoxes.obd2TripHistory,
      encryptionCipher: cipher,
    );
    await box.putAll(rows);
    await box.close();
    cipher.decryptions = 0;
    await HiveDeferredBoxOpener.open(
      {HiveBoxes.obd2TripHistory},
      {HiveBoxes.obd2TripHistory},
      tripHistoryBox: HiveBoxes.obd2TripHistory,
      boxSchema: HiveBoxes.boxSchema,
      cacheBox: HiveBoxes.cache,
      schemaVersion: HiveBoxes.currentSchemaVersion,
    );
    return TripHistoryRepository.fromOpenBox(HiveBoxes.obd2TripHistory);
  }

  test(
    'real deferred open decrypts metadata only; detail reads preserve samples',
    () async {
      final trips = [
        for (var i = 1; i <= 24; i++) _entry('trip-$i', count: 6000, day: i),
      ];
      final rows = {
        for (final trip in trips) ...encodeTripRowsV2(trip.toJson()),
      };
      final repo = await reopen(rows);
      expect(Hive.lazyBox<String>(HiveBoxes.obd2TripHistory).length, 504);
      expect(
        cipher.decryptions,
        24,
        reason: '480 encrypted sample chunks must stay on disk at startup',
      );
      expect(repo.loadSummaries(), hasLength(24));
      expect(
        repo.loadSummaries().every(
          (s) => s.samples.isEmpty && s.sampleCount == 6000,
        ),
        isTrue,
      );
      expect(
        cipher.decryptions,
        24,
        reason: 'rebuilding a summary list reads no payload',
      );
      final full = await repo.loadByIdAsync('trip-1');
      expect(full!.toJson(), trips.first.toJson());
      expect(
        cipher.decryptions,
        45,
        reason: 'one meta plus only its 20 chunks',
      );
      final speedFuel = await repo.loadSamplesWithAsync('trip-2', {'s', 'f'});
      expect(speedFuel, hasLength(6000));
      expect(speedFuel.first.speedKmh, 40);
      expect(speedFuel.first.fuelRateLPerHour, 3);
    },
  );

  test(
    'legacy summary projection keeps raw payload intact until async migration',
    () async {
      final entry = _entry('legacy');
      final raw = jsonEncode(entry.toJson());
      final repo = await reopen({'legacy': raw});
      final box = Hive.lazyBox<String>(HiveBoxes.obd2TripHistory);
      final summary = repo.loadSummaries().single;
      expect(summary.sampleCount, 650);
      expect(summary.samples, isEmpty);
      expect(await box.get('legacy'), raw);
      expect(await repo.migrateLegacyRow('legacy'), isTrue);
      expect(repo.loadSummaries().single.sampleCount, 650);
      expect((await repo.loadByIdAsync('legacy'))!.toJson(), entry.toJson());
      expect(await repo.migrateLegacyRow('legacy'), isFalse);
    },
  );

  test(
    'delete during asynchronous migration cannot resurrect the trip',
    () async {
      final repo = await reopen({
        'legacy': jsonEncode(_entry('legacy').toJson()),
      });
      final migrating = repo.migrateLegacyRow('legacy');
      await repo.delete('legacy');
      expect(await migrating, isFalse);
      expect(repo.storedIds, isEmpty);
      expect(Hive.lazyBox<String>(HiveBoxes.obd2TripHistory).keys, isEmpty);
    },
  );

  test(
    'save, verdict, cap, reopen and privacy erase retain their contracts',
    () async {
      final repo = await reopen({});
      final box = Hive.lazyBox<String>(HiveBoxes.obd2TripHistory);
      final capped = TripHistoryRepository.lazy(box: box, cap: 2);
      for (var i = 1; i <= 3; i++) {
        expect(await capped.save(_entry('trip-$i', day: i)), isTrue);
      }
      expect(capped.storedIds.toSet(), {'trip-2', 'trip-3'});
      expect(await capped.saveVerdict('trip-3', TripVerdict.smooth), isTrue);
      expect(capped.loadSummaries().first.verdict, TripVerdict.smooth.wireName);
      expect((await capped.loadAllAsync()).map((t) => t.samples.length), [
        650,
        650,
      ]);
      await box.close();
      final reopened = await Hive.openLazyBox<String>(
        HiveBoxes.obd2TripHistory,
        encryptionCipher: cipher,
      );
      await HiveTripHistoryIndex.prepare(reopened);
      final restored = TripHistoryRepository.lazy(box: reopened);
      expect(
        restored.loadSummaries().first.verdict,
        TripVerdict.smooth.wireName,
      );
      expect((await restored.loadByIdAsync('trip-3'))!.samples, hasLength(650));
      final erased = await LocalDataEraser.eraseBoxesForTest();
      expect(
        erased.failedSteps,
        isNot(contains('box:${HiveBoxes.obd2TripHistory}')),
      );
      expect(restored.loadSummaries(), isEmpty);
      expect(reopened.keys, isEmpty);
      expect(repo.cap, 100);
    },
  );
}
