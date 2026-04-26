import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/hive_boxes.dart';
import '../data/loyalty_card_repository.dart';
import '../domain/entities/loyalty_card.dart';

part 'loyalty_provider.g.dart';

/// Hive-backed loyalty repository (#1120 pilot). Returns null when the
/// settings box isn't open — widget tests that skip Hive init get a
/// silent no-op instead of a thrown error.
@Riverpod(keepAlive: true)
LoyaltyCardRepository? loyaltyCardRepository(Ref ref) {
  if (!Hive.isBoxOpen(HiveBoxes.settings)) return null;
  return LoyaltyCardRepository(box: Hive.box(HiveBoxes.settings));
}

/// Reactive list of every persisted loyalty card, newest-first.
///
/// Mutations go through this notifier so the UI rebuilds without
/// having to invalidate the provider manually. Disabled cards stay
/// in the list (the settings sub-screen needs them) — the consumer
/// that decides whether a discount applies should look at
/// [activeDiscountByBrandProvider] instead, which already filters by
/// `enabled`.
@Riverpod(keepAlive: true)
class LoyaltyCards extends _$LoyaltyCards {
  @override
  List<LoyaltyCard> build() {
    final repo = ref.watch(loyaltyCardRepositoryProvider);
    if (repo == null) return const [];
    return repo.loadAll();
  }

  /// Persist [card] (insert or overwrite by id) and refresh state.
  Future<void> upsert(LoyaltyCard card) async {
    final repo = ref.read(loyaltyCardRepositoryProvider);
    if (repo == null) return;
    await repo.upsert(card);
    state = repo.loadAll();
  }

  /// Remove a card by id.
  Future<void> remove(String id) async {
    final repo = ref.read(loyaltyCardRepositoryProvider);
    if (repo == null) return;
    await repo.remove(id);
    state = repo.loadAll();
  }

  /// Toggle the `enabled` flag for [id].
  Future<void> setEnabled(String id, {required bool enabled}) async {
    final repo = ref.read(loyaltyCardRepositoryProvider);
    if (repo == null) return;
    await repo.setEnabled(id, enabled: enabled);
    state = repo.loadAll();
  }

  /// Wipe every persisted card.
  Future<void> clearAll() async {
    final repo = ref.read(loyaltyCardRepositoryProvider);
    if (repo == null) return;
    await repo.clear();
    state = const [];
  }
}

/// Per-brand active discount lookup table (#1120).
///
/// The map collapses every enabled card down to the *largest*
/// per-litre discount on the user's books for that brand — if the
/// user has registered two Total cards (e.g. "Personal" 0.04 €/L
/// and "Company" 0.06 €/L) the price-display layer applies the
/// better one rather than summing them. Disabled cards are filtered
/// out here so consumers don't have to repeat the rule.
@riverpod
Map<LoyaltyBrand, double> activeDiscountByBrand(Ref ref) {
  final cards = ref.watch(loyaltyCardsProvider);
  final out = <LoyaltyBrand, double>{};
  for (final card in cards) {
    if (!card.enabled) continue;
    if (card.discountPerLiter <= 0) continue;
    final existing = out[card.brand];
    if (existing == null || card.discountPerLiter > existing) {
      out[card.brand] = card.discountPerLiter;
    }
  }
  return out;
}
