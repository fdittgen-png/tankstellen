// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/guarded.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/entities/fill_inventory.dart';

part 'fill_inventory_provider.g.dart';

/// Settings-box key of the persisted last inventory (#3917). One entry
/// app-wide: the card scopes itself to the active vehicle at read time.
const String kLastFillInventoryKey = 'last_fill_inventory';

/// The inventory the most recent fill established (#3917), persisted in
/// the settings box so the Carburant tab keeps showing it across
/// restarts until the next fill replaces it.
///
/// The fill-up save path publishes it through [set]; the post-save
/// sheet and the [FillInventoryCard] read it. Never throws on a
/// malformed stored payload — a stale setting reads as "no inventory".
@Riverpod(keepAlive: true)
class LastFillInventory extends _$LastFillInventory {
  @override
  FillInventory? build() {
    return guard(
      () {
        final raw = ref.watch(settingsStorageProvider).getSetting(kLastFillInventoryKey);
        if (raw is! String || raw.isEmpty) return null;
        final decoded = jsonDecode(raw);
        if (decoded is! Map) return null;
        return FillInventory.fromJson(decoded.cast<String, dynamic>());
      },
      where: 'LastFillInventory: stored payload unreadable',
      layer: ErrorLayer.providers,
      fallback: null,
    );
  }

  /// Persist [inventory] (null clears). Storage failures are logged and
  /// the in-memory state still updates — the sheet must show either way.
  Future<void> set(FillInventory? inventory) async {
    state = inventory;
    try {
      await ref.read(settingsStorageProvider).putSetting(
            kLastFillInventoryKey,
            inventory == null ? null : jsonEncode(inventory.toJson()),
          );
    } catch (e, st) {
      logFailure(e, st,
          where: 'LastFillInventory: persist failed',
          layer: ErrorLayer.providers);
    }
  }
}
