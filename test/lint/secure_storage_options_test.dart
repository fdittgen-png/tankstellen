// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/secure_storage_options.dart';

/// Static-scan guard (#4373): every `FlutterSecureStorage(` constructed in
/// `lib/` passes `aOptions: kSecureStorageAndroidOptions`.
///
/// **Why:** the plugin's Android default is `resetOnError: true`, which
/// answers a transient KeyStore read error by deleting stored secrets —
/// the Hive encryption key among them, which makes every encrypted box
/// unreadable forever. All instances share one preferences file, so ONE
/// construction left on the default endangers every secret. No
/// grandfathered set: the count is zero and stays zero.
///
/// The scan skips `//` comments and reads the whole argument list, so a
/// wrapped constructor call is judged like a one-line one.
void main() {
  test('the shared options never let the plugin delete on error', () {
    expect(kSecureStorageAndroidOptions.toMap()['resetOnError'], 'false');
  });

  test('every FlutterSecureStorage in lib/ uses the shared options', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;
      offenders.addAll(
          secureStorageOffenders(entity.path, entity.readAsStringSync()));
    }
    expect(offenders, isEmpty,
        reason: 'Construct secure storage with '
            '`FlutterSecureStorage(aOptions: kSecureStorageAndroidOptions)` '
            '(lib/core/storage/secure_storage_options.dart, #4373):\n'
            '${offenders.join('\n')}');
  });

  group('the scanner — fidelity', () {
    test('flags a default construction, const or not, wrapped or not', () {
      expect(secureStorageOffenders('a.dart', '''
const s = FlutterSecureStorage();
final t = FlutterSecureStorage(
  iOptions: IOSOptions(),
);
'''), hasLength(2));
    });

    test('flags an explicit resetOnError: true or other inline options', () {
      expect(secureStorageOffenders('a.dart', '''
const s = FlutterSecureStorage(aOptions: AndroidOptions());
'''), hasLength(1));
    });

    test('passes the shared options, including across lines', () {
      expect(secureStorageOffenders('a.dart', '''
const s = FlutterSecureStorage(aOptions: kSecureStorageAndroidOptions);
const t =
    FlutterSecureStorage(
        aOptions: kSecureStorageAndroidOptions);
'''), isEmpty);
    });

    test('ignores comments, types and static members', () {
      expect(secureStorageOffenders('a.dart', '''
/// constructs `const FlutterSecureStorage()` in production.
// FlutterSecureStorage() here is prose.
final FlutterSecureStorage? storage;
FlutterSecureStorage.setMockInitialValues({});
'''), isEmpty);
    });
  });
}

/// The `FlutterSecureStorage(` constructions in [source] that do not pass
/// the shared options, as `path:line` strings.
List<String> secureStorageOffenders(String path, String source) {
  final lines = source.split('\n');
  final code = [
    for (final line in lines)
      // Drop `//` comments (doc and plain) — prose may name the class.
      line.contains('//') ? line.substring(0, line.indexOf('//')) : line,
  ].join('\n');
  final offenders = <String>[];
  for (final match in RegExp(r'\bFlutterSecureStorage\s*\(').allMatches(code)) {
    var depth = 1;
    var i = match.end;
    while (i < code.length && depth > 0) {
      final ch = code[i];
      if (ch == '(') depth++;
      if (ch == ')') depth--;
      i++;
    }
    final args = code.substring(match.end, i - 1);
    if (!RegExp(r'\baOptions\s*:\s*kSecureStorageAndroidOptions\b')
        .hasMatch(args)) {
      final line = '\n'.allMatches(code.substring(0, match.start)).length + 1;
      offenders.add('$path:$line');
    }
  }
  return offenders;
}
