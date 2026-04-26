import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../domain/entities/loyalty_card.dart';

/// Hive-backed CRUD for [LoyaltyCard] records (#1120 pilot).
///
/// Storage strategy:
///   - Reuses the existing **encrypted** [HiveBoxes.settings] box —
///     loyalty cards (brand + per-litre discount + free-form label)
///     are mildly sensitive program data and the settings box is
///     already encrypted with the per-device key, so we don't need
///     a new box.
///   - Each card is keyed under `loyalty_card:<id>` so legacy
///     settings entries in the same box are untouched and a single
///     card can be deleted without rewriting a list payload.
///   - The payload is stored as a JSON string (same shape as
///     [AchievementsRepository]) — Hive's `Map` round-trip is
///     supported but JSON keeps the on-disk shape obvious during
///     diagnostics and avoids any coupling on Hive's nested-map
///     coercion behaviour.
///
/// All public methods degrade gracefully when the settings box isn't
/// open (e.g. unit tests that skip Hive init) — the repo behaves
/// like an empty store rather than throwing, mirroring
/// [RadiusAlertStore].
class LoyaltyCardRepository {
  /// Public so the price-display path / future BG isolate can iterate
  /// loyalty cards without re-importing this class.
  static const String keyPrefix = 'loyalty_card:';

  final Box<dynamic> _box;

  LoyaltyCardRepository({required Box<dynamic> box}) : _box = box;

  /// Load every persisted card, newest-first by [LoyaltyCard.addedAt].
  /// Corrupt payloads are skipped so a single bad write doesn't hide
  /// the whole list.
  List<LoyaltyCard> loadAll() {
    final out = <LoyaltyCard>[];
    for (final key in _box.keys) {
      if (key is! String || !key.startsWith(keyPrefix)) continue;
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        final json = _decode(raw);
        if (json == null) continue;
        out.add(LoyaltyCard.fromJson(json));
      } catch (e, st) {
        debugPrint('LoyaltyCardRepository.loadAll: skipping $key: $e\n$st');
      }
    }
    out.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return out;
  }

  /// Insert or overwrite [card] by id.
  Future<void> upsert(LoyaltyCard card) async {
    await _box.put('$keyPrefix${card.id}', jsonEncode(card.toJson()));
  }

  /// Remove a card by id. No-op when the key is absent.
  Future<void> remove(String id) async {
    await _box.delete('$keyPrefix$id');
  }

  /// Toggle the `enabled` flag in-place. Returns the updated card, or
  /// `null` when [id] doesn't exist.
  Future<LoyaltyCard?> setEnabled(String id, {required bool enabled}) async {
    final existing = loadAll().where((c) => c.id == id).firstOrNull;
    if (existing == null) return null;
    final updated = existing.copyWith(enabled: enabled);
    await upsert(updated);
    return updated;
  }

  /// Wipe every card. Used by the "reset" debug action.
  Future<void> clear() async {
    final keys = _box.keys
        .whereType<String>()
        .where((k) => k.startsWith(keyPrefix))
        .toList();
    for (final k in keys) {
      await _box.delete(k);
    }
  }

  Map<String, dynamic>? _decode(dynamic raw) {
    if (raw is String) {
      if (raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) return HiveBoxes.toStringDynamicMap(decoded);
      return null;
    }
    if (raw is Map) {
      return HiveBoxes.toStringDynamicMap(raw);
    }
    return null;
  }
}
