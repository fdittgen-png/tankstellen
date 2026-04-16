import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

/// Canonical EV test station. ID uses the `ocm-` prefix so that
/// [Favorites.toggle] routes it to EV storage (not fuel storage).
const testEvStation = ChargingStation(
  id: 'ocm-test-1',
  name: 'Test Fast Charger',
  operator: 'Ionity',
  latitude: 52.5200,
  longitude: 13.4050,
  address: 'Unter den Linden 1, 10117 Berlin',
  connectors: [
    EvConnector(
      id: 'ocm-test-1-c1',
      type: ConnectorType.ccs,
      maxPowerKw: 350,
      status: ConnectorStatus.available,
    ),
    EvConnector(
      id: 'ocm-test-1-c2',
      type: ConnectorType.type2,
      maxPowerKw: 22,
      status: ConnectorStatus.occupied,
    ),
  ],
);

const testEvStationMinimal = ChargingStation(
  id: 'ocm-test-minimal',
  name: 'Minimal Charger',
  latitude: 48.8566,
  longitude: 2.3522,
);
