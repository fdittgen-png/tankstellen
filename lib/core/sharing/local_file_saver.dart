import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Hook for the docs-directory lookup used by [LocalFileSaver]. Tests
/// substitute a fake (a per-test temp folder) to avoid pulling in the
/// `path_provider_platform_interface` dev-dep just to stub a single
/// call — the established pattern matches `debugPrivacyTempDirectoryOverride`
/// and `debugBackupTempDirectoryOverride` already used by the other
/// export sites.
typedef LocalFileSaverDocsProvider = Future<Directory> Function();

/// Test-only override for the docs-directory lookup. When set,
/// [LocalFileSaver] writes under this directory's `Downloads/` subfolder
/// instead of the platform's real `getApplicationDocumentsDirectory()`.
@visibleForTesting
LocalFileSaverDocsProvider? debugLocalFileSaverDocsOverride;

/// Saves an export to a fixed visible folder under the app's documents
/// directory — `<docs>/Downloads/` — and returns the absolute path of
/// the written file (#1993).
///
/// Used as an alternative to the OS share sheet by the various export
/// flows: the user finds the file later via any file manager, without
/// scrolling through share targets. The Downloads folder is created on
/// demand and reused across calls; existing files with the same
/// `fileName` are overwritten.
class LocalFileSaver {
  LocalFileSaver._();

  /// Writes [bytes] to `<docs>/Downloads/<fileName>` and returns the
  /// absolute path. Creates the Downloads folder on first save.
  static Future<String> saveBytesToDownloads({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final dir = await _downloadsDir();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Writes [text] (UTF-8) to `<docs>/Downloads/<fileName>` and returns
  /// the absolute path. Convenience wrapper around [saveBytesToDownloads]
  /// for the JSON / CSV / XML exports.
  static Future<String> saveTextToDownloads({
    required String text,
    required String fileName,
  }) async {
    final dir = await _downloadsDir();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(text, flush: true);
    return file.path;
  }

  static Future<Directory> _downloadsDir() async {
    final docsProvider =
        debugLocalFileSaverDocsOverride ?? getApplicationDocumentsDirectory;
    final docs = await docsProvider();
    final dir = Directory(
      '${docs.path}${Platform.pathSeparator}Downloads',
    );
    // `Directory.create(recursive: true)` is a no-op when the path
    // already exists, so we skip the up-front existence probe — that
    // avoids the avoid_slow_async_io lint and one syscall on every save.
    await dir.create(recursive: true);
    return dir;
  }
}
