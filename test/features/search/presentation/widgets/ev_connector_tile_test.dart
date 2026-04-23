import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_connector_tile.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

import '../../../../helpers/pump_app.dart';

void main() {
  group('EVConnectorTile', () {
    testWidgets('renders connector type, power, current type, qty and status',
        (tester) async {
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
      expect(find.text('Operational'), findsOneWidget);
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
    });
  });
}
