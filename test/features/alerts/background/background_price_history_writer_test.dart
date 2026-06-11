// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/features/alerts/background/background_price_history_writer.dart';
import 'package:tankstellen/core/constants/field_names.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';

/// #2864 — the BG price-history writer recorded only e5/e10/diesel, so a
/// non-DE station's extended fuel set (FR E85 / LPG, IT CNG, AR diesel-premium)
/// was dropped from history. The extraction is now mapping-driven over every
/// fuel field the country-agnostic price map can carry, while DE's three grades
/// stay byte-identical.
void main() {
  late Directory tempDir;
  late HiveStorage storage;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_price_hist_writer_');
    Hive.init(tempDir.path);
    storage = HiveStorage();
  });

  setUp(() async {
    if (Hive.isBoxOpen(HiveBoxes.priceHistory)) {
      await Hive.box<dynamic>(HiveBoxes.priceHistory).close();
    }
    await Hive.openBox<dynamic>(HiveBoxes.priceHistory);
    await Hive.box<dynamic>(HiveBoxes.priceHistory).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('records a non-DE fuel set (E85 / LPG / E98)', () async {
    final now = DateTime.utc(2026, 6, 4, 9);
    await BackgroundPriceHistoryWriter.recordHistory(
      storage,
      {
        'fr-123': {
          TankerkoenigFields.status: TankerkoenigFields.statusOpen,
          TankerkoenigFields.e5: 1.859,
          TankerkoenigFields.e10: 1.799,
          TankerkoenigFields.diesel: 1.749,
          TankerkoenigFields.e98: 1.949,
          TankerkoenigFields.e85: 0.999,
          TankerkoenigFields.lpg: 0.899,
        },
      },
      now,
    );

    final records = storage.getPriceRecords('fr-123');
    expect(records, hasLength(1));
    final r = records.single;
    // The widened grades are persisted, not just e5/e10/diesel.
    expect(r[TankerkoenigFields.e85], 0.999);
    expect(r[TankerkoenigFields.lpg], 0.899);
    expect(r[TankerkoenigFields.e98], 1.949);
    expect(r[TankerkoenigFields.diesel], 1.749);
    expect(r[TankerkoenigFields.e5], 1.859);
    expect(r[TankerkoenigFields.e10], 1.799);
  });

  test('records IT CNG (Metano) and AR diesel-premium', () async {
    final now = DateTime.utc(2026, 6, 4, 9);
    await BackgroundPriceHistoryWriter.recordHistory(
      storage,
      {
        'it-9': {
          TankerkoenigFields.status: TankerkoenigFields.statusOpen,
          TankerkoenigFields.e5: 1.899,
          TankerkoenigFields.diesel: 1.799,
          TankerkoenigFields.cng: 1.499,
        },
        'ar-7': {
          TankerkoenigFields.status: TankerkoenigFields.statusOpen,
          TankerkoenigFields.diesel: 950.0,
          TankerkoenigFields.dieselPremium: 1100.0,
          TankerkoenigFields.cng: 800.0,
        },
      },
      now,
    );

    final it = storage.getPriceRecords('it-9').single;
    expect(it[TankerkoenigFields.cng], 1.499);

    final ar = storage.getPriceRecords('ar-7').single;
    expect(ar[TankerkoenigFields.dieselPremium], 1100.0);
    expect(ar[TankerkoenigFields.cng], 800.0);
  });

  test('DE e5/e10/diesel recording is byte-identical', () async {
    final now = DateTime.utc(2026, 6, 4, 9);
    await BackgroundPriceHistoryWriter.recordHistory(
      storage,
      {
        'de-1': {
          TankerkoenigFields.status: TankerkoenigFields.statusOpen,
          TankerkoenigFields.e5: 1.759,
          TankerkoenigFields.e10: 1.699,
          TankerkoenigFields.diesel: 1.649,
        },
      },
      now,
    );

    final r = storage.getPriceRecords('de-1').single;
    expect(r[TankerkoenigFields.e5], 1.759);
    expect(r[TankerkoenigFields.e10], 1.699);
    expect(r[TankerkoenigFields.diesel], 1.649);
    // No extended grades present → recorded as null.
    expect(r[TankerkoenigFields.lpg], isNull);
    expect(r[TankerkoenigFields.cng], isNull);
  });
}
