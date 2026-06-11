// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'impl/public_file_exporter_io.dart' as impl;

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

/// Test-only override for [PublicFileExporter.downloadsInitialDirectory] so a
/// widget test can assert the import picker is opened with the Downloads hint
/// without touching path_provider / the platform (#2815).
@visibleForTesting
String? Function()? debugDownloadsInitialDirectoryOverride;

/// Writes user-visible exports to the device's **public** Downloads
/// folder (#2014). Replaces [LocalFileSaver], which saved to
/// `getApplicationDocumentsDirectory()/Downloads/` — a path that is
/// invisible to the Files app on both Android and iOS.
///
/// Platform behaviour (#3172 — the `Platform.isAndroid` dispatch lives in
/// `impl/public_file_exporter_io.dart`, off the epic-#2332 grandfather list):
/// - **Android Q+**: writes via `MediaStore.Downloads`, returning a
///   `content://` URI. No `WRITE_EXTERNAL_STORAGE` needed.
/// - **iOS**: writes to `getApplicationDocumentsDirectory()/Downloads/`.
///   The Info.plist keys `UIFileSharingEnabled` and
///   `LSSupportsOpeningDocumentsInPlace` make this folder visible
///   under Files → On My iPhone → tankstellen.
class PublicFileExporter {
  PublicFileExporter._();

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
    return impl.saveBytesToDownloadsImpl(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
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

  /// The directory a document picker should OPEN ON for an import, so the user
  /// lands where exports were saved instead of the (usually empty) "Recents"
  /// tab (#2815). iOS: the same `<docs>/Downloads` the exporter writes to.
  /// Android: the conventional public Downloads path — MediaStore (the export
  /// target) exposes no filesystem path, but `file_selector`'s SAF
  /// `initialDirectory` accepts this as a starting hint (honoured on most
  /// OEMs; harmless where ignored — the picker just falls back to its default).
  /// Returns null when the location can't be resolved (caller then opens the
  /// picker with no hint).
  static Future<String?> downloadsInitialDirectory() async {
    final override = debugDownloadsInitialDirectoryOverride;
    if (override != null) return override();
    return impl.downloadsInitialDirectoryImpl();
  }
}
