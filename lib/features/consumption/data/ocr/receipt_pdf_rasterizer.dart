// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/logging/error_logger.dart';

/// Renders the first page of a shared/opened **PDF** e-receipt to an
/// on-device JPEG bitmap so it can flow through the SAME ML Kit OCR path
/// (`ReceiptScanService.parseReceiptImage`) that an image share already
/// uses (#2737 / Epic #2687).
///
/// The rendering is fully on-device and GMS-free: `pdfx` delegates to the
/// OS-native `android.graphics.pdf.PdfRenderer` on Android and `CGPDFPage`
/// on iOS — no Play Services, no ML Kit, so the fdroid build stays clean
/// (the OCR step downstream is the only GMS-dependent part, and it is
/// already gracefully unavailable on fdroid by design).
///
/// **Never throws — returns null on any failure** (#2349). PDF input is
/// adversarial (corrupt bytes, password-protected, zero-byte, or — under
/// `flutter test`'s pure Dart VM — no native PdfRenderer at all), so every
/// failure path routes through [errorLogger] and yields `null`. The caller
/// (`share_receipt_handler`) treats `null` as "couldn't rasterise" and
/// shows the graceful #2735 fallback rather than crashing the user back to
/// the launcher. This mirrors the never-throws boundaries in
/// `receipt_scan_service` / `ocr_image_preprocessor`; the sibling
/// `receipt_pdf_rasterizer_test.dart` pins the contract with fault
/// injection.
class ReceiptPdfRasterizer {
  /// Hard cap on a document's page count. A receipt is a single page in
  /// practice; a many-page PDF is almost certainly not a receipt (or is a
  /// decompression-bomb risk), so we reject it up front rather than open
  /// it. There is no existing page-count guard to inherit, so this is the
  /// new bound (#2737 asks for one explicitly).
  static const int maxPages = 20;

  /// Upper bound on the longest rendered edge, in pixels. Caps the output
  /// bitmap so an unusually large page (e.g. an A0 poster mis-shared as a
  /// "receipt") cannot blow up memory; the page is rendered at its native
  /// size scaled down to fit this. Comfortably above what ML Kit needs to
  /// read receipt prose.
  static const double maxRenderEdge = 2400;

  /// Hint to the JPEG encoder (0–100). High enough that OCR is unaffected.
  static const int jpegQuality = 90;

  /// Temp-dir provider, overridable in tests (the app convention — see
  /// `widget_share_renderer.dart`). Production uses `getTemporaryDirectory`
  /// from `path_provider`.
  final Future<Directory> Function() _temporaryDirectory;

  const ReceiptPdfRasterizer({
    Future<Directory> Function()? temporaryDirectory,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  /// Rasterises the first page of the PDF at [path] to a temp JPEG and
  /// returns that JPEG's path, or `null` on ANY failure (never throws).
  ///
  /// Guards page count ([maxPages]) and page size ([maxRenderEdge]) before
  /// rendering. The returned JPEG lives in the temp dir; the OCR pipeline
  /// owns it from there (it deletes the file when OCR recognises no text,
  /// same as a captured photo).
  Future<String?> rasterize(String path) async {
    PdfDocument? document;
    PdfPage? page;
    try {
      // A corrupt / zero-byte / missing PDF (or — under `flutter test` —
      // the absent native renderer) surfaces as a thrown open/render error,
      // which the catch below turns into the documented `null` fault path;
      // no separate existence pre-check is needed (and an async
      // `File.exists` would trip `avoid_slow_async_io`).
      document = await PdfDocument.openFile(path);
      final pageCount = document.pagesCount;
      if (pageCount < 1 || pageCount > maxPages) {
        // No pages, or implausibly many for a receipt — silently decline
        // (first-page default per #2737; no "multi-page" user string).
        return null;
      }

      // First page wins — receipts are single-page; a stray cover page is
      // the exception, and the user can re-share if so.
      page = await document.getPage(1);
      final (renderWidth, renderHeight) = _renderSize(page.width, page.height);
      if (renderWidth < 1 || renderHeight < 1) return null;

      final image = await page.render(
        width: renderWidth,
        height: renderHeight,
        format: PdfPageImageFormat.jpeg,
        // ML Kit reads dark ink on a light field; a white background keeps
        // the JPEG from baking transparency to black and losing contrast.
        backgroundColor: '#FFFFFF',
        quality: jpegQuality,
      );
      if (image == null || image.bytes.isEmpty) return null;

      final dir = await _temporaryDirectory();
      final jpegPath =
          '${dir.path}/shared_receipt_${DateTime.now().microsecondsSinceEpoch}.jpg';
      await File(jpegPath).writeAsBytes(image.bytes, flush: true);
      debugPrint('ReceiptPdfRasterizer rendered $path -> $jpegPath '
          '(${image.bytes.length} bytes)');
      return jpegPath;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'ReceiptPdfRasterizer.rasterize',
      }));
      return null;
    } finally {
      // Close in reverse order; each close is itself best-effort so a
      // cleanup failure never masks (or replaces) the real result.
      await _safeClose(() => page?.close());
      await _safeClose(() => document?.close());
    }
  }

  /// Scales the native ([w]×[h]) page down to fit within [maxRenderEdge]
  /// on its longest edge, preserving aspect ratio. Pages report their size
  /// in PDF points (72/inch); rendering at the native point count gives a
  /// ~72-dpi bitmap, which is fine for receipt prose and bounded here.
  (double, double) _renderSize(double w, double h) {
    if (w <= 0 || h <= 0) return (0, 0);
    final longest = w > h ? w : h;
    if (longest <= maxRenderEdge) return (w, h);
    final scale = maxRenderEdge / longest;
    return (w * scale, h * scale);
  }

  Future<void> _safeClose(FutureOr<void> Function() close) async {
    try {
      await close();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'ReceiptPdfRasterizer cleanup',
      }));
    }
  }
}
