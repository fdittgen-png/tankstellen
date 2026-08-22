// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr/ocr_trace_package.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr/ocr_trace_recorder.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr/ocr_trace_serializer.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr/recognized_text_block.dart';

/// Coverage for `formatOcrTracePackageJson` (#2517): the JSON mirror of
/// `formatObd2DebugSessionXml`. Asserts schema versioning, the full chain
/// is present, and that the document round-trips (encode → decode → same
/// values), so the tester (Epic #2516 Child 2) and the AI analysing the
/// export read a stable, self-describing format.
void main() {
  const frProfile = OcrLocaleProfile(
    country: 'FR',
    currency: 'EUR',
    decimalSeparator: ',',
    priceMin: 0.5,
    priceMax: 4.0,
    volumeMax: 200.0,
    totalMax: 500.0,
  );

  RecognizedTextBlock block(String text,
          {required double l,
          required double t,
          required double r,
          required double b}) =>
      RecognizedTextBlock(
          text: text, box: OcrBox(left: l, top: t, right: r, bottom: b));

  List<RecognizedTextBlock> sampleBlocks() => <RecognizedTextBlock>[
        block('PRIX', l: 40, t: 100, r: 130, b: 130),
        block('18,59', l: 40, t: 140, r: 200, b: 185),
        block('VOLUME', l: 40, t: 220, r: 170, b: 250),
        block('23,30', l: 40, t: 260, r: 200, b: 305),
        block('PRIX DU LITRE', l: 40, t: 340, r: 230, b: 370),
        block('0,798', l: 40, t: 380, r: 180, b: 420),
      ];

  /// Feeds the recorder through its typed sinks with the same values
  /// the (removed, #3765) pump pipeline used to produce — the recorder
  /// and serializer are pipeline-agnostic, so the wire format is pinned
  /// directly.
  OcrTraceRecorder runTrace() {
    final recorder = OcrTraceRecorder(kind: OcrTraceKind.receipt);
    recorder.input(country: 'FR', profile: frProfile.toTraceJson());
    recorder.glare(fraction: 0.12, threshold: 0.4, rejected: false);
    recorder.blocks('PRIX 18,59 ...', sampleBlocks());
    recorder.classify('PRIX', 'label', field: 'totalCost', weight: 4);
    recorder.classify('18,59', 'numeric', value: 18.59, decimals: 2);
    recorder.anchorCandidates(const [
      OcrTraceAnchor(
        labelField: 'totalCost',
        labelText: 'PRIX',
        numericValue: 18.59,
        sqDistance: 1600,
        chosen: true,
      ),
    ]);
    recorder.confidence(
        hasTotal: true,
        hasVolume: true,
        hasPrice: true,
        isConsistent: true,
        total: 1.0);
    recorder.gateCheck(
      checks: const [
        OcrTraceGateCheck(name: 'enough-fields', passed: true),
        OcrTraceGateCheck(name: 'identity', passed: true),
      ],
      reason: 'consistent',
      accepted: true,
      identityDelta: 0.005,
    );
    recorder.result(
        totalCost: 18.59,
        liters: 23.30,
        pricePerLiter: 0.798,
        confidence: 1.0,
        validated: true);
    return recorder;
  }

  test('serialises schema 1, the kind, and the input/profile section', () {
    final json = formatOcrTracePackageJson(runTrace().build());
    final decoded = jsonDecode(json) as Map<String, dynamic>;

    expect(decoded['schema'], 1);
    expect(decoded['kind'], 'receipt');
    expect(decoded['capturedAt'], isA<String>());
    final input = decoded['input'] as Map<String, dynamic>;
    expect(input['country'], 'FR');
    expect((input['profile'] as Map)['priceMax'], 4.0);
  });

  test('carries the whole reasoning chain through to JSON', () {
    final decoded =
        jsonDecode(formatOcrTracePackageJson(runTrace().build())) as Map;

    expect((decoded['preprocess'] as Map)['rejected'], isFalse);
    expect((decoded['mlkit'] as Map)['flatText'], 'PRIX 18,59 ...');
    expect((decoded['mlkit'] as Map)['blocks'], isList);
    expect(decoded['classification'], isList);
    expect(decoded['anchors'], isList);
    expect(decoded['confidence'], isA<Map<dynamic, dynamic>>());
    expect((decoded['gate'] as Map)['reason'], 'consistent');
    expect((decoded['gate'] as Map)['checks'], isList);
    final result = decoded['result'] as Map;
    expect(result['totalCost'], closeTo(18.59, 0.001));
    expect(result['validated'], isTrue);
  });

  test('a block carries its bounding box as [l, t, r, b]', () {
    final decoded =
        jsonDecode(formatOcrTracePackageJson(runTrace().build())) as Map;
    final blocks = (decoded['mlkit'] as Map)['blocks'] as List;
    final first = blocks.first as Map;
    expect(first['text'], 'PRIX');
    expect(first['box'], [40, 100, 130, 130]);
  });

  test('round-trips: encode → decode → re-encode is stable', () {
    final pkg = runTrace().build();
    final once = formatOcrTracePackageJson(pkg);
    // Re-encode the decoded tree with the same indent → identical string.
    final reencoded = const JsonEncoder.withIndent('  ')
        .convert(jsonDecode(once));
    expect(reencoded, once);
  });

  test('a minimal package omits absent optional sections', () {
    final recorder = OcrTraceRecorder(kind: OcrTraceKind.receipt);
    recorder.input(country: 'GB');
    final decoded =
        jsonDecode(formatOcrTracePackageJson(recorder.build())) as Map;
    expect(decoded['kind'], 'receipt');
    expect(decoded.containsKey('mlkit'), isFalse);
    expect(decoded.containsKey('gate'), isFalse);
    expect(decoded.containsKey('result'), isFalse);
    // Empty list sections are omitted, not serialised as [].
    expect(decoded.containsKey('classification'), isFalse);
  });

  test('a crossCheck section serialises end to end', () {
    final recorder = runTrace();
    recorder.crossCheck(
        total: 18.59,
        volume: 23.30,
        derivedPath: 'pricePerLitre',
        computed: 0.798);
    // No throw, valid JSON, schema present.
    final decoded =
        jsonDecode(formatOcrTracePackageJson(recorder.build())) as Map;
    expect(decoded['schema'], 1);
    expect(decoded['crossCheck'], isA<Map<dynamic, dynamic>>());
  });

  group('includeImage (#2853 — clipboard TransactionTooLargeException)', () {
    // A recorder run plus a ~5 MB base64 capture image — the same shape that
    // tripped Android's ~1 MB Binder limit when the clipboard carried it.
    OcrTracePackage withLargeImage() {
      // 4 MB of bytes → ~5.3 MB base64, mirroring the real crash payload.
      final bytes = List<int>.filled(4 * 1024 * 1024, 7);
      final recorder = runTrace()
        ..image(fileName: 'capture.jpg', base64: base64Encode(bytes));
      return recorder.build();
    }

    test('default serialisation (file export) STILL carries the image', () {
      final json = formatOcrTracePackageJson(withLargeImage());
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded.containsKey('image'), isTrue);
      expect((decoded['image'] as Map)['base64'], isNotEmpty);
      // The file payload is necessarily huge (it embeds the capture).
      expect(utf8.encode(json).length, greaterThan(5 * 1024 * 1024));
    });

    test('includeImage:false omits the base64 blob entirely', () {
      final pkg = withLargeImage();
      final clip = formatOcrTracePackageJson(pkg, includeImage: false);

      // The base64 bytes must not appear anywhere in the clipboard JSON.
      expect(clip.contains(pkg.image!.base64), isFalse);
      expect((jsonDecode(clip) as Map).containsKey('image'), isFalse);
      // And the document is now far under the ~1 MB Binder transaction cap.
      expect(utf8.encode(clip).length, lessThan(64 * 1024));

      // Eliding the image leaves the rest of the reasoning chain intact.
      final decoded = jsonDecode(clip) as Map<String, dynamic>;
      expect(decoded['kind'], 'receipt');
      expect((decoded['result'] as Map)['totalCost'], closeTo(18.59, 0.001));
    });

    test('an image-less trace serialises identically either way', () {
      final pkg = runTrace().build();
      expect(
        formatOcrTracePackageJson(pkg, includeImage: false),
        formatOcrTracePackageJson(pkg),
      );
    });
  });
}
