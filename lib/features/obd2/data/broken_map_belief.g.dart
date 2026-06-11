// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broken_map_belief.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BrokenMapBelief _$BrokenMapBeliefFromJson(Map<String, dynamic> json) =>
    _BrokenMapBelief(
      alpha: (json['alpha'] as num?)?.toDouble() ?? 1.0,
      beta: (json['beta'] as num?)?.toDouble() ?? 9.0,
      observationCount: (json['observationCount'] as num?)?.toInt() ?? 0,
      lastUpdate: json['lastUpdate'] == null
          ? null
          : DateTime.parse(json['lastUpdate'] as String),
      lastTrigger:
          $enumDecodeNullable(_$BrokenMapReasonEnumMap, json['lastTrigger']) ??
          BrokenMapReason.none,
    );

Map<String, dynamic> _$BrokenMapBeliefToJson(_BrokenMapBelief instance) =>
    <String, dynamic>{
      'alpha': instance.alpha,
      'beta': instance.beta,
      'observationCount': instance.observationCount,
      'lastUpdate': instance.lastUpdate?.toIso8601String(),
      'lastTrigger': _$BrokenMapReasonEnumMap[instance.lastTrigger]!,
    };

const _$BrokenMapReasonEnumMap = {
  BrokenMapReason.idleVacuumMissing: 'idleVacuumMissing',
  BrokenMapReason.revDeltaMissing: 'revDeltaMissing',
  BrokenMapReason.pleinCompletDiscrepancy: 'pleinCompletDiscrepancy',
  BrokenMapReason.etaImplausible: 'etaImplausible',
  BrokenMapReason.priorObservation: 'priorObservation',
  BrokenMapReason.none: 'none',
};
