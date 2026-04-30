import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../ev/domain/entities/charging_log.dart';
import '../../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../domain/entities/fill_up.dart';
import '../../trip_history_repository.dart';
import 'backup_xml_writer.dart';
import 'backup_zipper.dart';

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

/// Result of a successful export — the bytes written and the absolute
/// path on disk. Returned for instrumentation / tests; the production
/// caller hands the path off to the share sheet via the supplied sink
/// before this value is used.
@immutable
class FullBackupExportResult {
  final String filePath;
  final int byteSize;

  const FullBackupExportResult({
    required this.filePath,
    required this.byteSize,
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

    final xml = xmlWriter.build(
      vehicles: vehicles,
      fillUps: fillUps,
      trips: trips,
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

    final params = ShareParams(
      files: [XFile(filePath, mimeType: 'application/zip')],
      subject: fileName,
      text: fileName,
    );
    final sink = debugBackupShareSinkOverride ?? _defaultShareSink;
    await sink(params);

    return FullBackupExportResult(
      filePath: filePath,
      byteSize: bytes.length,
    );
  }
}

Future<void> _defaultShareSink(ShareParams params) =>
    SharePlus.instance.share(params);
