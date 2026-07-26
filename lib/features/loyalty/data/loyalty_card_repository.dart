// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/storage/json_box_repository.dart';
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
/// Storage mechanics live in [JsonBoxRepository] (#3614). All public
/// methods degrade gracefully when the settings box isn't open (e.g.
/// unit tests that skip Hive init) — the repo behaves like an empty
/// store rather than throwing, mirroring [RadiusAlertStore].
class LoyaltyCardRepository extends JsonBoxRepository<LoyaltyCard> {
  /// Public so the price-display path / future BG isolate can iterate
  /// loyalty cards without re-importing this class.
  static const String keyPrefix = 'loyalty_card:';

  LoyaltyCardRepository({required super.box})
      : super(
          fromJson: LoyaltyCard.fromJson,
          toJson: (card) => card.toJson(),
          keyOf: (card) => card.id,
          entryKeyPrefix: keyPrefix,
          debugName: 'LoyaltyCardRepository',
        );

  /// Load every persisted card, newest-first by [LoyaltyCard.addedAt].
  /// Corrupt payloads are skipped so a single bad write doesn't hide
  /// the whole list.
  List<LoyaltyCard> loadAll() {
    final out = getAll();
    out.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return out;
  }

  /// Insert or overwrite [card] by id.
  Future<void> upsert(LoyaltyCard card) => put(card);

  /// Remove a card by id. No-op when the key is absent.
  Future<void> remove(String id) => deleteByKey(id);

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
  Future<void> clear() => clearStored();
}
