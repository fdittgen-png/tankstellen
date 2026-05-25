// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sharing/public_file_exporter.dart';

void main() {
  group('PublicFileExporter (#2014)', () {
    tearDown(() {
      debugPublicFileExporterOverride = null;
    });

    test('saveBytesToDownloads routes through the debug override', () async {
      Uint8List? capturedBytes;
      String? capturedName;
      String? capturedMime;
      debugPublicFileExporterOverride = ({
        required Uint8List bytes,
        required String fileName,
        required String mimeType,
      }) async {
        capturedBytes = bytes;
        capturedName = fileName;
        capturedMime = mimeType;
        return 'fake://Downloads/$fileName';
      };

      final result = await PublicFileExporter.saveBytesToDownloads(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'backup.zip',
        mimeType: 'application/zip',
      );

      expect(result, 'fake://Downloads/backup.zip');
      expect(capturedBytes, Uint8List.fromList([1, 2, 3]));
      expect(capturedName, 'backup.zip');
      expect(capturedMime, 'application/zip');
    });

    test('saveTextToDownloads encodes UTF-8 and forwards to the bytes path',
        () async {
      Uint8List? capturedBytes;
      String? capturedMime;
      debugPublicFileExporterOverride = ({
        required Uint8List bytes,
        required String fileName,
        required String mimeType,
      }) async {
        capturedBytes = bytes;
        capturedMime = mimeType;
        return 'ok';
      };

      await PublicFileExporter.saveTextToDownloads(
        text: 'héllo',
        fileName: 'export.json',
        mimeType: 'application/json',
      );

      expect(capturedBytes, isNotNull);
      // UTF-8 of 'héllo' is 6 bytes (é is two), not the 5 ASCII chars —
      // confirms the encoder ran rather than treating the string as Latin-1.
      expect(capturedBytes!.length, 6);
      expect(capturedMime, 'application/json');
    });

    test('saveBytesToDownloads uses default mime when none given', () async {
      String? capturedMime;
      debugPublicFileExporterOverride = ({
        required Uint8List bytes,
        required String fileName,
        required String mimeType,
      }) async {
        capturedMime = mimeType;
        return '';
      };

      await PublicFileExporter.saveBytesToDownloads(
        bytes: Uint8List(0),
        fileName: 'whatever.bin',
      );

      expect(capturedMime, 'application/octet-stream');
    });
  });
}
