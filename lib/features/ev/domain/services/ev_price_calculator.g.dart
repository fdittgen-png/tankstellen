// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ev_price_calculator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChargingCostBreakdown _$ChargingCostBreakdownFromJson(
  Map<String, dynamic> json,
) => _ChargingCostBreakdown(
  totalCost: (json['totalCost'] as num).toDouble(),
  energyCost: (json['energyCost'] as num?)?.toDouble() ?? 0,
  timeCost: (json['timeCost'] as num?)?.toDouble() ?? 0,
  flatFee: (json['flatFee'] as num?)?.toDouble() ?? 0,
  parkingCost: (json['parkingCost'] as num?)?.toDouble() ?? 0,
  blockingCost: (json['blockingCost'] as num?)?.toDouble() ?? 0,
  kwhDelivered: (json['kwhDelivered'] as num?)?.toDouble() ?? 0,
  currency: json['currency'] as String? ?? 'EUR',
);

Map<String, dynamic> _$ChargingCostBreakdownToJson(
  _ChargingCostBreakdown instance,
) => <String, dynamic>{
  'totalCost': instance.totalCost,
  'energyCost': instance.energyCost,
  'timeCost': instance.timeCost,
  'flatFee': instance.flatFee,
  'parkingCost': instance.parkingCost,
  'blockingCost': instance.blockingCost,
  'kwhDelivered': instance.kwhDelivered,
  'currency': instance.currency,
};

_TariffComparisonEntry _$TariffComparisonEntryFromJson(
  Map<String, dynamic> json,
) => _TariffComparisonEntry(
  tariffId: json['tariffId'] as String,
  totalCost: (json['totalCost'] as num).toDouble(),
  currency: json['currency'] as String,
);

Map<String, dynamic> _$TariffComparisonEntryToJson(
  _TariffComparisonEntry instance,
) => <String, dynamic>{
  'tariffId': instance.tariffId,
  'totalCost': instance.totalCost,
  'currency': instance.currency,
};
