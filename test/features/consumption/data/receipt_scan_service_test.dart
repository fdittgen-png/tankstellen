// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_geometry.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/consumption/data/pump_display_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_scan_service.dart';
import '../../../helpers/silence_error_logger.dart';

/// Unit tests for [ReceiptScanService] — the thin orchestration seam
/// that glues the camera picker to the on-device OCR recognizer and
/// dispatches to the correct parser (prose receipt vs. pump LCD).
///
/// The service itself contains no parsing logic — its value is the
/// control flow: cancel → return null; OCR success → build outcome
/// without deleting the file (receipt path keeps the image for the
/// bad-scan report flow, #713); OCR failure → delete the file; pump
/// display → always delete. These tests pin each branch via fakes
/// because [ImagePicker] and [TextRecognizer] both go through
/// platform channels that are unreachable in unit tests.

/// Fake picker whose [pickImage] returns a caller-controlled path.
class _FakePicker extends ImagePicker {
  String? pathToReturn;
  int pickCalls = 0;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    pickCalls++;
    if (pathToReturn == null) return null;
    return XFile(pathToReturn!);
  }
}

/// Fake recognizer. Either returns the queued text, or throws the
/// queued error if [errorToThrow] is set. Tracks how many times
/// [processImage] and [close] were called.
class _FakeRecognizer extends TextRecognizer {
  _FakeRecognizer();

  String textToReturn = '';
  Object? errorToThrow;
  int processCalls = 0;
  int closeCalls = 0;

  @override
  Future<RecognizedText> processImage(InputImage inputImage) async {
    processCalls++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return RecognizedText(text: textToReturn, blocks: const []);
  }

  @override
  Future<void> close() async {
    closeCalls++;
  }
}

/// Stub [ReceiptParser] that records the text it was asked to parse
/// and returns a caller-provided fixture. The real parser is
/// exhaustively covered elsewhere; here we only need a deterministic
/// handoff.
class _StubReceiptParser extends ReceiptParser {
  _StubReceiptParser(this.result);

  final ReceiptParseResult result;
  String? lastTextParsed;
  OcrLocaleProfile? lastProfile;
  int parseCalls = 0;

  @override
  ReceiptParseResult parse(
    String text, {
    String? stationId,
    OcrLocaleProfile? profile,
  }) {
    parseCalls++;
    lastTextParsed = text;
    lastProfile = profile;
    return result;
  }
}

/// Stub [PumpDisplayParser] matching the same pattern as the receipt
/// parser stub.
class _StubPumpDisplayParser extends PumpDisplayParser {
  const _StubPumpDisplayParser(this.result);

  final PumpDisplayParseResult result;

  @override
  PumpDisplayParseResult parse(String rawText, {OcrLocaleProfile? profile}) {
    return result;
  }
}

/// Creates a temporary file on disk and returns (path, parentDir).
/// The parent dir is the caller's to clean up at the end of the test,
/// regardless of whether the service deleted the file itself.
Future<_TempCapture> _createTempCapture() async {
  final dir = await Directory.systemTemp.createTemp('receipt_scan_test_');
  final file = File('${dir.path}${Platform.pathSeparator}capture.jpg');
  await file.writeAsBytes(<int>[0xFF, 0xD8, 0xFF, 0xD9]); // minimal jpeg bytes
  return _TempCapture(path: file.path, dir: dir);
}

class _TempCapture {
  _TempCapture({required this.path, required this.dir});
  final String path;
  final Directory dir;
}

void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiptScanService.scanReceipt', () {
    late _FakePicker picker;
    late _FakeRecognizer recognizer;
    late _StubReceiptParser parser;
    late ReceiptScanService service;

    setUp(() {
      picker = _FakePicker();
      recognizer = _FakeRecognizer();
      parser = _StubReceiptParser(const ReceiptParseResult(
        liters: 42.0,
        totalCost: 75.0,
      ));
      service = ReceiptScanService(
        picker: picker,
        recognizer: recognizer,
        parser: parser,
        pumpParser: const _StubPumpDisplayParser(PumpDisplayParseResult()),
      );
    });

    test('returns null when user cancels the camera', () async {
      picker.pathToReturn = null;

      final outcome = await service.scanReceipt();

      expect(outcome, isNull);
      expect(picker.pickCalls, 1);
      expect(recognizer.processCalls, 0,
          reason: 'OCR must not run when no image was captured.');
    });

    test('returns outcome with parsed fields on a successful OCR', () async {
      final capture = await _createTempCapture();
      picker.pathToReturn = capture.path;
      recognizer.textToReturn = 'TOTAL 75.00\nVOLUME 42.00';

      final outcome = await service.scanReceipt();

      expect(outcome, isNotNull);
      expect(outcome!.ocrText, 'TOTAL 75.00\nVOLUME 42.00');
      expect(outcome.imagePath, capture.path);
      expect(outcome.parse.liters, 42.0);
      expect(outcome.parse.totalCost, 75.0);
      expect(parser.lastTextParsed, 'TOTAL 75.00\nVOLUME 42.00',
          reason: 'The OCR text must flow unchanged into the parser.');

      // The receipt flow MUST keep the file on disk — the bad-scan
      // report sheet (#713) reads it. Deleting here would break the
      // "share a bad scan" UX.
      expect(File(capture.path).existsSync(), isTrue,
          reason: 'scanReceipt must preserve the image for the '
              'bad-scan report flow (#713).');

      await capture.dir.delete(recursive: true);
    });

    test('returns null and deletes the capture when OCR fails', () async {
      final capture = await _createTempCapture();
      picker.pathToReturn = capture.path;
      recognizer.errorToThrow = Exception('ML Kit barfed');

      final outcome = await service.scanReceipt();

      expect(outcome, isNull);
      expect(recognizer.processCalls, 1);
      expect(File(capture.path).existsSync(), isFalse,
          reason: 'OCR failure must not leave an orphan capture on disk — '
              'the caller never sees the path and cannot clean it up.');

      await capture.dir.delete(recursive: true);
    });

    test('swallows delete errors when the capture no longer exists', () async {
      final capture = await _createTempCapture();
      // Delete the file before the service tries to — simulates a
      // race or platform-driven cleanup. The service's _tryDelete
      // must not propagate a FileSystemException, otherwise a
      // no-op race would surface as a spurious crash.
      await File(capture.path).delete();
      picker.pathToReturn = capture.path;
      recognizer.errorToThrow = Exception('OCR failed too');

      final outcome = await service.scanReceipt();

      expect(outcome, isNull,
          reason: 'Service must still return null cleanly even when the '
              'temp file delete fails.');

      await capture.dir.delete(recursive: true);
    });

    test('threads the active country profile into the parser (#2273)',
        () async {
      // The receipt path must mirror the pump path: when a country is
      // passed, the country's OcrLocaleProfile (GB → GBP here) is loaded
      // from the OCR config and handed to the parser so currency-aware
      // extraction runs.
      const configJson = '''
{
  "version": 1,
  "localeProfiles": [
    {"country":"GB","currency":"GBP","decimalSeparator":".",
     "priceMin":0.8,"priceMax":3.0,"volumeMax":200.0,"totalMax":500.0}
  ],
  "brands": []
}''';
      final service = ReceiptScanService(
        picker: picker,
        recognizer: recognizer,
        parser: parser,
        pumpParser: const _StubPumpDisplayParser(PumpDisplayParseResult()),
        ocrConfig: PumpOcrConfig.fromJsonString(configJson),
      );
      final capture = await _createTempCapture();
      picker.pathToReturn = capture.path;
      recognizer.textToReturn = 'TOTAL 75.00';

      final outcome = await service.scanReceipt(country: 'GB');

      expect(outcome, isNotNull);
      expect(parser.lastProfile, isNotNull,
          reason: 'a known country must resolve to a profile.');
      expect(parser.lastProfile!.currency, 'GBP');

      await capture.dir.delete(recursive: true);
    });

    test('passes a null profile when no country is supplied (#2273)',
        () async {
      // Backwards compatibility: scanReceipt() with no country must keep
      // the parser on its EUR default (null profile), unchanged.
      final capture = await _createTempCapture();
      picker.pathToReturn = capture.path;
      recognizer.textToReturn = 'TOTAL 75.00';

      await service.scanReceipt();

      expect(parser.parseCalls, 1);
      expect(parser.lastProfile, isNull,
          reason: 'no country → no profile → EUR default, as before.');

      await capture.dir.delete(recursive: true);
    });
  });

  group('ReceiptScanService.scanPumpDisplay', () {
    late _FakePicker picker;
    late _FakeRecognizer recognizer;
    late ReceiptScanService service;

    setUp(() {
      picker = _FakePicker();
      recognizer = _FakeRecognizer();
      service = ReceiptScanService(
        picker: picker,
        recognizer: recognizer,
        parser: _StubReceiptParser(const ReceiptParseResult()),
        pumpParser: const _StubPumpDisplayParser(PumpDisplayParseResult(
          liters: 40.0,
          totalCost: 70.0,
          pricePerLiter: 1.75,
          confidence: 0.9,
        )),
      );
    });

    test('returns null when user cancels the camera', () async {
      picker.pathToReturn = null;

      final result = await service.scanPumpDisplay();

      expect(result, isNull);
      expect(recognizer.processCalls, 0);
    });

    test('returns parsed pump display and KEEPS the capture for #953',
        () async {
      final capture = await _createTempCapture();
      picker.pathToReturn = capture.path;
      recognizer.textToReturn = 'Betrag 70.00\nAbgabe 40.00\nPreis/L 1.75';

      final outcome = await service.scanPumpDisplay();

      expect(outcome, isNotNull);
      expect(outcome!.parse.liters, 40.0);
      expect(outcome.parse.totalCost, 70.0);
      expect(outcome.parse.pricePerLiter, 1.75);
      expect(outcome.imagePath, capture.path);
      expect(outcome.ocrText, contains('Betrag'));
      expect(File(capture.path).existsSync(), isTrue,
          reason: '#953 — pump-display photo must survive scan so the '
              'failure-flow / bad-scan report can ship the image.');

      await File(capture.path).delete();
      await capture.dir.delete(recursive: true);
    });

    test('returns null and deletes the capture when OCR itself fails',
        () async {
      final capture = await _createTempCapture();
      picker.pathToReturn = capture.path;
      recognizer.errorToThrow = Exception('OCR exploded');

      final result = await service.scanPumpDisplay();

      expect(result, isNull);
      // OCR-recognition failure means we have no usable text to ship —
      // there is nothing for the bad-scan flow to act on, so we still
      // clean up the temp file. (Parse failure with usable text is a
      // different path: the outcome is returned and the caller decides.)
      expect(File(capture.path).existsSync(), isFalse,
          reason: 'OCR-recognition error on pump-display path must clean '
              'up the capture — there is no outcome for the failure flow.');

      await capture.dir.delete(recursive: true);
    });
  });

  group('ReceiptScanService.parsePumpDisplayImage (#1868)', () {
    late ReceiptScanService service;
    late _FakeRecognizer recognizer;

    setUp(() {
      recognizer = _FakeRecognizer();
      service = ReceiptScanService(
        picker: _FakePicker(),
        recognizer: recognizer,
        parser: _StubReceiptParser(const ReceiptParseResult()),
        pumpParser: const _StubPumpDisplayParser(PumpDisplayParseResult(
          liters: 40.0,
          totalCost: 70.0,
          pricePerLiter: 1.75,
          confidence: 0.9,
        )),
      );
    });

    test('OCRs + parses an already-captured photo, keeping the file',
        () async {
      // #1868 — the in-app camera owns the capture; the service is
      // handed the resulting path. No picker call.
      final capture = await _createTempCapture();
      recognizer.textToReturn = 'Betrag 70.00\nAbgabe 40.00\nPreis/L 1.75';

      final outcome = await service.parsePumpDisplayImage(capture.path);

      expect(outcome, isNotNull);
      expect(outcome!.parse.liters, 40.0);
      expect(outcome.imagePath, capture.path);
      expect(outcome.ocrText, contains('Betrag'));
      expect(recognizer.processCalls, 1);
      expect(File(capture.path).existsSync(), isTrue,
          reason: 'the photo must survive for the #953 bad-scan report.');

      await File(capture.path).delete();
      await capture.dir.delete(recursive: true);
    });

    test('returns null and deletes the capture when OCR fails', () async {
      final capture = await _createTempCapture();
      recognizer.errorToThrow = Exception('OCR exploded');

      final outcome = await service.parsePumpDisplayImage(capture.path);

      expect(outcome, isNull);
      expect(File(capture.path).existsSync(), isFalse,
          reason: 'an unreadable capture must not leak to disk.');

      await capture.dir.delete(recursive: true);
    });
  });

  group('ReceiptScanService.dispose', () {
    test('closes the underlying text recognizer exactly once', () async {
      final recognizer = _FakeRecognizer();
      final service = ReceiptScanService(
        picker: _FakePicker(),
        recognizer: recognizer,
        parser: _StubReceiptParser(const ReceiptParseResult()),
        pumpParser: const _StubPumpDisplayParser(PumpDisplayParseResult()),
      );

      service.dispose();

      expect(recognizer.closeCalls, 1,
          reason: 'dispose must release the ML Kit native handle — '
              'leaking it across many scans would accumulate native '
              'memory on Android.');
    });
  });

  group('ReceiptScanOutcome', () {
    test('is an immutable value holder with the three source fields', () {
      const outcome = ReceiptScanOutcome(
        parse: ReceiptParseResult(liters: 10, totalCost: 20),
        ocrText: 'hello',
        imagePath: '/tmp/x.jpg',
      );

      expect(outcome.parse.liters, 10);
      expect(outcome.parse.totalCost, 20);
      expect(outcome.ocrText, 'hello');
      expect(outcome.imagePath, '/tmp/x.jpg');
    });
  });

  group('bakeImageOrientation (#1711)', () {
    test('rotates an EXIF-orientation-6 image upright — dimensions swap',
        () {
      // An 80×40 landscape image tagged orientation 6 ("rotate 90° CW")
      // displays as 40×80. Baking the rotation into the pixels must
      // produce a 40×80 upright image — the fix for the sideways
      // pump-display photos that ML Kit could not read.
      final src = img.Image(width: 80, height: 40);
      img.fill(src, color: img.ColorRgb8(40, 80, 120));
      src.exif.imageIfd['Orientation'] = 6;
      final tagged = Uint8List.fromList(img.encodeJpg(src));

      final baked = bakeImageOrientation(tagged);
      expect(baked, isNotNull);
      final out = img.decodeJpg(baked!)!;
      expect(out.width, 40);
      expect(out.height, 80);
    });

    test('leaves an already-upright image unchanged in dimensions', () {
      final src = img.Image(width: 100, height: 60);
      img.fill(src, color: img.ColorRgb8(10, 20, 30));
      final upright = Uint8List.fromList(img.encodeJpg(src));

      final baked = bakeImageOrientation(upright);
      expect(baked, isNotNull);
      final out = img.decodeJpg(baked!)!;
      expect(out.width, 100);
      expect(out.height, 60);
    });

    test('returns null for non-JPEG / garbage bytes', () {
      final garbage = Uint8List.fromList(List.generate(64, (i) => i % 256));
      expect(bakeImageOrientation(garbage), isNull);
    });
  });

  group('preprocessPumpDisplayForOcr (#2275 — adaptive binarization)', () {
    /// Histogram of the (grayscale) output, bucketed coarsely. Used to
    /// assert the output is a binary mask (ink + background), not a
    /// continuous-tone image.
    ({int min, int max}) luminanceSpan(img.Image im) {
      var lo = 255;
      var hi = 0;
      for (final p in im) {
        final v = p.r.round();
        if (v < lo) lo = v;
        if (v > hi) hi = v;
      }
      return (min: lo, max: hi);
    }

    test('binarizes a low-contrast capture into separated ink + background',
        () {
      // A washed-out display: thin dark *strokes* (like 7-segment bars)
      // on a slightly lighter field, both inside a narrow grey band. The
      // #1860 global normalize+contrast amplified glare; #2275's local
      // Sauvola pass must instead separate the strokes into ink (dark)
      // from background (light) — so the output spans nearly the full
      // 0..255 range even though the input barely spanned 40 levels.
      final src = img.Image(width: 80, height: 80);
      for (final p in src) {
        // Two thin horizontal bars (top + middle segment) of the digit.
        final onBar = (p.y >= 16 && p.y <= 22) || (p.y >= 38 && p.y <= 44);
        final shade = onBar ? 100 : 140;
        p.setRgb(shade, shade, shade);
      }
      final before = luminanceSpan(src);
      expect(before.max - before.min, lessThan(60),
          reason: 'fixture must start as a genuinely low-contrast image.');

      final out = preprocessPumpDisplayForOcr(
          Uint8List.fromList(img.encodeJpg(src)));
      expect(out, isNotNull);
      final after = luminanceSpan(img.decodeJpg(out!)!);
      expect(after.max - after.min, greaterThan(150),
          reason: 'adaptive thresholding must separate the dark strokes '
              'from the lighter field so a washed-out LCD becomes legible.');
    });

    test('bakes EXIF orientation upright — dimensions swap, like #1711',
        () {
      // An 80×40 image tagged orientation 6 displays as 40×80; the
      // pump path must apply the same orientation bake the plain path
      // does before it binarizes. (No ROI passed → full frame.)
      final src = img.Image(width: 80, height: 40);
      img.fill(src, color: img.ColorRgb8(60, 60, 60));
      src.exif.imageIfd['Orientation'] = 6;

      final out = preprocessPumpDisplayForOcr(
          Uint8List.fromList(img.encodeJpg(src)));
      expect(out, isNotNull);
      final decoded = img.decodeJpg(out!)!;
      expect(decoded.width, 40);
      expect(decoded.height, 80);
    });

    test('crops to the ROI first when one is supplied', () {
      // A 100×100 frame: passing a centred 0.2-wide ROI must shrink the
      // processed output to ~that crop, proving the reticle is applied
      // before anything else (#2275 concern 1).
      final src = img.Image(width: 100, height: 100);
      img.fill(src, color: img.ColorRgb8(60, 60, 60));
      final out = preprocessPumpDisplayForOcr(
        Uint8List.fromList(img.encodeJpg(src)),
        roi: const OcrNormalizedRect(
            left: 0.4, top: 0.4, width: 0.2, height: 0.2),
      );
      expect(out, isNotNull);
      final decoded = img.decodeJpg(out!)!;
      expect(decoded.width, lessThan(40));
      expect(decoded.height, lessThan(40));
    });

    test('returns null for non-JPEG / garbage bytes', () {
      final garbage = Uint8List.fromList(List.generate(64, (i) => i % 256));
      expect(preprocessPumpDisplayForOcr(garbage), isNull);
    });
  });
}
