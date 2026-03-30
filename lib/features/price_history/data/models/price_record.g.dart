// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PriceRecord _$PriceRecordFromJson(Map<String, dynamic> json) => _PriceRecord(
  stationId: json['stationId'] as String,
  recordedAt: DateTime.parse(json['recordedAt'] as String),
  e5: (json['e5'] as num?)?.toDouble(),
  e10: (json['e10'] as num?)?.toDouble(),
  e98: (json['e98'] as num?)?.toDouble(),
  diesel: (json['diesel'] as num?)?.toDouble(),
  dieselPremium: (json['dieselPremium'] as num?)?.toDouble(),
  e85: (json['e85'] as num?)?.toDouble(),
  lpg: (json['lpg'] as num?)?.toDouble(),
  cng: (json['cng'] as num?)?.toDouble(),
);

Map<String, dynamic> _$PriceRecordToJson(_PriceRecord instance) =>
    <String, dynamic>{
      'stationId': instance.stationId,
      'recordedAt': instance.recordedAt.toIso8601String(),
      'e5': instance.e5,
      'e10': instance.e10,
      'e98': instance.e98,
      'diesel': instance.diesel,
      'dieselPremium': instance.dieselPremium,
      'e85': instance.e85,
      'lpg': instance.lpg,
      'cng': instance.cng,
    };
