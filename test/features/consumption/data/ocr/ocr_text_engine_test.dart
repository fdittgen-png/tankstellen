// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_text_engine.dart';

/// #3052 — the iOS [VisionOcrTextEngine] is a thin bridge over the
/// `tankstellen/vision_ocr` MethodChannel (Apple Vision in AppDelegate.swift).
/// These tests pin the channel CONTRACT it relies on: the args it forwards and
/// the decode of the `{text, blocks:[{text,left,top,right,bottom}]}` payload
/// into the pure [RecognizedTextBlock]/[OcrBox] geometry the receipt + pump
/// extractors consume. The Swift side (coordinate flip, VNRecognizeTextRequest)
/// is verified on the maintainer's iOS build — the sim build is ML-Kit-blocked.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('tankstellen/vision_ocr');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('forwards args and maps the response into text + box geometry',
      () async {
    Map<Object?, Object?>? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call.arguments as Map<Object?, Object?>;
      return <String, Object?>{
        'text': 'PRIX\n1,859',
        'blocks': <Object?>[
          <String, Object?>{
            'text': 'PRIX',
            'left': 10.0,
            'top': 20.0,
            'right': 60.0,
            'bottom': 40.0,
          },
          <String, Object?>{
            'text': '1,859',
            'left': 70.0,
            'top': 22.0,
            'right': 140.0,
            'bottom': 41.0,
          },
          // Empty-text fragment must be dropped (matches ML Kit-side behaviour).
          <String, Object?>{
            'text': '',
            'left': 0.0,
            'top': 0.0,
            'right': 0.0,
            'bottom': 0.0,
          },
        ],
      };
    });

    final engine = VisionOcrTextEngine();
    final result = await engine.recognize(
      '/tmp/pump.jpg',
      languageCorrection: false,
      languages: const ['fr-FR'],
    );

    // Args forwarded verbatim to the Swift handler.
    expect(received?['path'], '/tmp/pump.jpg');
    expect(received?['languageCorrection'], false);
    expect(received?['languages'], ['fr-FR']);

    // Flat text preserved; empty fragment dropped; geometry mapped 1:1.
    expect(result, isNotNull);
    expect(result!.text, 'PRIX\n1,859');
    expect(result.blocks, hasLength(2));
    expect(result.blocks[0].text, 'PRIX');
    expect(result.blocks[0].box.left, 10.0);
    expect(result.blocks[0].box.bottom, 40.0);
    expect(result.blocks[1].text, '1,859');
    expect(result.blocks[1].box.right, 140.0);
    expect(result.blocks[1].box.cx, (70.0 + 140.0) / 2);
  });

  test('null channel response → null so the caller degrades like ML Kit',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    final engine = VisionOcrTextEngine();
    expect(await engine.recognize('/tmp/x.jpg'), isNull);
  });

  test('integer coordinates from the platform are coerced to double', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return <String, Object?>{
        'text': 'A',
        'blocks': <Object?>[
          // Platform may send whole numbers as int — must not throw.
          <String, Object?>{
            'text': 'A',
            'left': 1,
            'top': 2,
            'right': 3,
            'bottom': 4,
          },
        ],
      };
    });
    final engine = VisionOcrTextEngine();
    final result = await engine.recognize('/tmp/x.jpg');
    expect(result!.blocks.single.box.right, 3.0);
  });
}
