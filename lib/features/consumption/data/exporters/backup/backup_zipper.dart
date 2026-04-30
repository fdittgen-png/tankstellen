import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Zips a single backup XML payload into a one-entry archive
/// (`tankstellen_backup_<timestamp>.xml` inside the bytes returned).
///
/// Pure-Dart, no I/O; the orchestrator writes the resulting bytes to a
/// temp file before handing the path to the share sheet.
class BackupZipper {
  const BackupZipper();

  /// Compress [xml] into a single-entry zip and return the raw bytes.
  ///
  /// The inner filename uses [now] (UTC) to produce a deterministic
  /// `tankstellen_backup_<YYYYMMDDTHHMMSS>.xml` stem so successive
  /// backups don't overwrite each other when extracted to the same
  /// directory. Tests pass a fixed [now] to assert byte-stability.
  Uint8List zip(String xml, {required DateTime now}) {
    final innerName = innerFileNameFor(now);
    final archive = Archive();
    archive.addFile(
      ArchiveFile.bytes(innerName, utf8.encode(xml)),
    );
    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// Build the deterministic inner XML filename for a given timestamp.
  ///
  /// Format: `tankstellen_backup_<YYYYMMDDTHHMMSS>.xml`. UTC, colons
  /// stripped to keep the name filesystem-safe across Windows / iOS /
  /// Android extraction targets.
  static String innerFileNameFor(DateTime now) {
    final stamp = stampFor(now);
    return 'tankstellen_backup_$stamp.xml';
  }

  /// Build the deterministic compact-stamp suffix used by both the
  /// inner XML filename and the outer `.zip` filename.
  ///
  /// Example output: `20260430T220400`. Always UTC.
  static String stampFor(DateTime now) {
    final utc = now.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    final date = '${utc.year.toString().padLeft(4, '0')}'
        '${two(utc.month)}${two(utc.day)}';
    final time = '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}';
    return '${date}T$time';
  }
}
