// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'expense_fields.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExtractedReceiptFields _$ExtractedReceiptFieldsFromJson(
  Map<String, dynamic> json,
) => _ExtractedReceiptFields(
  stationName: json['stationName'] as String?,
  occurredAt: json['occurredAt'] == null
      ? null
      : DateTime.parse(json['occurredAt'] as String),
  fuelApiValue: json['fuelApiValue'] as String?,
  litres: (json['litres'] as num?)?.toDouble(),
  pricePerLitre: (json['pricePerLitre'] as num?)?.toDouble(),
  total: json['total'] == null
      ? null
      : Money.fromJson(json['total'] as Map<String, dynamic>),
  vat: json['vat'] == null
      ? null
      : Money.fromJson(json['vat'] as Map<String, dynamic>),
  vatRate: (json['vatRate'] as num?)?.toDouble(),
  paymentReference: json['paymentReference'] as String?,
  odometerKm: (json['odometerKm'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ExtractedReceiptFieldsToJson(
  _ExtractedReceiptFields instance,
) => <String, dynamic>{
  'stationName': instance.stationName,
  'occurredAt': instance.occurredAt?.toIso8601String(),
  'fuelApiValue': instance.fuelApiValue,
  'litres': instance.litres,
  'pricePerLitre': instance.pricePerLitre,
  'total': instance.total?.toJson(),
  'vat': instance.vat?.toJson(),
  'vatRate': instance.vatRate,
  'paymentReference': instance.paymentReference,
  'odometerKm': instance.odometerKm,
};

_FieldCorrection _$FieldCorrectionFromJson(Map<String, dynamic> json) =>
    _FieldCorrection(
      field: json['field'] as String,
      before: json['before'] as String?,
      after: json['after'] as String?,
      correctedAt: DateTime.parse(json['correctedAt'] as String),
      correctedBy: json['correctedBy'] as String,
    );

Map<String, dynamic> _$FieldCorrectionToJson(_FieldCorrection instance) =>
    <String, dynamic>{
      'field': instance.field,
      'before': instance.before,
      'after': instance.after,
      'correctedAt': instance.correctedAt.toIso8601String(),
      'correctedBy': instance.correctedBy,
    };
