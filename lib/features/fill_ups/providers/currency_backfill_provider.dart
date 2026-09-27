// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/app_clock.dart';
import '../domain/currency_backfill.dart';
import '../domain/entities/fill_up.dart';
import 'consumption_providers.dart';

/// Applies and undoes the driver's bulk currency statement (#4406).
///
/// Kept out of [FillUpList] (whose library sits at its length ratchet)
/// but writes through the same repository and refreshes the same list,
/// so every aggregate recomputes from the relabelled records at once.
/// Each changed record is stamped `updatedAt` (UTC) so the last-write-
/// wins sync merge carries the statement — and its undo — to the
/// driver's other devices, like any edit (#3122).
class CurrencyBackfillController {
  CurrencyBackfillController(this._ref);

  final Ref _ref;

  /// Label every unknown-currency fill on or before [onOrBefore] as
  /// [currency]. Returns what changed and what is still unknown.
  Future<CurrencyBackfill> apply({
    required String currency,
    required DateTime onOrBefore,
  }) async {
    final repo = _ref.read(fillUpRepositoryProvider);
    final now = _ref.read(appClockProvider).now();
    final result = applyCurrencyBackfill(
      repo.getAll(),
      currency: currency,
      onOrBefore: onOrBefore,
      statedAt: now,
    );
    await _save(result.labelled, now);
    return result;
  }

  /// Return every bulk-labelled record to unknown. Returns how many.
  Future<int> undo() async {
    final repo = _ref.read(fillUpRepositoryProvider);
    final reverted = revertCurrencyBackfill(repo.getAll());
    await _save(reverted, _ref.read(appClockProvider).now());
    return reverted.length;
  }

  Future<void> _save(List<FillUp> changed, DateTime now) async {
    if (changed.isEmpty) return;
    final stamp = now.toUtc();
    await _ref.read(fillUpRepositoryProvider).saveMany([
      for (final f in changed) f.copyWith(updatedAt: stamp),
    ]);
    _ref.invalidate(fillUpListProvider);
  }
}

/// The one [CurrencyBackfillController] (#4406).
final currencyBackfillProvider = Provider<CurrencyBackfillController>(
  CurrencyBackfillController.new,
);
