// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'station.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Station _$StationFromJson(Map<String, dynamic> json) => _Station(
  id: json['id'] as String,
  name: json['name'] as String,
  brand: json['brand'] as String,
  street: json['street'] as String,
  houseNumber: json['houseNumber'] as String?,
  postCode: _postCodeToString(json['postCode']),
  place: json['place'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  dist: (json['dist'] as num?)?.toDouble() ?? 0,
  e5: _priceFromJson(json['e5']),
  e10: _priceFromJson(json['e10']),
  e98: _priceFromJson(json['e98']),
  diesel: _priceFromJson(json['diesel']),
  dieselPremium: _priceFromJson(json['dieselPremium']),
  e85: _priceFromJson(json['e85']),
  lpg: _priceFromJson(json['lpg']),
  cng: _priceFromJson(json['cng']),
  isOpen: json['isOpen'] as bool,
  updatedAt: json['updatedAt'] as String?,
  openingHoursText: json['openingHoursText'] as String?,
  is24h: json['is24h'] as bool? ?? false,
  services:
      (json['services'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  availableFuels:
      (json['availableFuels'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  unavailableFuels:
      (json['unavailableFuels'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  stationType: json['stationType'] as String?,
  department: json['department'] as String?,
  region: json['region'] as String?,
);

Map<String, dynamic> _$StationToJson(_Station instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'brand': instance.brand,
  'street': instance.street,
  'houseNumber': instance.houseNumber,
  'postCode': instance.postCode,
  'place': instance.place,
  'lat': instance.lat,
  'lng': instance.lng,
  'dist': instance.dist,
  'e5': instance.e5,
  'e10': instance.e10,
  'e98': instance.e98,
  'diesel': instance.diesel,
  'dieselPremium': instance.dieselPremium,
  'e85': instance.e85,
  'lpg': instance.lpg,
  'cng': instance.cng,
  'isOpen': instance.isOpen,
  'updatedAt': instance.updatedAt,
  'openingHoursText': instance.openingHoursText,
  'is24h': instance.is24h,
  'services': instance.services,
  'availableFuels': instance.availableFuels,
  'unavailableFuels': instance.unavailableFuels,
  'stationType': instance.stationType,
  'department': instance.department,
  'region': instance.region,
};

_OpeningTime _$OpeningTimeFromJson(Map<String, dynamic> json) => _OpeningTime(
  text: json['text'] as String,
  start: json['start'] as String,
  end: json['end'] as String,
);

Map<String, dynamic> _$OpeningTimeToJson(_OpeningTime instance) =>
    <String, dynamic>{
      'text': instance.text,
      'start': instance.start,
      'end': instance.end,
    };
