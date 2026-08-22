// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr/ocr_trace_recorder.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/receipts_ocr/data/receipt_parser.dart';
import 'package:tankstellen/features/receipts_ocr/data/receipt_scan_service.dart';
import '../../../helpers/silence_error_logger.dart';

/// Unit tests for [ReceiptScanService] — the thin orchestration seam
/// that glues the camera picker to the on-device OCR recognizer and
/// the receipt parser.
///
/// The service itself contains no parsing logic — its value is the
/// control flow: cancel → return null; OCR success → build outcome
/// without deleting the file (the receipt path keeps the image for the
/// bad-scan report flow, #713); OCR failure → delete the file. These
/// tests pin each branch via fakes because [ImagePicker] and
/// [TextRecognizer] both go through platform channels that are
/// unreachable in unit tests.

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
      throw errorToThrow!; // ignore: only_throw_errors
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
    OcrTraceRecorder? trace,
  }) {
    parseCalls++;
    lastTextParsed = text;
    lastProfile = profile;
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
      // When a country is
      // passed, the country's OcrLocaleProfile (GB → GBP here) is loaded
      // from the OCR config and handed to the parser so currency-aware
      // extraction runs.
      const configJson = '''
{
  "version": 1,
  "localeProfiles": [
    {"country":"GB","currency":"GBP","decimalSeparator":".",
     "priceMin":0.8,"priceMax":3.0,"volumeMax":200.0,"totalMax":500.0}
  ]
}''';
      final service = ReceiptScanService(
        picker: picker,
        recognizer: recognizer,
        parser: parser,
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

  group('ReceiptScanService.dispose', () {
    test('closes the underlying text recognizer exactly once', () async {
      final recognizer = _FakeRecognizer();
      final service = ReceiptScanService(
        picker: _FakePicker(),
        recognizer: recognizer,
        parser: _StubReceiptParser(const ReceiptParseResult()),
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
      // capture photos that ML Kit could not read.
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
}
