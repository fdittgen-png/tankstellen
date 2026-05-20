import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sharing/local_file_saver.dart';

void main() {
  late Directory tempRoot;
  late Directory docs;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('local_file_saver_test_');
    docs = await Directory('${tempRoot.path}/docs').create(recursive: true);
    debugLocalFileSaverDocsOverride = () async => docs;
  });

  tearDown(() async {
    debugLocalFileSaverDocsOverride = null;
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  group('LocalFileSaver (#1993)', () {
    test('saveBytesToDownloads writes to <docs>/Downloads/<fileName> '
        'and returns the absolute path', () async {
      final bytes = Uint8List.fromList(utf8.encode('hello, world'));
      final savedPath = await LocalFileSaver.saveBytesToDownloads(
        bytes: bytes,
        fileName: 'hello.txt',
      );

      // Path lands under the Downloads subfolder of the docs dir.
      expect(savedPath, contains('Downloads'));
      expect(savedPath, endsWith('hello.txt'));
      expect(savedPath.startsWith(docs.path), isTrue,
          reason: 'saved file must live under the docs directory');

      final file = File(savedPath);
      expect(file.existsSync(), isTrue);
      expect(await file.readAsBytes(), bytes);
    });

    test('saveTextToDownloads writes the UTF-8 string', () async {
      final savedPath = await LocalFileSaver.saveTextToDownloads(
        text: 'café — données',
        fileName: 'note.txt',
      );

      expect(savedPath, endsWith('note.txt'));
      final file = File(savedPath);
      expect(await file.readAsString(), 'café — données');
    });

    test('creates the Downloads folder on first save', () async {
      final downloads = Directory('${docs.path}/Downloads');
      expect(downloads.existsSync(), isFalse);

      await LocalFileSaver.saveTextToDownloads(
        text: 'x',
        fileName: 'first.txt',
      );

      expect(downloads.existsSync(), isTrue,
          reason: 'Downloads folder must be created on demand');
    });

    test('overwrites an existing file with the same name', () async {
      await LocalFileSaver.saveTextToDownloads(
        text: 'v1',
        fileName: 'pinned.txt',
      );
      final secondPath = await LocalFileSaver.saveTextToDownloads(
        text: 'v2',
        fileName: 'pinned.txt',
      );

      expect(await File(secondPath).readAsString(), 'v2',
          reason: 'a second save with the same filename must overwrite');
    });

    test('returns a clean absolute path (no double-separators)',
        () async {
      // Light sanity check that nothing in the helper accidentally
      // double-joins the separator or leaves a trailing slash.
      final saved = await LocalFileSaver.saveTextToDownloads(
        text: 'ping',
        fileName: 'integrity.txt',
      );
      expect(saved.contains('//'), isFalse);
      expect(saved.endsWith('/'), isFalse);
      expect(saved.startsWith(docs.path), isTrue);
    });
  });
}
