import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

/// Canonical test ChargingStation after #560 consolidation. Uses the
/// OCM-prefixed id so [Favorites.toggle] routes it to EV storage.
///
/// Kept alongside [testEvStation] in `ev_stations.dart` — both point at
/// the same unified type; this one ships richer OCM-style connector
/// metadata for widgets that exercise `rawType` / `quantity` /
/// `currentType` / `statusLabel`.
const testChargingStation = ChargingStation(
  id: 'ocm-12345',
  name: 'Test EV Station',
  operator: 'Ionity',
  latitude: 52.5200,
  longitude: 13.4050,
  dist: 2.5,
  address: 'Unter den Linden 1',
  postCode: '10117',
  place: 'Berlin',
  connectors: [
    EvConnector(
      id: 'ocm-12345-c1',
      type: ConnectorType.ccs,
      rawType: 'CCS Type 2',
      maxPowerKw: 350,
      quantity: 4,
      currentType: 'DC',
      status: ConnectorStatus.available,
      statusLabel: 'Available',
    ),
    EvConnector(
      id: 'ocm-12345-c2',
      type: ConnectorType.type2,
      rawType: 'Type 2',
      maxPowerKw: 22,
      quantity: 2,
      currentType: 'AC',
    ),
    EvConnector(
      id: 'ocm-12345-c3',
      type: ConnectorType.chademo,
      rawType: 'CHAdeMO',
      maxPowerKw: 50,
      quantity: 1,
      currentType: 'DC',
    ),
  ],
  totalPoints: 7,
  isOperational: true,
  usageCost: '0.39 EUR/kWh',
  updatedAt: '27/03/2026',
  countryCode: 'DE',
);

const testChargingStationMinimal = ChargingStation(
  id: 'ocm-99',
  name: 'Minimal Station',
  operator: '',
  latitude: 48.8566,
  longitude: 2.3522,
  address: '',
  connectors: [],
);

final testChargingStationList = [
  testChargingStation,
  testChargingStation.copyWith(id: 'ocm-2', operator: 'Tesla', dist: 5.0),
  testChargingStation.copyWith(id: 'ocm-3', operator: 'EnBW', dist: 8.2),
];
