// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../../core/domain/vehicle_profile.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../ev/api.dart' show ChargingLog;
import '../../fill_ups/api.dart' show FillUp;
import '../../trips/api.dart' show TripHistoryEntry, buildGpxXml;
import '../../vehicle/api.dart' show ServiceReminder;

/// #3869 (Epic #3865, GDPR Art. 20) — ONE export of everything.
///
/// Four exporters used to exist with four disjoint scopes; the one the
/// policy pointed at omitted trips, vehicles and fill-ups. This builder
/// produces a single ZIP: a machine-readable JSON per local category, one
/// GPX per recorded trip, the consent record, and — when connected —
/// every server table. [kBoxExportCoverage] maps every Hive box in
/// `HiveBoxes.allBoxes` to the file that carries it (or documents why it
/// holds no personal data); `test/features/profile/data/
/// full_data_export_test.dart` fails when a box is unaccounted for.
class FullDataExportInput {
  const FullDataExportInput({
    required this.appVersion,
    required this.exportedAt,
    required this.policyVersion,
    required this.appDataJson,
    required this.vehicles,
    required this.fillUps,
    required this.trips,
    required this.chargingLogs,
    required this.serviceReminders,
    required this.baselines,
    required this.achievements,
    required this.obd2Caches,
    required this.inProgressTrips,
    required this.consent,
    this.server,
  });

  final String appVersion;
  final DateTime exportedAt;
  final int policyVersion;

  /// The existing settings/favorites/alerts/profiles/itineraries/price
  /// history JSON document (`exportPrivacyDataProvider`).
  final String appDataJson;
  final List<VehicleProfile> vehicles;
  final List<FillUp> fillUps;
  final List<TripHistoryEntry> trips;
  final List<ChargingLog> chargingLogs;
  final List<ServiceReminder> serviceReminders;

  /// Raw box contents (JSON strings decoded where possible).
  final Map<String, dynamic> baselines;
  final Map<String, dynamic> achievements;
  final Map<String, dynamic> obd2Caches;
  final Map<String, dynamic> inProgressTrips;

  /// The consent record (toggles, date, policy version).
  final Map<String, dynamic> consent;

  /// `UserDataSync.fetchAll()` — null when not connected.
  final Map<String, dynamic>? server;
}

/// Every box → the ZIP entry that carries its contents, or `null` with the
/// reason it holds nothing personal (pinned by test).
const Map<String, String?> kBoxExportCoverage = {
  HiveBoxes.settings: 'local/app_data.json',
  HiveBoxes.favorites: 'local/app_data.json',
  HiveBoxes.profiles: 'local/app_data.json',
  HiveBoxes.priceHistory: 'local/app_data.json',
  HiveBoxes.alerts: 'local/app_data.json',
  HiveBoxes.obd2TripHistory: 'local/trips.json',
  HiveBoxes.obd2Baselines: 'local/obd2_baselines.json',
  HiveBoxes.achievements: 'local/achievements.json',
  HiveBoxes.serviceReminders: 'local/service_reminders.json',
  HiveBoxes.obd2SupportedPids: 'local/obd2_caches.json',
  HiveBoxes.obd2NegotiatedProtocol: 'local/obd2_caches.json',
  HiveBoxes.obd2PausedTrips: 'local/trips_in_progress.json',
  HiveBoxes.obd2ActiveTrip: 'local/trips_in_progress.json',
  HiveBoxes.errorTraces: null, // exported by "Save error log" (scrubbed)
  HiveBoxes.isolateErrorSpool: null, // same, drained into error traces
  HiveBoxes.cache: null, // reconstructable API responses, no user input
  HiveBoxes.priceSnapshots: null, // public station prices, 6 h TTL
  HiveBoxes.trafficSignalsCache: null, // public OSM data
  HiveBoxes.featureFlags: null, // which features are on — in app_data
  HiveBoxes.appProfile: null, // the use-mode preset name — in app_data
  HiveBoxes.boxSchema: null, // integers: schema versions per box
};

/// Builds the ZIP bytes. Pure — no I/O.
Uint8List buildFullDataExportZip(FullDataExportInput input) {
  const enc = JsonEncoder.withIndent('  ');
  final archive = Archive();
  var count = 0;
  void add(String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
    count++;
  }

  add('local/app_data.json', input.appDataJson);
  add('local/vehicles.json',
      enc.convert(input.vehicles.map((v) => v.toJson()).toList()));
  add('local/fill_ups.json',
      enc.convert(input.fillUps.map((f) => f.toJson()).toList()));
  add('local/trips.json',
      enc.convert(input.trips.map((t) => t.toJson()).toList()));
  for (final trip in input.trips) {
    add('local/trips/${_safe(trip.id)}.gpx',
        buildGpxXml(trip, appVersion: input.appVersion));
  }
  add('local/charging_logs.json',
      enc.convert(input.chargingLogs.map((c) => c.toJson()).toList()));
  add('local/service_reminders.json',
      enc.convert(input.serviceReminders.map((r) => r.toJson()).toList()));
  add('local/obd2_baselines.json', enc.convert(input.baselines));
  add('local/achievements.json', enc.convert(input.achievements));
  add('local/obd2_caches.json', enc.convert(input.obd2Caches));
  add('local/trips_in_progress.json', enc.convert(input.inProgressTrips));
  add('local/consent.json', enc.convert(input.consent));
  final server = input.server;
  if (server != null) {
    for (final entry in server.entries) {
      if (entry.value is List) {
        add('server/${_safe(entry.key)}.json',
            enc.convert(entry.value as List<dynamic>));
      }
    }
    if (server['error'] != null) {
      add('server/ERROR.txt', '${server['error']}');
    }
  }
  add('README.txt', _readme(input, count + 1));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// Number of entries [buildFullDataExportZip] writes for [input].
int fullDataExportEntryCount(FullDataExportInput input) =>
    12 +
    input.trips.length +
    (input.server?.values.whereType<List<dynamic>>().length ?? 0) +
    (input.server?['error'] != null ? 1 : 0);

String _safe(String id) => id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

String _readme(FullDataExportInput i, int entries) => '''
Sparkilo — export of all your data (GDPR Art. 20)
Exported: ${i.exportedAt.toUtc().toIso8601String()}
App version: ${i.appVersion}
Privacy policy version: ${i.policyVersion}
Entries: $entries

local/   everything stored on this device (JSON; one GPX per recorded trip)
server/  every table of your TankSync database (present only when connected)
local/consent.json  the consents you gave, when, and the policy version

Decode a box file's values as JSON where they are JSON strings.
''';

/// Decodes a `Box<String>` map of JSON strings; non-JSON values pass
/// through unchanged so a malformed row never blocks the export.
Map<String, dynamic> decodeJsonBox(Map<dynamic, dynamic> raw) => {
      for (final e in raw.entries)
        '${e.key}': e.value is String ? _tryDecode(e.value as String) : e.value,
    };

dynamic _tryDecode(String s) {
  try {
    return jsonDecode(s);
  } on FormatException {
    return s;
  }
}
