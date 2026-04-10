import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_tariff.dart';

void main() {
  group('ChargingTariff', () {
    const energyOnly = ChargingTariff(
      id: 'tariff-1',
      currency: 'EUR',
      elements: [
        TariffElement(
          priceComponents: [
            TariffComponent(
              type: PriceComponentType.energy,
              price: 0.39,
              stepSize: 1,
            ),
          ],
        ),
      ],
    );

    test('energy-only tariff round-trips through JSON', () {
      final restored = ChargingTariff.fromJson(energyOnly.toJson());
      expect(restored, energyOnly);
    });

    test('complex tariff with restrictions round-trips through JSON', () {
      const tariff = ChargingTariff(
        id: 'tariff-complex',
        currency: 'EUR',
        type: TariffType.adHocPayment,
        elements: [
          TariffElement(
            priceComponents: [
              TariffComponent(
                type: PriceComponentType.energy,
                price: 0.79,
                stepSize: 1000,
              ),
              TariffComponent(
                type: PriceComponentType.flat,
                price: 1.0,
              ),
              TariffComponent(
                type: PriceComponentType.time,
                price: 0.1,
                stepSize: 60,
              ),
              TariffComponent(
                type: PriceComponentType.parkingTime,
                price: 0.05,
                stepSize: 60,
              ),
              TariffComponent(
                type: PriceComponentType.blockingTime,
                price: 0.2,
                stepSize: 60,
              ),
            ],
            restrictions: TariffRestriction(
              startTime: '22:00',
              endTime: '06:00',
              daysOfWeek: [1, 2, 3, 4, 5],
              minKwh: 1.0,
              maxKwh: 200.0,
            ),
          ),
        ],
      );
      final restored = ChargingTariff.fromJson(tariff.toJson());
      expect(restored, tariff);
    });

    test('headlinePricePerKwh picks the first energy component', () {
      expect(energyOnly.headlinePricePerKwh, 0.39);

      const multi = ChargingTariff(
        id: 't',
        elements: [
          TariffElement(
            priceComponents: [
              TariffComponent(type: PriceComponentType.flat, price: 0.5),
            ],
          ),
          TariffElement(
            priceComponents: [
              TariffComponent(
                type: PriceComponentType.energy,
                price: 0.42,
              ),
            ],
          ),
        ],
      );
      expect(multi.headlinePricePerKwh, 0.42);
    });

    test('headlinePricePerKwh returns null when no energy component exists', () {
      const timeOnly = ChargingTariff(
        id: 't',
        elements: [
          TariffElement(
            priceComponents: [
              TariffComponent(type: PriceComponentType.time, price: 0.1),
            ],
          ),
        ],
      );
      expect(timeOnly.headlinePricePerKwh, isNull);
    });

    test('enum.fromKey falls back to defaults on unknown input', () {
      expect(
        PriceComponentType.fromKey('bogus'),
        PriceComponentType.energy,
      );
      expect(TariffType.fromKey(null), TariffType.regular);
    });
  });
}
