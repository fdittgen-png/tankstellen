import 'package:tankstellen/features/search/domain/entities/charging_station.dart';

const testChargingStation = ChargingStation(
  id: 'ocm-12345',
  name: 'Test EV Station',
  operator: 'Ionity',
  lat: 52.5200,
  lng: 13.4050,
  dist: 2.5,
  address: 'Unter den Linden 1',
  postCode: '10117',
  place: 'Berlin',
  connectors: [
    Connector(type: 'CCS Type 2', powerKW: 350, quantity: 4, currentType: 'DC', status: 'Available'),
    Connector(type: 'Type 2', powerKW: 22, quantity: 2, currentType: 'AC'),
    Connector(type: 'CHAdeMO', powerKW: 50, quantity: 1, currentType: 'DC'),
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
  lat: 48.8566,
  lng: 2.3522,
  address: '',
  connectors: [],
);

final testChargingStationList = [
  testChargingStation,
  testChargingStation.copyWith(id: 'ocm-2', operator: 'Tesla', dist: 5.0),
  testChargingStation.copyWith(id: 'ocm-3', operator: 'EnBW', dist: 8.2),
];
