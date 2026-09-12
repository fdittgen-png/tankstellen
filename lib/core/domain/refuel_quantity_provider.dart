// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../error/guarded.dart';
import '../storage/storage_providers.dart';

part 'refuel_quantity_provider.g.dart';

/// The quantity the user says they usually buy, when they have said so
/// (#4095).
///
/// `null` — the default, and the state most users will stay in — means
/// "work it out". `realRefuelProfileProvider` then uses the MEDIAN of
/// their own fill volumes, which is already personal from the first few
/// fills and needs no question asked. This provider exists for the case
/// the measurement cannot cover: a driver who knows they always put in
/// 20 litres, or one with no fill-up history yet who would rather say
/// than wait.
///
/// It is declared in core, beside `refuelProfileProvider`, for the same
/// reason: the results screen reads it and `features/fill_ups` writes
/// the profile that consumes it, and neither may import the other.
///
/// ## Why this is not tank capacity
///
/// Capacity is a CEILING on this number, never the number itself, and
/// never a prerequisite (`docs/specs/refuel-economics.md` §2: tank
/// capacity is not in the formula). The "full tank" choice in the UI
/// resolves to the active vehicle's capacity where one is configured and
/// is simply absent where it is not — the app must never require a
/// capacity to work.
@Riverpod(keepAlive: true)
class RefuelQuantity extends _$RefuelQuantity {
  /// The `settings`-box key the choice persists under.
  static const String storageKey = 'refuel_intended_litres';

  /// The offered quantities, in litres. Coarse on purpose: this is an
  /// assumption behind a comparison, not a pump reading.
  static const List<double> presets = [20, 30, 40, 50];

  @override
  double? build() {
    try {
      final raw = ref.read(settingsStorageProvider).getSetting(storageKey);
      if (raw is num && raw > 0) return raw.toDouble();
      return null;
    } catch (e, st) {
      // No settings box yet: fall back to the measured median, which is
      // the better answer anyway.
      logFailure(e, st, where: 'RefuelQuantity.build');
      return null;
    }
  }

  /// Set the quantity, or pass `null` to hand the decision back to the
  /// measured median.
  Future<void> set(double? litres) async {
    if (state == litres) return;
    state = litres;
    try {
      await ref
          .read(settingsStorageProvider)
          .putSetting(storageKey, litres);
    } catch (e, st) {
      logFailure(e, st, where: 'RefuelQuantity.set');
    }
  }
}
