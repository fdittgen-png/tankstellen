// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4369 — the self-hosted F-Droid publish workflow built WITHOUT
// `FDROID_LIBRE=true` while scripts/fdroid_publish.sh and the fdroiddata
// recipe passed it. Dart ignores a define nobody passes just as silently as
// one nobody reads, so the self-hosted APK kept the developer tile proxy and
// the bundled TankSync defaults with every pipeline green.
//
// The fix routes every F-Droid build through ONE define list,
// tool/fdroid_dart_defines.json. This guard scans every Flutter build
// command under .github/workflows/ and scripts/ and requires each F-Droid
// build to resolve FDROID_LIBRE to "true" — from that file or an inline
// define — with an inline define winning over the file, as Flutter applies
// them.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The shared define list every F-Droid build reads.
const _definesFile = 'tool/fdroid_dart_defines.json';

/// Logical shell commands in [source]: comment lines dropped and
/// backslash-newline continuations joined, so a flag on a continuation line
/// belongs to its command.
List<String> _logicalCommands(String source) => source
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('#'))
    .join('\n')
    .replaceAll(RegExp(r'\\\n\s*'), ' ')
    .split('\n');

/// Violations for the build commands in [source] (a workflow or script at
/// [path]). [readDefines] resolves a `--dart-define-from-file` path to its
/// entries, or null when the file is missing or unreadable.
List<String> fdroidBuildViolations(
  String path,
  String source,
  Map<String, String>? Function(String definesPath) readDefines,
) {
  final violations = <String>[];
  for (final command in _logicalCommands(source)) {
    if (RegExp(r'\b(assemble|bundle)Fdroid').hasMatch(command)) {
      violations.add('$path: a Gradle F-Droid build bypasses the Flutter '
          'define list — build through `flutter build --flavor fdroid`: '
          '${command.trim()}');
      continue;
    }
    // At command position only — a message that QUOTES a build command
    // (`echo "Did 'flutter build apk' run?"`) builds nothing.
    if (!RegExp(r'(?:^|&&|\|\||;|\(|run:)\s*flutter build (apk|appbundle)\b')
        .hasMatch(command.trim())) {
      continue;
    }
    final flavor =
        RegExp(r'--flavor[= ]"?([A-Za-z0-9_]+)').firstMatch(command)?.group(1);
    if (flavor == null) {
      violations.add('$path: a build names no --flavor, so it cannot be '
          'classified: ${command.trim()}');
      continue;
    }
    if (flavor != 'fdroid') continue;

    final defines = <String, String>{};
    for (final m in RegExp(r'--dart-define-from-file[= ]"?([^"\s]+)"?')
        .allMatches(command)) {
      final file = m.group(1)!;
      final entries = readDefines(file);
      if (entries == null) {
        violations.add('$path: define file $file is missing or not a JSON '
            'object');
        continue;
      }
      defines.addAll(entries);
    }
    // Flutter: "Entries from --dart-define with identical keys take
    // precedence over entries from these files."
    for (final m in RegExp(r'--dart-define[= ]"?([A-Za-z0-9_]+)=([^"\s]*)"?')
        .allMatches(command)) {
      defines[m.group(1)!] = m.group(2)!;
    }
    if (defines['FDROID_LIBRE'] != 'true') {
      violations.add('$path: F-Droid build resolves FDROID_LIBRE to '
          '${defines['FDROID_LIBRE'] ?? 'nothing'}, so it ships the '
          'developer-hosted defaults: ${command.trim()}');
    }
  }
  return violations;
}

/// Reads a JSON define file relative to the repository root.
Map<String, String>? _readRepoDefines(String definesPath) {
  final file = File(definesPath);
  if (!file.existsSync()) return null;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) return null;
    return decoded.map((k, v) => MapEntry('$k', '$v'));
  } on FormatException {
    return null;
  }
}

void main() {
  group('fdroidBuildViolations — the scanner itself (#4369)', () {
    Map<String, String>? fixtureDefines(String p) => switch (p) {
          'libre.json' => {'FDROID_LIBRE': 'true'},
          'nonlibre.json' => {'FGS_FORM_APPROVED': 'true'},
          _ => null,
        };

    List<String> scan(String source) =>
        fdroidBuildViolations('fixture', source, fixtureDefines);

    test('an inline libre define passes', () {
      expect(
          scan('run: flutter build apk --release --flavor fdroid '
              '--dart-define=FDROID_LIBRE=true'),
          isEmpty);
    });

    test('a define file carrying the flag passes', () {
      expect(
          scan('flutter build apk --flavor fdroid '
              '--dart-define-from-file=libre.json'),
          isEmpty);
    });

    test('a define on a continuation line belongs to its command', () {
      expect(
          scan('flutter build apk --release --flavor fdroid \\\n'
              '  --dart-define=FDROID_LIBRE=true\n'),
          isEmpty);
      expect(
          scan('flutter build apk --release --flavor fdroid \\\n'
              '  --dart-define=FGS_FORM_APPROVED=true\n'
              'echo --dart-define=FDROID_LIBRE=true\n'),
          hasLength(1),
          reason: 'a flag on the NEXT command is not this build\'s flag');
    });

    test('a build without the flag is reported — the #4369 shape', () {
      expect(
          scan('run: flutter build apk --release --flavor fdroid '
              '--build-number=1 --dart-define=FORCE_LOCATION_MANAGER=true '
              '--dart-define=FGS_FORM_APPROVED=true'),
          hasLength(1));
      expect(
          scan('flutter build apk --flavor fdroid '
              '--dart-define-from-file=nonlibre.json'),
          hasLength(1));
    });

    test('an inline false overrides a libre file, as Flutter does', () {
      expect(
          scan('flutter build apk --flavor fdroid '
              '--dart-define-from-file=libre.json '
              '--dart-define=FDROID_LIBRE=false'),
          hasLength(1));
    });

    test('a missing define file is reported, not treated as empty', () {
      expect(
          scan('flutter build apk --flavor fdroid '
              '--dart-define-from-file=gone.json'),
          hasLength(2));
    });

    test('commented-out, quoted and play builds are ignored', () {
      expect(scan('# flutter build apk --flavor fdroid'), isEmpty);
      expect(scan('echo "Did \'flutter build apk --release\' run?"'), isEmpty);
      expect(
          scan('(cd "\$ROOT" && flutter build apk --flavor fdroid)'),
          hasLength(1),
          reason: 'a subshell build is still a build');
      expect(scan('flutter build appbundle --release --flavor play'), isEmpty);
    });

    test('flavorless and Gradle F-Droid builds cannot slip past', () {
      expect(scan('flutter build apk --release'), hasLength(1));
      expect(scan('./gradlew assembleFdroidRelease'), hasLength(1));
    });
  });

  group('every F-Droid build in the repo is libre (#4369)', () {
    late Map<String, String> sources;

    setUpAll(() {
      sources = {
        for (final dir in ['.github/workflows', 'scripts'])
          for (final f in Directory(dir).listSync().whereType<File>())
            if (f.path.endsWith('.yml') ||
                f.path.endsWith('.yaml') ||
                f.path.endsWith('.sh'))
              f.path: f.readAsStringSync(),
      };
    });

    test('the shared define list carries FDROID_LIBRE=true', () {
      final defines = _readRepoDefines(_definesFile);
      expect(defines, isNotNull, reason: '$_definesFile must be a JSON map');
      expect(defines!['FDROID_LIBRE'], 'true');
      // The defines the F-Droid builds carried before they moved here.
      expect(defines['FORCE_LOCATION_MANAGER'], 'true');
      expect(defines['FGS_FORM_APPROVED'], 'true');
    });

    test('no F-Droid build under .github/workflows/ or scripts/ ships '
        'without it', () {
      final violations = [
        for (final e in sources.entries)
          ...fdroidBuildViolations(e.key, e.value, _readRepoDefines),
      ];
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('the scan actually sees the F-Droid builds it guards', () {
      // A scanner that matched nothing would pass the test above forever.
      final fdroidBuilders = sources.entries
          .where((e) => _logicalCommands(e.value).any((c) =>
              c.contains('flutter build') && c.contains('--flavor fdroid')))
          .map((e) => e.key.replaceAll(r'\', '/'))
          .toSet();
      expect(
          fdroidBuilders,
          containsAll(<String>[
            '.github/workflows/fdroid-publish.yml',
            '.github/workflows/fdroid.yml',
            'scripts/fdroid_publish.sh',
          ]));
    });

    test('the publish workflow and script read the SAME define file', () {
      for (final path in [
        '.github/workflows/fdroid-publish.yml',
        'scripts/fdroid_publish.sh',
      ]) {
        expect(sources[path], contains('--dart-define-from-file=$_definesFile'),
            reason: '$path must share the one define list');
      }
    });
  });
}
