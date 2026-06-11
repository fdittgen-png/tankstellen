// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/sharing/public_file_exporter.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import 'backup_progress_dialog.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/exporters/backup/backup_xml_reader.dart';
import '../../data/exporters/backup/backup_zip_reader.dart';
import '../../data/exporters/backup/full_backup_importer.dart';
import '../../providers/charging_logs_provider.dart';
import '../../providers/consumption_providers.dart';
import '../../providers/trip_history_provider.dart';

/// Picks a `.zip` backup the user supplies and returns its raw bytes,
/// or null when the user cancelled (#2571). Injectable so widget tests
/// can drive the restore flow without the OS file dialog.
typedef BackupFilePicker = Future<Uint8List?> Function();

/// Drives the full-backup RESTORE user flow (#2571): pick a `.zip`,
/// confirm MERGE vs REPLACE, run [FullBackupImporter] against the
/// Riverpod-backed repositories, and surface success / failure via
/// [SnackBarHelper].
///
/// Lives outside [ConsumptionScreen] so that screen stays under the
/// 400-line guard and the flow is independently testable. The screen
/// owns nothing but the AppBar button that calls [run].
class BackupRestoreFlow {
  BackupRestoreFlow._();

  /// Test-only override for the file picker. Production uses the
  /// [file_selector] document picker; widget tests inject fixed bytes
  /// (or null to simulate a cancel).
  @visibleForTesting
  static BackupFilePicker? debugFilePickerOverride;

  /// Test-only override for the importer so a test can assert the flow
  /// without a real zip/XML round trip.
  @visibleForTesting
  static FullBackupImporter? debugImporterOverride;

  /// Entry point wired to the AppBar restore button. Safe to call with
  /// `unawaited(...)` from a button callback.
  static Future<void> run(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);

    final Uint8List? bytes;
    try {
      bytes = await (debugFilePickerOverride ?? _pickZipBytes)();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st,
          context: const {'where': 'BackupRestoreFlow: file pick failed'}));
      if (!context.mounted) return;
      SnackBarHelper.showError(
        context,
        l?.restoreBackupFailed ??
            'Restore failed — the file could not be read',
      );
      return;
    }
    if (bytes == null) return; // user cancelled the picker
    if (!context.mounted) return;

    final mode = await _confirmMode(context, l);
    if (mode == null) return; // user cancelled the dialog
    if (!context.mounted) return;

    final sinks = _sinksFor(ref);
    final importer = debugImporterOverride ?? FullBackupImporter();
    try {
      // #2815 — show an indeterminate progress modal while the zip decodes,
      // the XML parses, and 100+ records are written (previously a silent
      // freeze). Shown after the merge/replace confirmation so it doesn't
      // stack on that dialog.
      final result = await runWithBackupProgress(
        context,
        label: l?.backupImportProgress ?? 'Restoring your backup…',
        icon: Icons.settings_backup_restore,
        // bytes is non-null here (early-returned above); the `!` is needed
        // because promotion doesn't cross the closure boundary.
        work: () => importer.import(bytes: bytes!, sinks: sinks, mode: mode),
      );

      // #3159 — guard BEFORE the invalidates: the import await above means
      // the host can be gone here, and invalidating on a dead WidgetRef
      // throws a StateError under Riverpod 3. (Skipping just defers the
      // list refresh to the next provider rebuild.)
      if (!context.mounted) return;
      // Refresh every list provider so the restored records appear
      // without a relaunch. The repositories were written directly, so
      // the notifiers must be invalidated to re-read their stores.
      ref.invalidate(vehicleProfileListProvider);
      ref.invalidate(fillUpListProvider);
      ref.invalidate(tripHistoryListProvider);
      ref.invalidate(chargingLogsProvider);

      // #2815 — surface the per-entity breakdown, worded by mode so the user
      // sees exactly what was "merged" vs "replaced" (the result already
      // carries the counts + mode).
      final String msg;
      if (result.total == 0) {
        msg = l?.restoreBackupEmpty ??
            'Backup restored — it contained no records';
      } else if (result.mode == BackupImportMode.replace) {
        msg = l?.restoreBackupReplacedSummary(result.vehicles, result.fillUps,
                result.trips, result.chargingLogs) ??
            'Replaced all data with ${result.vehicles} vehicles, '
                '${result.fillUps} fill-ups, ${result.trips} trips, '
                '${result.chargingLogs} charging logs';
      } else {
        msg = l?.restoreBackupMergedSummary(result.vehicles, result.fillUps,
                result.trips, result.chargingLogs) ??
            'Merged ${result.vehicles} vehicles, ${result.fillUps} fill-ups, '
                '${result.trips} trips, ${result.chargingLogs} charging logs';
      }
      SnackBarHelper.showSuccess(context, msg);
    } on BackupZipReadException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st,
          context: const {'where': 'BackupRestoreFlow: corrupt zip'}));
      if (!context.mounted) return;
      SnackBarHelper.showError(
        context,
        l?.restoreBackupCorrupt ??
            'Restore failed — this file is not a valid Tankstellen backup',
      );
    } on BackupXmlReadException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st,
          context: const {'where': 'BackupRestoreFlow: bad XML/version'}));
      if (!context.mounted) return;
      SnackBarHelper.showError(
        context,
        l?.restoreBackupCorrupt ??
            'Restore failed — this file is not a valid Tankstellen backup',
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st,
          context: const {'where': 'BackupRestoreFlow: import failed'}));
      if (!context.mounted) return;
      SnackBarHelper.showError(
        context,
        l?.restoreBackupFailed ??
            'Restore failed — the file could not be read',
      );
    }
  }

  /// Open the OS document picker filtered to `.zip` and read the bytes.
  static Future<Uint8List?> _pickZipBytes() async {
    const group = XTypeGroup(
      // Brand-neutral filter group; the label is not user-visible on the
      // platforms we ship.
      label: 'zip', // i18n-ignore: file-extension filter label, not UI copy
      extensions: <String>['zip'],
      mimeTypes: <String>['application/zip'],
      uniformTypeIdentifiers: <String>['public.zip-archive'],
    );
    // #2815 — open the picker ON the Downloads folder (where exports are
    // saved) instead of the usually-empty "Recents" tab. A hint on Android
    // SAF (honoured on most OEMs; harmless where ignored).
    final initialDirectory =
        await PublicFileExporter.downloadsInitialDirectory();
    final file = await openFile(
      initialDirectory: initialDirectory,
      acceptedTypeGroups: const <XTypeGroup>[group],
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  /// Merge-vs-replace confirmation. Returns the chosen
  /// [BackupImportMode], or null when the user dismissed the dialog.
  /// Replace is the destructive option, so it carries the heavier
  /// styling and an explicit warning line in the body.
  static Future<BackupImportMode?> _confirmMode(
    BuildContext context,
    AppLocalizations? l,
  ) {
    return showDialog<BackupImportMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l?.restoreBackupDialogTitle ?? 'Restore backup'),
        content: Text(
          l?.restoreBackupDialogBody ??
              'Merge adds and updates records from the backup and keeps '
                  'everything already on this device. Replace deletes all '
                  'current data first, then restores only the backup — this '
                  'cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(BackupImportMode.replace),
            child: Text(l?.restoreBackupReplaceAction ?? 'Replace all'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(BackupImportMode.merge),
            child: Text(l?.restoreBackupMergeAction ?? 'Merge'),
          ),
        ],
      ),
    );
  }

  /// Build the repository-backed sinks. Writes go straight through the
  /// repositories/stores (not the notifier `add` paths) so a bulk
  /// restore doesn't trigger the per-fill-up reconciliation cascade; the
  /// caller invalidates the list providers afterwards to refresh the UI.
  static BackupImportSinks _sinksFor(WidgetRef ref) {
    final vehicleRepo = ref.read(vehicleProfileRepositoryProvider);
    final fillUpRepo = ref.read(fillUpRepositoryProvider);
    final tripRepo = ref.read(tripHistoryRepositoryProvider);
    final chargingStore = ref.read(chargingLogStoreProvider);
    return BackupImportSinks(
      saveVehicle: vehicleRepo.save,
      clearVehicles: vehicleRepo.clear,
      saveFillUp: fillUpRepo.save,
      clearFillUps: fillUpRepo.clear,
      saveTrip: (trip) async {
        if (tripRepo == null) return;
        await tripRepo.save(trip);
      },
      clearTrips: () async {
        if (tripRepo == null) return;
        await tripRepo.clearAll();
      },
      saveChargingLog: chargingStore.upsert,
      clearChargingLogs: chargingStore.clearAll,
    );
  }
}
