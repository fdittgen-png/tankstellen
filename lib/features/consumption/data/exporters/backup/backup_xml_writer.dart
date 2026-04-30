import 'package:xml/xml.dart';

import '../../../../ev/domain/entities/charging_log.dart';
import '../../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../domain/entities/fill_up.dart';
import '../../trip_history_repository.dart';

/// Pure-Dart writer for the v1 Tankstellen backup XML
/// (see `assets/schemas/tankstellen_backup_v1.xsd`).
///
/// No I/O — the writer accepts in-memory domain models and returns the
/// fully-rendered document as a `String`. The orchestrator
/// (`FullBackupExporter`) wraps the result in a single-entry zip and
/// hands it to the OS share sheet.
///
/// ### Determinism
/// Every list is emitted in the order the caller supplied; numeric
/// values are written via `.toString()` (no locale formatting); dates
/// use `toIso8601String()`. Optional fields are omitted entirely when
/// null — never emitted as empty elements — so a v1 → v1 round trip
/// is byte-identical for any input that doesn't carry adjacent-write
/// timestamps.
class BackupXmlWriter {
  /// Default namespace used by the schema's `targetNamespace`.
  static const String namespace = 'https://tankstellen.app/backup/v1';

  /// Schema version emitted as the root `version` attribute.
  static const String version = '1.0';

  /// Build the full XML document from the supplied domain snapshots.
  String build({
    required List<VehicleProfile> vehicles,
    required List<FillUp> fillUps,
    required List<TripHistoryEntry> trips,
    required List<ChargingLog> chargingLogs,
    required String appVersion,
    required DateTime exportedAt,
  }) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('TankstellenBackup', nest: () {
      builder.attribute('version', version);
      builder.attribute('xmlns', namespace);

      _writeText(builder, 'ExportedAt', _iso(exportedAt));
      _writeText(builder, 'AppVersion', appVersion);

      builder.element('Vehicles', nest: () {
        for (final v in vehicles) {
          _writeVehicle(builder, v);
        }
      });

      builder.element('FillUps', nest: () {
        for (final f in fillUps) {
          _writeFillUp(builder, f);
        }
      });

      builder.element('Trips', nest: () {
        for (final t in trips) {
          _writeTrip(builder, t);
        }
      });

      builder.element('ChargingLogs', nest: () {
        for (final c in chargingLogs) {
          _writeChargingLog(builder, c);
        }
      });
    });
    return builder.buildDocument().toXmlString(pretty: true);
  }

  // ── Vehicle ───────────────────────────────────────────────────────

  void _writeVehicle(XmlBuilder builder, VehicleProfile v) {
    builder.element('Vehicle', nest: () {
      _writeText(builder, 'Id', v.id);
      _writeText(builder, 'Name', v.name);
      _writeText(builder, 'EngineType', v.type.key);

      _writeOptionalNumber(builder, 'BatteryKwh', v.batteryKwh);
      _writeOptionalNumber(builder, 'MaxChargingKw', v.maxChargingKw);

      if (v.supportedConnectors.isNotEmpty) {
        builder.element('SupportedConnectors', nest: () {
          for (final c in v.supportedConnectors) {
            _writeText(builder, 'Connector', c.key);
          }
        });
      }

      // ChargingPreferences are always present (default-constructed),
      // so emit them unconditionally — the importer can decide
      // whether the defaults look "user-set" or not.
      builder.element('ChargingPreferences', nest: () {
        _writeText(
          builder,
          'MinSocPercent',
          v.chargingPreferences.minSocPercent.toString(),
        );
        _writeText(
          builder,
          'MaxSocPercent',
          v.chargingPreferences.maxSocPercent.toString(),
        );
        if (v.chargingPreferences.preferredNetworks.isNotEmpty) {
          builder.element('PreferredNetworks', nest: () {
            for (final n in v.chargingPreferences.preferredNetworks) {
              _writeText(builder, 'Network', n);
            }
          });
        }
      });

      _writeOptionalNumber(builder, 'TankCapacityL', v.tankCapacityL);
      _writeOptionalText(builder, 'PreferredFuelType', v.preferredFuelType);

      if (v.engineDisplacementCc != null) {
        _writeText(
          builder,
          'EngineDisplacementCc',
          v.engineDisplacementCc!.toString(),
        );
      }
      if (v.engineCylinders != null) {
        _writeText(builder, 'EngineCylinders', v.engineCylinders!.toString());
      }
      _writeText(
        builder,
        'VolumetricEfficiency',
        v.volumetricEfficiency.toString(),
      );
      _writeText(
        builder,
        'VolumetricEfficiencySamples',
        v.volumetricEfficiencySamples.toString(),
      );

      if (v.curbWeightKg != null) {
        _writeText(builder, 'CurbWeightKg', v.curbWeightKg!.toString());
      }

      _writeOptionalText(builder, 'Obd2AdapterMac', v.obd2AdapterMac);
      _writeOptionalText(builder, 'Obd2AdapterName', v.obd2AdapterName);
      _writeOptionalText(builder, 'PairedAdapterMac', v.pairedAdapterMac);

      _writeOptionalText(builder, 'Vin', v.vin);
      _writeText(builder, 'CalibrationMode', v.calibrationMode.key);

      _writeText(builder, 'AutoRecord', v.autoRecord.toString());
      _writeText(
        builder,
        'MovementStartThresholdKmh',
        v.movementStartThresholdKmh.toString(),
      );
      _writeText(
        builder,
        'DisconnectSaveDelaySec',
        v.disconnectSaveDelaySec.toString(),
      );
      _writeText(
        builder,
        'BackgroundLocationConsent',
        v.backgroundLocationConsent.toString(),
      );

      _writeOptionalText(builder, 'Make', v.make);
      _writeOptionalText(builder, 'Model', v.model);
      if (v.year != null) {
        _writeText(builder, 'Year', v.year!.toString());
      }
      _writeOptionalText(builder, 'ReferenceVehicleId', v.referenceVehicleId);

      if (v.aggregatesUpdatedAt != null) {
        _writeText(builder, 'AggregatesUpdatedAt', _iso(v.aggregatesUpdatedAt!));
      }
      if (v.aggregatesTripCount != null) {
        _writeText(
          builder,
          'AggregatesTripCount',
          v.aggregatesTripCount!.toString(),
        );
      }

      _writeText(
        builder,
        'TireCircumferenceMeters',
        v.tireCircumferenceMeters.toString(),
      );
      final centroids = v.gearCentroids;
      if (centroids != null && centroids.isNotEmpty) {
        builder.element('GearCentroids', nest: () {
          for (final c in centroids) {
            _writeText(builder, 'Centroid', c.toString());
          }
        });
      }
    });
  }

  // ── FillUp ────────────────────────────────────────────────────────

  void _writeFillUp(XmlBuilder builder, FillUp f) {
    builder.element('FillUp', nest: () {
      _writeText(builder, 'Id', f.id);
      _writeOptionalText(builder, 'VehicleId', f.vehicleId);
      _writeText(builder, 'Date', _iso(f.date));
      _writeText(builder, 'FuelType', f.fuelType.apiValue);
      _writeText(builder, 'Liters', f.liters.toString());
      _writeText(builder, 'TotalCost', f.totalCost.toString());
      _writeText(builder, 'OdometerKm', f.odometerKm.toString());
      _writeOptionalText(builder, 'StationId', f.stationId);
      _writeOptionalText(builder, 'StationName', f.stationName);
      _writeOptionalText(builder, 'Notes', f.notes);
      _writeText(builder, 'IsFullTank', f.isFullTank.toString());
      if (f.linkedTripIds.isNotEmpty) {
        builder.element('LinkedTripIds', nest: () {
          for (final id in f.linkedTripIds) {
            _writeText(builder, 'TripId', id);
          }
        });
      }
    });
  }

  // ── Trip ──────────────────────────────────────────────────────────

  void _writeTrip(XmlBuilder builder, TripHistoryEntry t) {
    builder.element('Trip', nest: () {
      _writeText(builder, 'Id', t.id);
      _writeOptionalText(builder, 'VehicleId', t.vehicleId);
      _writeText(builder, 'Automatic', t.automatic.toString());
      _writeOptionalText(builder, 'AdapterMac', t.adapterMac);
      _writeOptionalText(builder, 'AdapterName', t.adapterName);
      _writeOptionalText(builder, 'AdapterFirmware', t.adapterFirmware);

      builder.element('Summary', nest: () {
        _writeText(builder, 'DistanceKm', t.summary.distanceKm.toString());
        _writeText(builder, 'MaxRpm', t.summary.maxRpm.toString());
        _writeText(
          builder,
          'HighRpmSeconds',
          t.summary.highRpmSeconds.toString(),
        );
        _writeText(builder, 'IdleSeconds', t.summary.idleSeconds.toString());
        _writeText(builder, 'HarshBrakes', t.summary.harshBrakes.toString());
        _writeText(
          builder,
          'HarshAccelerations',
          t.summary.harshAccelerations.toString(),
        );
        _writeOptionalNumber(
          builder,
          'AvgLPer100Km',
          t.summary.avgLPer100Km,
        );
        _writeOptionalNumber(
          builder,
          'FuelLitersConsumed',
          t.summary.fuelLitersConsumed,
        );
        if (t.summary.startedAt != null) {
          _writeText(builder, 'StartedAt', _iso(t.summary.startedAt!));
        }
        if (t.summary.endedAt != null) {
          _writeText(builder, 'EndedAt', _iso(t.summary.endedAt!));
        }
        _writeText(builder, 'DistanceSource', t.summary.distanceSource);
        _writeText(
          builder,
          'ColdStartSurcharge',
          t.summary.coldStartSurcharge.toString(),
        );
        _writeOptionalNumber(
          builder,
          'SecondsBelowOptimalGear',
          t.summary.secondsBelowOptimalGear,
        );
      });

      builder.element('Samples', nest: () {
        for (final s in t.samples) {
          builder.element('Sample', nest: () {
            _writeText(builder, 'Timestamp', _iso(s.timestamp));
            _writeText(builder, 'SpeedKmh', s.speedKmh.toString());
            _writeText(builder, 'Rpm', s.rpm.toString());
            _writeOptionalNumber(
              builder,
              'FuelRateLPerHour',
              s.fuelRateLPerHour,
            );
            _writeOptionalNumber(builder, 'ThrottlePercent', s.throttlePercent);
            _writeOptionalNumber(
              builder,
              'EngineLoadPercent',
              s.engineLoadPercent,
            );
            _writeOptionalNumber(builder, 'CoolantTempC', s.coolantTempC);
          });
        }
      });
    });
  }

  // ── ChargingLog ───────────────────────────────────────────────────

  void _writeChargingLog(XmlBuilder builder, ChargingLog c) {
    builder.element('ChargingLog', nest: () {
      _writeText(builder, 'Id', c.id);
      _writeText(builder, 'VehicleId', c.vehicleId);
      _writeText(builder, 'Date', _iso(c.date));
      _writeText(builder, 'Kwh', c.kWh.toString());
      _writeText(builder, 'CostEur', c.costEur.toString());
      _writeText(builder, 'ChargeTimeMin', c.chargeTimeMin.toString());
      _writeText(builder, 'OdometerKm', c.odometerKm.toString());
      _writeOptionalText(builder, 'StationName', c.stationName);
      _writeOptionalText(builder, 'ChargingStationId', c.chargingStationId);
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────

  /// Render a `DateTime` as an ISO-8601 UTC string. Local timestamps are
  /// converted to UTC first so every emitted instant is unambiguous.
  String _iso(DateTime dt) => dt.toUtc().toIso8601String();

  void _writeText(XmlBuilder builder, String name, String value) {
    builder.element(name, nest: value);
  }

  void _writeOptionalText(XmlBuilder builder, String name, String? value) {
    if (value == null) return;
    builder.element(name, nest: value);
  }

  void _writeOptionalNumber(XmlBuilder builder, String name, double? value) {
    if (value == null) return;
    builder.element(name, nest: value.toString());
  }
}
