// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'document_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DocumentMeta _$DocumentMetaFromJson(Map<String, dynamic> json) =>
    _DocumentMeta(
      id: json['id'] as String,
      orgId: json['orgId'] as String,
      ownerId: json['ownerId'] as String,
      type: $enumDecode(_$FleetDocumentTypeEnumMap, json['type']),
      objectKey: json['objectKey'] as String,
      sha256: json['sha256'] as String,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      ocrEngine: json['ocrEngine'] as String?,
      ocrVersion: json['ocrVersion'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      retentionClass:
          $enumDecodeNullable(
            _$DocumentRetentionClassEnumMap,
            json['retentionClass'],
          ) ??
          DocumentRetentionClass.userManaged,
      deletionStatus:
          $enumDecodeNullable(
            _$DocumentDeletionStatusEnumMap,
            json['deletionStatus'],
          ) ??
          DocumentDeletionStatus.active,
    );

Map<String, dynamic> _$DocumentMetaToJson(
  _DocumentMeta instance,
) => <String, dynamic>{
  'id': instance.id,
  'orgId': instance.orgId,
  'ownerId': instance.ownerId,
  'type': _$FleetDocumentTypeEnumMap[instance.type]!,
  'objectKey': instance.objectKey,
  'sha256': instance.sha256,
  'capturedAt': instance.capturedAt.toIso8601String(),
  'ocrEngine': instance.ocrEngine,
  'ocrVersion': instance.ocrVersion,
  'confidence': instance.confidence,
  'retentionClass': _$DocumentRetentionClassEnumMap[instance.retentionClass]!,
  'deletionStatus': _$DocumentDeletionStatusEnumMap[instance.deletionStatus]!,
};

const _$FleetDocumentTypeEnumMap = {
  FleetDocumentType.receiptPhoto: 'receiptPhoto',
  FleetDocumentType.receiptPdf: 'receiptPdf',
  FleetDocumentType.eReceiptText: 'eReceiptText',
  FleetDocumentType.structuredInvoice: 'structuredInvoice',
};

const _$DocumentRetentionClassEnumMap = {
  DocumentRetentionClass.accountingDocument: 'accountingDocument',
  DocumentRetentionClass.attributionEvidence: 'attributionEvidence',
  DocumentRetentionClass.userManaged: 'userManaged',
};

const _$DocumentDeletionStatusEnumMap = {
  DocumentDeletionStatus.active: 'active',
  DocumentDeletionStatus.pendingDeletion: 'pendingDeletion',
  DocumentDeletionStatus.deleted: 'deleted',
};
