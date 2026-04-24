import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tankstellen/features/consumption/data/pump_display_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_scan_service.dart';

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

  @override
  ReceiptParseResult parse(String text, {String? stationId}) {
    lastTextParsed = text;
    return result;
  }
}

/// Stub [PumpDisplayParser] matching the same pattern as the receipt
/// parser stub.
class _StubPumpDisplayParser extends PumpDisplayParser {
  const _StubPumpDisplayParser(this.result);

  final PumpDisplayParseResult result;

  @override
  PumpDisplayParseResult parse(String rawText) {
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

    test('returns parsed pump display and deletes the capture', () async {
      final capture = await _createTempCapture();
      picker.pathToReturn = capture.path;
      recognizer.textToReturn = 'Betrag 70.00\nAbgabe 40.00\nPreis/L 1.75';

      final result = await service.scanPumpDisplay();

      expect(result, isNotNull);
      expect(result!.liters, 40.0);
      expect(result.totalCost, 70.0);
      expect(result.pricePerLiter, 1.75);
      expect(File(capture.path).existsSync(), isFalse,
          reason: 'Pump-display flow does not feed bad-scan reports, '
              'so the capture must be deleted to avoid leaking temp files.');

      await capture.dir.delete(recursive: true);
    });

    test('returns null and still deletes when OCR fails', () async {
      final capture = await _createTempCapture();
      picker.pathToReturn = capture.path;
      recognizer.errorToThrow = Exception('OCR exploded');

      final result = await service.scanPumpDisplay();

      expect(result, isNull);
      // _tryDelete is inside the `finally` of scanPumpDisplay — even
      // when recognition throws, the file must not leak.
      expect(File(capture.path).existsSync(), isFalse,
          reason: 'OCR error on pump-display path must still clean up '
              'the capture via the finally block.');

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
}
