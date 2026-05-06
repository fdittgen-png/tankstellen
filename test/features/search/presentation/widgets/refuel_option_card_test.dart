import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/refuel/charging_station_as_refuel_option.dart';
import 'package:tankstellen/core/refuel/refuel_availability.dart';
import 'package:tankstellen/core/refuel/refuel_option.dart';
import 'package:tankstellen/core/refuel/refuel_price.dart';
import 'package:tankstellen/core/refuel/refuel_provider.dart';
import 'package:tankstellen/core/refuel/station_as_refuel_option.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/domain/entities/station_amenity.dart';
import 'package:tankstellen/features/search/presentation/widgets/amenity_chips.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/widgets/refuel_option_card.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

/// Hand-rolled subtype mirroring the helper in
/// `test/core/refuel/refuel_option_test.dart`. Lets the widget tests
/// exercise the full availability matrix without depending on a real
/// adapter for every case.
class _FakeRefuelOption extends RefuelOption {
  @override
  ({double lat, double lng}) get coordinates => (lat: 0.0, lng: 0.0);
  @override
  final RefuelPrice? price;
  @override
  final RefuelProvider provider;
  @override
  final RefuelAvailability availability;
  @override
  final String id;
  @override
  String get address => '';
  @override
  double? get distanceMeters => null;
  @override
  final bool is24h;
  @override
  DateTime? get lastUpdated => null;
  @override
  Object get source => this;

  const _FakeRefuelOption({
    required this.id,
    required this.provider,
    required this.availability,
    this.price,
    this.is24h = false,
  });
}

const _evChargingStation = ChargingStation(
  id: 'ocm-77',
  name: 'Test Charger',
  operator: 'Ionity',
  latitude: 50.11,
  longitude: 8.68,
  dist: 2.4,
  address: 'Mainzer Str. 7',
  postCode: '60311',
  place: 'Frankfurt',
  connectors: [
    EvConnector(
      id: 'c1',
      type: ConnectorType.ccs,
      rawType: 'CCS Type 2',
      maxPowerKw: 350,
      quantity: 4,
      currentType: 'DC',
    ),
  ],
  totalPoints: 4,
  isOperational: true,
);

void main() {
  group('RefuelOptionCard', () {
    testWidgets('renders fuel station provider name as title', (tester) async {
      const option = StationAsRefuelOption(testStation, FuelType.e10);

      await pumpApp(
        tester,
        const RefuelOptionCard(option: option),
      );

      // Provider name from `Station.brand` is the canonical title.
      expect(find.text('STAR'), findsOneWidget);
    });

    testWidgets('renders fuel price + per-litre unit', (tester) async {
      const option = StationAsRefuelOption(testStation, FuelType.e10);

      await pumpApp(
        tester,
        const RefuelOptionCard(option: option),
      );

      // 1.799 EUR/L → 179.9 cents → "179,900" via PriceFormatter (de_DE).
      // The widget renders cents/100 = 1.799, formatted to 3 decimals.
      // The exact decimal separator depends on the active locale, so
      // assert on the digits that survive both `.` and `,` separators.
      final priceText = find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').contains('1') &&
            (w.data ?? '').contains('799'),
      );
      expect(priceText, findsOneWidget,
          reason: 'fuel price text must include the 1.799 digits');

      // Unit suffix from refuelUnitPerLiter ARB key.
      expect(find.text('/L'), findsOneWidget);
    });

    testWidgets('shows fuel icon for fuel-kind providers', (tester) async {
      const option = StationAsRefuelOption(testStation, FuelType.e10);

      await pumpApp(
        tester,
        const RefuelOptionCard(option: option),
      );

      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
      expect(find.byIcon(Icons.ev_station), findsNothing);
    });

    testWidgets('renders EV station provider name as title', (tester) async {
      const option = ChargingStationAsRefuelOption(_evChargingStation);

      await pumpApp(
        tester,
        const RefuelOptionCard(option: option),
      );

      expect(find.text('Ionity'), findsOneWidget);
    });

    testWidgets('shows EV icon for ev-kind providers', (tester) async {
      const option = ChargingStationAsRefuelOption(_evChargingStation);

      await pumpApp(
        tester,
        const RefuelOptionCard(option: option),
      );

      expect(find.byIcon(Icons.ev_station), findsOneWidget);
      expect(find.byIcon(Icons.local_gas_station), findsNothing);
    });

    testWidgets('shows EV icon for both-kind providers', (tester) async {
      // A mixed-site provider (fuel + chargers on the same forecourt).
      const option = _FakeRefuelOption(
        id: 'mixed:1',
        provider: RefuelProvider(
          name: 'Total + Recharge',
          kind: RefuelProviderKind.both,
        ),
        availability: RefuelAvailability.open,
      );

      await pumpApp(
        tester,
        const RefuelOptionCard(option: option),
      );

      expect(find.byIcon(Icons.ev_station), findsOneWidget);
    });

    testWidgets('renders kWh unit when price unit is centsPerKwh',
        (tester) async {
      const option = _FakeRefuelOption(
        id: 'ev:1',
        provider: RefuelProvider(
          name: 'Ionity',
          kind: RefuelProviderKind.ev,
        ),
        availability: RefuelAvailability.open,
        price: RefuelPrice(
          value: 39.0,
          unit: RefuelPriceUnit.centsPerKwh,
        ),
      );

      await pumpApp(
        tester,
        const RefuelOptionCard(option: option),
      );

      expect(find.text('/kWh'), findsOneWidget);
    });

    testWidgets('renders session unit when price unit is perSession',
        (tester) async {
      const option = _FakeRefuelOption(
        id: 'ev:flat',
        provider: RefuelProvider(
          name: 'Tesla',
          kind: RefuelProviderKind.ev,
        ),
        availability: RefuelAvailability.open,
        price: RefuelPrice(
          value: 1500.0,
          unit: RefuelPriceUnit.perSession,
        ),
      );

      await pumpApp(
        tester,
        const RefuelOptionCard(option: option),
      );

      expect(find.text('/session'), findsOneWidget);
    });

    testWidgets('shows em-dash placeholder when price is null',
        (tester) async {
      const option = ChargingStationAsRefuelOption(_evChargingStation);
      // ChargingStationAsRefuelOption.price is always null in phase 2.

      await pumpApp(
        tester,
        const RefuelOptionCard(option: option),
      );

      expect(find.text('--'), findsOneWidget);
    });

    group('availability indicator', () {
      Future<Color> dotColorFor(
        WidgetTester tester,
        RefuelAvailability availability,
      ) async {
        final option = _FakeRefuelOption(
          id: 'fake:1',
          provider: const RefuelProvider(
            name: 'Brand',
            kind: RefuelProviderKind.fuel,
          ),
          availability: availability,
        );

        await pumpApp(
          tester,
          RefuelOptionCard(option: option),
        );

        // The dot is the small 12x12 circle Container.
        final dot = find.byWidgetPredicate((w) {
          if (w is! Container) return false;
          final dec = w.decoration;
          if (dec is! BoxDecoration) return false;
          if (dec.shape != BoxShape.circle) return false;
          // Constraints for a SizedBox(width:12,height:12) inside Container.
          return w.constraints?.maxWidth == 12 &&
              w.constraints?.maxHeight == 12;
        });
        expect(dot, findsOneWidget,
            reason: 'card must render a 12x12 availability dot');
        final container = tester.widget<Container>(dot);
        return (container.decoration as BoxDecoration).color!;
      }

      testWidgets('open → success colour', (tester) async {
        late Color expected;
        await pumpApp(
          tester,
          Builder(builder: (context) {
            expected = DarkModeColors.success(context);
            return const SizedBox.shrink();
          }),
        );
        final actual = await dotColorFor(
          tester,
          RefuelAvailability.open,
        );
        expect(actual, expected);
      });

      testWidgets('limited → warning colour', (tester) async {
        late Color expected;
        await pumpApp(
          tester,
          Builder(builder: (context) {
            expected = DarkModeColors.warning(context);
            return const SizedBox.shrink();
          }),
        );
        final actual = await dotColorFor(
          tester,
          RefuelAvailability.limited(reason: 'queue forming'),
        );
        expect(actual, expected);
      });

      testWidgets('closed → error colour', (tester) async {
        late Color expected;
        await pumpApp(
          tester,
          Builder(builder: (context) {
            expected = DarkModeColors.error(context);
            return const SizedBox.shrink();
          }),
        );
        final actual = await dotColorFor(
          tester,
          RefuelAvailability.closed(),
        );
        expect(actual, expected);
      });

      testWidgets('unknown → neutral surface-variant colour', (tester) async {
        late Color expected;
        await pumpApp(
          tester,
          Builder(builder: (context) {
            expected = Theme.of(context).colorScheme.onSurfaceVariant;
            return const SizedBox.shrink();
          }),
        );
        final actual = await dotColorFor(
          tester,
          RefuelAvailability.unknown,
        );
        expect(actual, expected);
      });
    });

    testWidgets('limited reason text is surfaced under the title',
        (tester) async {
      final option = _FakeRefuelOption(
        id: 'fake:limited',
        provider: const RefuelProvider(
          name: 'Brand',
          kind: RefuelProviderKind.fuel,
        ),
        availability: RefuelAvailability.limited(
          reason: 'Queue forming at the diesel pump',
        ),
      );

      await pumpApp(
        tester,
        RefuelOptionCard(option: option),
      );

      expect(find.text('Queue forming at the diesel pump'), findsOneWidget);
    });

    testWidgets('falls back to provider kind when name is empty',
        (tester) async {
      const option = _FakeRefuelOption(
        id: 'fake:unknown-brand',
        provider: RefuelProvider.unknown,
        availability: RefuelAvailability.unknown,
      );

      await pumpApp(
        tester,
        const RefuelOptionCard(option: option),
      );

      // RefuelProvider.unknown.name == ''. The widget falls back to a
      // localized neutral label so the row never collapses to nothing.
      expect(find.byType(RefuelOptionCard), findsOneWidget);
      // The visible title text must not be the empty string.
      final titleTexts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(
        titleTexts.any((t) => t.data != null && t.data!.isNotEmpty),
        isTrue,
      );
    });

    testWidgets('onTap callback fires when card is tapped', (tester) async {
      var tapped = false;

      await pumpApp(
        tester,
        RefuelOptionCard(
          option: const StationAsRefuelOption(testStation, FuelType.e10),
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(RefuelOptionCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not crash when no onTap is provided', (tester) async {
      await pumpApp(
        tester,
        const RefuelOptionCard(
          option: StationAsRefuelOption(testStation, FuelType.e10),
        ),
      );

      // Tap should be a no-op (InkWell with null onTap), not a crash.
      await tester.tap(find.byType(RefuelOptionCard));
      await tester.pump();

      expect(find.byType(RefuelOptionCard), findsOneWidget);
    });

    testWidgets(
        'showDistanceAtRight=false hides the distance text under the title',
        (tester) async {
      // testStation.dist is 1.5 km → distanceMeters 1500. With the gate
      // on the card renders a "1.5 km"-style line; with it off the
      // distance text should NOT appear (the updated-at icon may still
      // appear since it is independent of the distance gate).
      await pumpApp(
        tester,
        const RefuelOptionCard(
          option: StationAsRefuelOption(testStation, FuelType.e10),
          showDistanceAtRight: false,
        ),
      );
      // Distance is formatted via PriceFormatter — the digits "1.5" or
      // "1,5" must not appear in any Text widget in the card when the
      // gate is off. (The price digits are 1.799 so a literal "1.5"
      // search still uniquely matches a distance label.)
      final hasDistanceText = tester
          .widgetList<Text>(find.byType(Text))
          .any((w) =>
              (w.data ?? '').contains('1.5') ||
              (w.data ?? '').contains('1,5'));
      expect(hasDistanceText, isFalse,
          reason: 'distance text must not appear when '
              'showDistanceAtRight is false');
    });

    group('phase 4 enrichment (#1116)', () {
      testWidgets('renders the address line under the title', (tester) async {
        // testStation: street "Hauptstr.", postCode "10115", place
        // "Berlin" → "Hauptstr., 10115 Berlin". The card must surface
        // this so the user can identify the station without tapping
        // through to detail.
        await pumpApp(
          tester,
          const RefuelOptionCard(
            option: StationAsRefuelOption(testStation, FuelType.e10),
          ),
        );

        expect(find.text('Hauptstr., 10115 Berlin'), findsOneWidget);
      });

      testWidgets('renders the distance label when distanceMeters is set',
          (tester) async {
        // testStation.dist = 1.5 km. PriceFormatter localises the
        // separator (1.5 vs 1,5), so assert on the digit substring that
        // survives both forms.
        await pumpApp(
          tester,
          const RefuelOptionCard(
            option: StationAsRefuelOption(testStation, FuelType.e10),
          ),
        );

        final hasDistanceDigits = tester
            .widgetList<Text>(find.byType(Text))
            .any((w) =>
                (w.data ?? '').contains('1.5') ||
                (w.data ?? '').contains('1,5'));
        expect(hasDistanceDigits, isTrue,
            reason: 'distance "1.5 km" digits must appear under the title');
      });

      testWidgets('renders the updated-at icon when lastUpdated is set',
          (tester) async {
        // testStation.updatedAt sets a real timestamp → the card must
        // render the Icons.update marker next to the elapsed-time text.
        await pumpApp(
          tester,
          const RefuelOptionCard(
            option: StationAsRefuelOption(testStation, FuelType.e10),
          ),
        );

        expect(find.byIcon(Icons.update), findsOneWidget);
      });

      testWidgets('renders the 24h badge when option.is24h is true',
          (tester) async {
        // The 24h badge sits under the status dot in the leading
        // status column — same shape as the legacy StationCard.
        const option = _FakeRefuelOption(
          id: 'fuel:24h',
          provider: RefuelProvider(
            name: 'Total Access',
            kind: RefuelProviderKind.fuel,
          ),
          availability: RefuelAvailability.open,
          is24h: true,
        );

        await pumpApp(
          tester,
          const RefuelOptionCard(option: option),
        );

        expect(find.text('24h'), findsOneWidget);
      });

      testWidgets('omits the 24h badge when option.is24h is false',
          (tester) async {
        const option = _FakeRefuelOption(
          id: 'fuel:no24',
          provider: RefuelProvider(
            name: 'Total',
            kind: RefuelProviderKind.fuel,
          ),
          availability: RefuelAvailability.open,
          is24h: false,
        );

        await pumpApp(
          tester,
          const RefuelOptionCard(option: option),
        );

        expect(find.text('24h'), findsNothing);
      });

      testWidgets('renders amenity chips for fuel-kind options', (tester) async {
        // testStation has no amenities, so build a station with one to
        // exercise the path. We use the public `Station` constructor
        // directly here rather than a fixture clone — keeps the test
        // narrow and free of helper imports.
        const stationWithAmenities = Station(
          id: 'amen-1',
          name: 'Test',
          brand: 'Total',
          street: 'Hauptstr.',
          postCode: '10115',
          place: 'Berlin',
          lat: 52.5,
          lng: 13.4,
          dist: 0.5,
          isOpen: true,
          amenities: {StationAmenity.toilet, StationAmenity.shop},
        );

        await pumpApp(
          tester,
          const RefuelOptionCard(
            option: StationAsRefuelOption(stationWithAmenities, FuelType.e10),
          ),
        );

        // AmenityChips renders a Wrap with one _AmenityChip per amenity;
        // assert by widget type from the helper.
        expect(find.byType(AmenityChips), findsOneWidget);
        final chips = tester.widget<AmenityChips>(find.byType(AmenityChips));
        expect(chips.amenities, {StationAmenity.toilet, StationAmenity.shop});
      });

      testWidgets('omits amenity chips when fuel station has no amenities',
          (tester) async {
        // testStation.amenities is the default `{}` set.
        await pumpApp(
          tester,
          const RefuelOptionCard(
            option: StationAsRefuelOption(testStation, FuelType.e10),
          ),
        );

        // AmenityChips returns SizedBox.shrink() on an empty set, but
        // the parent widget must not even instantiate it when empty —
        // that guards against accidental layout space being reserved.
        expect(find.byType(AmenityChips), findsNothing);
      });

      testWidgets('renders EV stats row for EV-kind options', (tester) async {
        // _evChargingStation has one CCS connector at 350 kW (status
        // is the legacy default, which decodes to ConnectorStatus
        // .unknown — so available count is 0/1).
        await pumpApp(
          tester,
          const RefuelOptionCard(
            option: ChargingStationAsRefuelOption(_evChargingStation),
          ),
        );

        expect(find.byIcon(Icons.electrical_services), findsOneWidget);
        // The stats text should include the kW number, the X/Y count,
        // and the connector type. The exact separator is "·" but we
        // only assert the substrings to keep the test resilient.
        final hasStats = tester
            .widgetList<Text>(find.byType(Text))
            .any((w) =>
                (w.data ?? '').contains('350 kW') &&
                (w.data ?? '').contains('CCS'));
        expect(hasStats, isTrue,
            reason: 'EV stats row must include kW + connector type');
      });

      testWidgets(
          'omits the address line when option.address is empty',
          (tester) async {
        // A sparse option (no address data) must not render an empty
        // address Text widget — the card collapses gracefully.
        const option = _FakeRefuelOption(
          id: 'sparse:1',
          provider: RefuelProvider(
            name: 'Generic Station',
            kind: RefuelProviderKind.fuel,
          ),
          availability: RefuelAvailability.open,
        );

        await pumpApp(
          tester,
          const RefuelOptionCard(option: option),
        );

        // Generic Station appears (title), the availability fallback
        // ("Open") appears under it. No empty Text widgets.
        final emptyTexts = tester
            .widgetList<Text>(find.byType(Text))
            .where((w) => (w.data ?? '').isEmpty);
        expect(emptyTexts, isEmpty,
            reason: 'no empty Text widgets when address is unavailable');
      });
    });

    testWidgets('option with null price (EV phase-2 adapter) renders cleanly',
        (tester) async {
      const option = ChargingStationAsRefuelOption(_evChargingStation);

      await pumpApp(
        tester,
        const RefuelOptionCard(option: option),
      );

      // No unit suffix should be shown when price is null — only the
      // em-dash placeholder.
      expect(find.text('--'), findsOneWidget);
      expect(find.text('/L'), findsNothing);
      expect(find.text('/kWh'), findsNothing);
      expect(find.text('/session'), findsNothing);
    });
  });
}
