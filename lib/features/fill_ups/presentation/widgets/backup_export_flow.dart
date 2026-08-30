// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/guarded.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../charging/api.dart';
import '../../../trips/api.dart';
import '../../../vehicle/api.dart';
import '../../data/exporters/backup/full_backup_exporter.dart';
import '../../providers/consumption_providers.dart';
import 'backup_progress_dialog.dart';

/// The full XML-in-ZIP backup export flow (#1317 / #2815), shared by the
/// Consumption overflow menu and Settings → Backup & restore (#3884).
///
/// One implementation for both call sites: gather vehicles, fill-ups,
/// trips and charging logs, run the exporter behind the indeterminate
/// progress modal, then name the written file in a success snackbar.
/// Failures are routed through [runGuarded] (logged + error snackbar).
class BackupExportFlow {
  const BackupExportFlow._();

  /// Runs the export from [context]. [exporter] lets a caller inject a
  /// recording exporter (the `ConsumptionScreen.debugExporterOverride`
  /// test seam); production passes null and gets a fresh
  /// [FullBackupExporter].
  static Future<void> run(
    BuildContext context,
    WidgetRef ref, {
    FullBackupExporter? exporter,
    String where = 'BackupExportFlow.run failed',
  }) async {
    final l = AppLocalizations.of(context);
    await runGuarded(
      context,
      where: where,
      errorText: l.exportBackupFailed,
      action: () async {
        final vehicles = ref.read(vehicleProfileListProvider);
        final fillUps = ref.read(fillUpListProvider);
        final tripsRepo = ref.read(tripHistoryRepositoryProvider);
        final trips = tripsRepo?.loadAll() ?? const [];
        final chargingLogs =
            ref.read(chargingLogsProvider).asData?.value ?? const [];

        final effectiveExporter = exporter ?? FullBackupExporter();
        // #2815 — show an indeterminate progress modal while the XML builds,
        // zips, and writes (1-3 s, previously a silent freeze).
        final result = await runWithBackupProgress(
          context,
          label: l.backupExportProgress,
          icon: Icons.archive_outlined,
          work: () => effectiveExporter.export(
            vehicles: vehicles,
            fillUps: fillUps,
            trips: trips,
            chargingLogs: chargingLogs,
          ),
        );

        if (!context.mounted) return;
        // #2014 / #2815 — when the exporter wrote a copy to the public
        // Downloads folder, name the file so the user can find it (e.g. in
        // the restore picker, which now also opens on Downloads).
        final message = (result.savedPath != null)
            ? (l.exportBackupSavedAs(result.fileName))
            : (l.exportBackupReady);
        SnackBarHelper.showSuccess(context, message);
      },
    );
  }
}
