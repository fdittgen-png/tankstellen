// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'receipt_parser.dart';

// The scan-outcome value type of `receipt_scan_service.dart`, split out
// (#2518) so the service file stays under the 400-line norm after the
// `parseReceiptImage` capture-owning entry was added. The service file
// re-exports it so existing importers see one unit.

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
