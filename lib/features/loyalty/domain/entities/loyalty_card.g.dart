// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LoyaltyCard _$LoyaltyCardFromJson(Map<String, dynamic> json) => _LoyaltyCard(
  id: json['id'] as String,
  brand: $enumDecode(_$LoyaltyBrandEnumMap, json['brand']),
  discountPerLiter: (json['discountPerLiter'] as num).toDouble(),
  label: json['label'] as String,
  addedAt: DateTime.parse(json['addedAt'] as String),
  enabled: json['enabled'] as bool? ?? true,
);

Map<String, dynamic> _$LoyaltyCardToJson(_LoyaltyCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'brand': _$LoyaltyBrandEnumMap[instance.brand]!,
      'discountPerLiter': instance.discountPerLiter,
      'label': instance.label,
      'addedAt': instance.addedAt.toIso8601String(),
      'enabled': instance.enabled,
    };

const _$LoyaltyBrandEnumMap = {
  LoyaltyBrand.totalEnergies: 'totalEnergies',
  LoyaltyBrand.aral: 'aral',
  LoyaltyBrand.shell: 'shell',
  LoyaltyBrand.bp: 'bp',
  LoyaltyBrand.esso: 'esso',
};
