// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/sharing/public_file_exporter.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/exporters/gpx_exporter.dart';
import '../../data/trip_history_repository.dart';

/// Test-only override for the GPX save sink (#2032). Originally named
/// `*ShareOverride` when this path used the OS share sheet; preserved
/// for test compatibility after the action became download-only in
/// the 2026-05-24 follow-up (user request: "for files only download
/// and do not suggest sharing").
@visibleForTesting
Future<void> Function({
  required Uint8List bytes,
  required String fileName,
})? debugTripDetailGpxShareOverride;

/// Export the trip's persisted GPS samples as a GPX 1.1 file and save
/// it to the device's public Downloads folder (#2032 + 2026-05-24
/// follow-up). The file lands where the user can find it via the
/// system file manager — no share sheet, no chooser; a single
/// confirmation snackbar reports success.
///
/// Best-effort: a save failure surfaces an error snackbar, never
/// throws. Empty-GPS trips short-circuit with the same "no GPS
/// samples" message the share path used.
Future<void> shareTripGpx(
  BuildContext context,
  AppLocalizations? l,
  TripHistoryEntry entry,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final scheme = Theme.of(context).colorScheme;
  if (countGpsFixes(entry) == 0) {
    final msg = l?.trajetDetailShareGpxEmpty ?? 'No GPS samples in this trip';
    messenger?.showSnackBar(SnackBarHelper.errorSnackBar(scheme, msg));
    return;
  }
  final gpx = buildGpxXml(entry);
  final bytes = Uint8List.fromList(utf8.encode(gpx));
  final fileName = gpxFileNameFor(entry);
  final override = debugTripDetailGpxShareOverride;
  try {
    if (override != null) {
      await override(bytes: bytes, fileName: fileName);
      return;
    }
    await PublicFileExporter.saveBytesToDownloads(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/gpx+xml',
    );
    if (messenger == null) return;
    final ok =
        l?.savedToDownloadsFolder ?? 'Saved to your Downloads folder';
    messenger.showSnackBar(SnackBar(content: Text(ok)));
  } catch (e, st) {
    debugPrint('TripDetailScreen save GPX: $e\n$st');
    if (messenger == null) return;
    final errorMsg = l?.trajetDetailShareError ?? "Couldn't save the GPX file";
    messenger.showSnackBar(SnackBarHelper.errorSnackBar(scheme, errorMsg));
  }
}
