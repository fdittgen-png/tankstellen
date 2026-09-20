// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExpenseTransition _$ExpenseTransitionFromJson(Map<String, dynamic> json) =>
    _ExpenseTransition(
      from: $enumDecode(_$ExpenseStatusEnumMap, json['from']),
      to: $enumDecode(_$ExpenseStatusEnumMap, json['to']),
      at: DateTime.parse(json['at'] as String),
      byUserId: json['byUserId'] as String,
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$ExpenseTransitionToJson(_ExpenseTransition instance) =>
    <String, dynamic>{
      'from': _$ExpenseStatusEnumMap[instance.from]!,
      'to': _$ExpenseStatusEnumMap[instance.to]!,
      'at': instance.at.toIso8601String(),
      'byUserId': instance.byUserId,
      'reason': instance.reason,
    };

const _$ExpenseStatusEnumMap = {
  ExpenseStatus.draft: 'draft',
  ExpenseStatus.needsReview: 'needsReview',
  ExpenseStatus.submitted: 'submitted',
  ExpenseStatus.approved: 'approved',
  ExpenseStatus.rejected: 'rejected',
  ExpenseStatus.exported: 'exported',
  ExpenseStatus.archived: 'archived',
};

_FleetAttribution _$FleetAttributionFromJson(Map<String, dynamic> json) =>
    _FleetAttribution(
      orgId: json['orgId'] as String,
      fleetVehicleId: json['fleetVehicleId'] as String,
      assignmentId: json['assignmentId'] as String?,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
    );

Map<String, dynamic> _$FleetAttributionToJson(_FleetAttribution instance) =>
    <String, dynamic>{
      'orgId': instance.orgId,
      'fleetVehicleId': instance.fleetVehicleId,
      'assignmentId': instance.assignmentId,
      'capturedAt': instance.capturedAt.toIso8601String(),
    };

_Expense _$ExpenseFromJson(Map<String, dynamic> json) => _Expense(
  id: json['id'] as String,
  orgId: json['orgId'] as String,
  userId: json['userId'] as String,
  fillUpId: json['fillUpId'] as String?,
  fleetAttribution: json['fleetAttribution'] == null
      ? null
      : FleetAttribution.fromJson(
          json['fleetAttribution'] as Map<String, dynamic>,
        ),
  extracted: ExtractedReceiptFields.fromJson(
    json['extracted'] as Map<String, dynamic>,
  ),
  confirmed: ExtractedReceiptFields.fromJson(
    json['confirmed'] as Map<String, dynamic>,
  ),
  corrections:
      (json['corrections'] as List<dynamic>?)
          ?.map((e) => FieldCorrection.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <FieldCorrection>[],
  documentId: json['documentId'] as String?,
  importSource: $enumDecode(_$ExpenseImportSourceEnumMap, json['importSource']),
  authoritative: json['authoritative'] as bool? ?? false,
  status:
      $enumDecodeNullable(_$ExpenseStatusEnumMap, json['status']) ??
      ExpenseStatus.draft,
  history:
      (json['history'] as List<dynamic>?)
          ?.map((e) => ExpenseTransition.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ExpenseTransition>[],
  claim:
      $enumDecodeNullable(_$ClaimClassEnumMap, json['claim']) ??
      ClaimClass.accountingCandidate,
);

Map<String, dynamic> _$ExpenseToJson(_Expense instance) => <String, dynamic>{
  'id': instance.id,
  'orgId': instance.orgId,
  'userId': instance.userId,
  'fillUpId': instance.fillUpId,
  'fleetAttribution': instance.fleetAttribution?.toJson(),
  'extracted': instance.extracted.toJson(),
  'confirmed': instance.confirmed.toJson(),
  'corrections': instance.corrections.map((e) => e.toJson()).toList(),
  'documentId': instance.documentId,
  'importSource': _$ExpenseImportSourceEnumMap[instance.importSource]!,
  'authoritative': instance.authoritative,
  'status': _$ExpenseStatusEnumMap[instance.status]!,
  'history': instance.history.map((e) => e.toJson()).toList(),
  'claim': _$ClaimClassEnumMap[instance.claim]!,
};

const _$ExpenseImportSourceEnumMap = {
  ExpenseImportSource.ocrPhoto: 'ocrPhoto',
  ExpenseImportSource.ocrPdf: 'ocrPdf',
  ExpenseImportSource.eReceiptText: 'eReceiptText',
  ExpenseImportSource.structuredInvoice: 'structuredInvoice',
};

const _$ClaimClassEnumMap = {
  ClaimClass.measuredFact: 'measuredFact',
  ClaimClass.calculatedOperational: 'calculatedOperational',
  ClaimClass.estimate: 'estimate',
  ClaimClass.accountingCandidate: 'accountingCandidate',
  ClaimClass.environmentalEstimate: 'environmentalEstimate',
  ClaimClass.personalDataInference: 'personalDataInference',
};
