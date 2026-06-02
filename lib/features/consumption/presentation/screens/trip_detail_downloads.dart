// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/sharing/public_file_exporter.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/exporters/gpx_exporter.dart';
import '../../data/exporters/trip_detail_exporter.dart';
import '../../data/trip_history_repository.dart';

/// Test seam mirroring [debugTripDetailGpxShareOverride]
/// (trip_detail_gpx_share.dart): lets the widget test capture
/// `{text, fileName, mimeType}` for the CSV / JSON download handlers
/// without touching the platform channel.
@visibleForTesting
Future<void> Function({
  required String text,
  required String fileName,
  required String mimeType,
})? debugTripDetailDownloadOverride;

/// Save the trip's full telemetry sample stream as a CSV file to the
/// device's public Downloads folder (#2652). Mirrors [shareTripGpx]:
/// serialize → [PublicFileExporter.saveTextToDownloads] → a single
/// success / error snackbar. Download-only — no share sheet (the
/// 2026-05-24 "files only download" decision). A samples-less trip
/// (legacy summary-only entry) short-circuits with the same "no GPS
/// samples in this trip" empty message the GPX path uses, so the user
/// is never handed a header-only file.
Future<void> downloadTripCsv(
  BuildContext context,
  AppLocalizations? l,
  TripHistoryEntry entry,
) =>
    _downloadTripText(
      context,
      l,
      entry,
      text: () => buildTripDetailCsv(entry),
      fileName: _fileNameFor(entry, 'csv'),
      mimeType: 'text/csv',
    );

/// Save the trip as its persisted, re-importable JSON wire form to the
/// device's public Downloads folder (#2652). Same delivery + error +
/// empty-trip semantics as [downloadTripCsv].
Future<void> downloadTripJson(
  BuildContext context,
  AppLocalizations? l,
  TripHistoryEntry entry,
) =>
    _downloadTripText(
      context,
      l,
      entry,
      text: () => buildTripDetailJson(entry),
      fileName: _fileNameFor(entry, 'json'),
      mimeType: 'application/json',
    );

Future<void> _downloadTripText(
  BuildContext context,
  AppLocalizations? l,
  TripHistoryEntry entry, {
  required String Function() text,
  required String fileName,
  required String mimeType,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final scheme = Theme.of(context).colorScheme;
  if (entry.samples.isEmpty) {
    final msg = l?.trajetDetailShareGpxEmpty ?? 'No GPS samples in this trip';
    messenger?.showSnackBar(SnackBarHelper.errorSnackBar(scheme, msg));
    return;
  }
  final payload = text();
  final override = debugTripDetailDownloadOverride;
  try {
    if (override != null) {
      await override(text: payload, fileName: fileName, mimeType: mimeType);
      return;
    }
    await PublicFileExporter.saveTextToDownloads(
      text: payload,
      fileName: fileName,
      mimeType: mimeType,
    );
    if (messenger == null) return;
    final ok = l?.savedToDownloadsFolder ?? 'Saved to your Downloads folder';
    messenger.showSnackBar(SnackBarHelper.successSnackBar(scheme, ok));
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.ui, e, st,
        context: const {'where': 'TripDetailScreen download'}));
    if (messenger == null) return;
    final errorMsg = l?.trajetDetailDownloadError ?? "Couldn't save the file";
    messenger.showSnackBar(SnackBarHelper.errorSnackBar(scheme, errorMsg));
  }
}

/// Builds the share / download popup-menu rows for the trip-detail
/// AppBar (#2032 + #2240 + #2652). Lives here (next to the download
/// handlers) so `trip_detail_screen.dart` stays under the 400-line
/// guard. Values map to the screen's `onSelected` switch: `image`,
/// `gpx`, `download_csv`, `download_json`, `cross_account`.
///
/// [showCrossAccount] gates the #2240 cross-account row (only when trip
/// sync is on). The GPX row doubles as the GPS-track download — it is
/// disabled (with an explanatory subtitle) when the trip has no GPS fix.
List<PopupMenuEntry<String>> buildTripDetailShareMenuItems(
  AppLocalizations? l,
  TripHistoryEntry entry, {
  required bool showCrossAccount,
}) {
  final hasGps = countGpsFixes(entry) > 0;
  return <PopupMenuEntry<String>>[
    PopupMenuItem<String>(
      key: const Key('trip_detail_share_image_option'),
      value: 'image',
      child: ListTile(
        leading: const Icon(Icons.image_outlined),
        title: Text(l?.trajetDetailShareImageOption ?? 'Share image'),
      ),
    ),
    PopupMenuItem<String>(
      key: const Key('trip_detail_share_gpx_option'),
      value: 'gpx',
      enabled: hasGps,
      child: ListTile(
        leading: const Icon(Icons.route_outlined),
        title: Text(
          l?.trajetDetailShareGpxOption ?? 'Share GPS track (GPX)',
        ),
        subtitle: hasGps
            ? null
            : Text(
                l?.trajetDetailShareGpxEmpty ?? 'No GPS samples in this trip',
              ),
      ),
    ),
    // #2652 — download the full telemetry sample stream (OBD2 + GPS)
    // for spreadsheet / pandas analysis or re-import. The GPX row above
    // is the GPS-track download; these add the machine-readable formats.
    PopupMenuItem<String>(
      key: const Key('trip_detail_download_csv_option'),
      value: 'download_csv',
      child: ListTile(
        leading: const Icon(Icons.table_chart_outlined),
        title: Text(
          l?.trajetDetailDownloadCsvOption ?? 'Download telemetry (CSV)',
        ),
      ),
    ),
    PopupMenuItem<String>(
      key: const Key('trip_detail_download_json_option'),
      value: 'download_json',
      child: ListTile(
        leading: const Icon(Icons.data_object),
        title: Text(
          l?.trajetDetailDownloadJsonOption ?? 'Download telemetry (JSON)',
        ),
      ),
    ),
    // #2240 — cross-account share, only when trip sync is on (you can't
    // share a trip the server doesn't have).
    if (showCrossAccount)
      PopupMenuItem<String>(
        key: const Key('trip_detail_share_cross_account_option'),
        value: 'cross_account',
        child: ListTile(
          leading: const Icon(Icons.group_add_outlined),
          title: Text(
            l?.tripShareAction ?? 'Share with another account',
          ),
        ),
      ),
  ];
}

/// Filename for a trip download in [extension] (no leading dot). Mirrors
/// [gpxFileNameFor] so CSV / JSON / GPX share one date stem:
/// `tankstellen-trajet-<YYYYMMDD>T<hhmm>.<ext>`, falling back to the
/// trip id when the trip has no start time.
String _fileNameFor(TripHistoryEntry entry, String extension) {
  final gpxName = gpxFileNameFor(entry); // …/.gpx
  final stem = gpxName.substring(0, gpxName.length - '.gpx'.length);
  return '$stem.$extension';
}
