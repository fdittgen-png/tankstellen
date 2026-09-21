// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// The `fastlane supply` command of a `run:` block as one logical line:
/// backslash-newline continuations joined, comment lines dropped.
String _supplyCommand(String run) {
  final logical = run
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('#'))
      .join('\n')
      .replaceAll(RegExp(r'\\\n\s*'), ' ');
  return logical
      .split('\n')
      .firstWhere((l) => l.contains('fastlane supply'), orElse: () => '');
}

/// #4371 — the listing publish failed on every run from 2026-08-26 with
/// "More than one release found in this track. Please specify with the
/// :version_code option". These guards pin the fix: the newest version
/// code on the track is resolved first and handed to `supply`.
void main() {
  late List<YamlMap> steps;

  setUpAll(() {
    final file = File('.github/workflows/play-store-listing.yml');
    expect(file.existsSync(), isTrue);
    final doc = loadYaml(file.readAsStringSync()) as YamlMap;
    final job = (doc['jobs'] as YamlMap)['publish'] as YamlMap;
    steps = (job['steps'] as YamlList).cast<YamlMap>().toList();
  });

  int indexWhere(bool Function(YamlMap s) test) => steps.indexWhere(test);

  int supplyIndex() => indexWhere(
      (s) => _supplyCommand((s['run'] ?? '') as String).isNotEmpty);

  group('play-store-listing selects one release (#4371)', () {
    test('the supply invocation carries --version_code', () {
      final i = supplyIndex();
      expect(i, isNot(-1), reason: 'no step runs `fastlane supply`');
      final command = _supplyCommand(steps[i]['run'] as String);
      expect(command, contains('--version_code "\$SUPPLY_VERSION_CODE"'),
          reason: 'supply without --version_code aborts once the track '
              'holds more than one release');
    });

    test('the version code comes from the resolver step, not a literal', () {
      final supply = steps[supplyIndex()];
      final env = supply['env'] as YamlMap;
      expect(env['SUPPLY_VERSION_CODE'],
          r'${{ steps.version_code.outputs.version_code }}');
      expect(supply['run'] as String,
          contains(r'if [ -z "${SUPPLY_VERSION_CODE:-}" ]'),
          reason: 'an empty version code must stop the step, not reach '
              'supply as `--version_code ""`');
    });

    test('the resolver runs before supply, under the same dry-run gate', () {
      final resolver = indexWhere((s) => s['id'] == 'version_code');
      final supply = supplyIndex();
      expect(resolver, isNot(-1));
      expect(resolver, lessThan(supply));
      expect(steps[resolver]['if'], steps[supply]['if'],
          reason: 'a dry run skips supply; the resolver needs the key and '
              'bundler, so it must be skipped with it');
    });

    test('it reads the track with google_play_track_version_codes using the '
        'same key, package and track as supply', () {
      final resolver = steps[indexWhere((s) => s['id'] == 'version_code')];
      final supplyEnv = steps[supplyIndex()]['env'] as YamlMap;
      final env = resolver['env'] as YamlMap;
      for (final key in [
        'SUPPLY_JSON_KEY',
        'SUPPLY_PACKAGE_NAME',
        'SUPPLY_TRACK',
      ]) {
        expect(env[key], supplyEnv[key], reason: '$key differs');
      }
      final run = resolver['run'] as String;
      expect(run, contains('GooglePlayTrackVersionCodesAction'));
      // API codes are strings; a lexical max would pick "999" over "5138".
      expect(run, contains('Integer(c.to_s, 10)'));
      expect(run, contains('codes.max'));
    });

    test('an empty track fails loudly instead of publishing', () {
      final resolver = steps[indexWhere((s) => s['id'] == 'version_code')];
      final run = resolver['run'] as String;
      final emptyBranch =
          RegExp(r'if codes\.empty\?\s*\n\s*puts "::error::.*has no release'
                  r'.*\n\s*exit 1\s*\n\s*end')
              .hasMatch(run);
      expect(emptyBranch, isTrue);
    });
  });
}
