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

  const _FakeRefuelOption({
    required this.id,
    required this.provider,
    required this.availability,
    this.price,
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
        'showDistanceAtRight=false hides the trailing distance slot',
        (tester) async {
      // The distance slot is a SizedBox.shrink() that occupies no
      // visible space — verify by counting siblings of the price column.
      // When the gate is on, the slot is in the tree; when off, it
      // isn't. We assert by widget descendant count.
      await pumpApp(
        tester,
        const RefuelOptionCard(
          option: StationAsRefuelOption(testStation, FuelType.e10),
        ),
      );
      // Find the inner Row of the card.
      final rowOn = tester.widget<Row>(find.descendant(
        of: find.byType(RefuelOptionCard),
        matching: find.byType(Row),
      ).first);
      final childCountOn = rowOn.children.length;

      await tester.pumpWidget(const SizedBox.shrink());

      await pumpApp(
        tester,
        const RefuelOptionCard(
          option: StationAsRefuelOption(testStation, FuelType.e10),
          showDistanceAtRight: false,
        ),
      );
      final rowOff = tester.widget<Row>(find.descendant(
        of: find.byType(RefuelOptionCard),
        matching: find.byType(Row),
      ).first);
      final childCountOff = rowOff.children.length;

      expect(
        childCountOn - childCountOff,
        1,
        reason: 'showDistanceAtRight=false must remove exactly one '
            'slot from the trailing row',
      );
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
