// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: json['id'] as String,
  name: json['name'] as String,
  preferredFuelType: json['preferredFuelType'] == null
      ? FuelType.e10
      : const FuelTypeJsonConverter().fromJson(
          json['preferredFuelType'] as String,
        ),
  defaultSearchRadius:
      (json['defaultSearchRadius'] as num?)?.toDouble() ?? 10.0,
  landingScreen:
      $enumDecodeNullable(_$LandingScreenEnumMap, json['landingScreen']) ??
      LandingScreen.nearest,
  favoriteStationIds:
      (json['favoriteStationIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  homeZipCode: json['homeZipCode'] as String?,
  autoUpdatePosition: json['autoUpdatePosition'] as bool? ?? false,
  countryCode: json['countryCode'] as String?,
  languageCode: json['languageCode'] as String?,
  routeSegmentKm: (json['routeSegmentKm'] as num?)?.toDouble() ?? 50.0,
  avoidHighways: json['avoidHighways'] as bool? ?? false,
  showFuel: json['showFuel'] as bool? ?? true,
  showElectric: json['showElectric'] as bool? ?? true,
  ratingMode: json['ratingMode'] as String? ?? 'local',
  preferredAmenities:
      (json['preferredAmenities'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$StationAmenityEnumMap, e))
          .toList() ??
      const [],
  defaultVehicleId: json['defaultVehicleId'] as String?,
  hybridFuelChoice: _$JsonConverterFromJson<String, FuelType>(
    json['hybridFuelChoice'],
    const FuelTypeJsonConverter().fromJson,
  ),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'preferredFuelType': const FuelTypeJsonConverter().toJson(
        instance.preferredFuelType,
      ),
      'defaultSearchRadius': instance.defaultSearchRadius,
      'landingScreen': _$LandingScreenEnumMap[instance.landingScreen]!,
      'favoriteStationIds': instance.favoriteStationIds,
      'homeZipCode': instance.homeZipCode,
      'autoUpdatePosition': instance.autoUpdatePosition,
      'countryCode': instance.countryCode,
      'languageCode': instance.languageCode,
      'routeSegmentKm': instance.routeSegmentKm,
      'avoidHighways': instance.avoidHighways,
      'showFuel': instance.showFuel,
      'showElectric': instance.showElectric,
      'ratingMode': instance.ratingMode,
      'preferredAmenities': instance.preferredAmenities
          .map((e) => _$StationAmenityEnumMap[e]!)
          .toList(),
      'defaultVehicleId': instance.defaultVehicleId,
      'hybridFuelChoice': _$JsonConverterToJson<String, FuelType>(
        instance.hybridFuelChoice,
        const FuelTypeJsonConverter().toJson,
      ),
    };

const _$LandingScreenEnumMap = {
  LandingScreen.favorites: 'favorites',
  LandingScreen.map: 'map',
  LandingScreen.cheapest: 'cheapest',
  LandingScreen.nearest: 'nearest',
};

const _$StationAmenityEnumMap = {
  StationAmenity.shop: 'shop',
  StationAmenity.carWash: 'carWash',
  StationAmenity.airPump: 'airPump',
  StationAmenity.toilet: 'toilet',
  StationAmenity.restaurant: 'restaurant',
  StationAmenity.atm: 'atm',
  StationAmenity.wifi: 'wifi',
  StationAmenity.ev: 'ev',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
