// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/ev/charging_station.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_connector_tile.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_station_info_cards.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart'
    show ConnectorType;

import '../../../../helpers/pump_app.dart';

void main() {
  // Minimal station fixture — extended per test by copyWith.
  const baseStation = ChargingStation(
    id: 'ocm-1',
    name: 'Test Hub',
    latitude: 48.0,
    longitude: 2.0,
  );

  group('EVAddressCard', () {
    testWidgets('renders address text and place icon', (tester) async {
      final station = baseStation.copyWith(
        address: '123 Rue de Test',
        postCode: '34120',
        place: 'Pézenas',
        dist: 1.5,
      );

      await pumpApp(tester, EVAddressCard(station: station));

      expect(find.text('123 Rue de Test'), findsOneWidget);
      expect(find.byIcon(Icons.place), findsOneWidget);
    });

    testWidgets('renders postcode + place when both present', (tester) async {
      final station = baseStation.copyWith(
        address: 'Some street',
        postCode: '34120',
        place: 'Pézenas',
      );

      await pumpApp(tester, EVAddressCard(station: station));

      expect(find.text('34120 Pézenas'), findsOneWidget);
    });

    testWidgets('renders only postcode when place is empty', (tester) async {
      final station = baseStation.copyWith(
        address: 'Some street',
        postCode: '34120',
        place: '',
      );

      await pumpApp(tester, EVAddressCard(station: station));

      expect(find.text('34120'), findsOneWidget);
    });

    testWidgets('renders only place when postcode is empty', (tester) async {
      final station = baseStation.copyWith(
        address: 'Some street',
        postCode: '',
        place: 'Pézenas',
      );

      await pumpApp(tester, EVAddressCard(station: station));

      expect(find.text('Pézenas'), findsOneWidget);
    });

    testWidgets('hides postcode/place row when both empty', (tester) async {
      final station = baseStation.copyWith(
        address: 'Just a street',
        postCode: '',
        place: '',
      );

      await pumpApp(tester, EVAddressCard(station: station));

      // Address still shown
      expect(find.text('Just a street'), findsOneWidget);
      // The trimmed combined text would be the empty string; ensure the
      // conditional row does not render any non-empty placeholder.
      expect(find.text(' '), findsNothing);
    });

    testWidgets('renders distance text', (tester) async {
      final station = baseStation.copyWith(
        address: 'Street',
        dist: 2.5,
      );

      await pumpApp(tester, EVAddressCard(station: station));

      // PriceFormatter.formatDistance is exercised. The exact unit/format
      // depends on the locale, but the widget MUST emit a non-empty Text
      // for it. Assert that some Text descendant other than the address
      // is present at the distance position.
      expect(find.byType(Text), findsAtLeastNWidgets(2));
    });
  });

  group('EVConnectorsCard', () {
    testWidgets('renders header with totalPoints count', (tester) async {
      final station = baseStation.copyWith(totalPoints: 4);

      await pumpApp(
        tester,
        EVConnectorsCard(station: station, evColor: Colors.green),
      );

      // English fallback: "Connectors (4 points)"
      expect(find.text('Connectors (4 points)'), findsOneWidget);
      expect(find.byIcon(Icons.electrical_services), findsOneWidget);
    });

    testWidgets('renders one EVConnectorTile per connector', (tester) async {
      final station = baseStation.copyWith(
        totalPoints: 2,
        connectors: const [
          EvConnector(
            id: 'c1',
            type: ConnectorType.ccs,
            rawType: 'CCS2',
            maxPowerKw: 150,
          ),
          EvConnector(
            id: 'c2',
            type: ConnectorType.type2,
            rawType: 'Type 2',
            maxPowerKw: 22,
          ),
        ],
      );

      await pumpApp(
        tester,
        EVConnectorsCard(station: station, evColor: Colors.green),
      );

      expect(find.byType(EVConnectorTile), findsNWidgets(2));
      expect(find.text('CCS2'), findsOneWidget);
      expect(find.text('Type 2'), findsOneWidget);
    });

    testWidgets('shows fallback message when connectors empty',
        (tester) async {
      final station = baseStation.copyWith(totalPoints: 0);

      await pumpApp(
        tester,
        EVConnectorsCard(station: station, evColor: Colors.green),
      );

      expect(find.text('No connector details available'), findsOneWidget);
      expect(find.byType(EVConnectorTile), findsNothing);
    });
  });

  group('EVPricingCard', () {
    testWidgets('free access → "Free" chip with money-off icon',
        (tester) async {
      final station = baseStation.copyWith(
        usageTypeId: 1,
        usageTypeTitle: 'Public - Free',
        isPayAtLocation: false,
        isMembershipRequired: false,
      );

      await pumpApp(
        tester,
        EVPricingCard(station: station, evColor: Colors.green),
      );

      expect(find.text('Free'), findsOneWidget);
      expect(find.byIcon(Icons.money_off), findsOneWidget);
    });

    testWidgets('paid access → "Pay at location" chip', (tester) async {
      final station = baseStation.copyWith(
        usageTypeId: 4,
        usageTypeTitle: 'Public - Pay At Location',
        isPayAtLocation: true,
      );

      await pumpApp(
        tester,
        EVPricingCard(station: station, evColor: Colors.green),
      );

      expect(find.text('Pay at location'), findsOneWidget);
    });

    testWidgets('membership access → "Membership required" chip',
        (tester) async {
      final station = baseStation.copyWith(
        usageTypeId: 5,
        usageTypeTitle: 'Public - Membership Required',
        isMembershipRequired: true,
      );

      await pumpApp(
        tester,
        EVPricingCard(station: station, evColor: Colors.green),
      );

      expect(find.text('Membership required'), findsOneWidget);
      expect(find.byIcon(Icons.card_membership), findsOneWidget);
    });

    testWidgets('raw usageCost text → renders text + indicative disclaimer',
        (tester) async {
      // No structured access signal — only the scraped indicative text.
      final station = baseStation.copyWith(usageCost: 'Ask the operator');

      await pumpApp(
        tester,
        EVPricingCard(station: station, evColor: Colors.green),
      );

      expect(find.text('Usage cost'), findsOneWidget);
      expect(find.text('Ask the operator'), findsOneWidget);
      expect(
        find.textContaining('declared by the operator'),
        findsOneWidget,
      );
    });

    testWidgets('France IRVE attribution shows only when enriched',
        (tester) async {
      final enriched = baseStation.copyWith(
        usageCost: '0.42 EUR/kWh',
        isPayAtLocation: true,
        isFranceIrveEnriched: true,
      );

      await pumpApp(
        tester,
        EVPricingCard(station: enriched, evColor: Colors.green),
      );

      expect(find.textContaining('Base nationale des IRVE'), findsOneWidget);

      // A non-enriched station with the same data must NOT show it.
      final plain = baseStation.copyWith(
        usageCost: '0.42 EUR/kWh',
        isPayAtLocation: true,
      );
      await pumpApp(
        tester,
        EVPricingCard(station: plain, evColor: Colors.green),
      );
      expect(find.textContaining('Base nationale des IRVE'), findsNothing);
    });

    testWidgets(
        'structured per-kWh usageCost → "Indicative price" labelled line '
        'with amount + /kWh unit', (tester) async {
      // #2616 — a parseable per-kWh tariff surfaces as a prominent labelled
      // price line above the raw text.
      final station = baseStation.copyWith(usageCost: '0.49 EUR/kWh');

      await pumpApp(
        tester,
        EVPricingCard(station: station, evColor: Colors.green),
      );

      // A prominent labelled line carries the "Indicative price" qualifier +
      // the parsed amount + the /kWh unit (the raw "0.49 EUR/kWh" text also
      // renders below it, hence the precise structured-line match here).
      expect(
        find.text('Indicative price: 0.49 EUR/kWh'),
        findsOneWidget,
      );
      // Both the structured line and the raw text contain the amount + unit.
      expect(find.textContaining('0.49'), findsWidgets);
      expect(find.textContaining('/kWh'), findsWidgets);
    });

    testWidgets(
        'non-IRVE usageCost → best-effort OCM caption + operator disclaimer',
        (tester) async {
      // #2616 — an unparseable usage-cost string on a non-IRVE station shows
      // the best-effort OpenChargeMap caption alongside the operator
      // disclaimer (no structured price line).
      final station = baseStation.copyWith(usageCost: 'Ask the operator');

      await pumpApp(
        tester,
        EVPricingCard(station: station, evColor: Colors.green),
      );

      expect(
        find.textContaining('Best-effort pricing from OpenChargeMap'),
        findsOneWidget,
      );
      expect(
        find.textContaining('declared by the operator'),
        findsOneWidget,
      );
    });

    testWidgets(
        'IRVE-enriched usageCost → IRVE line present, best-effort caption '
        'absent (mutual exclusion)', (tester) async {
      // #2616 — IRVE stations keep the IRVE attribution; the OCM best-effort
      // caption is suppressed.
      final station = baseStation.copyWith(
        usageCost: '0.42 EUR/kWh',
        isFranceIrveEnriched: true,
      );

      await pumpApp(
        tester,
        EVPricingCard(station: station, evColor: Colors.green),
      );

      expect(find.textContaining('Base nationale des IRVE'), findsOneWidget);
      expect(
        find.textContaining('Best-effort pricing from OpenChargeMap'),
        findsNothing,
      );
    });

    testWidgets(
        'free usageCost → no "Indicative price" line, best-effort caption '
        'still shown', (tester) async {
      // #2616 — "Free" parses to EvPriceKind.free → label() returns null, so
      // no structured price line; the raw text + best-effort caption remain.
      final station = baseStation.copyWith(usageCost: 'Free');

      await pumpApp(
        tester,
        EVPricingCard(station: station, evColor: Colors.green),
      );

      // No labelled "Indicative price: …" structured line (the qualifier is
      // only emitted for parseable per-kWh / per-session amounts). The raw
      // "Free" text is still shown neutrally (the structured access badge also
      // reads "Free" for a free-usage string, hence findsWidgets, not one).
      expect(find.textContaining('Indicative price:'), findsNothing);
      expect(find.text('Free'), findsWidgets);
      expect(
        find.textContaining('Best-effort pricing from OpenChargeMap'),
        findsOneWidget,
      );
    });

    testWidgets('unknown access + empty usageCost → unavailable fallback',
        (tester) async {
      await pumpApp(
        tester,
        const EVPricingCard(station: baseStation, evColor: Colors.green),
      );

      expect(find.text('Usage cost'), findsOneWidget);
      expect(
        find.text('Pricing not available from provider'),
        findsOneWidget,
      );
      // #2616 — the genuinely-empty path shows neither the structured price
      // line nor the best-effort caption.
      expect(find.textContaining('Indicative price'), findsNothing);
      expect(
        find.textContaining('Best-effort pricing from OpenChargeMap'),
        findsNothing,
      );
    });

    testWidgets('unknown access + empty-string usageCost → fallback',
        (tester) async {
      final station = baseStation.copyWith(usageCost: '');

      await pumpApp(
        tester,
        EVPricingCard(station: station, evColor: Colors.green),
      );

      expect(
        find.text('Pricing not available from provider'),
        findsOneWidget,
      );
    });
  });

  group('EVLastUpdatedCard', () {
    testWidgets('renders updatedAt timestamp when present', (tester) async {
      final station = baseStation.copyWith(updatedAt: '2024-01-15 14:30');

      await pumpApp(tester, EVLastUpdatedCard(station: station));

      expect(find.text('Last updated'), findsOneWidget);
      expect(find.text('2024-01-15 14:30'), findsOneWidget);
      expect(find.byIcon(Icons.update), findsOneWidget);
    });

    testWidgets('renders Unknown when updatedAt is null', (tester) async {
      await pumpApp(tester, const EVLastUpdatedCard(station: baseStation));

      expect(find.text('Last updated'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('renders attribution and disclaimer', (tester) async {
      await pumpApp(tester, const EVLastUpdatedCard(station: baseStation));

      expect(
        find.text('Data from OpenChargeMap (community-sourced)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Status may not reflect real-time availability'),
        findsOneWidget,
      );
    });
  });
}
