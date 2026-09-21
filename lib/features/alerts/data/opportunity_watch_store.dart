// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/hive_boxes.dart';
import '../domain/opportunity.dart';

/// What the user asked the engine to watch for (#4154).
///
/// The settings the alert screen grew up with configure MECHANISM — a
/// station, a radius, a threshold. This configures the question instead:
/// which kinds of finding are worth an interruption. Everything the
/// engine finds still reaches the feed; an unwatched kind simply never
/// becomes a notification.
///
/// Absent row ⇒ every kind watched. A fresh install must not be silent,
/// and neither must an upgrade: this is opt-out, never opt-in.
class OpportunityWatchStore {
  const OpportunityWatchStore();

  static const String storageKey = 'opportunity_watch_kinds';

  Box<dynamic>? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.alerts)) return null;
      return Hive.box(HiveBoxes.alerts);
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {
        'where': 'OpportunityWatchStore: alerts box unavailable',
      });
      return null;
    }
  }

  /// The watched kinds. Every kind when nothing was ever configured.
  Set<OpportunityKind> read() {
    final box = _boxOrNull();
    final raw = box?.get(storageKey);
    if (raw is! String || raw.isEmpty) return OpportunityKind.values.toSet();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return OpportunityKind.values.toSet();
      final names = decoded.map((e) => e.toString()).toSet();
      return {
        for (final kind in OpportunityKind.values)
          if (names.contains(kind.name)) kind,
      };
    } on FormatException catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {
        'where': 'OpportunityWatchStore.read: malformed row',
      });
      return OpportunityKind.values.toSet();
    }
  }

  /// True when [kind] may become a notification.
  bool isWatched(OpportunityKind kind) => read().contains(kind);

  /// Replace the watched set. A closed box drops the write rather than
  /// throwing — the caller is a settings tap, not a data path.
  Future<void> write(Set<OpportunityKind> kinds) async {
    final box = _boxOrNull();
    if (box == null) {
      log.debug('write: alerts box closed, dropping ${kinds.length} kinds',
          tag: 'OpportunityWatchStore');
      return;
    }
    await box.put(
        storageKey, jsonEncode([for (final k in kinds) k.name]));
  }

  /// Turn one kind on or off, leaving the rest as they are.
  Future<Set<OpportunityKind>> toggle(
    OpportunityKind kind, {
    required bool watched,
  }) async {
    final next = read().toSet();
    if (watched) {
      next.add(kind);
    } else {
      next.remove(kind);
    }
    await write(next);
    return next;
  }
}
