// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'pump_display_parser.dart';
import 'receipt_parser.dart';

// The scan-outcome value types of `receipt_scan_service.dart`, split out
// (#2518) so the service file stays under the 400-line norm after the
// `parseReceiptImage` capture-owning entry was added. The service file
// re-exports both so existing importers see one unit.

/// Outcome of a single receipt capture: parsed fields plus the source
/// OCR text and the path to the captured JPEG on disk. The caller is
/// responsible for deleting [imagePath] once it no longer needs it — we
/// keep the file around so the "report bad scan" flow (#713) can share
/// the photo alongside the user's corrected values.
class ReceiptScanOutcome {
  final ReceiptParseResult parse;
  final String ocrText;
  final String imagePath;

  const ReceiptScanOutcome({
    required this.parse,
    required this.ocrText,
    required this.imagePath,
  });
}

/// Outcome of a single pump-display capture: parsed fields plus the
/// source OCR text and the path to the captured JPEG on disk. Mirrors
/// [ReceiptScanOutcome] so the bad-scan reporting flow (#953) can ship
/// the photo and OCR text alongside the user's corrected values when a
/// pump-display read fails.
///
/// The caller is responsible for deleting [imagePath] once it no longer
/// needs it (form saved, user dismissed the failure flow, or report
/// submitted).
class PumpDisplayScanOutcome {
  final PumpDisplayParseResult parse;
  final String ocrText;
  final String imagePath;

  /// `true` when the captured ROI was rejected for excessive glare
  /// (#2275) — the caller shows a "re-angle" prompt instead of the
  /// generic failure sheet.
  final bool glareRejected;

  const PumpDisplayScanOutcome({
    required this.parse,
    required this.ocrText,
    required this.imagePath,
    this.glareRejected = false,
  });
}
