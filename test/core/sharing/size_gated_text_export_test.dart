// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tankstellen/core/sharing/public_file_exporter.dart';
import 'package:tankstellen/core/sharing/size_gated_text_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final savedDownloads = <String, String>{};

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('size_gated_export_test');
    savedDownloads.clear();
    debugPublicFileExporterOverride = ({
      required Uint8List bytes,
      required String fileName,
      required String mimeType,
    }) async {
      savedDownloads[fileName] = String.fromCharCodes(bytes);
      return 'Downloads/$fileName';
    };
    // Silence the real clipboard channel — SensitiveClipboard goes
    // through SystemChannels.platform.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  tearDown(() {
    debugPublicFileExporterOverride = null;
    tempDir.deleteSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('exportTextSizeGated', () {
    test(
        'large payload goes through the share seam with a staged file '
        'and writes Downloads exactly once (#2236)', () async {
      ShareParams? captured;
      final outcome = await exportTextSizeGated(
        text: 'x' * 32,
        fileName: 'export.json',
        mimeType: 'application/json',
        logWhere: 'test.large',
        clipboardThresholdBytes: 16,
        shareSink: (params) async => captured = params,
        tempDirectoryProvider: () async => tempDir,
      );

      expect(outcome, SizeGatedTextExportOutcome.sharedAndSaved);
      expect(outcome.savedToDownloads, isTrue);
      expect(captured, isNotNull);
      expect(captured!.files, hasLength(1));
      expect(captured!.subject, 'export.json');
      final staged = File('${tempDir.path}/export.json');
      expect(staged.existsSync(), isTrue);
      expect(staged.readAsStringSync(), 'x' * 32);
      expect(savedDownloads, {'export.json': 'x' * 32});
    });

    test('failing share seam falls back to the clipboard copy', () async {
      final outcome = await exportTextSizeGated(
        text: 'y' * 32,
        fileName: 'export.json',
        mimeType: 'application/json',
        logWhere: 'test.share-fail',
        clipboardThresholdBytes: 16,
        shareSink: (_) async => throw StateError('share broke'),
        tempDirectoryProvider: () async => tempDir,
      );
      expect(outcome, SizeGatedTextExportOutcome.shareFailedCopied);
      expect(outcome.announcedViaClipboard, isTrue);
      // The failed large path never writes Downloads.
      expect(savedDownloads, isEmpty);
    });

    test('small payload copies to clipboard and never touches the seam',
        () async {
      var seamCalls = 0;
      final outcome = await exportTextSizeGated(
        text: 'small',
        fileName: 'export.json',
        mimeType: 'application/json',
        logWhere: 'test.small',
        clipboardThresholdBytes: 1024,
        shareSink: (_) async => seamCalls++,
        tempDirectoryProvider: () async => tempDir,
      );
      expect(seamCalls, 0);
      expect(outcome, SizeGatedTextExportOutcome.copiedAndSaved);
      expect(savedDownloads, {'export.json': 'small'});
    });

    test('small payload with a failing Downloads write reports copiedOnly',
        () async {
      debugPublicFileExporterOverride = ({
        required Uint8List bytes,
        required String fileName,
        required String mimeType,
      }) async {
        throw const FileSystemException('no space');
      };
      final outcome = await exportTextSizeGated(
        text: 'small',
        fileName: 'export.json',
        mimeType: 'application/json',
        logWhere: 'test.save-fail',
      );
      expect(outcome, SizeGatedTextExportOutcome.copiedOnly);
      expect(outcome.savedToDownloads, isFalse);
      expect(outcome.announcedViaClipboard, isTrue);
    });
  });
}
