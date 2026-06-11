// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../../../../ev/domain/entities/charging_log.dart';
import '../../../../../core/domain/vehicle_profile.dart';
import '../../../domain/correction_fill_up.dart';
import '../../../domain/entities/fill_up.dart';
import '../../trip_dedup.dart';
import '../../trip_history_repository.dart';
import 'backup_xml_reader.dart';
import 'backup_zip_reader.dart';

/// How a restore reconciles the backup's records against the data
/// already on the device (#2571).
///
/// Data-loss care: [merge] is the safe default — it adds new ids and
/// updates matching ids without ever removing a local record the backup
/// doesn't mention. [replace] wipes each store first, so it must always
/// sit behind an explicit confirmation in the UI.
enum BackupImportMode {
  /// Upsert every backed-up record by id; leave untouched any local
  /// record whose id isn't in the backup. No data is deleted.
  merge,

  /// Clear every store, then write only the backed-up records. Local
  /// records absent from the backup are permanently removed.
  replace,
}

/// Sinks the importer writes restored entities through (#2571).
///
/// The importer has no Riverpod dependency — exactly like
/// [FullBackupExporter] reads its snapshots from caller-supplied lists,
/// the importer writes through caller-supplied functions. This keeps it
/// trivially unit-testable against in-memory fakes and lets the
/// consumption screen own the "which provider/repository persists this"
/// decision.
///
/// Each `save*` is an upsert-by-id (matching the repositories'
/// existing `save` / `upsert` semantics). Each `clear*` wipes the
/// corresponding store and is invoked once, up front, only in
/// [BackupImportMode.replace].
@immutable
class BackupImportSinks {
  final Future<void> Function(VehicleProfile) saveVehicle;
  final Future<void> Function() clearVehicles;
  final Future<void> Function(FillUp) saveFillUp;
  final Future<void> Function() clearFillUps;
  final Future<void> Function(TripHistoryEntry) saveTrip;
  final Future<void> Function() clearTrips;
  final Future<void> Function(ChargingLog) saveChargingLog;
  final Future<void> Function() clearChargingLogs;

  const BackupImportSinks({
    required this.saveVehicle,
    required this.clearVehicles,
    required this.saveFillUp,
    required this.clearFillUps,
    required this.saveTrip,
    required this.clearTrips,
    required this.saveChargingLog,
    required this.clearChargingLogs,
  });
}

/// Per-entity counts written by a successful import — surfaced in the
/// confirmation snackbar and asserted by tests.
@immutable
class FullBackupImportResult {
  final BackupImportMode mode;
  final int vehicles;
  final int fillUps;
  final int trips;
  final int chargingLogs;

  const FullBackupImportResult({
    required this.mode,
    required this.vehicles,
    required this.fillUps,
    required this.trips,
    required this.chargingLogs,
  });

  int get total => vehicles + fillUps + trips + chargingLogs;
}

/// Orchestrates the full Tankstellen restore pipeline (#2571) — the
/// mirror image of [FullBackupExporter]:
///
///   1. Decode the chosen `.zip` bytes via [BackupZipReader].
///   2. Parse the v1 XML via [BackupXmlReader] (version-dispatched).
///   3. In [BackupImportMode.replace] only, clear each store first.
///   4. Upsert every backed-up record through the supplied sinks.
///
/// Throws [BackupZipReadException] / [BackupXmlReadException] on a
/// corrupt or unrecognised file; the caller catches these and surfaces
/// a localized error. An empty-but-valid backup completes successfully
/// with a zero-count result.
class FullBackupImporter {
  final BackupZipReader zipReader;
  final BackupXmlReader xmlReader;

  FullBackupImporter({
    BackupZipReader? zipReader,
    BackupXmlReader? xmlReader,
  })  : zipReader = zipReader ?? const BackupZipReader(),
        xmlReader = xmlReader ?? const BackupXmlReader();

  /// Read [bytes], parse, and write the restored records through
  /// [sinks] using the requested [mode].
  Future<FullBackupImportResult> import({
    required Uint8List bytes,
    required BackupImportSinks sinks,
    required BackupImportMode mode,
  }) async {
    final xml = zipReader.readXml(bytes);
    final payload = xmlReader.read(xml);

    // #2834 — drop OBD2-reconciliation correction records before they
    // reach the store. They are derived data (TotalCost 0, IsFullTank
    // false, unrounded litres); a v1 backup loses the `isCorrection` flag
    // so the durable `correction_` id prefix is what identifies them. Left
    // in, they resurface as phantom zero-cost fill-ups and re-export
    // forever.
    final fillUps = withoutReconciliationCorrections(payload.fillUps);
    // #2833 — drop ghost 0-sample trips whose sampled twin is also in the
    // backup (a finalisation double-save artefact), so the import neither
    // restores nor counts the duplicate.
    final trips = dedupeGhostTrips(payload.trips);

    if (mode == BackupImportMode.replace) {
      // Wipe up front so a record the backup omits is removed exactly
      // once. Order is immaterial — the stores are independent.
      await sinks.clearVehicles();
      await sinks.clearFillUps();
      await sinks.clearTrips();
      await sinks.clearChargingLogs();
    }

    for (final v in payload.vehicles) {
      await sinks.saveVehicle(v);
    }
    for (final f in fillUps) {
      await sinks.saveFillUp(f);
    }
    for (final t in trips) {
      await sinks.saveTrip(t);
    }
    for (final c in payload.chargingLogs) {
      await sinks.saveChargingLog(c);
    }

    return FullBackupImportResult(
      mode: mode,
      vehicles: payload.vehicles.length,
      fillUps: fillUps.length,
      trips: trips.length,
      chargingLogs: payload.chargingLogs.length,
    );
  }
}
