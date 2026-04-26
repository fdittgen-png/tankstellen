import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/loyalty/domain/entities/loyalty_card.dart';
import 'package:tankstellen/features/loyalty/providers/loyalty_provider.dart';

void main() {
  late Directory tempDir;

  LoyaltyCard makeCard({
    String id = 'c1',
    LoyaltyBrand brand = LoyaltyBrand.totalEnergies,
    double discountPerLiter = 0.05,
    bool enabled = true,
    DateTime? addedAt,
  }) {
    return LoyaltyCard(
      id: id,
      brand: brand,
      discountPerLiter: discountPerLiter,
      label: 'label-$id',
      addedAt: addedAt ?? DateTime(2026, 4, 1),
      enabled: enabled,
    );
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_loyalty_provider_');
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

  group('loyaltyCardsProvider', () {
    test('builds an empty list on a fresh box', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loyaltyCardsProvider), isEmpty);
    });

    test('upsert persists the card and rebuilds the list', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(loyaltyCardsProvider.notifier)
          .upsert(makeCard(id: 'a1'));

      final state = container.read(loyaltyCardsProvider);
      expect(state, hasLength(1));
      expect(state.single.id, 'a1');
    });

    test('remove drops the card and rebuilds the list', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(loyaltyCardsProvider.notifier);

      await notifier.upsert(makeCard(id: 'a1'));
      await notifier.upsert(makeCard(id: 'a2'));
      await notifier.remove('a1');

      final ids = container.read(loyaltyCardsProvider).map((c) => c.id);
      expect(ids, ['a2']);
    });
  });

  group('activeDiscountByBrandProvider', () {
    test('is empty when there are no cards', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(activeDiscountByBrandProvider), isEmpty);
    });

    test('reflects every enabled card grouped by brand', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(loyaltyCardsProvider.notifier);

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

      final map = container.read(activeDiscountByBrandProvider);
      expect(map[LoyaltyBrand.totalEnergies], 0.05);
      expect(map[LoyaltyBrand.aral], 0.04);
    });

    test('skips disabled cards even when persisted', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(loyaltyCardsProvider.notifier);

      await notifier.upsert(makeCard(
        id: 'total',
        brand: LoyaltyBrand.totalEnergies,
        discountPerLiter: 0.05,
        enabled: false,
      ));

      final map = container.read(activeDiscountByBrandProvider);
      expect(map.containsKey(LoyaltyBrand.totalEnergies), isFalse);
    });

    test(
        'resurfaces a card once the user re-enables it via setEnabled',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(loyaltyCardsProvider.notifier);

      await notifier.upsert(makeCard(
        id: 'total',
        brand: LoyaltyBrand.totalEnergies,
        discountPerLiter: 0.05,
        enabled: false,
      ));
      expect(container.read(activeDiscountByBrandProvider), isEmpty);

      await notifier.setEnabled('total', enabled: true);

      expect(container.read(activeDiscountByBrandProvider)[
          LoyaltyBrand.totalEnergies], 0.05);
    });

    test(
        'collapses two cards of the same brand to the larger discount',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(loyaltyCardsProvider.notifier);

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

      final map = container.read(activeDiscountByBrandProvider);
      expect(map[LoyaltyBrand.totalEnergies], 0.06);
    });

    test('drops cards with non-positive discounts (defensive)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(loyaltyCardsProvider.notifier);

      await notifier.upsert(makeCard(
        id: 'zero',
        brand: LoyaltyBrand.shell,
        discountPerLiter: 0,
      ));
      await notifier.upsert(makeCard(
        id: 'negative',
        brand: LoyaltyBrand.shell,
        discountPerLiter: -1,
      ));

      expect(container.read(activeDiscountByBrandProvider), isEmpty);
    });
  });
}
