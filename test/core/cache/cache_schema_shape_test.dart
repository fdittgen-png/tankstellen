// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3619 — THE enforcement behind CacheSchema: every cache codec's
// structural signature (recursive keys + value types, values erased) is
// pinned here TOGETHER with its registered schema version. Changing a
// codec's serialized shape without bumping the matching
// CacheSchema.byPrefix entry fails this test — the discipline that lets
// getFresh stop cold-booting every cache on every app update.
//
// When this test fails after an intentional shape change:
//  1. bump the prefix's version in lib/core/cache/cache_schema.dart;
//  2. update the pinned signature below to the printed actual.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_schema.dart';
import 'package:tankstellen/core/domain/opening_hours.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/station_prices.dart';
import 'package:tankstellen/core/services/location_search_service.dart';
import 'package:tankstellen/core/services/station_service_chain_codec.dart';

import '../../fixtures/stations.dart';

/// Canonical structural signature: keys sorted, value types erased,
/// lists described by their first element. Deterministic for a fixed
/// fixture, insensitive to VALUES — only shape drift changes it.
String shapeOf(dynamic v) {
  if (v == null) return 'null';
  if (v is Map) {
    final keys = v.keys.map((k) => k.toString()).toList()..sort();
    return '{${keys.map((k) => '$k:${shapeOf(v[k])}').join(',')}}';
  }
  if (v is List) return '[${v.isEmpty ? '' : shapeOf(v.first)}]';
  if (v is String) return 'str';
  if (v is bool) return 'bool';
  if (v is int) return 'int';
  if (v is double) return 'double';
  return v.runtimeType.toString();
}

void main() {
  // Deterministic fixtures; fields they leave null pin as `null` — the
  // signature tracks keys and populated types, which is where parser
  // shape drift lives.
  const detail = StationDetail(
    station: testStation,
    openingTimes: [
      OpeningTime(text: 'Mo-Fr', start: '06:00', end: '22:00'),
    ],
    overrides: ['override'],
    wholeDay: false,
    state: 'open',
    openingHours: WeeklyOpeningHours(),
  );
  const prices = StationPrices(
    e5: 1.85,
    e10: 1.79,
    e98: 1.99,
    diesel: 1.65,
    dieselPremium: 1.75,
    e85: 1.10,
    lpg: 0.99,
    cng: 1.09,
    status: 'open',
  );
  const location = ResolvedLocation(
    name: 'Berlin',
    lat: 52.52,
    lng: 13.405,
    postcode: '10115',
    osmId: 240109189,
    importance: 0.9,
    placeRank: 15,
    addressType: 'city',
    country: 'DE',
  );

  // prefix → (version, codec sample). The geo shapes are inline literals
  // in geocoding_chain.dart (three sub-shapes under one prefix) — pinned
  // here as literals; keep them in sync with that file.
  final codecs = <String, ({int version, Map<String, dynamic> sample})>{
    'search': (
      version: CacheSchema.byPrefix['search']!,
      sample: serializeStationList([testStation]),
    ),
    'station': (
      version: CacheSchema.byPrefix['station']!,
      sample: serializeStationList([testStation]),
    ),
    'dataset': (
      version: CacheSchema.byPrefix['dataset']!,
      sample: serializeStationList([testStation]),
    ),
    'detail': (
      version: CacheSchema.byPrefix['detail']!,
      sample: serializeStationDetail(detail),
    ),
    'prices': (
      version: CacheSchema.byPrefix['prices']!,
      sample: serializePrices({'id-1': prices}),
    ),
    'geo': (
      version: CacheSchema.byPrefix['geo']!,
      sample: {
        'zip': {'lat': 52.52, 'lng': 13.405},
        'revAddress': {'address': 'Hauptstr. 12'},
        'revCountry': {'countryCode': 'DE'},
      },
    ),
    'city': (
      version: CacheSchema.byPrefix['city']!,
      sample: serializeLocations(const [location]),
    ),
  };

  /// The pinned (version, signature) pairs. A mismatch means the codec's
  /// shape drifted: bump CacheSchema.byPrefix AND update the pin here.
  const pins = <String, ({int version, String shape})>{
    'search': (version: 1, shape: _stationListShape),
    'station': (version: 1, shape: _stationListShape),
    'dataset': (version: 1, shape: _stationListShape),
    'detail': (version: 1, shape: _detailShape),
    'prices': (version: 1, shape: _pricesShape),
    'geo': (version: 1, shape: _geoShape),
    'city': (version: 1, shape: _cityShape),
  };

  test('every CacheSchema prefix is pinned and vice versa', () {
    expect(codecs.keys.toSet(), CacheSchema.byPrefix.keys.toSet());
    expect(pins.keys.toSet(), CacheSchema.byPrefix.keys.toSet());
  });

  for (final entry in codecs.entries) {
    test('${entry.key}: codec shape matches its registered schema version',
        () {
      final pin = pins[entry.key]!;
      expect(entry.value.version, pin.version,
          reason: 'CacheSchema.byPrefix["${entry.key}"] drifted from the '
              'pinned version without updating this test');
      final actual = shapeOf(entry.value.sample);
      expect(actual, pin.shape,
          reason: 'The ${entry.key} codec\'s serialized SHAPE changed. If '
              'intentional: bump CacheSchema.byPrefix["${entry.key}"] and '
              're-pin. Actual signature:\n$actual');
    });
  }
}

// Pinned structural signatures (see shapeOf). Nullable fields the
// fixture leaves unset print as `null` — key ADDS/REMOVES/RENAMES are
// the drift this pin exists to catch.
const _stationListShape = '{stations:[{amenities:[],availableFuels:[],brand:str,cng:null,department:null,diesel:double,dieselPremium:null,dist:double,e10:double,e5:double,e85:null,e98:null,houseNumber:str,id:str,is24h:bool,isOpen:bool,lat:double,lng:double,lpg:null,name:str,openingHours:null,openingHoursText:null,place:str,postCode:str,region:null,services:[],stationType:null,street:str,unavailableFuels:[],updatedAt:str}]}';
const _detailShape =
    '{openingHours:{automate24h:bool,availability:str,days:[],'
    'rawSource:null},openingTimes:[{end:str,start:str,text:str}],'
    'overrides:[str],state:str,station:{amenities:[],availableFuels:[],brand:str,cng:null,department:null,diesel:double,dieselPremium:null,dist:double,e10:double,e5:double,e85:null,e98:null,houseNumber:str,id:str,is24h:bool,isOpen:bool,lat:double,lng:double,lpg:null,name:str,openingHours:null,openingHoursText:null,place:str,postCode:str,region:null,services:[],stationType:null,street:str,unavailableFuels:[],updatedAt:str},wholeDay:bool}';
const _pricesShape =
    '{prices:{id-1:{cng:double,diesel:double,dieselPremium:double,'
    'e10:double,e5:double,e85:double,e98:double,lpg:double,'
    'status:str}}}';
const _geoShape = '{revAddress:{address:str},'
    'revCountry:{countryCode:str},zip:{lat:double,lng:double}}';
const _cityShape = '{locations:[{addressType:str,country:str,'
    'importance:double,lat:double,lng:double,name:str,osmId:int,'
    'placeRank:int,postcode:str}]}';
