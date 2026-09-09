// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The fdroiddata review checklist, as errors (#4025).
///
/// Every rule below was stated once by a human reviewing MR !42093, or
/// by a CI job rejecting it. A reviewer's attention is the scarcest
/// thing in the submission process, so a rule they have had to state is
/// a rule that belongs in a test — the next violation should fail here,
/// on our machine, before a push.
///
/// Each group names the review that produced it. That matters: without
/// the citation these read as preferences, and the next person to touch
/// the recipe cannot tell which lines are load-bearing.
///
/// Not covered: the reproducible build itself, which needs
/// fdroidserver's buildserver image. That stays verified on GitLab.
void main() {
  final recipe =
      File('metadata/de.tankstellen.fuelprices.yml').readAsStringSync();
  final entries = _buildEntries(recipe);

  group('per-ABI split — linsui asked for the standard gradle scheme', () {
    test('three build entries, one per ABI, sharing versionName and commit',
        () {
      expect(entries, hasLength(3),
          reason: '--split-per-abi ships one APK per ABI; each needs its own '
              'entry with its own versionCode');
      expect(entries.map((e) => e.versionName).toSet(), hasLength(1),
          reason: 'the three ABIs are one release');
      expect(entries.map((e) => e.commit).toSet(), hasLength(1),
          reason: 'the three ABIs must build the SAME source; a split here '
              'would ship three different apps under one version');
      expect(entries.map((e) => e.targetPlatform).toList(),
          ['android-arm', 'android-arm64', 'android-x64'],
          reason: 'hardcoded per block, in ABI order — linsui replaced a '
              '`case` derivation with exactly this');
    });

    test('versionCode is base * 10 + the ABI index', () {
      // #3518 — Play's wall-clock code x10 would overflow int32, so the
      // scheme is flavor-gated in build.gradle.kts. The recipe has to
      // agree with it or F-Droid ships codes the app cannot produce.
      const abiIndex = {'android-arm': 1, 'android-arm64': 2, 'android-x64': 3};
      final bases = <int>{};
      for (final e in entries) {
        expect(e.versionCode % 10, abiIndex[e.targetPlatform],
            reason: '${e.targetPlatform} must end in '
                '${abiIndex[e.targetPlatform]}; got ${e.versionCode}');
        bases.add(e.versionCode ~/ 10);
      }
      expect(bases, hasLength(1),
          reason: 'all three derive from one base versionCode');
    });

    test('the build passes the base code, not the per-ABI one', () {
      for (final e in entries) {
        expect(e.buildCommand, contains(r'--build-number=$(( $$VERCODE$$ / 10 ))'),
            reason: r'the APK must carry the BASE number; passing $$VERCODE$$'
                ' undivided would put the ABI digit in the app version');
      }
    });

    test('VercodeOperation lists one operation per ABI, in the same order',
        () {
      // F-Droid derives the NEXT release's codes from these. If they
      // disagree with the entries above, auto-updates produce codes that
      // collide with a shipped APK or skip a slot.
      final ops = RegExp(r"^  - '(%c \* 10 \+ \d)'$", multiLine: true)
          .allMatches(recipe)
          .map((m) => m.group(1)!)
          .toList();
      expect(ops, ['%c * 10 + 1', '%c * 10 + 2', '%c * 10 + 3'],
          reason: 'one per ABI, in the same order as the build entries');
      expect(ops, hasLength(entries.length),
          reason: 'an operation per build entry, or a future release drops '
              'an ABI');
    });
  });

  group('pin discipline — linsui asked for a full commit hash', () {
    test('every commit is a full 40-hex sha, never a tag or short sha', () {
      for (final e in entries) {
        expect(e.commit, matches(RegExp(r'^[0-9a-f]{40}$')),
            reason: 'a tag can be moved and a short sha can collide; '
                'F-Droid builds what the pin resolves to, so the pin must be '
                'the thing itself. Got: ${e.commit}');
      }
    });

    test('CurrentVersion* match the build entries', () {
      final highest =
          entries.map((e) => e.versionCode).reduce((a, b) => a > b ? a : b);
      expect(_scalar(recipe, 'CurrentVersionCode'), '$highest',
          reason: 'CurrentVersionCode drives the update check; below the '
              'highest build entry it re-offers a version already shipped');
      expect(_scalar(recipe, 'CurrentVersion'), entries.first.versionName);
    });

    test('UpdateCheckMode rejects the beta and nightly tags', () {
      final mode = _scalar(recipe, 'UpdateCheckMode')!;
      expect(mode, startsWith('Tags '));
      final pattern = RegExp(mode.substring('Tags '.length));
      // Asserted against real tag names rather than by reading the
      // regex: these are the tags this repo actually pushes, and
      // admitting one would ship a beta to every F-Droid user.
      expect(pattern.hasMatch('v6.0.5'), isTrue, reason: 'release tags pass');
      for (final beta in [
        'nightly-2026-09-08',
        'v6.0.5+2026704063',
        'beta-6.0.5',
      ]) {
        expect(pattern.hasMatch(beta), isFalse,
            reason: '$beta must not be picked up as a release');
      }
    });
  });

  group('keys F-Droid reads from elsewhere — dropped during review', () {
    test('no subdir / gradle keys', () {
      // The whole-app `flutter build apk --flavor fdroid` needs neither;
      // they were removed in the MR iterations and re-adding one would
      // send the buildserver into android/ instead of the project root.
      for (final key in ['subdir:', 'gradle:']) {
        expect(recipe, isNot(contains('\n    $key')), reason: 'dropped: $key');
      }
    });

    test('no Summary / Description — fastlane/metadata owns them', () {
      for (final key in ['Summary:', 'Description:']) {
        expect(recipe, isNot(contains('\n$key')),
            reason: '$key here would silently diverge from '
                'fastlane/metadata, which is what F-Droid actually renders');
      }
    });
  });

  group('the scan reads the recipe it claims to — fidelity check', () {
    test('build entries parse with their real values', () {
      expect(entries.map((e) => e.versionCode).toList(),
          [51381, 51382, 51383]);
      expect(entries.first.versionName, '6.0.5');
      expect(entries.every((e) => e.buildCommand.contains('--flavor fdroid')),
          isTrue);
    });

    test('a broken entry is actually caught', () {
      // #2348 — if the parser silently found nothing, every assertion
      // above would pass on an empty list.
      const mangled = '''
Builds:
  - versionName: 6.0.5
    versionCode: 51384
    commit: v6.0.5
    build:
      - flutter build apk --flavor fdroid --target-platform android-arm
''';
      final bad = _buildEntries(mangled);
      expect(bad, hasLength(1));
      expect(bad.single.commit, 'v6.0.5',
          reason: 'the tag-instead-of-sha case the pin test rejects');
      expect(bad.single.versionCode % 10, isNot(1),
          reason: 'the ABI-digit mismatch the scheme test rejects');
    });
  });
}

/// One `Builds:` entry, reduced to what the review rules talk about.
class _Entry {
  _Entry({
    required this.versionName,
    required this.versionCode,
    required this.commit,
    required this.buildCommand,
  });

  final String versionName;
  final int versionCode;
  final String commit;
  final String buildCommand;

  /// The single `--target-platform` this entry hardcodes.
  String get targetPlatform =>
      RegExp(r'--target-platform (\S+)').firstMatch(buildCommand)?.group(1) ??
      '<none>';
}

List<_Entry> _buildEntries(String recipe) {
  final out = <_Entry>[];
  // Entries start at `  - versionName:` and run to the next one.
  final starts = RegExp(r'^  - versionName: (\S+)$', multiLine: true)
      .allMatches(recipe)
      .toList();
  for (var i = 0; i < starts.length; i++) {
    final from = starts[i].start;
    final to = i + 1 < starts.length ? starts[i + 1].start : recipe.length;
    final chunk = recipe.substring(from, to);
    final code = RegExp(r'versionCode: (\d+)').firstMatch(chunk);
    final commit = RegExp(r'commit: (\S+)').firstMatch(chunk);
    if (code == null || commit == null) continue;
    // The build: block, unfolded — YAML rejoins its lines with a space.
    final build = RegExp(r'\n    build:\n((?:      .*\n?)*)').firstMatch(chunk);
    out.add(_Entry(
      versionName: starts[i].group(1)!,
      versionCode: int.parse(code.group(1)!),
      commit: commit.group(1)!,
      buildCommand: (build?.group(1) ?? '')
          .split('\n')
          .map((l) => l.trim())
          .join(' '),
    ));
  }
  return out;
}

/// A top-level `Key: value` scalar.
String? _scalar(String recipe, String key) =>
    RegExp('^$key: (.+)\$', multiLine: true).firstMatch(recipe)?.group(1)?.trim();
