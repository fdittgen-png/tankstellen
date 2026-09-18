// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Where [BudgetState] lives between scans (#4183).
///
/// #4151 deliberately left this out: the policy is pure functions over a
/// state value "the caller loads and stores", because the storage is a
/// detail that differs between the foreground and the background
/// isolate. This is that caller's half.
///
/// Without it the budget resets on every wakeup, and a policy that
/// forgets what it sent an hour ago is not a budget — it is a per-scan
/// filter with a cap of one. `alert_delivery_sla`'s "1-3 per day, never
/// next-day" is a statement about a DAY, and a day spans many isolate
/// lifetimes.
///
/// Same box as everything else the scan touches ([HiveBoxes.alerts]:
/// encrypted, open in both isolates), and the state is [pruned] on every
/// save so a device running for a year does not accumulate a year of
/// timestamps.
library;

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/hive_boxes.dart';
import '../domain/opportunity_budget.dart';

/// A notification slot reserved before its post (#4333): enough identity
/// to reconcile the reservation when the process dies before committing.
typedef PendingDelivery = ({int id, String? key, DateTime at});

/// Loads and persists the cross-kind attention budget's state.
///
/// ## Reservation, then commit (#4333)
///
/// The dispatcher writes the winner's slot BEFORE the post, together with
/// a [PendingDelivery] marker, in one put: nothing can show a notification
/// whose slot is not yet on disk. After the post it commits (the same
/// state without the marker) or, when the post was refused, releases (the
/// state as it was before). A process that dies in between leaves the
/// marker, and the next dispatch resolves it ([resolvePending]) by keeping
/// the slot spent: the OS may or may not have shown the notification, and
/// the budget chooses **at most once** — a lost notification inside one
/// quiet window over a duplicate.
class BudgetStateStore {
  const BudgetStateStore();

  /// Hive key holding the JSON blob.
  static const String storageKey = 'opportunity_budget_state';

  Box<dynamic>? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.alerts)) return null;
      return Hive.box(HiveBoxes.alerts);
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {
        'where': 'BudgetStateStore: alerts box unavailable',
      });
      return null;
    }
  }

  /// The stored state, or an empty one.
  ///
  /// An empty state means "nothing has been sent", which permits a
  /// notification. That is the right failure direction here and the
  /// opposite of the usual one: a budget that cannot read its state and
  /// therefore stays silent would turn a storage hiccup into an app that
  /// never alerts again, and nothing in the UI would say why. The cost of
  /// the other direction is bounded — at worst one extra notification
  /// after a genuine storage failure.
  BudgetState read() {
    final box = _boxOrNull();
    if (box == null) return const BudgetState();
    final raw = box.get(storageKey);
    if (raw is! String || raw.isEmpty) return const BudgetState();
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return const BudgetState();
      return BudgetState(
        recentNotifications: [
          for (final t in (map['sent'] as List? ?? const []))
            ?(t is String ? DateTime.tryParse(t) : null),
        ],
        lastToldByStationFuel: {
          for (final e in (map['told'] as Map? ?? const {}).entries)
            if (e.key is String && e.value is String)
              e.key as String: ?DateTime.tryParse(e.value as String),
        },
      );
    } on FormatException catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {
        'where': 'BudgetStateStore.read: malformed state',
      });
      return const BudgetState();
    }
  }

  /// Persist [state], pruned against [now] — with a [pending] reservation
  /// marker when the dispatcher is about to post, without one otherwise
  /// (which is a commit or a release of any previous marker).
  Future<void> write(
    BudgetState state,
    DateTime now, {
    PendingDelivery? pending,
  }) async {
    final box = _boxOrNull();
    if (box == null) {
      log.debug('write: alerts box closed, dropping',
          tag: 'BudgetStateStore');
      return;
    }
    final pruned = state.pruned(now);
    await box.put(
      storageKey,
      jsonEncode({
        'sent': [
          for (final t in pruned.recentNotifications) t.toIso8601String(),
        ],
        'told': {
          for (final e in pruned.lastToldByStationFuel.entries)
            e.key: e.value.toIso8601String(),
        },
        if (pending != null)
          'pending': {
            'id': pending.id,
            'key': pending.key,
            'at': pending.at.toIso8601String(),
          },
      }),
    );
  }

  /// The reservation a dispatch left uncommitted, or null.
  PendingDelivery? readPending() {
    final raw = _boxOrNull()?.get(storageKey);
    if (raw is! String || raw.isEmpty) return null;
    try {
      final pending = (jsonDecode(raw) as Map?)?['pending'];
      if (pending is! Map) return null;
      final id = pending['id'];
      final at = DateTime.tryParse('${pending['at']}');
      if (id is! int || at == null) return null;
      return (id: id, key: pending['key'] as String?, at: at);
    } on FormatException catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {
        'where': 'BudgetStateStore.readPending: malformed state',
      });
      return null;
    }
  }

  /// Resolve a reservation a dead process left: keep its slot spent, drop
  /// the marker, and return it (null when there was none).
  Future<PendingDelivery?> resolvePending(DateTime now) async {
    final pending = readPending();
    if (pending == null) return null;
    await write(read(), now);
    return pending;
  }

  /// Forget everything sent — the "clear all data" troubleshoot path.
  Future<void> clear() async {
    final box = _boxOrNull();
    if (box == null) return;
    await box.delete(storageKey);
  }
}
