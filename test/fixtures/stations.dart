import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// A basic station with all fields filled.
const testStation = Station(
  id: '51d4b477-a095-1aa0-e100-80009459e03a',
  name: 'Star Tankstelle',
  brand: 'STAR',
  street: 'Hauptstr.',
  houseNumber: '12',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.5200,
  lng: 13.4050,
  dist: 1.5,
  e5: 1.859,
  e10: 1.799,
  diesel: 1.659,
  isOpen: true,
  updatedAt: '2026-03-27T10:00:00+01:00',
);

/// Three stations with different prices, useful for sorting tests.
final testStationList = <Station>[
  const Station(
    id: 'station-cheap',
    name: 'Günstig Tanken',
    brand: 'JET',
    street: 'Berliner Str.',
    houseNumber: '1',
    postCode: '10178',
    place: 'Berlin',
    lat: 52.5210,
    lng: 13.4100,
    dist: 0.8,
    e5: 1.799,
    e10: 1.739,
    diesel: 1.599,
    isOpen: true,
  ),
  const Station(
    id: 'station-mid',
    name: 'Mittel Tankstelle',
    brand: 'ARAL',
    street: 'Friedrichstr.',
    houseNumber: '55',
    postCode: '10117',
    place: 'Berlin',
    lat: 52.5190,
    lng: 13.3880,
    dist: 2.3,
    e5: 1.859,
    e10: 1.799,
    diesel: 1.659,
    isOpen: true,
  ),
  const Station(
    id: 'station-expensive',
    name: 'Premium Fuel',
    brand: 'SHELL',
    street: 'Kurfürstendamm',
    houseNumber: '100',
    postCode: '10711',
    place: 'Berlin',
    lat: 52.5030,
    lng: 13.3270,
    dist: 5.1,
    e5: 1.919,
    e10: 1.859,
    diesel: 1.719,
    isOpen: false,
  ),
];

/// A StationDetail wrapping testStation.
const testStationDetail = StationDetail(
  station: testStation,
  openingTimes: [
    OpeningTime(text: 'Mo-Fr', start: '06:00', end: '22:00'),
    OpeningTime(text: 'Sa', start: '07:00', end: '22:00'),
    OpeningTime(text: 'So', start: '08:00', end: '20:00'),
  ],
  wholeDay: false,
  state: 'Berlin',
);

/// Default SearchParams for GPS-based search.
const testSearchParams = SearchParams(
  lat: 52.5200,
  lng: 13.4050,
  radiusKm: 10.0,
  fuelType: FuelType.all,
  sortBy: SortBy.price,
);
