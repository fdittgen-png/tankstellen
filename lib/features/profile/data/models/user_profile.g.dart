// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: json['id'] as String,
  name: json['name'] as String,
  preferredFuelType:
      $enumDecodeNullable(_$FuelTypeEnumMap, json['preferredFuelType']) ??
      FuelType.e10,
  defaultSearchRadius:
      (json['defaultSearchRadius'] as num?)?.toDouble() ?? 10.0,
  landingScreen:
      $enumDecodeNullable(_$LandingScreenEnumMap, json['landingScreen']) ??
      LandingScreen.search,
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
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'preferredFuelType': _$FuelTypeEnumMap[instance.preferredFuelType]!,
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
    };

const _$FuelTypeEnumMap = {
  FuelType.e5: 'e5',
  FuelType.e10: 'e10',
  FuelType.e98: 'e98',
  FuelType.diesel: 'diesel',
  FuelType.dieselPremium: 'dieselPremium',
  FuelType.e85: 'e85',
  FuelType.lpg: 'lpg',
  FuelType.cng: 'cng',
  FuelType.hydrogen: 'hydrogen',
  FuelType.electric: 'electric',
  FuelType.all: 'all',
};

const _$LandingScreenEnumMap = {
  LandingScreen.search: 'search',
  LandingScreen.favorites: 'favorites',
  LandingScreen.map: 'map',
  LandingScreen.cheapest: 'cheapest',
};
