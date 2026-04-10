import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/ev/presentation/widgets/ev_marker_widget.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

import '../../../helpers/pump_app.dart';

void main() {
  group('EvMarkerWidget', () {
    const availableStation = ChargingStation(
      id: 'a',
      name: 'Available',
      latitude: 0,
      longitude: 0,
      connectors: [
        EvConnector(
          id: 'a1',
          type: ConnectorType.ccs,
          maxPowerKw: 50,
          status: ConnectorStatus.available,
        ),
      ],
    );

    const occupiedStation = ChargingStation(
      id: 'b',
      name: 'Occupied',
      latitude: 0,
      longitude: 0,
      connectors: [
        EvConnector(
          id: 'b1',
          type: ConnectorType.ccs,
          maxPowerKw: 50,
          status: ConnectorStatus.occupied,
        ),
      ],
    );

    const unknownStation = ChargingStation(
      id: 'c',
      name: 'Unknown',
      latitude: 0,
      longitude: 0,
      connectors: [
        EvConnector(
          id: 'c1',
          type: ConnectorType.type2,
          maxPowerKw: 22,
        ),
      ],
    );

    test('colorFor returns green for available, red for occupied,'
        ' grey for unknown', () {
      expect(EvMarkerWidget.colorFor(availableStation), Colors.green);
      expect(EvMarkerWidget.colorFor(occupiedStation), Colors.red);
      expect(EvMarkerWidget.colorFor(unknownStation), Colors.grey);
    });

    testWidgets('renders an ev_station icon and responds to tap',
        (tester) async {
      var tapped = 0;
      await pumpApp(
        tester,
        EvMarkerWidget(
          station: availableStation,
          onTap: () => tapped++,
        ),
      );

      expect(find.byIcon(Icons.ev_station), findsOneWidget);
      await tester.tap(find.byIcon(Icons.ev_station));
      expect(tapped, 1);
    });

    test('buildMarker returns a Marker anchored at station coordinates', () {
      final marker = EvMarkerWidget.buildMarker(
        const ChargingStation(
          id: 'x',
          name: 'X',
          latitude: 48.1,
          longitude: 2.5,
        ),
      );
      expect(marker.point.latitude, 48.1);
      expect(marker.point.longitude, 2.5);
      expect(marker.width, 44);
      expect(marker.height, 44);
    });
  });
}
