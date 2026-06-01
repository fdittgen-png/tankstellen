// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/ev_access_cost.dart';

void main() {
  group('EvAccessCost.from', () {
    test('paid via IsPayAtLocation flag', () {
      final cost = EvAccessCost.from(
        usageTypeId: 4,
        usageTypeTitle: 'Public - Pay At Location',
        isPayAtLocation: true,
        isMembershipRequired: false,
      );
      expect(cost.kind, EvAccessCostKind.paid);
      expect(cost.isKnown, isTrue);
    });

    test('free via flags + title', () {
      final cost = EvAccessCost.from(
        usageTypeId: 1,
        usageTypeTitle: 'Public - Free',
        isPayAtLocation: false,
        isMembershipRequired: false,
      );
      expect(cost.kind, EvAccessCostKind.free);
    });

    test('membership via IsMembershipRequired flag', () {
      final cost = EvAccessCost.from(
        usageTypeId: 5,
        usageTypeTitle: 'Public - Membership Required',
        isPayAtLocation: false,
        isMembershipRequired: true,
      );
      expect(cost.kind, EvAccessCostKind.membership);
    });

    test('membership via title heuristic when flags null', () {
      final cost = EvAccessCost.from(
        usageTypeTitle: 'Private - For Staff, Visitors or Customers, '
            'Membership Required',
      );
      expect(cost.kind, EvAccessCostKind.membership);
    });

    test('free via usageCost free-words when no flags/title', () {
      final cost = EvAccessCost.from(usageCost: 'Free of charge');
      expect(cost.kind, EvAccessCostKind.free);
    });

    test("'0.49 EUR/kWh' + title 'Public - Free' → paid "
        '(real tariff overrides free title)', () {
      final cost = EvAccessCost.from(
        usageTypeTitle: 'Public - Free',
        usageCost: '0.49 EUR/kWh',
      );
      expect(cost.kind, EvAccessCostKind.paid);
    });

    test("'notice required' title with no tariff → unknown", () {
      final cost = EvAccessCost.from(
        usageTypeTitle: 'Public - Notice Required',
      );
      expect(cost.kind, EvAccessCostKind.unknown);
      expect(cost.isKnown, isFalse);
    });

    test('notice-required title WITH a real tariff resolves to paid', () {
      final cost = EvAccessCost.from(
        usageTypeTitle: 'Public - Notice Required',
        usageCost: '0.39 EUR/kWh',
      );
      expect(cost.kind, EvAccessCostKind.paid);
    });

    test('no flags, no title, no usageCost → unknown', () {
      final cost = EvAccessCost.from();
      expect(cost.kind, EvAccessCostKind.unknown);
    });

    test('IsPayAtLocation flag wins even when title says Free', () {
      final cost = EvAccessCost.from(
        usageTypeTitle: 'Public - Free',
        isPayAtLocation: true,
      );
      expect(cost.kind, EvAccessCostKind.paid);
    });

    test('membership flag with a real tariff stays membership', () {
      // Membership is an access gate, not contradicted by a tariff.
      final cost = EvAccessCost.from(
        isMembershipRequired: true,
        usageCost: '0.55 EUR/kWh',
      );
      expect(cost.kind, EvAccessCostKind.membership);
    });

    test('bare 0 usageCost with explicit non-paid flags → free', () {
      final cost = EvAccessCost.from(
        isPayAtLocation: false,
        isMembershipRequired: false,
        usageCost: '0',
      );
      expect(cost.kind, EvAccessCostKind.free);
    });

    group('FR gratuit / multilingual free-word normalization', () {
      // The shared EvPrice free-words table backs the cross-check; these
      // assert the access-cost classifier honours them when there is no
      // structured flag/title.
      const freeWords = <String>[
        'Gratuit',
        'gratuit',
        'GRATUIT',
        'Recharge gratuite',
        'Free',
        'Kostenlos',
        'Gratis',
        'Gratuito',
      ];
      for (final word in freeWords) {
        test("'$word' → free", () {
          final cost = EvAccessCost.from(usageCost: word);
          expect(cost.kind, EvAccessCostKind.free, reason: word);
        });
      }

      test("'Gratuit' free-word does NOT override an explicit pay flag", () {
        final cost = EvAccessCost.from(
          isPayAtLocation: true,
          usageCost: 'Gratuit',
        );
        expect(cost.kind, EvAccessCostKind.paid);
      });
    });

    test('value equality', () {
      expect(
        const EvAccessCost(EvAccessCostKind.free),
        const EvAccessCost(EvAccessCostKind.free),
      );
      expect(
        const EvAccessCost(EvAccessCostKind.free),
        isNot(const EvAccessCost(EvAccessCostKind.paid)),
      );
    });
  });
}
