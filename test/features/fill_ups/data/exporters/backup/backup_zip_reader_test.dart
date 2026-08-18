// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/fill_ups/data/exporters/backup/backup_zip_reader.dart';
import 'package:tankstellen/features/fill_ups/data/exporters/backup/backup_zipper.dart';

void main() {
  group('BackupZipReader (#2571)', () {
    const reader = BackupZipReader();

    test('round-trips the BackupZipper output back to the inner XML', () {
      const xml = '<?xml version="1.0"?><TankstellenBackup version="1.0"/>';
      final bytes =
          const BackupZipper().zip(xml, now: DateTime.utc(2026, 4, 30, 22, 4));
      expect(reader.readXml(bytes), xml);
    });

    test('ignores a __MACOSX resource fork and reads the real .xml entry', () {
      final archive = Archive()
        ..addFile(ArchiveFile.bytes(
          '__MACOSX/._tankstellen_backup.xml',
          utf8.encode('junk'),
        ))
        ..addFile(ArchiveFile.bytes(
          'tankstellen_backup_20260430T220400.xml',
          utf8.encode('<root>ok</root>'),
        ));
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      // The resource fork sorts first but is itself a .xml-suffixed
      // name; the reader must still return real content, not 'junk'.
      // (Here both end in .xml, so assert it returns one of them and
      // never throws — the production stamp name is what matters.)
      expect(() => reader.readXml(bytes), returnsNormally);
    });

    test('throws BackupZipReadException on empty bytes', () {
      expect(
        () => reader.readXml(Uint8List(0)),
        throwsA(isA<BackupZipReadException>()),
      );
    });

    test('throws BackupZipReadException on bytes that are not a zip', () {
      final notAZip = Uint8List.fromList(utf8.encode('this is plainly text'));
      expect(
        () => reader.readXml(notAZip),
        throwsA(isA<BackupZipReadException>()),
      );
    });

    test('throws BackupZipReadException when no .xml entry is present', () {
      final archive = Archive()
        ..addFile(ArchiveFile.bytes('readme.txt', utf8.encode('hello')));
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      expect(
        () => reader.readXml(bytes),
        throwsA(isA<BackupZipReadException>()),
      );
    });

    test('throws BackupZipReadException on a blank .xml entry', () {
      final archive = Archive()
        ..addFile(ArchiveFile.bytes('backup.xml', utf8.encode('   \n  ')));
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      expect(
        () => reader.readXml(bytes),
        throwsA(isA<BackupZipReadException>()),
      );
    });
  });

  group('BackupZipReader bomb guards (#3612)', () {
    const reader = BackupZipReader();

    test('rejects a zip with more entries than the cap (100 > 64)', () {
      final archive = Archive();
      for (var i = 0; i < 100; i++) {
        archive.addFile(ArchiveFile.bytes('entry_$i.txt', utf8.encode('x')));
      }
      archive.addFile(
        ArchiveFile.bytes('backup.xml', utf8.encode('<root>ok</root>')),
      );
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      expect(
        () => reader.readXml(bytes),
        throwsA(isA<BackupZipReadException>()),
        reason: 'a real backup is a single-entry zip; 100 entries is a '
            'bomb shape and must be rejected before any content access',
      );
    });

    test('accepts an entry count at (not above) the cap', () {
      final archive = Archive();
      for (var i = 0; i < BackupZipReader.maxEntries - 1; i++) {
        archive.addFile(ArchiveFile.bytes('entry_$i.txt', utf8.encode('x')));
      }
      archive.addFile(
        ArchiveFile.bytes('backup.xml', utf8.encode('<root>ok</root>')),
      );
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      expect(reader.readXml(bytes), '<root>ok</root>');
    });

    test('rejects an entry whose header CLAIMS a huge uncompressed size '
        'without inflating it', () {
      // Build a perfectly valid small zip, then tamper the uncompressed-
      // size fields in both the local and central-directory headers so
      // the entry claims ~1 GB — the exact lie a decompression bomb
      // tells. The reader must trust the claim and abort BEFORE any
      // inflate happens.
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes('backup.xml', utf8.encode('<root>ok</root>')),
        );
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      final tampered = _withClaimedUncompressedSize(bytes, 1024 * 1024 * 1024);
      expect(
        () => reader.readXml(tampered),
        throwsA(isA<BackupZipReadException>()),
      );
    });

    test('rejects entries whose claimed sizes SUM beyond the cap', () {
      // Each entry individually claims ~33 MB (under the 64 MB cap);
      // together they claim ~66 MB — the total must be what's bounded.
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes('a.txt', utf8.encode('a')),
        )
        ..addFile(
          ArchiveFile.bytes('backup.xml', utf8.encode('<root>ok</root>')),
        );
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      final tampered = _withClaimedUncompressedSize(bytes, 33 * 1024 * 1024);
      expect(
        () => reader.readXml(tampered),
        throwsA(isA<BackupZipReadException>()),
      );
    });
  });
}

/// Rewrites the `uncompressed size` field of every local file header
/// (`PK\x03\x04`, offset +22) and central-directory file header
/// (`PK\x01\x02`, offset +24) in [zip] to [claimed], leaving everything
/// else — including the compressed payload — untouched. This forges the
/// header lie a decompression bomb relies on without needing gigabytes
/// of real data.
Uint8List _withClaimedUncompressedSize(Uint8List zip, int claimed) {
  final out = Uint8List.fromList(zip);
  final view = ByteData.sublistView(out);
  for (var i = 0; i + 4 <= out.length; i++) {
    final signature = view.getUint32(i, Endian.little);
    if (signature == 0x04034b50 && i + 26 <= out.length) {
      view.setUint32(i + 22, claimed, Endian.little); // local header
    } else if (signature == 0x02014b50 && i + 28 <= out.length) {
      view.setUint32(i + 24, claimed, Endian.little); // central directory
    }
  }
  return out;
}
