import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/loyalty/data/loyalty_card_repository.dart';
import 'package:tankstellen/features/loyalty/domain/entities/loyalty_card.dart';
import 'package:tankstellen/features/loyalty/providers/loyalty_provider.dart';

/// Unit tests for `lib/features/loyalty/providers/loyalty_provider.dart`
/// (Refs #561 phase: loyalty_provider).
///
/// The file under test exposes three providers:
///
///   * [loyaltyCardRepositoryProvider] — factory that returns `null`
///     when the settings Hive box isn't open.
///   * [LoyaltyCards] — keep-alive state notifier with `upsert`,
///     `remove`, `setEnabled`, and `clearAll` mutators that all become
///     no-ops when the repository is unavailable.
///   * [activeDiscountByBrandProvider] — derived `Map<LoyaltyBrand,
///     double>` that keeps the largest enabled discount per brand.
void main() {
  late Directory tempDir;

  LoyaltyCard makeCard({
    String id = 'card-1',
    LoyaltyBrand brand = LoyaltyBrand.totalEnergies,
    double discountPerLiter = 0.05,
    String label = 'Personal',
    DateTime? addedAt,
    bool enabled = true,
  }) {
    return LoyaltyCard(
      id: id,
      brand: brand,
      discountPerLiter: discountPerLiter,
      label: label,
      addedAt: addedAt ?? DateTime(2026, 4, 1, 10),
      enabled: enabled,
    );
  }

  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  setUpAll(() async {
    tempDir =
        await Directory.systemTemp.createTemp('hive_loyalty_provider_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close().timeout(
      const Duration(seconds: 3),
      onTimeout: () => <void>[],
    );
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ---------------------------------------------------------------------------
  // loyaltyCardRepositoryProvider
  // ---------------------------------------------------------------------------
  group('loyaltyCardRepositoryProvider', () {
    test('returns null when the settings box is NOT open', () async {
      // Make absolutely sure the box is closed before we read the
      // provider.
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        await Hive.box(HiveBoxes.settings).close();
      }

      final c = makeContainer();
      final repo = c.read(loyaltyCardRepositoryProvider);

      expect(
        repo,
        isNull,
        reason:
            'Provider must degrade to null instead of throwing when '
            'Hive is not initialised (e.g. widget tests that skip Hive).',
      );
    });

    test(
      'returns a non-null LoyaltyCardRepository when the box is open',
      () async {
        if (!Hive.isBoxOpen(HiveBoxes.settings)) {
          await Hive.openBox(HiveBoxes.settings);
        }
        addTearDown(() async {
          if (Hive.isBoxOpen(HiveBoxes.settings)) {
            await Hive.box(HiveBoxes.settings).close();
          }
        });

        final c = makeContainer();
        final repo = c.read(loyaltyCardRepositoryProvider);

        expect(repo, isNotNull);
        expect(repo, isA<LoyaltyCardRepository>());
      },
    );
  });

  // ---------------------------------------------------------------------------
  // LoyaltyCards notifier — happy path with Hive open
  // ---------------------------------------------------------------------------
  group('LoyaltyCards (Hive open)', () {
    setUp(() async {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        await Hive.box(HiveBoxes.settings).close();
      }
      await Hive.openBox(HiveBoxes.settings);
      await Hive.box(HiveBoxes.settings).clear();
    });

    tearDown(() async {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        await Hive.box(HiveBoxes.settings).clear();
        await Hive.box(HiveBoxes.settings).close();
      }
    });

    test('build returns an empty list on a fresh box', () {
      final c = makeContainer();
      expect(c.read(loyaltyCardsProvider), isEmpty);
    });

    test('upsert adds a single card and the state reflects it', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);

      await notifier.upsert(makeCard(id: 'a1'));

      final state = c.read(loyaltyCardsProvider);
      expect(state, hasLength(1));
      expect(state.single.id, 'a1');
      expect(state.single.brand, LoyaltyBrand.totalEnergies);
      expect(state.single.discountPerLiter, closeTo(0.05, 1e-9));
    });

    test('upsert with a new id appends a second card to the state',
        () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);

      await notifier.upsert(
        makeCard(id: 'a1', addedAt: DateTime(2026, 4, 1)),
      );
      await notifier.upsert(
        makeCard(id: 'a2', addedAt: DateTime(2026, 4, 2)),
      );

      final state = c.read(loyaltyCardsProvider);
      expect(state, hasLength(2));
      expect(state.map((card) => card.id).toSet(), {'a1', 'a2'});
    });

    test(
      'upsert with the same id overwrites without producing a duplicate',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);

        await notifier.upsert(
          makeCard(id: 'a1', discountPerLiter: 0.04, label: 'Personal'),
        );
        await notifier.upsert(
          makeCard(id: 'a1', discountPerLiter: 0.07, label: 'Updated'),
        );

        final state = c.read(loyaltyCardsProvider);
        expect(state, hasLength(1), reason: 'overwrite, not append');
        expect(state.single.id, 'a1');
        expect(state.single.discountPerLiter, closeTo(0.07, 1e-9));
        expect(state.single.label, 'Updated');
      },
    );

    test('remove drops the targeted card from the state', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(
        makeCard(id: 'a1', addedAt: DateTime(2026, 4, 1)),
      );
      await notifier.upsert(
        makeCard(id: 'a2', addedAt: DateTime(2026, 4, 2)),
      );

      await notifier.remove('a1');

      final ids = c.read(loyaltyCardsProvider).map((card) => card.id);
      expect(ids, ['a2']);
    });

    test('remove with an unknown id leaves the state unchanged', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(makeCard(id: 'a1'));
      final before = c.read(loyaltyCardsProvider);

      await notifier.remove('does-not-exist');

      final after = c.read(loyaltyCardsProvider);
      expect(after, hasLength(before.length));
      expect(after.single.id, 'a1');
    });

    test('setEnabled flips the flag and the state reflects it', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(makeCard(id: 'a1', enabled: true));

      await notifier.setEnabled('a1', enabled: false);

      final state = c.read(loyaltyCardsProvider);
      expect(state, hasLength(1));
      expect(state.single.enabled, isFalse);
    });

    test('setEnabled can re-enable a previously disabled card', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(makeCard(id: 'a1', enabled: false));

      await notifier.setEnabled('a1', enabled: true);

      expect(c.read(loyaltyCardsProvider).single.enabled, isTrue);
    });

    test('setEnabled with an unknown id is a no-op', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(makeCard(id: 'a1', enabled: true));
      final before = c.read(loyaltyCardsProvider);

      await notifier.setEnabled('does-not-exist', enabled: false);

      final after = c.read(loyaltyCardsProvider);
      expect(after, hasLength(before.length));
      expect(after.single.id, 'a1');
      expect(after.single.enabled, isTrue,
          reason: 'untouched card stays enabled');
    });

    test('clearAll empties the state', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(makeCard(id: 'a1'));
      await notifier.upsert(
        makeCard(id: 'a2', addedAt: DateTime(2026, 4, 2)),
      );
      expect(c.read(loyaltyCardsProvider), hasLength(2));

      await notifier.clearAll();

      expect(c.read(loyaltyCardsProvider), isEmpty);
    });

    test('clearAll on an already empty list is a no-op', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);

      await notifier.clearAll();

      expect(c.read(loyaltyCardsProvider), isEmpty);
    });

    test('build returns cards newest-first by addedAt', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(
        makeCard(id: 'oldest', addedAt: DateTime(2025, 1, 1)),
      );
      await notifier.upsert(
        makeCard(id: 'newest', addedAt: DateTime(2026, 5, 1)),
      );
      await notifier.upsert(
        makeCard(id: 'middle', addedAt: DateTime(2026, 1, 1)),
      );

      final ids =
          c.read(loyaltyCardsProvider).map((card) => card.id).toList();
      expect(ids, ['newest', 'middle', 'oldest']);
    });

    test('disabled cards stay in the state (UI needs them visible)',
        () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(
        makeCard(id: 'a1', enabled: false),
      );
      await notifier.upsert(
        makeCard(id: 'a2', enabled: true, addedAt: DateTime(2026, 4, 2)),
      );

      final state = c.read(loyaltyCardsProvider);
      expect(state, hasLength(2));
      expect(
        state.map((card) => card.enabled).toSet(),
        {true, false},
        reason:
            'Disabled cards must still appear so the settings screen '
            'can render them; activeDiscountByBrand filters separately.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // LoyaltyCards notifier — repo == null degrade path
  // ---------------------------------------------------------------------------
  group('LoyaltyCards (Hive closed → repo is null)', () {
    setUp(() async {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        await Hive.box(HiveBoxes.settings).close();
      }
    });

    test('build returns const [] when the settings box is closed', () {
      final c = makeContainer();
      expect(c.read(loyaltyCardsProvider), isEmpty);
    });

    test(
      'upsert is a silent no-op when the settings box is closed',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);

        await notifier.upsert(makeCard(id: 'a1'));

        // No throw, state stays empty.
        expect(c.read(loyaltyCardsProvider), isEmpty);
      },
    );

    test(
      'remove is a silent no-op when the settings box is closed',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);

        await notifier.remove('a1');

        expect(c.read(loyaltyCardsProvider), isEmpty);
      },
    );

    test(
      'setEnabled is a silent no-op when the settings box is closed',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);

        await notifier.setEnabled('a1', enabled: false);

        expect(c.read(loyaltyCardsProvider), isEmpty);
      },
    );

    test(
      'clearAll is a silent no-op when the settings box is closed',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);

        await notifier.clearAll();

        expect(c.read(loyaltyCardsProvider), isEmpty);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // activeDiscountByBrandProvider
  // ---------------------------------------------------------------------------
  group('activeDiscountByBrandProvider', () {
    setUp(() async {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        await Hive.box(HiveBoxes.settings).close();
      }
      await Hive.openBox(HiveBoxes.settings);
      await Hive.box(HiveBoxes.settings).clear();
    });

    tearDown(() async {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        await Hive.box(HiveBoxes.settings).clear();
        await Hive.box(HiveBoxes.settings).close();
      }
    });

    test('returns an empty map when there are no cards', () {
      final c = makeContainer();
      expect(c.read(activeDiscountByBrandProvider), isEmpty);
    });

    test('returns an empty map when every card is disabled', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(makeCard(
        id: 'total',
        brand: LoyaltyBrand.totalEnergies,
        discountPerLiter: 0.05,
        enabled: false,
      ));
      await notifier.upsert(makeCard(
        id: 'aral',
        brand: LoyaltyBrand.aral,
        discountPerLiter: 0.06,
        enabled: false,
      ));

      expect(c.read(activeDiscountByBrandProvider), isEmpty);
    });

    test('returns an empty map when every discount is zero', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(makeCard(
        id: 'a',
        brand: LoyaltyBrand.totalEnergies,
        discountPerLiter: 0,
      ));
      await notifier.upsert(makeCard(
        id: 'b',
        brand: LoyaltyBrand.aral,
        discountPerLiter: 0,
      ));

      expect(c.read(activeDiscountByBrandProvider), isEmpty);
    });

    test('drops cards with negative discounts (defensive)', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(makeCard(
        id: 'a',
        brand: LoyaltyBrand.totalEnergies,
        discountPerLiter: -0.05,
      ));

      expect(c.read(activeDiscountByBrandProvider), isEmpty);
    });

    test(
      'returns {brand: discount} for a single enabled card with one brand',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);
        await notifier.upsert(makeCard(
          id: 'total',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.05,
        ));

        final map = c.read(activeDiscountByBrandProvider);
        expect(map, hasLength(1));
        expect(
          map[LoyaltyBrand.totalEnergies],
          closeTo(0.05, 1e-9),
        );
      },
    );

    test(
      'collapses two cards of the same brand to the LARGER discount',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);
        await notifier.upsert(makeCard(
          id: 'personal',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.04,
        ));
        await notifier.upsert(makeCard(
          id: 'company',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.06,
        ));

        final map = c.read(activeDiscountByBrandProvider);
        expect(map, hasLength(1));
        expect(map[LoyaltyBrand.totalEnergies], closeTo(0.06, 1e-9));
      },
    );

    test(
      'larger-discount selection is order-independent (smaller card last)',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);
        await notifier.upsert(makeCard(
          id: 'company',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.08,
        ));
        await notifier.upsert(makeCard(
          id: 'personal',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.03,
        ));

        expect(
          c.read(activeDiscountByBrandProvider)[LoyaltyBrand.totalEnergies],
          closeTo(0.08, 1e-9),
        );
      },
    );

    test(
      'excludes a disabled card even when it has the larger discount',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);
        // Larger but disabled — must NOT win.
        await notifier.upsert(makeCard(
          id: 'company',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.10,
          enabled: false,
        ));
        await notifier.upsert(makeCard(
          id: 'personal',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.04,
          enabled: true,
        ));

        final map = c.read(activeDiscountByBrandProvider);
        expect(map[LoyaltyBrand.totalEnergies], closeTo(0.04, 1e-9));
      },
    );

    test('produces one entry per brand when cards span brands', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(makeCard(
        id: 'total',
        brand: LoyaltyBrand.totalEnergies,
        discountPerLiter: 0.05,
      ));
      await notifier.upsert(makeCard(
        id: 'aral',
        brand: LoyaltyBrand.aral,
        discountPerLiter: 0.04,
      ));
      await notifier.upsert(makeCard(
        id: 'shell',
        brand: LoyaltyBrand.shell,
        discountPerLiter: 0.03,
      ));

      final map = c.read(activeDiscountByBrandProvider);
      expect(map.keys.toSet(), {
        LoyaltyBrand.totalEnergies,
        LoyaltyBrand.aral,
        LoyaltyBrand.shell,
      });
      expect(map[LoyaltyBrand.totalEnergies], closeTo(0.05, 1e-9));
      expect(map[LoyaltyBrand.aral], closeTo(0.04, 1e-9));
      expect(map[LoyaltyBrand.shell], closeTo(0.03, 1e-9));
    });

    test(
      'mixes per-brand collapse with multi-brand entries correctly',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);
        // Two TotalEnergies cards (bigger should win), one Aral.
        await notifier.upsert(makeCard(
          id: 'total-personal',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.04,
        ));
        await notifier.upsert(makeCard(
          id: 'total-company',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.06,
        ));
        await notifier.upsert(makeCard(
          id: 'aral',
          brand: LoyaltyBrand.aral,
          discountPerLiter: 0.03,
        ));

        final map = c.read(activeDiscountByBrandProvider);
        expect(map, hasLength(2));
        expect(map[LoyaltyBrand.totalEnergies], closeTo(0.06, 1e-9));
        expect(map[LoyaltyBrand.aral], closeTo(0.03, 1e-9));
      },
    );

    test(
      'updates the map reactively when a card is upserted later',
      () async {
        final c = makeContainer();
        expect(c.read(activeDiscountByBrandProvider), isEmpty);

        await c.read(loyaltyCardsProvider.notifier).upsert(makeCard(
              id: 'total',
              brand: LoyaltyBrand.totalEnergies,
              discountPerLiter: 0.05,
            ));

        expect(
          c.read(activeDiscountByBrandProvider)[LoyaltyBrand.totalEnergies],
          closeTo(0.05, 1e-9),
        );
      },
    );

    test('removes the brand entry once the only card is removed',
        () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(makeCard(
        id: 'total',
        brand: LoyaltyBrand.totalEnergies,
        discountPerLiter: 0.05,
      ));
      expect(
        c.read(activeDiscountByBrandProvider).containsKey(
              LoyaltyBrand.totalEnergies,
            ),
        isTrue,
      );

      await notifier.remove('total');

      expect(c.read(activeDiscountByBrandProvider), isEmpty);
    });

    test(
      'removes the brand entry when its only card is disabled via setEnabled',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);
        await notifier.upsert(makeCard(
          id: 'total',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.05,
        ));
        expect(
          c.read(activeDiscountByBrandProvider)[LoyaltyBrand.totalEnergies],
          closeTo(0.05, 1e-9),
        );

        await notifier.setEnabled('total', enabled: false);

        expect(c.read(activeDiscountByBrandProvider), isEmpty);
      },
    );

    test('clearAll wipes every brand entry', () async {
      final c = makeContainer();
      final notifier = c.read(loyaltyCardsProvider.notifier);
      await notifier.upsert(makeCard(
        id: 'total',
        brand: LoyaltyBrand.totalEnergies,
        discountPerLiter: 0.05,
      ));
      await notifier.upsert(makeCard(
        id: 'aral',
        brand: LoyaltyBrand.aral,
        discountPerLiter: 0.04,
      ));
      expect(c.read(activeDiscountByBrandProvider), hasLength(2));

      await notifier.clearAll();

      expect(c.read(activeDiscountByBrandProvider), isEmpty);
    });

    test(
      'mixed enabled/disabled across brands keeps only enabled entries',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);
        await notifier.upsert(makeCard(
          id: 'total',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.05,
          enabled: true,
        ));
        await notifier.upsert(makeCard(
          id: 'aral',
          brand: LoyaltyBrand.aral,
          discountPerLiter: 0.06,
          enabled: false,
        ));

        final map = c.read(activeDiscountByBrandProvider);
        expect(map, hasLength(1));
        expect(map.containsKey(LoyaltyBrand.totalEnergies), isTrue);
        expect(map.containsKey(LoyaltyBrand.aral), isFalse);
      },
    );

    test(
      'discounts of exactly zero are dropped even when enabled',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);
        await notifier.upsert(makeCard(
          id: 'zero',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0,
          enabled: true,
        ));
        await notifier.upsert(makeCard(
          id: 'positive',
          brand: LoyaltyBrand.aral,
          discountPerLiter: 0.02,
          enabled: true,
        ));

        final map = c.read(activeDiscountByBrandProvider);
        expect(map.containsKey(LoyaltyBrand.totalEnergies), isFalse);
        expect(map[LoyaltyBrand.aral], closeTo(0.02, 1e-9));
      },
    );

    test(
      'falls back to the next-largest enabled card when the larger '
      'one is disabled',
      () async {
        final c = makeContainer();
        final notifier = c.read(loyaltyCardsProvider.notifier);
        // Three cards on the same brand: 0.10 disabled, 0.07 enabled,
        // 0.03 enabled. Expected winner: 0.07.
        await notifier.upsert(makeCard(
          id: 'biggest-disabled',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.10,
          enabled: false,
        ));
        await notifier.upsert(makeCard(
          id: 'middle',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.07,
        ));
        await notifier.upsert(makeCard(
          id: 'smallest',
          brand: LoyaltyBrand.totalEnergies,
          discountPerLiter: 0.03,
        ));

        expect(
          c.read(activeDiscountByBrandProvider)[LoyaltyBrand.totalEnergies],
          closeTo(0.07, 1e-9),
        );
      },
    );

    test('returns an empty map when the settings box is closed', () async {
      // Close the box for this test only — the dispatcher provider
      // returns null, so the cards list is const [] and the derived
      // map collapses to an empty map.
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        await Hive.box(HiveBoxes.settings).close();
      }

      final c = makeContainer();
      expect(c.read(activeDiscountByBrandProvider), isEmpty);
    });
  });
}
