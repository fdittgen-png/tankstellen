import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_tariff.dart';
import 'package:tankstellen/features/ev/domain/services/ev_price_calculator.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Builds a single-element tariff from a flat list of components.
ChargingTariff _tariff(
  List<TariffComponent> components, {
  String id = 't',
  String currency = 'EUR',
  TariffRestriction? restrictions,
}) =>
    ChargingTariff(
      id: id,
      currency: currency,
      elements: [
        TariffElement(
          priceComponents: components,
          restrictions: restrictions,
        ),
      ],
    );

void main() {
  group('EvPriceCalculator.calculateChargingCost', () {
    test('energy-only tariff bills kWh at the component price', () {
      final tariff = _tariff(const [
        TariffComponent(
          type: PriceComponentType.energy,
          price: 0.39,
        ),
      ]);
      final cost = EvPriceCalculator.calculateChargingCost(
        tariff,
        40.0,
        const Duration(minutes: 45),
      );
      expect(cost.energyCost, closeTo(15.60, 1e-9));
      expect(cost.totalCost, closeTo(15.60, 1e-9));
      expect(cost.timeCost, 0);
      expect(cost.flatFee, 0);
      expect(cost.currency, 'EUR');
      expect(cost.kwhDelivered, 40.0);
      expect(cost.effectivePricePerKwh, closeTo(0.39, 1e-9));
    });

    test('time-only tariff bills duration per minute', () {
      final tariff = _tariff(const [
        TariffComponent(type: PriceComponentType.time, price: 0.10),
      ]);
      final cost = EvPriceCalculator.calculateChargingCost(
        tariff,
        0,
        const Duration(minutes: 30),
      );
      expect(cost.timeCost, closeTo(3.0, 1e-9));
      expect(cost.totalCost, closeTo(3.0, 1e-9));
      expect(cost.effectivePricePerKwh, isNull);
    });

    test('flat fee is charged exactly once', () {
      final tariff = _tariff(const [
        TariffComponent(type: PriceComponentType.flat, price: 1.0),
      ]);
      final cost = EvPriceCalculator.calculateChargingCost(
        tariff,
        10,
        const Duration(minutes: 20),
      );
      expect(cost.flatFee, 1.0);
      expect(cost.totalCost, 1.0);
    });

    test('combined energy + time + flat tariff sums all components', () {
      final tariff = _tariff(const [
        TariffComponent(type: PriceComponentType.energy, price: 0.45),
        TariffComponent(type: PriceComponentType.time, price: 0.10),
        TariffComponent(type: PriceComponentType.flat, price: 1.0),
      ]);
      final cost = EvPriceCalculator.calculateChargingCost(
        tariff,
        40.0,
        const Duration(minutes: 45),
      );
      expect(cost.energyCost, closeTo(18.0, 1e-9));
      expect(cost.timeCost, closeTo(4.5, 1e-9));
      expect(cost.flatFee, 1.0);
      expect(cost.totalCost, closeTo(23.5, 1e-9));
    });

    test('parking fee is billed per parking minute only', () {
      final tariff = _tariff(const [
        TariffComponent(type: PriceComponentType.energy, price: 0.30),
        TariffComponent(type: PriceComponentType.parkingTime, price: 0.20),
      ]);
      final cost = EvPriceCalculator.calculateChargingCost(
        tariff,
        20,
        const Duration(minutes: 30),
        parkingTime: const Duration(minutes: 15),
      );
      expect(cost.energyCost, closeTo(6.0, 1e-9));
      expect(cost.parkingCost, closeTo(3.0, 1e-9));
      expect(cost.totalCost, closeTo(9.0, 1e-9));
    });

    test('blocking fee is billed per blocking minute only', () {
      final tariff = _tariff(const [
        TariffComponent(type: PriceComponentType.blockingTime, price: 0.50),
      ]);
      final cost = EvPriceCalculator.calculateChargingCost(
        tariff,
        0,
        Duration.zero,
        blockingTime: const Duration(minutes: 10),
      );
      expect(cost.blockingCost, closeTo(5.0, 1e-9));
      expect(cost.totalCost, closeTo(5.0, 1e-9));
    });

    test('zero kwh + zero duration returns zero cost', () {
      final tariff = _tariff(const [
        TariffComponent(type: PriceComponentType.energy, price: 0.39),
        TariffComponent(type: PriceComponentType.time, price: 0.10),
      ]);
      final cost = EvPriceCalculator.calculateChargingCost(
        tariff,
        0,
        Duration.zero,
      );
      expect(cost.totalCost, 0);
      expect(cost.effectivePricePerKwh, isNull);
    });

    test('negative inputs are clamped to zero', () {
      final tariff = _tariff(const [
        TariffComponent(type: PriceComponentType.energy, price: 0.39),
      ]);
      final cost = EvPriceCalculator.calculateChargingCost(
        tariff,
        -5,
        const Duration(seconds: -10),
      );
      expect(cost.totalCost, 0);
      expect(cost.kwhDelivered, 0);
    });

    test('tariff with no components produces zero cost', () {
      final tariff = _tariff(const []);
      final cost = EvPriceCalculator.calculateChargingCost(
        tariff,
        40,
        const Duration(minutes: 30),
      );
      expect(cost.totalCost, 0);
    });

    test('completely empty tariff with no elements produces zero cost', () {
      const tariff = ChargingTariff(id: 'empty');
      final cost = EvPriceCalculator.calculateChargingCost(
        tariff,
        10,
        const Duration(minutes: 10),
      );
      expect(cost.totalCost, 0);
    });

    test('energy stepSize rounds up to whole Wh increments', () {
      final tariff = _tariff(const [
        TariffComponent(
          type: PriceComponentType.energy,
          price: 1.0,
          stepSize: 1000, // 1 kWh increments
        ),
      ]);
      // 40.3 kWh -> billed as 41 kWh
      final cost = EvPriceCalculator.calculateChargingCost(
        tariff,
        40.3,
        const Duration(minutes: 30),
      );
      expect(cost.energyCost, closeTo(41.0, 1e-9));
    });

    test('time stepSize rounds up to whole seconds', () {
      final tariff = _tariff(const [
        TariffComponent(
          type: PriceComponentType.time,
          price: 0.60,
          stepSize: 900, // 15 minute blocks
        ),
      ]);
      // 16 minutes -> billed as 30 minutes (two blocks)
      final cost = EvPriceCalculator.calculateChargingCost(
        tariff,
        0,
        const Duration(minutes: 16),
      );
      expect(cost.timeCost, closeTo(18.0, 1e-9));
    });

    test('first matching element wins for a given component type', () {
      const tariff = ChargingTariff(
        id: 'tiered',
        elements: [
          TariffElement(
            priceComponents: [
              TariffComponent(
                type: PriceComponentType.energy,
                price: 0.20,
              ),
            ],
            restrictions: TariffRestriction(minKwh: 50),
          ),
          TariffElement(
            priceComponents: [
              TariffComponent(
                type: PriceComponentType.energy,
                price: 0.39,
              ),
            ],
          ),
        ],
      );
      // 10 kWh -> first element skipped (min 50), second matches
      final cheap = EvPriceCalculator.calculateChargingCost(
        tariff,
        10,
        const Duration(minutes: 10),
      );
      expect(cheap.energyCost, closeTo(3.9, 1e-9));

      // 100 kWh -> first element wins (0.20/kWh)
      final bulk = EvPriceCalculator.calculateChargingCost(
        tariff,
        100,
        const Duration(minutes: 60),
      );
      expect(bulk.energyCost, closeTo(20.0, 1e-9));
    });

    test('time-of-day restriction filters element when startTime is outside',
        () {
      const tariff = ChargingTariff(
        id: 'night',
        elements: [
          TariffElement(
            priceComponents: [
              TariffComponent(
                type: PriceComponentType.energy,
                price: 0.20,
              ),
            ],
            restrictions:
                TariffRestriction(startTime: '22:00', endTime: '06:00'),
          ),
          TariffElement(
            priceComponents: [
              TariffComponent(
                type: PriceComponentType.energy,
                price: 0.45,
              ),
            ],
          ),
        ],
      );
      final day = EvPriceCalculator.calculateChargingCost(
        tariff,
        10,
        const Duration(minutes: 20),
        startTime: DateTime(2026, 4, 8, 14, 0),
      );
      expect(day.energyCost, closeTo(4.5, 1e-9));

      final night = EvPriceCalculator.calculateChargingCost(
        tariff,
        10,
        const Duration(minutes: 20),
        startTime: DateTime(2026, 4, 8, 23, 30),
      );
      expect(night.energyCost, closeTo(2.0, 1e-9));
    });

    test('day-of-week restriction filters element', () {
      const tariff = ChargingTariff(
        id: 'weekday',
        elements: [
          TariffElement(
            priceComponents: [
              TariffComponent(
                type: PriceComponentType.energy,
                price: 0.25,
              ),
            ],
            restrictions: TariffRestriction(daysOfWeek: [1, 2, 3, 4, 5]),
          ),
          TariffElement(
            priceComponents: [
              TariffComponent(
                type: PriceComponentType.energy,
                price: 0.50,
              ),
            ],
          ),
        ],
      );
      // 2026-04-08 is a Wednesday -> weekday rate
      final wed = EvPriceCalculator.calculateChargingCost(
        tariff,
        10,
        Duration.zero,
        startTime: DateTime(2026, 4, 8, 12, 0),
      );
      expect(wed.energyCost, closeTo(2.5, 1e-9));

      // 2026-04-11 is a Saturday -> fallback rate
      final sat = EvPriceCalculator.calculateChargingCost(
        tariff,
        10,
        Duration.zero,
        startTime: DateTime(2026, 4, 11, 12, 0),
      );
      expect(sat.energyCost, closeTo(5.0, 1e-9));
    });
  });

  group('EvPriceCalculator.estimateChargeCost', () {
    const vehicle = VehicleProfile(
      id: 'v1',
      name: 'Zoe',
      type: VehicleType.ev,
      batteryKwh: 52.0,
      maxChargingKw: 50.0,
      supportedConnectors: {ConnectorType.ccs, ConnectorType.type2},
    );

    final tariff = _tariff(const [
      TariffComponent(type: PriceComponentType.energy, price: 0.40),
    ]);

    test('estimates kWh from SoC delta and battery capacity', () {
      final cost = EvPriceCalculator.estimateChargeCost(
        tariff,
        vehicle,
        startSoc: 20,
        targetSoc: 80,
      );
      expect(cost, isNotNull);
      // 60% of 52 kWh = 31.2 kWh @ 0.40 = 12.48
      expect(cost!.kwhDelivered, closeTo(31.2, 1e-9));
      expect(cost.totalCost, closeTo(12.48, 1e-6));
    });

    test('returns null when battery capacity is unknown', () {
      final noBattery = vehicle.copyWith(batteryKwh: null);
      expect(
        EvPriceCalculator.estimateChargeCost(
          tariff,
          noBattery,
          startSoc: 20,
          targetSoc: 80,
        ),
        isNull,
      );
    });

    test('returns null when targetSoc is not greater than startSoc', () {
      expect(
        EvPriceCalculator.estimateChargeCost(
          tariff,
          vehicle,
          startSoc: 80,
          targetSoc: 80,
        ),
        isNull,
      );
    });
  });

  group('EvPriceCalculator.compareTariffs', () {
    test('returns entries sorted by total cost ascending', () {
      final a = _tariff(
        const [
          TariffComponent(type: PriceComponentType.energy, price: 0.45),
          TariffComponent(type: PriceComponentType.flat, price: 1.0),
        ],
        id: 'a',
      );
      final b = _tariff(
        const [
          TariffComponent(type: PriceComponentType.energy, price: 0.39),
        ],
        id: 'b',
      );
      final c = _tariff(
        const [
          TariffComponent(type: PriceComponentType.energy, price: 0.60),
        ],
        id: 'c',
      );

      final entries = EvPriceCalculator.compareTariffs(
        [a, b, c],
        40,
        duration: const Duration(minutes: 30),
      );
      expect(entries.map((e) => e.tariffId).toList(), ['b', 'a', 'c']);
      expect(entries.first.totalCost, closeTo(15.6, 1e-9));
      expect(entries.last.totalCost, closeTo(24.0, 1e-9));
    });

    test('returns an empty list when no tariffs are provided', () {
      expect(EvPriceCalculator.compareTariffs(const [], 10), isEmpty);
    });
  });

  group('ChargingCostBreakdown JSON', () {
    test('round-trips through JSON', () {
      const breakdown = ChargingCostBreakdown(
        totalCost: 23.5,
        energyCost: 18.0,
        timeCost: 4.5,
        flatFee: 1.0,
        parkingCost: 0,
        blockingCost: 0,
        kwhDelivered: 40,
        currency: 'EUR',
      );
      final restored =
          ChargingCostBreakdown.fromJson(breakdown.toJson());
      expect(restored, breakdown);
      expect(restored.effectivePricePerKwh, closeTo(0.5875, 1e-9));
    });
  });
}
