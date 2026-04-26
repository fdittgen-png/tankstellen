import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/loyalty/data/loyalty_card_repository.dart';
import 'package:tankstellen/features/loyalty/domain/entities/loyalty_card.dart';

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

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_loyalty_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.box(HiveBoxes.settings).close();
    }
    await Hive.openBox(HiveBoxes.settings);
    await Hive.box(HiveBoxes.settings).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('LoyaltyCardRepository', () {
    test('loadAll returns empty list on a fresh box', () {
      final repo = LoyaltyCardRepository(box: Hive.box(HiveBoxes.settings));
      expect(repo.loadAll(), isEmpty);
    });

    test('upsert persists a card retrievable via loadAll', () async {
      final repo = LoyaltyCardRepository(box: Hive.box(HiveBoxes.settings));
      final card = makeCard(id: 'a1');

      await repo.upsert(card);

      final all = repo.loadAll();
      expect(all, hasLength(1));
      expect(all.single.id, 'a1');
      expect(all.single.brand, LoyaltyBrand.totalEnergies);
      expect(all.single.discountPerLiter, closeTo(0.05, 1e-9));
    });

    test('upsert overwrites an existing card with the same id', () async {
      final repo = LoyaltyCardRepository(box: Hive.box(HiveBoxes.settings));
      await repo.upsert(makeCard(id: 'a1', discountPerLiter: 0.05));
      await repo.upsert(makeCard(id: 'a1', discountPerLiter: 0.07));

      final all = repo.loadAll();
      expect(all, hasLength(1));
      expect(all.single.discountPerLiter, closeTo(0.07, 1e-9));
    });

    test('remove deletes only the targeted card', () async {
      final repo = LoyaltyCardRepository(box: Hive.box(HiveBoxes.settings));
      await repo.upsert(makeCard(id: 'a1'));
      await repo.upsert(
        makeCard(id: 'a2', addedAt: DateTime(2026, 4, 2)),
      );

      await repo.remove('a1');

      final all = repo.loadAll();
      expect(all, hasLength(1));
      expect(all.single.id, 'a2');
    });

    test('remove is a no-op when the id is unknown', () async {
      final repo = LoyaltyCardRepository(box: Hive.box(HiveBoxes.settings));
      await repo.upsert(makeCard(id: 'a1'));

      await repo.remove('does-not-exist');

      expect(repo.loadAll(), hasLength(1));
    });

    test('setEnabled toggles the persisted flag', () async {
      final repo = LoyaltyCardRepository(box: Hive.box(HiveBoxes.settings));
      await repo.upsert(makeCard(id: 'a1', enabled: true));

      final updated = await repo.setEnabled('a1', enabled: false);

      expect(updated, isNotNull);
      expect(updated!.enabled, isFalse);
      expect(repo.loadAll().single.enabled, isFalse);
    });

    test('setEnabled returns null for an unknown id', () async {
      final repo = LoyaltyCardRepository(box: Hive.box(HiveBoxes.settings));
      expect(await repo.setEnabled('nope', enabled: false), isNull);
    });

    test('loadAll returns cards newest-first by addedAt', () async {
      final repo = LoyaltyCardRepository(box: Hive.box(HiveBoxes.settings));
      await repo.upsert(makeCard(id: 'oldest', addedAt: DateTime(2025, 1, 1)));
      await repo.upsert(makeCard(id: 'newest', addedAt: DateTime(2026, 4, 1)));
      await repo.upsert(makeCard(id: 'middle', addedAt: DateTime(2026, 1, 1)));

      final ids = repo.loadAll().map((c) => c.id).toList();
      expect(ids, ['newest', 'middle', 'oldest']);
    });

    test('loadAll ignores unrelated keys in the shared settings box',
        () async {
      final box = Hive.box(HiveBoxes.settings);
      // Legacy settings entry — must not be deserialised as a card.
      await box.put('some_other_setting', {'foo': 'bar'});

      final repo = LoyaltyCardRepository(box: box);
      await repo.upsert(makeCard(id: 'card-only'));

      final all = repo.loadAll();
      expect(all, hasLength(1));
      expect(all.single.id, 'card-only');
    });

    test('clear wipes only the loyalty-card keys', () async {
      final box = Hive.box(HiveBoxes.settings);
      await box.put('unrelated_setting', {'x': 1});
      final repo = LoyaltyCardRepository(box: box);
      await repo.upsert(makeCard(id: 'a1'));
      await repo.upsert(makeCard(id: 'a2'));

      await repo.clear();

      expect(repo.loadAll(), isEmpty);
      // Sibling unrelated key is untouched.
      expect(box.get('unrelated_setting'), isNotNull);
    });

    test(
        'persistence survives a re-open of the underlying box',
        () async {
      final repo1 = LoyaltyCardRepository(box: Hive.box(HiveBoxes.settings));
      await repo1.upsert(
        makeCard(id: 'persisted', label: 'Holds across restarts'),
      );

      // Simulate "app restart": close and reopen the box.
      await Hive.box(HiveBoxes.settings).close();
      await Hive.openBox(HiveBoxes.settings);

      final repo2 = LoyaltyCardRepository(box: Hive.box(HiveBoxes.settings));
      final all = repo2.loadAll();
      expect(all, hasLength(1));
      expect(all.single.id, 'persisted');
      expect(all.single.label, 'Holds across restarts');
    });
  });

  group('LoyaltyBrand canonical mapping', () {
    test('every enum value carries a non-empty canonical brand string', () {
      for (final brand in LoyaltyBrand.values) {
        expect(brand.canonicalBrand, isNotEmpty);
      }
    });

    test('fromCanonical resolves the matching enum', () {
      expect(LoyaltyBrand.fromCanonical('TotalEnergies'),
          LoyaltyBrand.totalEnergies);
      expect(LoyaltyBrand.fromCanonical('Aral'), LoyaltyBrand.aral);
    });

    test('fromCanonical returns null for unknown brand strings', () {
      expect(LoyaltyBrand.fromCanonical(null), isNull);
      expect(LoyaltyBrand.fromCanonical('NotARealBrand'), isNull);
    });
  });
}
