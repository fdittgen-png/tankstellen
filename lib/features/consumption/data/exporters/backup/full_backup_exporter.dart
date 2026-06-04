// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/sharing/public_file_exporter.dart';
import '../../../../ev/domain/entities/charging_log.dart';
import '../../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../domain/correction_fill_up.dart';
import '../../../domain/entities/fill_up.dart';
import '../../trip_dedup.dart';
import '../../trip_history_repository.dart';
import 'backup_xml_writer.dart';
import 'backup_zipper.dart';
import '../../../../../core/logging/error_logger.dart';

/// Hook for the share-sheet handoff (#1317). Production uses
/// `SharePlus.instance.share`; tests substitute a fake via
/// [debugBackupShareSinkOverride] to assert the outgoing [ShareParams]
/// without launching the OS share sheet.
typedef BackupShareSink = Future<void> Function(ShareParams params);

/// Test-only override for the share sink used by [FullBackupExporter].
@visibleForTesting
BackupShareSink? debugBackupShareSinkOverride;

/// Hook for the temporary-directory lookup used by [FullBackupExporter].
typedef BackupTempDirectoryProvider = Future<Directory> Function();

/// Test-only override for the temp-directory lookup. Returns a
/// [Directory] the exporter is allowed to write into.
@visibleForTesting
BackupTempDirectoryProvider? debugBackupTempDirectoryOverride;

/// Test-only override for the wall-clock used to stamp the backup
/// filename and the `<ExportedAt>` element.
@visibleForTesting
DateTime Function()? debugBackupClockOverride;

/// Test-only override for the app version embedded in `<AppVersion>`.
/// Defaults to [AppConstants.appVersion] in production.
@visibleForTesting
String? debugBackupAppVersionOverride;

/// Result of a successful export — the bytes written, the absolute
/// temp-file path used for the share sheet, and the on-device Downloads
/// path the same payload was also written to (#1993). Returned for
/// instrumentation / tests; the production caller hands [filePath] off
/// to the share sheet via the supplied sink and surfaces [savedPath]
/// in a confirmation snackbar so the user can find the file in any
/// file manager.
@immutable
class FullBackupExportResult {
  final String filePath;
  final int byteSize;

  /// Absolute path under `<docs>/Downloads/` where a second copy of the
  /// zip was written. `null` only if the save-to-Downloads side step
  /// failed; the temp-file + share-sheet path is unaffected.
  final String? savedPath;

  /// The bare backup file name (`tankstellen_backup_<stamp>.zip`), so the
  /// success UX can tell the user what to look for in the picker (#2815).
  /// The platform [savedPath] (a `content://` URI on Android) is NOT
  /// user-displayable; this is.
  final String fileName;

  const FullBackupExportResult({
    required this.filePath,
    required this.byteSize,
    required this.fileName,
    this.savedPath,
  });
}

/// Orchestrates the full Tankstellen backup pipeline (#1317):
///
///   1. Pull current snapshots of vehicles + fill-ups + trips +
///      charging logs from caller-supplied lists.
///   2. Build a v1 XML document via [BackupXmlWriter].
///   3. Compress into a single-entry zip via [BackupZipper].
///   4. Persist the bytes under the platform's temporary directory.
///   5. Hand the resulting `XFile` to the OS share sheet.
///
/// The exporter has no Riverpod dependency — call sites read the
/// providers and pass the snapshots in. This keeps the class trivially
/// testable (no `ProviderContainer` setup) and lets the consumption
/// screen own the "which providers do we read" decision.
class FullBackupExporter {
  final BackupXmlWriter xmlWriter;
  final BackupZipper zipper;

  FullBackupExporter({
    BackupXmlWriter? xmlWriter,
    BackupZipper? zipper,
  })  : xmlWriter = xmlWriter ?? BackupXmlWriter(),
        zipper = zipper ?? const BackupZipper();

  /// Build, persist and share a backup containing the supplied
  /// snapshots. Returns the bytes-on-disk metadata so callers can
  /// surface a confirmation snackbar with a non-zero size.
  Future<FullBackupExportResult> export({
    required List<VehicleProfile> vehicles,
    required List<FillUp> fillUps,
    required List<TripHistoryEntry> trips,
    required List<ChargingLog> chargingLogs,
  }) async {
    final clock = debugBackupClockOverride ?? DateTime.now;
    final now = clock();
    final appVersion = debugBackupAppVersionOverride ?? AppConstants.appVersion;

    // #2834 — never write OBD2-reconciliation correction records into a
    // backup: they are derived data (zero-cost, unrounded litres) that
    // would re-import as phantom fill-ups. #2833 — drop ghost 0-sample
    // trip duplicates so a backup carries the de-duped truth (the in-app
    // `loadAll` already de-dupes, but a caller that passes a raw list is
    // covered here too).
    final cleanFillUps = withoutReconciliationCorrections(fillUps);
    final cleanTrips = dedupeGhostTrips(trips);

    final xml = xmlWriter.build(
      vehicles: vehicles,
      fillUps: cleanFillUps,
      trips: cleanTrips,
      chargingLogs: chargingLogs,
      appVersion: appVersion,
      exportedAt: now,
    );

    final bytes = zipper.zip(xml, now: now);
    final tempDir = await (debugBackupTempDirectoryOverride ??
        getTemporaryDirectory)();

    final stamp = BackupZipper.stampFor(now);
    final fileName = 'tankstellen_backup_$stamp.zip';
    final filePath = '${tempDir.path}${Platform.pathSeparator}$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    // 2026-05-24 follow-up — file exports go straight to the device's
    // public Downloads folder via PublicFileExporter (MediaStore on
    // Android Q+, Files-app-visible Documents/Downloads on iOS). The
    // OS share sheet is no longer offered: the user explicitly asked
    // for "files only download, do not suggest sharing." The tempDir
    // copy above is kept because some test fakes assert on
    // `result.filePath`; the production caller now only reads
    // `result.savedPath` and surfaces a "Saved to Downloads" snackbar.
    String? savedPath;
    try {
      savedPath = await PublicFileExporter.saveBytesToDownloads(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'application/zip',
      );
    } on Object catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'FullBackupExporter: save-to-downloads failed'}));
    }

    // Keep the share-sink shape so existing test fakes (and any
    // future surface that wants to re-enable a share fallback) can
    // still hand the file off. Production wires the no-op default
    // below.
    final sink = debugBackupShareSinkOverride;
    if (sink != null) {
      final params = ShareParams(
        files: [XFile(filePath, mimeType: 'application/zip')],
        subject: fileName,
        text: fileName,
      );
      await sink(params);
    }

    return FullBackupExportResult(
      filePath: filePath,
      byteSize: bytes.length,
      fileName: fileName,
      savedPath: savedPath,
    );
  }
}

