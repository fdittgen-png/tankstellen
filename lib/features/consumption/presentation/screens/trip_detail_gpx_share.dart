import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/exporters/gpx_exporter.dart';
import '../../data/trip_history_repository.dart';

/// Test-only override for the GPX share sink (#2032).
@visibleForTesting
Future<void> Function({
  required Uint8List bytes,
  required String fileName,
})? debugTripDetailGpxShareOverride;

/// Export the trip's persisted GPS samples as a GPX 1.1 file and hand
/// it to the OS share sheet (#2032). Extracted from
/// `trip_detail_screen.dart` to keep that file under the 400-line
/// guard. Best-effort: a share failure surfaces a snackbar, never
/// throws.
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
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/gpx+xml',
            name: fileName,
          ),
        ],
        subject: fileName,
      ),
    );
  } catch (e, st) {
    debugPrint('TripDetailScreen share GPX: $e\n$st');
    if (messenger == null) return;
    final errorMsg =
        l?.trajetDetailShareError ?? "Couldn't share the GPX file";
    messenger.showSnackBar(SnackBarHelper.errorSnackBar(scheme, errorMsg));
  }
}
