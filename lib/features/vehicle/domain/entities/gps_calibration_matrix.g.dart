// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gps_calibration_matrix.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GpsCalibrationMatrix _$GpsCalibrationMatrixFromJson(
  Map<String, dynamic> json,
) => _GpsCalibrationMatrix(
  baseline: (json['baseline'] as num?)?.toDouble() ?? 6.5,
  idleCost: (json['idleCost'] as num?)?.toDouble() ?? 1.2,
  highSpeedPenalty: (json['highSpeedPenalty'] as num?)?.toDouble() ?? 2.0,
  accelEventCost: (json['accelEventCost'] as num?)?.toDouble() ?? 0.5,
  brakeEventCost: (json['brakeEventCost'] as num?)?.toDouble(),
  gradeClimbCost: (json['gradeClimbCost'] as num?)?.toDouble(),
  cornerLoadCost: (json['cornerLoadCost'] as num?)?.toDouble(),
  fillUpReconciliationCount:
      (json['fillUpReconciliationCount'] as num?)?.toInt() ?? 0,
  residualVariance: (json['residualVariance'] as num?)?.toDouble() ?? 0.0,
  lastReconciledAt: json['lastReconciledAt'] == null
      ? null
      : DateTime.parse(json['lastReconciledAt'] as String),
);

Map<String, dynamic> _$GpsCalibrationMatrixToJson(
  _GpsCalibrationMatrix instance,
) => <String, dynamic>{
  'baseline': instance.baseline,
  'idleCost': instance.idleCost,
  'highSpeedPenalty': instance.highSpeedPenalty,
  'accelEventCost': instance.accelEventCost,
  'brakeEventCost': instance.brakeEventCost,
  'gradeClimbCost': instance.gradeClimbCost,
  'cornerLoadCost': instance.cornerLoadCost,
  'fillUpReconciliationCount': instance.fillUpReconciliationCount,
  'residualVariance': instance.residualVariance,
  'lastReconciledAt': instance.lastReconciledAt?.toIso8601String(),
};
