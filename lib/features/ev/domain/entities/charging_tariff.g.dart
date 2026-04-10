// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charging_tariff.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TariffComponent _$TariffComponentFromJson(Map<String, dynamic> json) =>
    _TariffComponent(
      type: json['type'] == null
          ? PriceComponentType.energy
          : const PriceComponentTypeJsonConverter().fromJson(
              json['type'] as String,
            ),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stepSize: (json['stepSize'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$TariffComponentToJson(_TariffComponent instance) =>
    <String, dynamic>{
      'type': const PriceComponentTypeJsonConverter().toJson(instance.type),
      'price': instance.price,
      'stepSize': instance.stepSize,
    };

_TariffRestriction _$TariffRestrictionFromJson(Map<String, dynamic> json) =>
    _TariffRestriction(
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      daysOfWeek:
          (json['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      minKwh: (json['minKwh'] as num?)?.toDouble(),
      maxKwh: (json['maxKwh'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TariffRestrictionToJson(_TariffRestriction instance) =>
    <String, dynamic>{
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'daysOfWeek': instance.daysOfWeek,
      'minKwh': instance.minKwh,
      'maxKwh': instance.maxKwh,
    };

_TariffElement _$TariffElementFromJson(Map<String, dynamic> json) =>
    _TariffElement(
      priceComponents: json['priceComponents'] == null
          ? const <TariffComponent>[]
          : const TariffComponentListConverter().fromJson(
              json['priceComponents'] as List,
            ),
      restrictions: const TariffRestrictionNullableConverter().fromJson(
        json['restrictions'] as Map<String, dynamic>?,
      ),
    );

Map<String, dynamic> _$TariffElementToJson(_TariffElement instance) =>
    <String, dynamic>{
      'priceComponents': const TariffComponentListConverter().toJson(
        instance.priceComponents,
      ),
      'restrictions': const TariffRestrictionNullableConverter().toJson(
        instance.restrictions,
      ),
    };

_ChargingTariff _$ChargingTariffFromJson(Map<String, dynamic> json) =>
    _ChargingTariff(
      id: json['id'] as String,
      currency: json['currency'] as String? ?? 'EUR',
      type: json['type'] == null
          ? TariffType.regular
          : const TariffTypeJsonConverter().fromJson(json['type'] as String),
      elements: json['elements'] == null
          ? const <TariffElement>[]
          : const TariffElementListConverter().fromJson(
              json['elements'] as List,
            ),
      validFrom: json['validFrom'] == null
          ? null
          : DateTime.parse(json['validFrom'] as String),
      validTo: json['validTo'] == null
          ? null
          : DateTime.parse(json['validTo'] as String),
    );

Map<String, dynamic> _$ChargingTariffToJson(_ChargingTariff instance) =>
    <String, dynamic>{
      'id': instance.id,
      'currency': instance.currency,
      'type': const TariffTypeJsonConverter().toJson(instance.type),
      'elements': const TariffElementListConverter().toJson(instance.elements),
      'validFrom': instance.validFrom?.toIso8601String(),
      'validTo': instance.validTo?.toIso8601String(),
    };
