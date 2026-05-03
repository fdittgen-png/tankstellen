// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChargingPreferences _$ChargingPreferencesFromJson(Map<String, dynamic> json) =>
    _ChargingPreferences(
      minSocPercent: (json['minSocPercent'] as num?)?.toInt() ?? 20,
      maxSocPercent: (json['maxSocPercent'] as num?)?.toInt() ?? 80,
      preferredNetworks:
          (json['preferredNetworks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$ChargingPreferencesToJson(
  _ChargingPreferences instance,
) => <String, dynamic>{
  'minSocPercent': instance.minSocPercent,
  'maxSocPercent': instance.maxSocPercent,
  'preferredNetworks': instance.preferredNetworks,
};

_VehicleProfile _$VehicleProfileFromJson(Map<String, dynamic> json) =>
    _VehicleProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] == null
          ? VehicleType.combustion
          : const VehicleTypeJsonConverter().fromJson(json['type'] as String),
      batteryKwh: (json['batteryKwh'] as num?)?.toDouble(),
      maxChargingKw: (json['maxChargingKw'] as num?)?.toDouble(),
      supportedConnectors: json['supportedConnectors'] == null
          ? const <ConnectorType>{}
          : const ConnectorTypeSetConverter().fromJson(
              json['supportedConnectors'] as List,
            ),
      chargingPreferences: json['chargingPreferences'] == null
          ? const ChargingPreferences()
          : const ChargingPreferencesJsonConverter().fromJson(
              json['chargingPreferences'] as Map<String, dynamic>,
            ),
      tankCapacityL: (json['tankCapacityL'] as num?)?.toDouble(),
      preferredFuelType: json['preferredFuelType'] as String?,
      engineDisplacementCc: (json['engineDisplacementCc'] as num?)?.toInt(),
      engineCylinders: (json['engineCylinders'] as num?)?.toInt(),
      volumetricEfficiency:
          (json['volumetricEfficiency'] as num?)?.toDouble() ?? 0.85,
      volumetricEfficiencySamples:
          (json['volumetricEfficiencySamples'] as num?)?.toInt() ?? 0,
      curbWeightKg: (json['curbWeightKg'] as num?)?.toInt(),
      obd2AdapterMac: json['obd2AdapterMac'] as String?,
      obd2AdapterName: json['obd2AdapterName'] as String?,
      vin: json['vin'] as String?,
      calibrationMode: json['calibrationMode'] == null
          ? VehicleCalibrationMode.rule
          : const VehicleCalibrationModeJsonConverter().fromJson(
              json['calibrationMode'] as String?,
            ),
      autoRecord: json['autoRecord'] as bool? ?? false,
      pairedAdapterMac: json['pairedAdapterMac'] as String?,
      movementStartThresholdKmh:
          (json['movementStartThresholdKmh'] as num?)?.toDouble() ?? 5.0,
      disconnectSaveDelaySec:
          (json['disconnectSaveDelaySec'] as num?)?.toInt() ?? 60,
      backgroundLocationConsent:
          json['backgroundLocationConsent'] as bool? ?? false,
      make: json['make'] as String?,
      model: json['model'] as String?,
      year: (json['year'] as num?)?.toInt(),
      referenceVehicleId: json['referenceVehicleId'] as String?,
      tripLengthAggregates: json['tripLengthAggregates'] == null
          ? null
          : TripLengthBreakdown.fromJson(
              json['tripLengthAggregates'] as Map<String, dynamic>,
            ),
      speedConsumptionAggregates: json['speedConsumptionAggregates'] == null
          ? null
          : SpeedConsumptionHistogram.fromJson(
              json['speedConsumptionAggregates'] as Map<String, dynamic>,
            ),
      aggregatesUpdatedAt: json['aggregatesUpdatedAt'] == null
          ? null
          : DateTime.parse(json['aggregatesUpdatedAt'] as String),
      aggregatesTripCount: (json['aggregatesTripCount'] as num?)?.toInt(),
      tireCircumferenceMeters:
          (json['tireCircumferenceMeters'] as num?)?.toDouble() ?? 1.95,
      gearCentroids: (json['gearCentroids'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      lastReadVin: json['lastReadVin'] as String?,
      lastVinReadAt: json['lastVinReadAt'] == null
          ? null
          : DateTime.parse(json['lastVinReadAt'] as String),
      detectedMake: json['detectedMake'] as String?,
      detectedModel: json['detectedModel'] as String?,
      detectedYear: (json['detectedYear'] as num?)?.toInt(),
      detectedEngineDisplacementCc:
          (json['detectedEngineDisplacementCc'] as num?)?.toInt(),
      detectedFuelType: json['detectedFuelType'] as String?,
    );

Map<String, dynamic> _$VehicleProfileToJson(
  _VehicleProfile instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': const VehicleTypeJsonConverter().toJson(instance.type),
  'batteryKwh': instance.batteryKwh,
  'maxChargingKw': instance.maxChargingKw,
  'supportedConnectors': const ConnectorTypeSetConverter().toJson(
    instance.supportedConnectors,
  ),
  'chargingPreferences': const ChargingPreferencesJsonConverter().toJson(
    instance.chargingPreferences,
  ),
  'tankCapacityL': instance.tankCapacityL,
  'preferredFuelType': instance.preferredFuelType,
  'engineDisplacementCc': instance.engineDisplacementCc,
  'engineCylinders': instance.engineCylinders,
  'volumetricEfficiency': instance.volumetricEfficiency,
  'volumetricEfficiencySamples': instance.volumetricEfficiencySamples,
  'curbWeightKg': instance.curbWeightKg,
  'obd2AdapterMac': instance.obd2AdapterMac,
  'obd2AdapterName': instance.obd2AdapterName,
  'vin': instance.vin,
  'calibrationMode': const VehicleCalibrationModeJsonConverter().toJson(
    instance.calibrationMode,
  ),
  'autoRecord': instance.autoRecord,
  'pairedAdapterMac': instance.pairedAdapterMac,
  'movementStartThresholdKmh': instance.movementStartThresholdKmh,
  'disconnectSaveDelaySec': instance.disconnectSaveDelaySec,
  'backgroundLocationConsent': instance.backgroundLocationConsent,
  'make': instance.make,
  'model': instance.model,
  'year': instance.year,
  'referenceVehicleId': instance.referenceVehicleId,
  'tripLengthAggregates': instance.tripLengthAggregates?.toJson(),
  'speedConsumptionAggregates': instance.speedConsumptionAggregates?.toJson(),
  'aggregatesUpdatedAt': instance.aggregatesUpdatedAt?.toIso8601String(),
  'aggregatesTripCount': instance.aggregatesTripCount,
  'tireCircumferenceMeters': instance.tireCircumferenceMeters,
  'gearCentroids': instance.gearCentroids,
  'lastReadVin': instance.lastReadVin,
  'lastVinReadAt': instance.lastVinReadAt?.toIso8601String(),
  'detectedMake': instance.detectedMake,
  'detectedModel': instance.detectedModel,
  'detectedYear': instance.detectedYear,
  'detectedEngineDisplacementCc': instance.detectedEngineDisplacementCc,
  'detectedFuelType': instance.detectedFuelType,
};
