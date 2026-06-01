// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:xml/xml.dart';

import '../../../../ev/domain/entities/charging_log.dart';
import '../../../../search/domain/entities/fuel_type.dart';
import '../../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../domain/entities/fill_up.dart';
import '../../../domain/trip_recorder.dart';
import '../../trip_history_repository.dart';
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
/// domain models the writer emitted. The reader is the exact mirror of
/// the writer: every element the writer can produce is read back, and
/// every element the writer omits for a null value is treated as null
/// here — so a writer → reader round trip reconstructs the same
/// entities (for the fields the v1 schema carries).
///
/// ### Version dispatch
/// The root `version` attribute is inspected first. `"1.0"` parses via
/// the v1 path below. A backup produced by a FUTURE schema (`"2.0"`,
/// `"3.x"`, …) is rejected with a clear [BackupXmlReadException] so an
/// older app build never silently mis-reads a newer file — the schema
/// doc's "a future importer dispatches on that value" contract. A
/// missing or non-numeric version is likewise rejected as "not a
/// recognised backup".
class BackupXmlReader {
  const BackupXmlReader();

  /// Parse [xml] into a [BackupPayload]. Throws [BackupXmlReadException]
  /// on malformed input or an unsupported schema version.
  BackupPayload read(String xml) {
    final XmlDocument doc;
    try {
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
        minSocPercent: _int(prefsBox, 'MinSocPercent') ?? 20,
        maxSocPercent: _int(prefsBox, 'MaxSocPercent') ?? 80,
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
      id: _reqText(v, 'Id'),
      name: _reqText(v, 'Name'),
      type: VehicleType.fromKey(_text(v, 'EngineType')),
      batteryKwh: _double(v, 'BatteryKwh'),
      maxChargingKw: _double(v, 'MaxChargingKw'),
      supportedConnectors: connectors,
      chargingPreferences: prefs,
      tankCapacityL: _double(v, 'TankCapacityL'),
      preferredFuelType: _text(v, 'PreferredFuelType'),
      engineDisplacementCc: _int(v, 'EngineDisplacementCc'),
      engineCylinders: _int(v, 'EngineCylinders'),
      volumetricEfficiency: _double(v, 'VolumetricEfficiency') ?? 0.85,
      volumetricEfficiencySamples: _int(v, 'VolumetricEfficiencySamples') ?? 0,
      curbWeightKg: _int(v, 'CurbWeightKg'),
      obd2AdapterMac: _text(v, 'Obd2AdapterMac'),
      obd2AdapterName: _text(v, 'Obd2AdapterName'),
      vin: _text(v, 'Vin'),
      calibrationMode: VehicleCalibrationMode.fromKey(_text(v, 'CalibrationMode')),
      autoRecord: _bool(v, 'AutoRecord') ?? false,
      movementStartThresholdKmh:
          _double(v, 'MovementStartThresholdKmh') ?? 5.0,
      disconnectSaveDelaySec: _int(v, 'DisconnectSaveDelaySec') ?? 60,
      backgroundLocationConsent: _bool(v, 'BackgroundLocationConsent') ?? false,
      make: _text(v, 'Make'),
      model: _text(v, 'Model'),
      year: _int(v, 'Year'),
      referenceVehicleId: _text(v, 'ReferenceVehicleId'),
      aggregatesUpdatedAt: _date(v, 'AggregatesUpdatedAt'),
      aggregatesTripCount: _int(v, 'AggregatesTripCount'),
      tireCircumferenceMeters: _double(v, 'TireCircumferenceMeters') ?? 1.95,
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
      id: _reqText(f, 'Id'),
      vehicleId: _text(f, 'VehicleId'),
      date: _reqDate(f, 'Date'),
      fuelType: FuelType.fromString(_reqText(f, 'FuelType')),
      liters: _reqDouble(f, 'Liters'),
      totalCost: _reqDouble(f, 'TotalCost'),
      odometerKm: _reqDouble(f, 'OdometerKm'),
      stationId: _text(f, 'StationId'),
      stationName: _text(f, 'StationName'),
      notes: _text(f, 'Notes'),
      isFullTank: _bool(f, 'IsFullTank') ?? true,
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
          timestamp: _reqDate(e, 'Timestamp'),
          type: HarshEventType.fromWireName(_text(e, 'Type')),
          magnitudeG: _reqDouble(e, 'MagnitudeG'),
          speedKmh: _reqDouble(e, 'SpeedKmh'),
        ));
      }
    }

    final summary = TripSummary(
      distanceKm: _reqDouble(summaryEl, 'DistanceKm'),
      maxRpm: _reqDouble(summaryEl, 'MaxRpm'),
      highRpmSeconds: _reqDouble(summaryEl, 'HighRpmSeconds'),
      idleSeconds: _reqDouble(summaryEl, 'IdleSeconds'),
      harshBrakes: _reqInt(summaryEl, 'HarshBrakes'),
      harshAccelerations: _reqInt(summaryEl, 'HarshAccelerations'),
      avgLPer100Km: _double(summaryEl, 'AvgLPer100Km'),
      fuelLitersConsumed: _double(summaryEl, 'FuelLitersConsumed'),
      startedAt: _date(summaryEl, 'StartedAt'),
      endedAt: _date(summaryEl, 'EndedAt'),
      distanceSource: _text(summaryEl, 'DistanceSource') ?? 'virtual',
      coldStartSurcharge: _bool(summaryEl, 'ColdStartSurcharge') ?? false,
      secondsBelowOptimalGear: _double(summaryEl, 'SecondsBelowOptimalGear'),
      kind: TripKind.fromWireName(_text(summaryEl, 'Kind')),
      harshEvents: harshEvents,
    );

    final samples = <TripSample>[];
    final samplesBox = t.findElements('Samples').firstOrNull;
    if (samplesBox != null) {
      for (final s in samplesBox.findElements('Sample')) {
        samples.add(TripSample(
          timestamp: _reqDate(s, 'Timestamp'),
          speedKmh: _reqDouble(s, 'SpeedKmh'),
          rpm: _reqDouble(s, 'Rpm'),
          fuelRateLPerHour: _double(s, 'FuelRateLPerHour'),
          throttlePercent: _double(s, 'ThrottlePercent'),
          engineLoadPercent: _double(s, 'EngineLoadPercent'),
          coolantTempC: _double(s, 'CoolantTempC'),
          latitude: _double(s, 'Latitude'),
          longitude: _double(s, 'Longitude'),
          altitudeM: _double(s, 'AltitudeM'),
          hAccuracyM: _double(s, 'HAccuracyM'),
          bearingDeg: _double(s, 'BearingDeg'),
          accelG: _double(s, 'AccelG'),
        ));
      }
    }

    return TripHistoryEntry(
      id: _reqText(t, 'Id'),
      vehicleId: _text(t, 'VehicleId'),
      automatic: _bool(t, 'Automatic') ?? false,
      adapterMac: _text(t, 'AdapterMac'),
      adapterName: _text(t, 'AdapterName'),
      adapterFirmware: _text(t, 'AdapterFirmware'),
      summary: summary,
      samples: samples,
    );
  }

  // ── ChargingLog ───────────────────────────────────────────────────

  ChargingLog _readChargingLog(XmlElement c) => ChargingLog(
        id: _reqText(c, 'Id'),
        vehicleId: _reqText(c, 'VehicleId'),
        date: _reqDate(c, 'Date'),
        kWh: _reqDouble(c, 'Kwh'),
        costEur: _reqDouble(c, 'CostEur'),
        chargeTimeMin: _reqInt(c, 'ChargeTimeMin'),
        odometerKm: _reqInt(c, 'OdometerKm'),
        stationName: _text(c, 'StationName'),
        chargingStationId: _text(c, 'ChargingStationId'),
      );

  // ── Element helpers ─────────────────────────────────────────────────

  String? _text(XmlElement parent, String name) =>
      parent.findElements(name).firstOrNull?.innerText;

  String _reqText(XmlElement parent, String name) {
    final v = _text(parent, name);
    if (v == null) {
      throw BackupXmlReadException('missing required <$name>');
    }
    return v;
  }

  double? _double(XmlElement parent, String name) {
    final v = _text(parent, name);
    return v == null ? null : double.tryParse(v);
  }

  double _reqDouble(XmlElement parent, String name) {
    final v = _double(parent, name);
    if (v == null) {
      throw BackupXmlReadException('missing/invalid required <$name>');
    }
    return v;
  }

  int? _int(XmlElement parent, String name) {
    final v = _text(parent, name);
    if (v == null) return null;
    // Numbers are written via `.toString()`, so a double-typed field
    // that happens to hold a whole number is still safe to read as int.
    return int.tryParse(v) ?? double.tryParse(v)?.toInt();
  }

  int _reqInt(XmlElement parent, String name) {
    final v = _int(parent, name);
    if (v == null) {
      throw BackupXmlReadException('missing/invalid required <$name>');
    }
    return v;
  }

  bool? _bool(XmlElement parent, String name) {
    final v = _text(parent, name);
    if (v == null) return null;
    return v.toLowerCase() == 'true';
  }

  DateTime? _date(XmlElement parent, String name) {
    final v = _text(parent, name);
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  DateTime _reqDate(XmlElement parent, String name) {
    final v = _date(parent, name);
    if (v == null) {
      throw BackupXmlReadException('missing/invalid required <$name>');
    }
    return v;
  }
}
