// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/hive_boxes.dart';
import '../domain/expense.dart';

/// The on-device copy of this employee's fleet expenses (#4215).
///
/// Persistence is INJECTED ([readAll] / [persist] / [remove]) the way
/// `FleetDirectoryCache` (#4212) and `ScopedIdSets` (#4047) do it, so
/// the logic runs in memory under test and the encrypted box is a
/// detail of [FleetExpenseStore.hive].
///
/// The box is encrypted and deferred, and both are deliberate. A fuel
/// receipt names a person, a place, a time and a payment instrument —
/// ADR 0025 D9 files it as an accounting document — so it does not sit
/// in plaintext on disk; and nothing about the landing search screen
/// needs it, so it does not open before the first frame.
///
/// A storage fault is logged and degrades: a box that cannot be read
/// reads as empty, a write that fails is recorded. The caller decides
/// what to show; the store does not.
class FleetExpenseStore {
  FleetExpenseStore({
    required this.readAll,
    required this.persist,
    required this.remove,
  });

  /// The store over the encrypted `fleet_expenses` box. A box that is
  /// not open — before `HiveBoxes.initDeferred`, in a widget test —
  /// reads as empty and writes nowhere.
  factory FleetExpenseStore.hive() {
    Box<String>? box() => Hive.isBoxOpen(HiveBoxes.fleetExpenses)
        ? Hive.box<String>(HiveBoxes.fleetExpenses)
        : null;
    return FleetExpenseStore(
      readAll: () => box()?.toMap().map((k, v) => MapEntry('$k', v)) ?? const {},
      persist: (id, json) async => box()?.put(id, json),
      remove: (id) async => box()?.delete(id),
    );
  }

  final Map<String, String> Function() readAll;
  final Future<void> Function(String id, String json) persist;
  final Future<void> Function(String id) remove;

  /// Every expense the device holds, newest first. A row this build
  /// cannot decode is skipped and logged — one bad blob does not hide
  /// the rest of somebody's expenses.
  List<Expense> loadAll() {
    final Map<String, String> raw;
    try {
      raw = readAll();
    } catch (e, st) {
      _warn('loadAll', null, e, st);
      return const [];
    }
    final expenses = <Expense>[];
    for (final entry in raw.entries) {
      final decoded = _decode(entry.key, entry.value);
      if (decoded != null) expenses.add(decoded);
    }
    expenses.sort((a, b) => b.id.compareTo(a.id));
    return expenses;
  }

  /// Store [expense] under its id, replacing any previous version.
  Future<void> write(Expense expense) async {
    try {
      await persist(expense.id, jsonEncode(expense.toJson()));
    } catch (e, st) {
      _warn('write', expense.id, e, st);
    }
  }

  /// Drop [id] — the local half of an erasure request.
  Future<void> forget(String id) async {
    try {
      await remove(id);
    } catch (e, st) {
      _warn('forget', id, e, st);
    }
  }

  Expense? _decode(String id, String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return Expense.fromJson(decoded);
    } catch (e, st) {
      _warn('decode', id, e, st);
      return null;
    }
  }

  void _warn(String op, String? id, Object e, StackTrace st) =>
      log.warn('FleetExpenseStore.$op failed',
          tag: 'storage',
          error: e,
          stack: st,
          layer: ErrorLayer.storage,
          context: {'id': id ?? ''});
}
