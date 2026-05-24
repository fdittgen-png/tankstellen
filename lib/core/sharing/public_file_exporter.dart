import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Test seam: a function the unit test can install to bypass the
/// platform-channel / iOS-docs branches and capture writes in a per-test
/// temp dir. Mirrors the `debugLocalFileSaverDocsOverride` seam that
/// preceded this class — keeps call-site tests synchronous without
/// requiring channel-mock plumbing in every caller.
typedef PublicFileExporterOverride = Future<String> Function({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
});

@visibleForTesting
PublicFileExporterOverride? debugPublicFileExporterOverride;

/// Writes user-visible exports to the device's **public** Downloads
/// folder (#2014). Replaces [LocalFileSaver], which saved to
/// `getApplicationDocumentsDirectory()/Downloads/` — a path that is
/// invisible to the Files app on both Android and iOS.
///
/// Platform behaviour:
/// - **Android Q+**: writes via `MediaStore.Downloads`, returning a
///   `content://` URI. No `WRITE_EXTERNAL_STORAGE` needed.
/// - **iOS**: writes to `getApplicationDocumentsDirectory()/Downloads/`.
///   The Info.plist keys `UIFileSharingEnabled` and
///   `LSSupportsOpeningDocumentsInPlace` make this folder visible
///   under Files → On My iPhone → tankstellen.
class PublicFileExporter {
  PublicFileExporter._();

  static const MethodChannel _channel =
      MethodChannel('tankstellen/public_files');

  /// Writes [bytes] to the user-visible Downloads location and returns
  /// a value suitable for logging / debug display. The display string
  /// is platform-specific (filesystem path on iOS, content URI on
  /// Android Q+) and should NOT be shown to users directly — call sites
  /// should use the `savedToDownloadsFolder` ARB string for the
  /// snackbar instead.
  static Future<String> saveBytesToDownloads({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'application/octet-stream',
  }) async {
    final override = debugPublicFileExporterOverride;
    if (override != null) {
      return override(bytes: bytes, fileName: fileName, mimeType: mimeType);
    }
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

  /// UTF-8 convenience wrapper around [saveBytesToDownloads] for the
  /// JSON / CSV / XML export sites.
  static Future<String> saveTextToDownloads({
    required String text,
    required String fileName,
    String mimeType = 'text/plain',
  }) {
    return saveBytesToDownloads(
      bytes: Uint8List.fromList(utf8.encode(text)),
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  static Future<Directory> _iosDocumentsDownloads() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}Downloads');
    await dir.create(recursive: true);
    return dir;
  }
}
