// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_scan_service.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/'
    'fill_up_scan_handlers.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/'
    'fill_up_share_scan_handlers.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import '../../../../helpers/silence_error_logger.dart';

/// Reuse-fidelity coverage for the #2734 shared receipt-outcome prefill.
///
/// The whole point of the refactor is that the camera path
/// ([runReceiptScan]) and the path-fed share-scan sibling
/// ([runSharedReceiptScan]) prefill the form through ONE shared body
/// ([applyReceiptOutcome]) — so a share-intent receipt must fill the
/// form byte-for-byte identically to a camera scan.
///
/// To pin that, both flows are driven by the REAL [ReceiptParser] inside
/// a real [ReceiptScanService] — only the OCR boundary is faked, queued
/// with a shipped fixture's OCR text (never a request-echoing fake, which
/// would mask a parse-shape regression). The expected values are exactly
/// those the parser-level test pins for the same fixture.

/// Fake picker whose [pickImage] hands back a caller-controlled path so
/// [runReceiptScan]'s camera step resolves to the fixture capture.
class _FakePicker extends ImagePicker {
  _FakePicker(this.pathToReturn);
  final String? pathToReturn;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (pathToReturn == null) return null;
    return XFile(pathToReturn!);
  }
}

/// Recognizer that returns the queued OCR text, or throws when
/// [errorToThrow] is set (the #2349 fault-injection seam).
class _FakeRecognizer extends TextRecognizer {
  _FakeRecognizer();
  String textToReturn = '';
  Object? errorToThrow;

  @override
  Future<RecognizedText> processImage(InputImage inputImage) async {
    if (errorToThrow != null) throw errorToThrow!;
    return RecognizedText(text: textToReturn, blocks: const []);
  }

  @override
  Future<void> close() async {}
}

/// Captured mutations of a [FillUpScanHostState] — the screen normally
/// routes these through `setState`; here we just record them so two
/// flows can be compared field-by-field.
class _CapturedState {
  final litersCtrl = TextEditingController();
  final costCtrl = TextEditingController();
  String? vehicleId;
  DateTime? date;
  FuelType? fuelType;
  double? scannedPricePerLiter;
  ReceiptScanOutcome? lastScan;
  bool scanning = false;
  ReceiptScanService? service;

  FillUpScanHostState host({String? country}) => FillUpScanHostState(
        litersCtrl: litersCtrl,
        costCtrl: costCtrl,
        vehicleId: vehicleId,
        readService: () => service,
        writeService: (s) => service = s,
        setScanning: (v) => scanning = v,
        setScanningPump: (_) {},
        setDate: (d) => date = d,
        setFuelType: (f) => fuelType = f,
        setScannedPricePerLiter: (p) => scannedPricePerLiter = p,
        setLastScan: (o) => lastScan = o,
        isMounted: () => true,
        capturePumpImage: (_) async => null,
        activeCountry: country,
      );

  /// A serialisable snapshot of the form fields the prefill touches,
  /// so two flows can be compared with a single `equals`.
  Map<String, Object?> snapshot() => {
        'liters': litersCtrl.text,
        'cost': costCtrl.text,
        'date': date?.toIso8601String(),
        'fuelType': fuelType?.name,
        'scannedPricePerLiter': scannedPricePerLiter,
      };

  void dispose() {
    litersCtrl.dispose();
    costCtrl.dispose();
  }
}

/// Builds a [ReceiptScanService] wired to the real [ReceiptParser] with a
/// queued OCR text (or a throwing recognizer).
ReceiptScanService _realParserService({
  required _FakePicker picker,
  required _FakeRecognizer recognizer,
}) =>
    ReceiptScanService(
      picker: picker,
      recognizer: recognizer,
      parser: const ReceiptParser(),
    );

/// Reads a shipped receipt OCR fixture's raw text.
String _fixture(String name) => File(
      'test/features/consumption/data/receipt_parser/fixtures/$name',
    ).readAsStringSync();

/// Writes a throwaway capture file (minimal JPEG bytes) and returns its
/// path. `bakeImageOrientation` can't decode it, so the recognizer reads
/// the original path — which the fake ignores in favour of the queued
/// text. The caller cleans up the parent dir.
Future<({String path, Directory dir})> _tempCapture() async {
  final dir = await Directory.systemTemp.createTemp('share_scan_test_');
  final file = File('${dir.path}${Platform.pathSeparator}capture.jpg');
  await file.writeAsBytes(<int>[0xFF, 0xD8, 0xFF, 0xD9]);
  return (path: file.path, dir: dir);
}

/// Pumps a minimal localized app and hands the test a [BuildContext]
/// whose [AppLocalizations] + [ScaffoldMessenger] the scan handlers need.
Future<BuildContext> _localizedContext(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        captured = context;
        return const Scaffold(body: SizedBox());
      }),
    ),
  );
  return captured;
}

const _fixtureName = 'super_u_pomerols_2026-04-19.txt';

void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('applyReceiptOutcome (#2734 shared prefill)', () {
    test(
      'sets liters/cost/date/price/fuel from the real Super U fixture parse',
      () {
        // Drive the REAL parser over the shipped fixture text — same
        // values the parser-level test pins (5.24 L, €10.47, 1.999 €/L,
        // 2026-04-19, SP95-E10 → e10, brand SUPER U).
        final parse = const ReceiptParser().parse(_fixture(_fixtureName));
        final outcome = ReceiptScanOutcome(
          parse: parse,
          ocrText: _fixture(_fixtureName),
          imagePath: '/tmp/capture.jpg',
        );
        final state = _CapturedState();
        addTearDown(state.dispose);

        applyReceiptOutcome(state.host(), outcome);

        expect(state.litersCtrl.text, '5.24');
        expect(state.costCtrl.text, '10.47');
        expect(state.date, DateTime(2026, 4, 19));
        expect(state.scannedPricePerLiter, closeTo(1.999, 0.005));
        expect(state.fuelType, FuelType.e10,
            reason: 'no vehicle bound → the receipt fuel pre-selects');
        expect(state.lastScan, same(outcome));
      },
    );

    test('does NOT pre-select fuel when a vehicle is already bound (#698)',
        () {
      final parse = const ReceiptParser().parse(_fixture(_fixtureName));
      final outcome = ReceiptScanOutcome(
        parse: parse,
        ocrText: '',
        imagePath: '/tmp/x.jpg',
      );
      final state = _CapturedState()..vehicleId = 'veh-1';
      addTearDown(state.dispose);

      applyReceiptOutcome(state.host(), outcome);

      expect(state.fuelType, isNull,
          reason: 'the bound vehicle owns the fuel — receipt must not '
              'override it');
      // The numeric prefill still happens.
      expect(state.litersCtrl.text, '5.24');
    });
  });

  group('receiptScanSuccessMessage (#2734 station banner)', () {
    testWidgets('prepends the detected station name when present',
        (tester) async {
      final context = await _localizedContext(tester);
      final l = AppLocalizations.of(context);
      const outcome = ReceiptScanOutcome(
        parse: ReceiptParseResult(
          liters: 5.24,
          totalCost: 10.47,
          stationName: 'SUPER U',
        ),
        ocrText: '',
        imagePath: '/tmp/x.jpg',
      );

      final msg = receiptScanSuccessMessage(l, outcome);

      expect(msg, startsWith('SUPER U'),
          reason: 'the station hint is surfaced inline, non-blocking');
      expect(msg, contains(l!.scanReceiptSuccess),
          reason: 'the existing success copy is reused verbatim');
    });

    testWidgets('falls back to the plain success copy with no station',
        (tester) async {
      final context = await _localizedContext(tester);
      final l = AppLocalizations.of(context);
      const outcome = ReceiptScanOutcome(
        parse: ReceiptParseResult(liters: 5.24, totalCost: 10.47),
        ocrText: '',
        imagePath: '/tmp/x.jpg',
      );

      expect(receiptScanSuccessMessage(l, outcome), l!.scanReceiptSuccess);
    });
  });

  group('runReceiptScan vs runSharedReceiptScan — identical prefill', () {
    testWidgets(
      'both flows produce byte-identical form state from the same fixture',
      (tester) async {
        final context = await _localizedContext(tester);
        final cameraState = _CapturedState();
        final shareState = _CapturedState();
        addTearDown(cameraState.dispose);
        addTearDown(shareState.dispose);

        // The handlers run real file I/O (orientation bake, temp-file
        // cleanup); `tester.runAsync` runs them in the real async zone so
        // those futures actually complete instead of stalling fake-async.
        await tester.runAsync(() async {
          // ── Camera path ────────────────────────────────────────────
          final cameraCapture = await _tempCapture();
          cameraState.service = _realParserService(
            picker: _FakePicker(cameraCapture.path),
            recognizer: _FakeRecognizer()..textToReturn = _fixture(_fixtureName),
          );
          await runReceiptScan(context, cameraState.host());

          // ── Path-fed share path ────────────────────────────────────
          final shareCapture = await _tempCapture();
          shareState.service = _realParserService(
            picker: _FakePicker(null),
            recognizer: _FakeRecognizer()..textToReturn = _fixture(_fixtureName),
          );
          await runSharedReceiptScan(
              context, shareState.host(), shareCapture.path);

          await cameraCapture.dir.delete(recursive: true);
          await shareCapture.dir.delete(recursive: true);
        });

        // The load-bearing assertion: zero prefill drift between flows.
        expect(shareState.snapshot(), cameraState.snapshot());
        // And the snapshot is the real fixture's values, not empty.
        expect(cameraState.snapshot(), {
          'liters': '5.24',
          'cost': '10.47',
          'date': DateTime(2026, 4, 19).toIso8601String(),
          'fuelType': FuelType.e10.name,
          'scannedPricePerLiter': closeTo(1.999, 0.005),
        });
      },
    );
  });

  group('runSharedReceiptScan — never throws (#2349 fault injection)', () {
    testWidgets('completes normally when the recognizer throws',
        (tester) async {
      final context = await _localizedContext(tester);
      final state = _CapturedState();
      addTearDown(state.dispose);

      await tester.runAsync(() async {
        final capture = await _tempCapture();
        state.service = _realParserService(
          picker: _FakePicker(null),
          recognizer: _FakeRecognizer()..errorToThrow = Exception('OCR barfed'),
        );

        await expectLater(
          runSharedReceiptScan(context, state.host(), capture.path),
          completes,
        );

        await capture.dir.delete(recursive: true);
      });

      // A thrown OCR error must leave the form untouched, not half-filled.
      expect(state.litersCtrl.text, isEmpty);
      expect(state.lastScan, isNull);
      expect(state.scanning, isFalse,
          reason: 'the finally-block must always clear the loading flag');
    });

    testWidgets('shows no-data (not success) when OCR yields nothing usable',
        (tester) async {
      final context = await _localizedContext(tester);
      final state = _CapturedState();
      addTearDown(state.dispose);

      await tester.runAsync(() async {
        final capture = await _tempCapture();
        // Empty OCR text → parser finds no liters/cost → outcome.hasData
        // is false → the no-data branch, no prefill.
        state.service = _realParserService(
          picker: _FakePicker(null),
          recognizer: _FakeRecognizer()..textToReturn = '',
        );

        await runSharedReceiptScan(context, state.host(), capture.path);

        if (capture.dir.existsSync()) {
          await capture.dir.delete(recursive: true);
        }
      });

      expect(state.lastScan, isNull,
          reason: 'no usable data → no prefill, no cached scan');
      expect(state.litersCtrl.text, isEmpty);
    });
  });
}
