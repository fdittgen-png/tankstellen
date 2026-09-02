// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/error/guarded.dart';
import '../../../../../../core/export/data_exporter.dart';
import '../../../../../../core/logging/error_logger.dart';
import '../../../../../../core/navigation/app_routes.dart';
import '../../../../../../core/providers/app_state_provider.dart';
import '../../../../../../core/services/sensitive_clipboard.dart';
import '../../../../../../core/sharing/public_file_exporter.dart';
import '../../../../../../core/sharing/share_seam.dart';
import '../../../../../../core/storage/hive_boxes.dart';
import '../../../../../../core/storage/local_data_eraser.dart';
import '../../../../../../core/storage/storage_providers.dart';
import '../../../../../../core/sync/sync_provider.dart';
import '../../../../../../core/sync/user_data_sync.dart';
import '../../../../../../core/telemetry/storage/trace_storage.dart';
import '../../../../../../core/time/app_clock.dart';
import '../../../../../../core/utils/unit_formatter.dart';
import '../../../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../../../core/widgets/snackbar_helper.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../charging/api.dart' show chargingLogsProvider;
import '../../../../../fill_ups/api.dart' show fillUpListProvider;
import '../../../../../obd2/api.dart' show ActiveTripSampleWal;
import '../../../../../trips/api.dart' show tripHistoryRepositoryProvider;
import '../../../../../vehicle/api.dart'
    show serviceReminderRepositoryProvider, vehicleProfileListProvider;
import '../../../../../widget/api.dart' show clearHomeWidgetData;
import '../../../../data/full_data_export.dart';
import '../../../../providers/privacy_data_provider.dart';
import '../../../widgets/error_log_export_row.dart'
    show errorLogExportSnackbar, exportErrorLogSizeGated;

/// Test-only override for the share-sheet handoff used by
/// [PrivacyExportActions.exportErrorLog] — the shared [ShareSink] seam
/// (#1301).
@visibleForTesting
ShareSink? debugPrivacyShareSinkOverride;

/// Test-only override for the temporary-directory lookup used by the
/// large-log share path — the shared [ShareTempDirectoryProvider] seam
/// (#1301).
@visibleForTesting
ShareTempDirectoryProvider? debugPrivacyTempDirectoryOverride;

/// The export / error-log / delete handlers of the "Export or delete"
/// screen (#3912, Epic #3907) — moved verbatim from the former Privacy
/// Dashboard state so every write path (ZIP #3869, JSON, CSV, the
/// size-gated error-log export #1301/#2236, the registry-driven local
/// erasure #3867) stays the one implementation.
mixin PrivacyExportActions<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// #3869 (Epic #3865, GDPR Art. 20) — one ZIP with everything.
  Future<void> exportAll() async {
    final l = AppLocalizations.of(context);
    final consent = ref.read(gdprConsentProvider);
    final syncConfig = ref.read(syncStateProvider);
    final server =
        syncConfig.userId != null ? await UserDataSync.fetchAll() : null;
    if (!mounted) return;
    Map<String, dynamic> box(String name) => Hive.isBoxOpen(name)
        ? decodeJsonBox(Hive.box<String>(name).toMap())
        : const {};
    final input = FullDataExportInput(
      appVersion: AppConstants.appVersion,
      exportedAt: ref.read(appClockProvider).now(),
      policyVersion: AppConstants.privacyPolicyVersion,
      appDataJson: ref.read(exportPrivacyDataProvider),
      vehicles: ref.read(vehicleProfileListProvider),
      fillUps: ref.read(fillUpListProvider),
      trips: ref.read(tripHistoryRepositoryProvider)?.loadAll() ?? const [],
      chargingLogs: ref.read(chargingLogsProvider).asData?.value ?? const [],
      serviceReminders: ref.read(serviceReminderRepositoryProvider).getAll(),
      baselines: box(HiveBoxes.obd2Baselines),
      achievements: box(HiveBoxes.achievements),
      obd2Caches: {
        HiveBoxes.obd2SupportedPids: box(HiveBoxes.obd2SupportedPids),
        HiveBoxes.obd2NegotiatedProtocol:
            box(HiveBoxes.obd2NegotiatedProtocol),
      },
      inProgressTrips: {
        HiveBoxes.obd2PausedTrips: box(HiveBoxes.obd2PausedTrips),
        HiveBoxes.obd2ActiveTrip: box(HiveBoxes.obd2ActiveTrip),
      },
      consent: {
        'location': consent.location,
        'errorReporting': consent.errorReporting,
        'cloudSync': consent.cloudSync,
        'syncTrips': consent.syncTrips,
        'vinOnlineDecode': consent.vinOnlineDecode,
        'recordedAt': consent.recordedAt?.toIso8601String(),
        'policyVersion': consent.policyVersion,
      },
      server: server,
    );
    final bytes = buildFullDataExportZip(input);
    final stamp = input.exportedAt.toIso8601String().substring(0, 10);
    final fileName = 'sparkilo-my-data-$stamp.zip';
    try {
      await PublicFileExporter.saveBytesToDownloads(
          bytes: bytes, fileName: fileName, mimeType: 'application/zip');
    } on Object catch (e, st) {
      logFailure(
        e,
        st,
        where: 'PrivacyExportActions.exportAll',
        layer: ErrorLayer.storage,
      );
      if (!mounted) return;
      SnackBarHelper.showError(context, l.privacyExportAllFailed);
      return;
    }
    if (!mounted) return;
    SnackBarHelper.showSuccess(context,
        l.privacyExportAllSuccess(fileName, fullDataExportEntryCount(input)));
  }

  Future<void> exportJson() async {
    // Grab the localizations BEFORE any async gap so the analyzer is
    // satisfied that we never reach across one to look up `context`.
    final l = AppLocalizations.of(context);
    final json = ref.read(exportPrivacyDataProvider);
    // #3611 — the export blob aggregates the user's stored data; use
    // SensitiveClipboard so the clipboard is auto-cleared after 60 s.
    await SensitiveClipboard.copy(json);
    // #1993 — also save a copy to the on-device Downloads folder so the
    // user can find the file later via any file manager.
    await _saveExportToDownloads(
      text: json,
      fileName: 'tankstellen-data.json',
      copySnackbar: l.privacyExportSuccess,
    );
  }

  Future<void> exportCsv() async {
    final l = AppLocalizations.of(context);
    final storage = ref.read(storageRepositoryProvider);
    final exporter = DataExporter(storage);
    final parts = exporter.exportAllAsCsv();
    final buf = StringBuffer();
    parts.forEach((name, csv) {
      buf
        ..writeln('# $name')
        ..writeln(csv);
    });
    final csvText = buf.toString();
    // #3611 — same hygiene as the JSON export: auto-clear after 60 s.
    await SensitiveClipboard.copy(csvText);
    await _saveExportToDownloads(
      text: csvText,
      fileName: 'tankstellen-data.csv',
      copySnackbar: l.privacyExportCsvSuccess,
    );
  }

  Future<void> exportErrorLog() async {
    final traces = ref.read(traceStorageProvider);
    final json = traces.exportAsJson();
    final byteSize = utf8.encode(json).length;
    final kb = UnitFormatter.formatDecimal(byteSize / 1024);
    final parsed = traces.parsedCount;
    final unparsed = traces.unparsedCount;
    final totalEntries = parsed + unparsed;

    // The ONE size-gated clipboard / share-seam / single-Downloads-write
    // flow (#1301 / #1993 / #2236 / #3611), shared with the Developer
    // tools row (#2248) via `exportErrorLogSizeGated`.
    final outcome = await exportErrorLogSizeGated(
      json: json,
      logWhere: 'PrivacyExportActions.exportErrorLog',
      shareSink: debugPrivacyShareSinkOverride,
      tempDirectoryProvider: debugPrivacyTempDirectoryOverride,
    );
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(
      context,
      errorLogExportSnackbar(
        outcome: outcome,
        savedToDownloadsMessage: l.savedToDownloadsFolder,
        parsed: parsed,
        unparsed: unparsed,
        totalEntries: totalEntries,
        kb: kb,
      ),
    );
  }

  /// Clears every buffered error trace and refreshes the count (#1971).
  Future<void> clearErrorLog() async {
    await ref.read(traceStorageProvider).clearAll();
    if (!mounted) return;
    // `traceStorageProvider` hands back a stable wrapper over the Hive
    // box, so invalidate it to force `build`'s `count` read to re-run.
    ref.invalidate(traceStorageProvider);
    final l = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(context, l.privacyErrorLogCleared);
  }

  /// Writes [text] to the device's public Downloads folder via
  /// [PublicFileExporter] (#2014) and announces the outcome; on failure
  /// falls back to [copySnackbar] so the user still gets the clipboard
  /// confirmation.
  Future<void> _saveExportToDownloads({
    required String text,
    required String fileName,
    required String copySnackbar,
  }) async {
    final l = AppLocalizations.of(context);
    try {
      await PublicFileExporter.saveTextToDownloads(
        text: text,
        fileName: fileName,
        mimeType: fileName.endsWith('.csv') ? 'text/csv' : 'application/json',
      );
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, l.savedToDownloadsFolder);
    } on Object catch (e, st) {
      // #2146 — surface on the user-exportable log.
      logFailure(
        e,
        st,
        where: 'PrivacyExportActions._saveExportToDownloads',
        layer: ErrorLayer.storage,
        extra: {'fileName': fileName},
      );
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, copySnackbar);
    }
  }

  /// The delete-everything flow: the shared confirmation (#3682), then —
  /// with sync configured — the server erasure with its honest per-table
  /// outcome (#3868), then the ONE registry-driven local erasure (#3867:
  /// every box, secure storage, prefs, the widget container, the trip
  /// WAL), and back to setup.
  Future<void> deleteAllData() async {
    final l = AppLocalizations.of(context);
    final syncConfig = ref.read(syncStateProvider);
    final syncNotifier = ref.read(syncStateProvider.notifier);
    final storage = ref.read(storageRepositoryProvider);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l.privacyDeleteTitle,
      message: syncConfig.isConfigured
          ? '${l.privacyDeleteBody}\n\n${l.privacyDangerZoneBody}'
          : l.privacyDeleteBody,
      confirmLabel: l.privacyDeleteConfirm,
      confirmKey: const Key('privacyDeleteConfirmButton'),
    );
    if (!confirmed || !mounted) return;

    if (syncConfig.isConfigured) {
      final server = await syncNotifier.deleteAccount();
      if (!mounted) return;
      if (!server.complete) {
        SnackBarHelper.showError(
            context, l.serverErasurePartial(server.failedTables.join(', ')));
      }
    }

    final result = await LocalDataEraser.eraseAll(
      storage: storage,
      extraWipes: [clearHomeWidgetData, ActiveTripSampleWal.instance.clear],
    );
    if (!mounted) return;
    ref.invalidate(storageManagementProvider);
    ref.invalidate(deviceDataInventoryProvider);
    if (!result.complete) {
      SnackBarHelper.showError(
          context, l.localErasurePartial(result.failedSteps.join(', ')));
    }
    context.go(RoutePaths.setup);
  }
}
