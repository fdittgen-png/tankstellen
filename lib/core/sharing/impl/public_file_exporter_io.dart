// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Platform-dispatching bodies of [PublicFileExporter] (#3172, epic #2332
/// burn-down). Lives in `impl/` so the `Platform.isAndroid` fork stays out
/// of shared code (`test/lint/no_inline_platform_check_test.dart`); the
/// public API + debug-override seams stay in
/// `lib/core/sharing/public_file_exporter.dart`. Move-only — behaviour
/// byte-identical to the pre-split inline branches.

/// Android side of the write: `MediaStore.Downloads` via the
/// `tankstellen/public_files` method channel (no `WRITE_EXTERNAL_STORAGE`
/// needed on Q+), returning a `content://` URI.
const MethodChannel _channel = MethodChannel('tankstellen/public_files');

/// Writes [bytes] to the platform's user-visible Downloads location.
/// Android Q+: MediaStore (content URI). iOS: `<docs>/Downloads/`, visible
/// under Files → On My iPhone via the `UIFileSharingEnabled` +
/// `LSSupportsOpeningDocumentsInPlace` Info.plist keys.
Future<String> saveBytesToDownloadsImpl({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  if (Platform.isAndroid) {
    final result = await _channel.invokeMethod<String>('saveBytes', {
      'fileName': fileName,
      'mimeType': mimeType,
      'bytes': bytes,
    });
    return result ?? '';
  }
  final dir = await _iosDocumentsDownloads();
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

/// The directory a document picker should OPEN ON for an import (#2815).
/// iOS: the same `<docs>/Downloads` the exporter writes to. Android: the
/// conventional public Downloads path as a SAF `initialDirectory` hint
/// (honoured on most OEMs; harmless where ignored). Null when the location
/// can't be resolved (caller then opens the picker with no hint).
Future<String?> downloadsInitialDirectoryImpl() async {
  if (Platform.isAndroid) return '/storage/emulated/0/Download';
  try {
    final dir = await _iosDocumentsDownloads();
    return dir.path;
  } on Object {
    return null;
  }
}

Future<Directory> _iosDocumentsDownloads() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}${Platform.pathSeparator}Downloads');
  await dir.create(recursive: true);
  return dir;
}
