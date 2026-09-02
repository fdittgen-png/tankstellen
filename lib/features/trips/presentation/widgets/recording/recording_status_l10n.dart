// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../providers/recording_link_status_provider.dart';

/// Pure status → copy / glyph mappings for the recording screen's status
/// strip and its sheets (#3916). Kept free of widgets so the chip, the
/// sheet and the text-expansion test share exactly one vocabulary.

/// Chip label for the OBD2 status.
String obd2StatusChipLabel(AppLocalizations l, RecordingObd2Status s) {
  switch (s) {
    case Obd2StatusLive(:final readsPerSecond):
      return readsPerSecond == null
          ? l.recordingObd2ChipLive
          : l.recordingObd2ChipLiveRate(readsPerSecond);
    case Obd2StatusReconnecting(:final attempt):
      return attempt == null
          ? l.recordingObd2ChipReconnecting
          : l.recordingObd2ChipReconnectingAttempt(attempt);
    case Obd2StatusGpsOnly():
      return l.recordingObd2ChipGpsOnly;
    case Obd2StatusEngineOff():
      return l.recordingObd2ChipEngineOff;
    case Obd2StatusNoAdapter():
      return l.recordingObd2ChipNoAdapter;
  }
}

/// Plain-language sheet body for the OBD2 status: what the state means
/// for the recording and what (if anything) the driver can do.
String obd2StatusSheetBody(AppLocalizations l, RecordingObd2Status s) {
  switch (s) {
    case Obd2StatusLive():
      return l.recordingObd2SheetLive;
    case Obd2StatusReconnecting():
      return l.recordingObd2SheetReconnecting;
    case Obd2StatusGpsOnly():
      return l.recordingObd2SheetGpsOnly;
    case Obd2StatusEngineOff():
      return l.recordingObd2SheetEngineOff;
    case Obd2StatusNoAdapter():
      return l.recordingObd2SheetNoAdapter;
  }
}

/// Glyph for the OBD2 status.
IconData obd2StatusIcon(RecordingObd2Status s) {
  switch (s) {
    case Obd2StatusLive():
      return Icons.bluetooth_connected;
    case Obd2StatusReconnecting():
      return Icons.bluetooth_searching;
    case Obd2StatusGpsOnly():
      return Icons.bluetooth_disabled;
    case Obd2StatusEngineOff():
      return Icons.key_off_outlined;
    case Obd2StatusNoAdapter():
      return Icons.satellite_alt_outlined;
  }
}

/// True when the sheet should offer the shared connection reset — a
/// link that dropped and is being recovered. Never while the engine is
/// off (a reset dials a sleeping dongle, #3860) and never for a trip
/// without an adapter.
bool obd2StatusOffersReset(RecordingObd2Status s) {
  switch (s) {
    case Obd2StatusReconnecting():
    case Obd2StatusGpsOnly():
      return true;
    case Obd2StatusLive():
    case Obd2StatusEngineOff():
    case Obd2StatusNoAdapter():
      return false;
  }
}

/// The fix half of the GPS chip label (without coverage).
String gpsFixLabel(AppLocalizations l, RecordingGpsStatus g) {
  switch (g.quality) {
    case GpsFixQuality.precise:
      return l.recordingGpsChipPrecise(g.accuracyM ?? 0);
    case GpsFixQuality.approximate:
      return l.recordingGpsChipApprox(g.accuracyM ?? 0);
    case GpsFixQuality.unknownAccuracy:
      return l.recordingGpsChipFixUnknownAccuracy;
    case GpsFixQuality.none:
      return l.recordingGpsChipNoFix;
  }
}

/// Chip label for the GPS status: the fix text, plus the coverage so
/// far when known.
String gpsStatusChipLabel(AppLocalizations l, RecordingGpsStatus g) {
  final fix = gpsFixLabel(l, g);
  final coverage = g.coveragePercent;
  return coverage == null ? fix : l.recordingGpsChipWithCoverage(fix, coverage);
}

/// Plain-language sheet body for the GPS status.
String gpsStatusSheetBody(AppLocalizations l, RecordingGpsStatus g) {
  switch (g.quality) {
    case GpsFixQuality.precise:
      return l.recordingGpsSheetPrecise;
    case GpsFixQuality.approximate:
    case GpsFixQuality.unknownAccuracy:
      return l.recordingGpsSheetApprox;
    case GpsFixQuality.none:
      return l.recordingGpsSheetNoFix;
  }
}

/// Glyph for the GPS status.
IconData gpsStatusIcon(RecordingGpsStatus g) {
  switch (g.quality) {
    case GpsFixQuality.precise:
      return Icons.gps_fixed;
    case GpsFixQuality.approximate:
    case GpsFixQuality.unknownAccuracy:
      return Icons.gps_not_fixed;
    case GpsFixQuality.none:
      return Icons.gps_off;
  }
}
