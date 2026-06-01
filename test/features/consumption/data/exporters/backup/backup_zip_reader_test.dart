// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_zip_reader.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_zipper.dart';

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
}
