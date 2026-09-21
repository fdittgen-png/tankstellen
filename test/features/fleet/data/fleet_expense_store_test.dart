// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/fleet/data/fleet_expense_store.dart';
import 'package:tankstellen/features/fleet/domain/expense.dart';
import 'package:tankstellen/features/fleet/domain/expense_fields.dart';
import 'package:tankstellen/features/fleet/domain/money.dart';
import 'package:tankstellen/features/profile/data/full_data_export.dart';

/// #4215 (F5) — the local, encrypted, deferred `fleet_expenses` box and
/// the registry entries every new box must carry (#3867 erasure, #3869
/// export).
void main() {
  const fields = ExtractedReceiptFields(
    stationName: 'Aral Köln',
    litres: 44.07,
    pricePerLitre: 1.759,
    total: Money(amount: 77.52, currency: 'EUR'),
  );

  Expense expense(String id) => Expense(
        id: id,
        orgId: 'org-1',
        userId: 'user-1',
        extracted: fields,
        confirmed: fields,
        importSource: ExpenseImportSource.ocrPhoto,
      );

  ({FleetExpenseStore store, Map<String, String> rows}) inMemory() {
    final rows = <String, String>{};
    return (
      store: FleetExpenseStore(
        readAll: () => Map<String, String>.from(rows),
        persist: (id, json) async => rows[id] = json,
        remove: (id) async => rows.remove(id),
      ),
      rows: rows,
    );
  }

  test('an expense round-trips through the store', () async {
    final harness = inMemory();
    await harness.store.write(expense('exp-1'));
    expect(harness.rows.keys, ['exp-1']);
    final loaded = harness.store.loadAll();
    expect(loaded, [expense('exp-1')]);
  });

  test('a row this build cannot decode is skipped, not fatal', () {
    final rows = <String, String>{
      'good': jsonEncode(expense('good').toJson()),
      'broken': '{not json',
      'wrong-shape': '[]',
    };
    final store = FleetExpenseStore(
      readAll: () => rows,
      persist: (_, _) async {},
      remove: (_) async {},
    );
    expect(store.loadAll().map((e) => e.id), ['good']);
  });

  test('a storage fault degrades to empty instead of surfacing', () {
    final store = FleetExpenseStore(
      readAll: () => throw StateError('box closed'),
      persist: (_, _) async {},
      remove: (_) async {},
    );
    expect(() => store.loadAll(), returnsNormally);
    expect(store.loadAll(), isEmpty);
  });

  test('a write fault is swallowed and logged, not thrown at the caller',
      () async {
    final store = FleetExpenseStore(
      readAll: () => const {},
      persist: (_, _) async => throw StateError('disk full'),
      remove: (_) async => throw StateError('disk full'),
    );
    await expectLater(store.write(expense('exp-1')), completes);
    await expectLater(store.forget('exp-1'), completes);
  });

  test('forget drops the row', () async {
    final harness = inMemory();
    await harness.store.write(expense('exp-1'));
    await harness.store.forget('exp-1');
    expect(harness.rows, isEmpty);
  });

  group('registry', () {
    test('the box is registered for erasure and for the export', () {
      expect(HiveBoxes.allBoxes, contains(HiveBoxes.fleetExpenses));
      expect(kBoxExportCoverage[HiveBoxes.fleetExpenses],
          'local/fleet_expenses.json');
    });

    test('the box is encrypted and deferred — a receipt names a person, '
        'and no first frame needs it', () {
      // The sets are private; their membership is asserted the way
      // `hive_boxes_test.dart` does it, off the declaring source.
      final source = _hiveBoxesSource();
      final deferred = RegExp(r'_deferredBoxes = \{(.*?)\};', dotAll: true)
          .firstMatch(source)
          ?.group(1);
      final encrypted =
          RegExp(r'_encryptedDeferredBoxes = \{(.*?)\};', dotAll: true)
              .firstMatch(source)
              ?.group(1);
      expect(deferred, contains('fleetExpenses'));
      expect(encrypted, contains('fleetExpenses'));
    });
  });
}

String _hiveBoxesSource() =>
    File('lib/core/storage/hive_boxes.dart').readAsStringSync();
