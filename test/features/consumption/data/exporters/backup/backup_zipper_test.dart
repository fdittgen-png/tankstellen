import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_zipper.dart';

void main() {
  group('BackupZipper (#1317)', () {
    test('produces a single-entry zip with deterministic filename', () {
      const zipper = BackupZipper();
      final bytes = zipper.zip(
        '<TankstellenBackup version="1.0"/>',
        now: DateTime.utc(2026, 4, 30, 22, 4, 0),
      );

      final decoded = ZipDecoder().decodeBytes(bytes);
      expect(decoded.files.length, 1);
      final entry = decoded.files.single;
      expect(entry.name, 'tankstellen_backup_20260430T220400.xml');
    });

    test('decompressed bytes equal the input XML string', () {
      const xml = '<TankstellenBackup version="1.0">\n  <ExportedAt>'
          '2026-04-30T22:04:00.000Z</ExportedAt>\n</TankstellenBackup>';
      const zipper = BackupZipper();
      final bytes = zipper.zip(
        xml,
        now: DateTime.utc(2026, 4, 30, 22, 4, 0),
      );

      final decoded = ZipDecoder().decodeBytes(bytes);
      final entry = decoded.files.single;
      final extracted = utf8.decode(entry.content as List<int>);
      expect(extracted, xml);
    });

    test('stampFor renders UTC and pads every component to two digits', () {
      // 1 January 2026 at 03:07:09 UTC. Output must be the
      // canonical compact form `20260101T030709`.
      final stamp = BackupZipper.stampFor(DateTime.utc(2026, 1, 1, 3, 7, 9));
      expect(stamp, '20260101T030709');
    });

    test('inner filename matches the published pattern', () {
      final name = BackupZipper.innerFileNameFor(
        DateTime.utc(2026, 12, 31, 23, 59, 59),
      );
      expect(name, 'tankstellen_backup_20261231T235959.xml');
    });

    test('local-zone timestamps are normalised to UTC before stamping', () {
      // Construct a timezone-local DateTime that resolves to a known
      // UTC instant; stampFor must use the UTC components.
      final local = DateTime.utc(2026, 6, 15, 12, 0, 0).toLocal();
      final stamp = BackupZipper.stampFor(local);
      expect(stamp, '20260615T120000');
    });
  });
}
