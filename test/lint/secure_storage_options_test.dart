// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/secure_storage_options.dart';

/// Static-scan guard (#4373, #4357): every `FlutterSecureStorage(`
/// constructed in `lib/` passes BOTH
/// `aOptions: kSecureStorageAndroidOptions` and
/// `iOptions: kSecureStorageIosOptions`.
///
/// **Why the Android half (#4373):** the plugin's Android default is
/// `resetOnError: true`, which answers a transient KeyStore read error
/// by deleting stored secrets — the Hive encryption key among them,
/// which makes every encrypted box unreadable forever. All instances
/// share one preferences file, so ONE construction left on the default
/// endangers every secret.
///
/// **Why the iOS half (#4357):** the plugin's iOS default is
/// `kSecAttrAccessibleWhenUnlocked`, which a background recorder on a
/// locked phone cannot read at all — a trip recorded with the screen
/// off loses the key to its own storage. The shared constant moves the
/// items to `afterFirstUnlockThisDeviceOnly`, and the `ThisDeviceOnly`
/// half keeps the key out of backups and device transfers, which is
/// what stops a key and a box file from ever meeting on a device where
/// they do not match (#4118 — a wrong key TRUNCATES the box).
///
/// Both halves are the same kind of guarantee, so both are enforced the
/// same way. No grandfathered set: the count is zero and stays zero.
///
/// The scan skips `//` comments and reads the whole argument list, so a
/// wrapped constructor call is judged like a one-line one.
void main() {
  test('the shared options never let the plugin delete on error', () {
    expect(kSecureStorageAndroidOptions.toMap()['resetOnError'], 'false');
  });

  test('the shared iOS options survive a locked screen, but not a backup',
      () {
    expect(kSecureStorageIosOptions.accessibility,
        KeychainAccessibility.first_unlock_this_device,
        reason: 'anything narrower (unlocked / unlocked_this_device) cannot '
            'be read by a background recording; anything wider (first_unlock '
            'without ThisDeviceOnly) lets the key travel in a backup');
    expect(kSecureStorageIosOptions.toMap()['accessibility'],
        'first_unlock_this_device',
        reason: 'the value the plugin actually sends over the channel');
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
            '`FlutterSecureStorage(aOptions: kSecureStorageAndroidOptions, '
            'iOptions: kSecureStorageIosOptions)` '
            '(lib/core/storage/secure_storage_options.dart, #4373/#4357):\n'
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

    test('flags the Android options alone — the iOS half is not optional',
        () {
      expect(secureStorageOffenders('a.dart', '''
const s = FlutterSecureStorage(aOptions: kSecureStorageAndroidOptions);
'''), hasLength(1),
          reason: 'this is exactly the pre-#4357 shape; if it passes, the '
              'keychain-accessibility convention is unenforced and will '
              'regress at the next call site');
    });

    test('flags the iOS options alone, and an inline IOSOptions literal', () {
      expect(secureStorageOffenders('a.dart', '''
const s = FlutterSecureStorage(iOptions: kSecureStorageIosOptions);
const t = FlutterSecureStorage(
  aOptions: kSecureStorageAndroidOptions,
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
'''), hasLength(2));
    });

    test('passes both shared options, including across lines', () {
      expect(secureStorageOffenders('a.dart', '''
const s = FlutterSecureStorage(
    aOptions: kSecureStorageAndroidOptions,
    iOptions: kSecureStorageIosOptions);
const t =
    FlutterSecureStorage(
        iOptions: kSecureStorageIosOptions,
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
/// BOTH shared option constants, as `path:line` strings.
List<String> secureStorageOffenders(String path, String source) {
  final lines = source.split('\n');
  final code = [
    for (final line in lines)
      // Drop `//` comments (doc and plain) — prose may name the class.
      line.contains('//') ? line.substring(0, line.indexOf('//')) : line,
  ].join('\n');
  final required = [
    RegExp(r'\baOptions\s*:\s*kSecureStorageAndroidOptions\b'),
    RegExp(r'\biOptions\s*:\s*kSecureStorageIosOptions\b'),
  ];
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
    if (required.every((r) => r.hasMatch(args))) continue;
    final line = '\n'.allMatches(code.substring(0, match.start)).length + 1;
    offenders.add('$path:$line');
  }
  return offenders;
}
