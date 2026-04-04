import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_connector_tile.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('EVConnectorTile', () {
    testWidgets('renders connector type and power', (tester) async {
      await pumpApp(
        tester,
        const EVConnectorTile(
          connector: Connector(
            type: 'CCS2',
            powerKW: 150.0,
            currentType: 'DC',
            quantity: 2,
            status: 'Operational',
          ),
        ),
      );

      expect(find.text('CCS2'), findsOneWidget);
      expect(find.text('150 kW'), findsOneWidget);
      expect(find.text('DC'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
      expect(find.text('Operational'), findsOneWidget);
    });

    testWidgets('renders without status when null', (tester) async {
      await pumpApp(
        tester,
        const EVConnectorTile(
          connector: Connector(
            type: 'Type 2',
            powerKW: 22.0,
            quantity: 1,
          ),
        ),
      );

      expect(find.text('Type 2'), findsOneWidget);
      expect(find.text('22 kW'), findsOneWidget);
    });
  });
}
