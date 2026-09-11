// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:xml/xml.dart';

import 'backup_xml_element_helpers.dart';

import '../../../../ev/domain/entities/charging_log.dart';
import '../../../../../core/domain/fuel_type.dart';
import '../../../../../core/domain/vehicle_profile.dart';
import '../../../domain/entities/fill_up.dart';
import '../../../../trips/api.dart';
import 'backup_xml_pump_gain.dart';
import 'backup_xml_writer.dart';

/// Decoded payload of a restore-side backup parse (#2571) — the same
/// four entity lists [BackupXmlWriter] consumes on the export side.
class BackupPayload {
  final List<VehicleProfile> vehicles;
  final List<FillUp> fillUps;
  final List<TripHistoryEntry> trips;
  final List<ChargingLog> chargingLogs;

  const BackupPayload({
    required this.vehicles,
    required this.fillUps,
    required this.trips,
    required this.chargingLogs,
  });

  /// True when every list is empty — a structurally-valid backup that
  /// carried no records. The importer treats this as a success with a
  /// "nothing to restore" result rather than an error.
  bool get isEmpty =>
      vehicles.isEmpty &&
      fillUps.isEmpty &&
      trips.isEmpty &&
      chargingLogs.isEmpty;
}

/// Raised when a backup XML cannot be parsed into a [BackupPayload]
/// (#2571) — malformed XML, a missing/unknown schema version, or a
/// wrong root element. The orchestrator maps this to a localized error
/// snackbar; the raw `xml` package exception never reaches the UI.
class BackupXmlReadException implements Exception {
  final String reason;
  const BackupXmlReadException(this.reason);

  @override
  String toString() => 'BackupXmlReadException: $reason';
}

/// Inverse of [BackupXmlWriter] (#2571).
///
/// Parses a v1 Tankstellen backup document back into the in-memory
/// domain models the writer emitted — the exact mirror of the writer:
/// every element it can produce is read back, every omitted one is null,
/// so a writer → reader round trip reconstructs the same entities.
///
/// ### Version dispatch
/// The root `version` attribute is inspected first: `"1.0"` parses via
/// the v1 path; a FUTURE major (`"2.0"`, …) or a missing / non-numeric
/// version is rejected with a clear [BackupXmlReadException] so an older
/// build never silently mis-reads a newer file.
class BackupXmlReader {
  const BackupXmlReader();

  /// Parse [xml] into a [BackupPayload]. Throws [BackupXmlReadException]
  /// on malformed input or an unsupported schema version.
  BackupPayload read(String xml) {
    final XmlDocument doc;
    try {
      // #3612 — verified against package:xml: `parse` never fetches
      // external entities/DTDs and keeps a DOCTYPE's internal subset as
      // an opaque node; only the predefined character entities expand
      // (default `XmlDefaultEntityMapping.xml()`), so a "billion
      // laughs" / XXE payload cannot amplify or exfiltrate here.
      doc = XmlDocument.parse(xml);
    } catch (e, st) {
      Error.throwWithStackTrace(
        const BackupXmlReadException('malformed XML'),
        st,
      );
    }

    final XmlElement root;
    try {
      root = doc.rootElement;
    } catch (e, st) {
      Error.throwWithStackTrace(
        const BackupXmlReadException('no root element'),
        st,
      );
    }

    if (root.name.local != 'TankstellenBackup') {
      throw const BackupXmlReadException('not a Tankstellen backup document');
    }

    final version = root.getAttribute('version');
    if (version == null || version.trim().isEmpty) {
      throw const BackupXmlReadException('missing schema version');
    }
    final major = _majorOf(version);
    if (major == null) {
      throw BackupXmlReadException('unrecognised schema version "$version"');
    }
    // v1 is the only shipped schema. A newer major is from a future app
    // build — refuse rather than guess. (When a v2 reader ships it adds
    // its own branch here.)
    if (major != 1) {
      throw BackupXmlReadException(
        'unsupported schema version "$version" — produced by a newer app',
      );
    }

    return _readV1(root);
  }

  /// Extracts the integer major component of a `"<major>.<minor>"`
  /// version string, or null when it isn't numeric.
  int? _majorOf(String version) {
    final head = version.split('.').first.trim();
    return int.tryParse(head);
  }

  // ── v1 ─────────────────────────────────────────────────────────────

  BackupPayload _readV1(XmlElement root) {
    final vehicles = _childList(root, 'Vehicles', 'Vehicle', _readVehicle);
    final fillUps = _childList(root, 'FillUps', 'FillUp', _readFillUp);
    final trips = _childList(root, 'Trips', 'Trip', _readTrip);
    final logs =
        _childList(root, 'ChargingLogs', 'ChargingLog', _readChargingLog);
    return BackupPayload(
      vehicles: vehicles,
      fillUps: fillUps,
      trips: trips,
      chargingLogs: logs,
    );
  }

  List<T> _childList<T>(
    XmlElement root,
    String container,
    String item,
    T Function(XmlElement) read,
  ) {
    final box = root.findElements(container).firstOrNull;
    if (box == null) return <T>[];
    return box.findElements(item).map(read).toList(growable: false);
  }

  // ── Vehicle ─────────────────────────────────────────────────────────

  VehicleProfile _readVehicle(XmlElement v) {
    final connectors = <ConnectorType>{};
    final connectorsBox = v.findElements('SupportedConnectors').firstOrNull;
    if (connectorsBox != null) {
      for (final c in connectorsBox.findElements('Connector')) {
        final ct = ConnectorType.fromKey(c.innerText);
        if (ct != null) connectors.add(ct);
      }
    }

    var prefs = const ChargingPreferences();
    final prefsBox = v.findElements('ChargingPreferences').firstOrNull;
    if (prefsBox != null) {
      final networks = <String>[];
      final networksBox = prefsBox.findElements('PreferredNetworks').firstOrNull;
      if (networksBox != null) {
        for (final n in networksBox.findElements('Network')) {
          networks.add(n.innerText);
        }
      }
      prefs = ChargingPreferences(
        minSocPercent: readInt(prefsBox, 'MinSocPercent') ?? 20,
        maxSocPercent: readInt(prefsBox, 'MaxSocPercent') ?? 80,
        preferredNetworks: networks,
      );
    }

    final centroids = <double>[];
    final centroidsBox = v.findElements('GearCentroids').firstOrNull;
    if (centroidsBox != null) {
      for (final c in centroidsBox.findElements('Centroid')) {
        final d = double.tryParse(c.innerText);
        if (d != null) centroids.add(d);
      }
    }

    return VehicleProfile(
      id: reqText(v, 'Id'),
      name: reqText(v, 'Name'),
      type: VehicleType.fromKey(readText(v, 'EngineType')),
      batteryKwh: readDouble(v, 'BatteryKwh'),
      maxChargingKw: readDouble(v, 'MaxChargingKw'),
      supportedConnectors: connectors,
      chargingPreferences: prefs,
      tankCapacityL: readDouble(v, 'TankCapacityL'),
      preferredFuelType: readText(v, 'PreferredFuelType'),
      engineDisplacementCc: readInt(v, 'EngineDisplacementCc'),
      engineCylinders: readInt(v, 'EngineCylinders'),
      volumetricEfficiency: readDouble(v, 'VolumetricEfficiency') ?? 0.85,
      volumetricEfficiencySamples: readInt(v, 'VolumetricEfficiencySamples') ?? 0,
      pumpGain: readDouble(v, 'PumpGain') ?? 1.0, // #3887
      pumpGainSamples: readInt(v, 'PumpGainSamples') ?? 0,
      pumpGainUpdatedAt: DateTime.tryParse(readText(v, 'PumpGainUpdatedAt') ?? ''),
      pumpGainByFuel: readPumpGainByFuel(v), // #3918
      tankFuelKey: readTankFuelKey(v),
      curbWeightKg: readInt(v, 'CurbWeightKg'),
      obd2AdapterMac: readText(v, 'Obd2AdapterMac'),
      obd2AdapterName: readText(v, 'Obd2AdapterName'),
      vin: readText(v, 'Vin'),
      calibrationMode: VehicleCalibrationMode.fromKey(readText(v, 'CalibrationMode')),
      autoRecord: readBool(v, 'AutoRecord') ?? false,
      movementStartThresholdKmh:
          readDouble(v, 'MovementStartThresholdKmh') ?? 5.0,
      disconnectSaveDelaySec: readInt(v, 'DisconnectSaveDelaySec') ?? 60,
      backgroundLocationConsent: readBool(v, 'BackgroundLocationConsent') ?? false,
      make: readText(v, 'Make'),
      model: readText(v, 'Model'),
      year: readInt(v, 'Year'),
      referenceVehicleId: readText(v, 'ReferenceVehicleId'),
      aggregatesUpdatedAt: readDate(v, 'AggregatesUpdatedAt'),
      aggregatesTripCount: readInt(v, 'AggregatesTripCount'),
      tireCircumferenceMeters: readDouble(v, 'TireCircumferenceMeters') ?? 1.95,
      gearCentroids: centroids.isEmpty ? null : centroids,
    );
  }

  // ── FillUp ──────────────────────────────────────────────────────────

  FillUp _readFillUp(XmlElement f) {
    final linked = <String>[];
    final linkedBox = f.findElements('LinkedTripIds').firstOrNull;
    if (linkedBox != null) {
      for (final id in linkedBox.findElements('TripId')) {
        linked.add(id.innerText);
      }
    }
    return FillUp(
      id: reqText(f, 'Id'),
      vehicleId: readText(f, 'VehicleId'),
      date: reqDate(f, 'Date'),
      fuelType: FuelType.fromString(reqText(f, 'FuelType')),
      liters: reqNonNegativeDouble(f, 'Liters'),
      totalCost: reqDouble(f, 'TotalCost'),
      odometerKm: reqDouble(f, 'OdometerKm'),
      stationId: readText(f, 'StationId'),
      stationName: readText(f, 'StationName'),
      notes: readText(f, 'Notes'),
      isFullTank: readBool(f, 'IsFullTank') ?? true,
      linkedTripIds: linked,
    );
  }

  // ── Trip ────────────────────────────────────────────────────────────

  TripHistoryEntry _readTrip(XmlElement t) {
    final summaryEl = t.findElements('Summary').first;
    final harshEvents = <HarshEvent>[];
    final harshBox = summaryEl.findElements('HarshEvents').firstOrNull;
    if (harshBox != null) {
      for (final e in harshBox.findElements('HarshEvent')) {
        harshEvents.add(HarshEvent(
          timestamp: reqDate(e, 'Timestamp'),
          type: HarshEventType.fromWireName(readText(e, 'Type')),
          magnitudeG: reqDouble(e, 'MagnitudeG'),
          speedKmh: reqDouble(e, 'SpeedKmh'),
        ));
      }
    }

    final summary = TripSummary(
      distanceKm: reqDouble(summaryEl, 'DistanceKm'),
      maxRpm: reqDouble(summaryEl, 'MaxRpm'),
      highRpmSeconds: reqDouble(summaryEl, 'HighRpmSeconds'),
      idleSeconds: reqDouble(summaryEl, 'IdleSeconds'),
      harshBrakes: reqInt(summaryEl, 'HarshBrakes'),
      harshAccelerations: reqInt(summaryEl, 'HarshAccelerations'),
      avgLPer100Km: readDouble(summaryEl, 'AvgLPer100Km'),
      fuelLitersConsumed: readDouble(summaryEl, 'FuelLitersConsumed'),
      startedAt: readDate(summaryEl, 'StartedAt'),
      endedAt: readDate(summaryEl, 'EndedAt'),
      distanceSource: readText(summaryEl, 'DistanceSource') ?? 'virtual',
      coldStartSurcharge: readBool(summaryEl, 'ColdStartSurcharge') ?? false,
      secondsBelowOptimalGear: readDouble(summaryEl, 'SecondsBelowOptimalGear'),
      kind: TripKind.fromWireName(readText(summaryEl, 'Kind')),
      harshEvents: harshEvents,
    );

    final samples = <TripSample>[];
    final samplesBox = t.findElements('Samples').firstOrNull;
    if (samplesBox != null) {
      for (final s in samplesBox.findElements('Sample')) {
        samples.add(TripSample(
          timestamp: reqDate(s, 'Timestamp'),
          speedKmh: reqDouble(s, 'SpeedKmh'),
          // #2692 C4-G — optional now: legacy backups always wrote Rpm, so
          // they still read back unchanged; a GPS-only sample reads null.
          rpm: readDouble(s, 'Rpm'),
          fuelRateLPerHour: readDouble(s, 'FuelRateLPerHour'),
          throttlePercent: readDouble(s, 'ThrottlePercent'),
          engineLoadPercent: readDouble(s, 'EngineLoadPercent'),
          coolantTempC: readDouble(s, 'CoolantTempC'),
          latitude: readDouble(s, 'Latitude'),
          longitude: readDouble(s, 'Longitude'),
          altitudeM: readDouble(s, 'AltitudeM'),
          hAccuracyM: readDouble(s, 'HAccuracyM'),
          bearingDeg: readDouble(s, 'BearingDeg'),
          accelG: readDouble(s, 'AccelG'),
        ));
      }
    }

    return TripHistoryEntry(
      id: reqText(t, 'Id'),
      vehicleId: readText(t, 'VehicleId'),
      automatic: readBool(t, 'Automatic') ?? false,
      adapterMac: readText(t, 'AdapterMac'),
      adapterName: readText(t, 'AdapterName'),
      adapterFirmware: readText(t, 'AdapterFirmware'),
      summary: summary,
      samples: samples,
    );
  }

  // ── ChargingLog ───────────────────────────────────────────────────

  ChargingLog _readChargingLog(XmlElement c) => ChargingLog(
        id: reqText(c, 'Id'),
        vehicleId: reqText(c, 'VehicleId'),
        date: reqDate(c, 'Date'),
        kWh: reqDouble(c, 'Kwh'),
        costEur: reqDouble(c, 'CostEur'),
        chargeTimeMin: reqInt(c, 'ChargeTimeMin'),
        odometerKm: reqInt(c, 'OdometerKm'),
        stationName: readText(c, 'StationName'),
        chargingStationId: readText(c, 'ChargingStationId'),
      );

}
