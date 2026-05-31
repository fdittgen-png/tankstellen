// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_connector_tile.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;
import 'package:tankstellen/l10n/app_localizations_en.dart';
import 'package:tankstellen/l10n/app_localizations_de.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('EVConnectorTile', () {
    testWidgets('renders connector type, power, current type, qty and status', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const EVConnectorTile(
          connector: EvConnector(
            id: 'c1',
            type: ConnectorType.ccs,
            rawType: 'CCS2',
            maxPowerKw: 150,
            currentType: 'DC',
            quantity: 2,
            status: ConnectorStatus.available,
            statusLabel: 'Operational',
          ),
        ),
      );

      expect(find.text('CCS2'), findsOneWidget);
      expect(find.text('150 kW'), findsOneWidget);
      expect(find.text('DC'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
      // #2493 — the status chip now shows the LOCALISED label for the
      // canonical enum, not the upstream free-form English string. With an
      // `available` status the en label is "Available", regardless of what
      // the upstream `statusLabel` happened to read.
      expect(find.text(AppLocalizationsEn().evStatusAvailable), findsOneWidget);
      expect(find.text('Operational'), findsNothing);
    });

    testWidgets(
      'renders without status when the connector has no statusLabel',
      (tester) async {
        await pumpApp(
          tester,
          const EVConnectorTile(
            connector: EvConnector(
              id: 'c2',
              type: ConnectorType.type2,
              rawType: 'Type 2',
              maxPowerKw: 22,
              quantity: 1,
            ),
          ),
        );

        expect(find.text('Type 2'), findsOneWidget);
        expect(find.text('22 kW'), findsOneWidget);
        // No statusLabel + unknown status ⇒ no status chip at all.
        expect(find.text(AppLocalizationsEn().evStatusUnknown), findsNothing);
      },
    );

    testWidgets(
      'resolves status by ENUM (not English string) in a non-English locale',
      (tester) async {
        // #2493 — the regression this issue fixes: status used to be driven
        // off hardcoded English string-equality, so in German (and the other
        // 21 locales) the operational scale silently vanished. Here the
        // upstream label is German and the status enum is `available`; the
        // chip must still render, localised into German.
        await pumpApp(
          tester,
          const EVConnectorTile(
            connector: EvConnector(
              id: 'c3',
              type: ConnectorType.ccs,
              rawType: 'CCS2',
              maxPowerKw: 150,
              status: ConnectorStatus.available,
              statusLabel: 'Verfügbar',
            ),
          ),
          locale: const Locale('de'),
        );

        expect(
          find.text(AppLocalizationsDe().evStatusAvailable),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders the partial status with its localised label', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const EVConnectorTile(
          connector: EvConnector(
            id: 'c4',
            type: ConnectorType.ccs,
            rawType: 'CCS2',
            maxPowerKw: 150,
            status: ConnectorStatus.partial,
            statusLabel: 'Partly Operational',
          ),
        ),
      );

      expect(find.text(AppLocalizationsEn().evStatusPartial), findsOneWidget);
    });
  });
}
