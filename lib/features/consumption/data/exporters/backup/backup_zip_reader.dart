// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Thrown when a `.zip` chosen for restore cannot be decoded into a
/// single readable backup XML payload (#2571).
///
/// The orchestrator ([FullBackupImporter]) catches this and surfaces a
/// localized "corrupt / unrecognised file" message — it never lets the
/// raw `archive` exception bubble into the UI.
class BackupZipReadException implements Exception {
  final String reason;
  const BackupZipReadException(this.reason);

  @override
  String toString() => 'BackupZipReadException: $reason';
}

/// Inverse of [BackupZipper] (#2571): decodes the raw bytes of a
/// `tankstellen_backup_<stamp>.zip` and returns the single inner XML
/// document as a `String`.
///
/// Pure-Dart, no I/O — the orchestrator reads the file bytes and hands
/// them in, mirroring how the writer side keeps the zipper I/O-free.
///
/// ### Robustness
/// A backup is, by construction, a one-entry zip whose sole member is a
/// `.xml` file (see `SCHEMA-BACKUP-XML.md`). Real-world archives can
/// nonetheless carry macOS `__MACOSX/` resource forks or a stray
/// directory entry if the user re-zipped the file by hand, so the
/// reader does not insist on exactly one entry — it selects the first
/// non-directory `.xml` member and ignores the rest. Anything that
/// decodes to zero `.xml` members, or whose bytes are not a valid zip
/// at all, raises [BackupZipReadException] rather than throwing the
/// underlying `archive`/format error.
class BackupZipReader {
  const BackupZipReader();

  /// #3612 — hard cap on the number of entries a restore zip may carry.
  /// A real backup is one `.xml` entry (plus, at worst, a handful of
  /// hand-re-zip artifacts like `__MACOSX/` forks); thousands of entries
  /// is a zip-bomb shape, rejected before any content is touched.
  static const int maxEntries = 64;

  /// #3612 — hard cap on the TOTAL claimed decompressed size across all
  /// entries (64 MB). The claimed sizes come from the zip's central
  /// directory, so a decompression bomb (tiny compressed payload
  /// claiming/holding gigabytes) is rejected BEFORE any entry is
  /// inflated. 64 MB is orders of magnitude above any real backup XML.
  static const int maxTotalUncompressedBytes = 64 * 1024 * 1024;

  /// Decode [bytes] and return the inner backup XML as a UTF-8 string.
  ///
  /// Throws [BackupZipReadException] when the bytes are not a valid
  /// zip, exceed the entry-count / decompressed-size caps (#3612),
  /// carry no `.xml` entry, or hold an empty XML payload.
  String readXml(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const BackupZipReadException('empty file');
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e, st) {
      // The raw decode error (FormatException / RangeError) is useless
      // to the user; rethrow as our typed exception. `st` is piped so a
      // future diagnostics path keeps the original trace (#1103).
      Error.throwWithStackTrace(
        const BackupZipReadException('not a valid zip archive'),
        st,
      );
    }

    // #3612 — bomb guards. `ZipDecoder.decodeBytes` only parses the
    // directory headers; each entry's content is inflated lazily on
    // first `.content` access, so both checks below run BEFORE any
    // decompression happens. `ArchiveFile.size` is the header's claimed
    // uncompressed size.
    if (archive.files.length > maxEntries) {
      throw const BackupZipReadException('too many entries in the zip');
    }
    var totalUncompressed = 0;
    for (final file in archive.files) {
      if (!file.isFile) continue;
      totalUncompressed += file.size;
      if (totalUncompressed > maxTotalUncompressedBytes) {
        throw const BackupZipReadException(
          'zip decompresses beyond the size cap',
        );
      }
    }

    ArchiveFile? xmlEntry;
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (file.name.toLowerCase().endsWith('.xml')) {
        xmlEntry = file;
        break;
      }
    }

    if (xmlEntry == null) {
      throw const BackupZipReadException('no XML entry inside the zip');
    }

    final content = xmlEntry.content;
    if (content.isEmpty) {
      throw const BackupZipReadException('empty XML entry');
    }

    final String xml;
    try {
      xml = utf8.decode(content);
    } catch (e, st) {
      Error.throwWithStackTrace(
        const BackupZipReadException('XML entry is not valid UTF-8'),
        st,
      );
    }
    if (xml.trim().isEmpty) {
      throw const BackupZipReadException('blank XML entry');
    }
    return xml;
  }
}
