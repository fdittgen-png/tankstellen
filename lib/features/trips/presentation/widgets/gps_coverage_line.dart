// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../l10n/app_localizations.dart';
import '../../domain/gps_coverage_report.dart';

/// Localized copy for the #3465 GPS coverage verdict rendered on the
/// [GpsDiagnosticsCard] — extracted to its own helper so the card stays
/// under the 400-line norm and the string mapping is unit-testable
/// without pumping a widget tree.

/// The one-line coverage verdict, or null when no report exists.
/// "Track covers {pct}% — longest gap {duration} ({cause})", degrading to
/// the no-gaps phrasing on a hole-free track.
String? gpsCoverageSummaryLine(GpsCoverageReport? c, AppLocalizations l) {
  if (c == null) return null;
  final pct = (c.coverageRatio * 100).round();
  final longest = c.longestGap;
  if (longest == null) return l.gpsCoverageSummaryNoGaps(pct);
  return l.gpsCoverageSummary(
    pct,
    formatGpsGapDuration(longest.duration),
    gpsGapAttributionLabel(longest.attribution, l),
  );
}

/// Short "so what" hint for the longest gap's attribution (#3465), or
/// null when the track has no gaps (nothing to explain).
String? gpsCoverageHint(GpsCoverageReport? c, AppLocalizations l) {
  final attribution = c?.longestGap?.attribution;
  if (attribution == null) return null;
  switch (attribution) {
    case GpsGapAttribution.backgroundThrottle:
      return l.gpsCoverageHintBackgroundThrottle;
    case GpsGapAttribution.osBatching:
      return l.gpsCoverageHintOsBatching;
    case GpsGapAttribution.linkRecovery:
      return l.gpsCoverageHintLinkRecovery;
    case GpsGapAttribution.gateRejected:
      return l.gpsCoverageHintGateRejected;
    case GpsGapAttribution.signalLoss:
      return l.gpsCoverageHintSignalLoss;
    case GpsGapAttribution.unknown:
      return l.gpsCoverageHintUnknown;
  }
}

/// Localized label for a gap attribution (#3465) — the raw enum name must
/// never leak into the UI (the #2765 lifecycle-label lesson).
String gpsGapAttributionLabel(GpsGapAttribution a, AppLocalizations l) {
  switch (a) {
    case GpsGapAttribution.backgroundThrottle:
      return l.gpsCoverageAttrBackgroundThrottle;
    case GpsGapAttribution.osBatching:
      return l.gpsCoverageAttrOsBatching;
    case GpsGapAttribution.linkRecovery:
      return l.gpsCoverageAttrLinkRecovery;
    case GpsGapAttribution.gateRejected:
      return l.gpsCoverageAttrGateRejected;
    case GpsGapAttribution.signalLoss:
      return l.gpsCoverageAttrSignalLoss;
    case GpsGapAttribution.unknown:
      return l.gpsCoverageAttrUnknown;
  }
}

/// Format a gap duration as "3m 42s" / "42s" — the same language-neutral
/// unit-suffix convention as the card's time-span formatter.
String formatGpsGapDuration(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds - minutes * 60;
  if (minutes == 0) return '${seconds}s';
  return '${minutes}m ${seconds}s';
}
