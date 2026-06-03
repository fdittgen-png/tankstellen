// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/'
    'receipt_pdf_rasterizer.dart';
import '../../../../helpers/silence_error_logger.dart';

/// Never-throws coverage for the on-device PDF→bitmap rasteriser (#2737),
/// mirroring the `ocr_image_preprocessor_test` / `receipt_scan_service`
/// fault-path idiom (#2349).
///
/// IMPORTANT — headless caveat: the native `android.graphics.pdf
/// .PdfRenderer` / `CGPDFPage` channel `pdfx` delegates to is NOT
/// available under `flutter test` (pure Dart VM). So we do NOT assert that
/// a real PDF rasterises SUCCESSFULLY here — that can only pass on a
/// device/emulator and would flake CI. Instead we drive the FAULT path:
/// feed corrupt / zero-byte / missing input, assert the call `returns
/// Normally` and yields `null`. In the headless env the missing platform
/// channel naturally errors, which is exactly the failure the documented
/// catch→null boundary must absorb. The success path is covered instead by
/// the MIME-branch wiring test (`share_receipt_handler_test.dart`) with the
/// rasteriser faked.
void main() {
  silenceErrorLoggerSpool();

  late Directory tempDir;
  late ReceiptPdfRasterizer rasterizer;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pdf_rasterizer_test');
    rasterizer =
        ReceiptPdfRasterizer(temporaryDirectory: () async => tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('ReceiptPdfRasterizer.rasterize — never throws (#2349)', () {
    test('a missing file returns null, not a throw', () async {
      final badPath = '${tempDir.path}/does_not_exist.pdf';
      // Await the result. An unawaited `returnsNormally` on an async fn leaks
      // the future — if it later completes with an error (e.g. headless,
      // where the absent pdfx platform channel throws) that surfaces as an
      // *unhandled* async error and fails the test. `completion(isNull)`
      // awaits + asserts the documented null fault path without leaking.
      await expectLater(
        rasterizer.rasterize(badPath),
        completion(isNull),
        reason: 'a missing PDF must be caught + logged, never propagated',
      );
    });

    test('a zero-byte file returns null, not a throw', () async {
      final zeroByte = File('${tempDir.path}/empty.pdf')..createSync();
      expect(zeroByte.lengthSync(), 0);
      await expectLater(
        rasterizer.rasterize(zeroByte.path),
        completion(isNull),
      );
    });

    test('a corrupt (non-PDF) file returns null, not a throw', () async {
      // Real bytes, but not a valid PDF — the native open/decode fails
      // (or, headless, the channel is absent); either way → null.
      final corrupt = File('${tempDir.path}/garbage.pdf')
        ..writeAsStringSync('this is definitely not a PDF document');
      await expectLater(
        rasterizer.rasterize(corrupt.path),
        completion(isNull),
      );
    });

    test('a file with a PDF magic header but garbage body returns null',
        () async {
      // `%PDF-1.4` header then junk — exercises the open-then-render fault
      // path rather than a header-rejection at open.
      final header = File('${tempDir.path}/fakeheader.pdf')
        ..writeAsBytesSync(<int>[
          0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34, 0x0a, // %PDF-1.4\n
          ...List<int>.filled(64, 0x00),
        ]);
      await expectLater(
        rasterizer.rasterize(header.path),
        completion(isNull),
      );
    });
  });
}
