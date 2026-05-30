// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Returns the body of the named top-level job in [workflowYaml] — the
/// lines from the `<jobName>:` header (indented exactly two spaces) up to
/// but not including the next two-space-indented `<name>:` job header.
///
/// A deliberately simple line scanner rather than a YAML parser: it keeps
/// the test dependency-free and the GitHub-Actions job grammar is regular
/// enough (every top-level job is a key indented exactly two spaces) for a
/// scan to be unambiguous.
String _jobBody(String workflowYaml, String jobName) {
  final lines = workflowYaml.split('\n');
  final header = RegExp('^  $jobName:\\s*\$');
  final anyJobHeader = RegExp(r'^  [A-Za-z0-9_-]+:\s*$');
  final buffer = StringBuffer();
  var inJob = false;
  for (final line in lines) {
    if (inJob) {
      // A new two-space-indented `name:` line ends the current job.
      if (anyJobHeader.hasMatch(line)) break;
      buffer.writeln(line);
      continue;
    }
    if (header.hasMatch(line)) {
      inJob = true;
    }
  }
  return buffer.toString();
}

/// Tests that verify the CI workflow file contains expected jobs and steps.
void main() {
  late String ciYaml;

  setUpAll(() {
    final file = File('.github/workflows/ci.yml');
    expect(file.existsSync(), isTrue, reason: 'CI workflow file must exist');
    ciYaml = file.readAsStringSync();
  });

  group('CI workflow structure', () {
    test('contains analyze job', () {
      expect(ciYaml, contains('analyze:'));
      expect(ciYaml, contains('flutter analyze'));
    });

    test('contains test job with coverage', () {
      expect(ciYaml, contains('test:'));
      // #1581 — test job is now a 4-way shard matrix; the
      // `flutter test --coverage ... --total-shards=4` invocation
      // spans multiple lines inside a YAML `run: |` block, so the
      // literal substring check became multi-token. Assert the
      // distinctive pieces individually.
      expect(ciYaml, contains('flutter test'));
      expect(ciYaml, contains('--coverage'));
      expect(ciYaml, contains('--total-shards=4'));
      // Coverage threshold enforcement moved into the downstream
      // `coverage-merge` job (still in this workflow).
      expect(ciYaml, contains('Check coverage threshold'));
    });

    test('contains security-scan job with OSV scanner', () {
      expect(ciYaml, contains('security-scan:'));
      expect(ciYaml, contains('osv-scanner'));
    });

    test('contains license-audit job', () {
      expect(ciYaml, contains('license-audit:'));
      expect(ciYaml, contains('Audit dependency licenses'));
      expect(ciYaml, contains('scripts/license_audit.sh'));
    });

    test('contains dependency-check job', () {
      expect(ciYaml, contains('dependency-check:'));
      expect(ciYaml, contains('Check outdated dependencies and advisories'));
      expect(ciYaml, contains('scripts/pub_outdated_check.sh'));
    });

    test('contains build-android job gated on analyze only', () {
      expect(ciYaml, contains('build-android:'));
      // #1580 — `test` removed from build-android's needs so it runs
      // in parallel with the (sharded, slow) test job. `analyze`
      // stays as a fast pre-gate against build-on-broken-syntax.
      expect(ciYaml, contains('needs: [analyze]'));
    });

    test('contains release job gated on build-android', () {
      expect(ciYaml, contains('release:'));
      expect(ciYaml, contains('needs: [build-android]'));
    });

    test('runs on PRs to master and pushes to master', () {
      expect(ciYaml, contains('push:'));
      expect(ciYaml, contains('pull_request:'));
      expect(ciYaml, contains('branches: [master]'));
    });

    test('has concurrency group to cancel redundant runs', () {
      expect(ciYaml, contains('concurrency:'));
      expect(ciYaml, contains('cancel-in-progress: true'));
    });
  });

  group('CI scripts exist', () {
    test('license_audit.sh exists and is non-empty', () {
      final script = File('scripts/license_audit.sh');
      expect(script.existsSync(), isTrue,
          reason: 'License audit script must exist');
      expect(script.readAsStringSync().length, greaterThan(100));
    });

    test('pub_outdated_check.sh exists and is non-empty', () {
      final script = File('scripts/pub_outdated_check.sh');
      expect(script.existsSync(), isTrue,
          reason: 'Pub outdated check script must exist');
      expect(script.readAsStringSync().length, greaterThan(100));
    });
  });

  group('License audit script content', () {
    late String licenseScript;

    setUpAll(() {
      licenseScript = File('scripts/license_audit.sh').readAsStringSync();
    });

    test('checks for forbidden GPL patterns', () {
      expect(licenseScript, contains('GNU General Public License'));
      expect(licenseScript, contains('GPL-2'));
      expect(licenseScript, contains('GPL-3'));
      expect(licenseScript, contains('GNU Affero'));
      expect(licenseScript, contains('SSPL'));
    });

    test('allows MIT, BSD, Apache, MPL, ISC, Unlicense licenses', () {
      expect(licenseScript, contains('MIT'));
      expect(licenseScript, contains('BSD'));
      expect(licenseScript, contains('Apache'));
      expect(licenseScript, contains('MPL-2.0'));
      expect(licenseScript, contains('ISC'));
      expect(licenseScript, contains('Unlicense'));
    });

    test('checks allowed licenses before forbidden to avoid false positives',
        () {
      // MPL-2.0 mentions GPL in its compatibility section, so allowed
      // must be checked first
      expect(licenseScript, contains('classify_license'));
      expect(licenseScript, contains('Mozilla Public License'));
    });

    test('supports --report flag for generating license inventory', () {
      expect(licenseScript, contains('--report'));
      expect(licenseScript, contains('DEPENDENCY_LICENSES.md'));
    });

    test('uses dart pub deps for dependency listing', () {
      expect(licenseScript, contains('dart pub deps'));
    });

    test('returns non-zero exit code on forbidden licenses', () {
      expect(licenseScript, contains('EXIT_CODE=1'));
      expect(licenseScript, contains(r'exit $EXIT_CODE'));
    });
  });

  group('Pub outdated check script content', () {
    late String outdatedScript;

    setUpAll(() {
      outdatedScript = File('scripts/pub_outdated_check.sh').readAsStringSync();
    });

    test('runs flutter pub outdated', () {
      expect(outdatedScript, contains('flutter pub outdated'));
    });

    test('uses JSON output for machine-readable analysis', () {
      expect(outdatedScript, contains('dart pub outdated --json'));
    });

    test('checks for security advisories', () {
      expect(outdatedScript, contains('advisories'));
      expect(outdatedScript, contains('SECURITY_ISSUES_FOUND'));
    });

    test('checks for discontinued packages', () {
      expect(outdatedScript, contains('isDiscontinued'));
      expect(outdatedScript, contains('Discontinued'));
    });

    test('fails on security issues', () {
      expect(outdatedScript, contains('EXIT_CODE=1'));
    });

    test('reports major version lag as informational', () {
      expect(outdatedScript, contains('Major version updates available'));
    });
  });

  // #2334 — the codegen-drift job must NOT cache `.dart_tool`. Caching
  // it keyed on pubspec.lock alone lets two PRs with the same lockfile
  // share build_runner's incremental asset graph, so a stale `.g.dart`
  // re-emits and the diff check passes against identically-stale
  // committed files (the #2322 / #2245 poisoning vector).
  group('codegen-drift stale-hash hardening (#2334)', () {
    late String codegenJob;

    setUpAll(() {
      codegenJob = _jobBody(ciYaml, 'codegen-drift');
      expect(codegenJob, isNotEmpty,
          reason: 'codegen-drift job must exist in ci.yml');
    });

    test('codegen-drift job does NOT cache .dart_tool', () {
      // Ignore comment lines — the rationale comment mentions `.dart_tool`
      // in prose; what matters is no executable `path:` entry restores it.
      final executable = codegenJob
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('#'))
          .join('\n');
      expect(executable.contains('.dart_tool'), isFalse,
          reason: 'codegen-drift must start from a fresh .dart_tool so '
              'build_runner regenerates honestly — see #2334.');
    });

    test('codegen-drift still caches ~/.pub-cache and regenerates', () {
      expect(codegenJob, contains('~/.pub-cache'));
      expect(codegenJob,
          contains('dart run build_runner build --delete-conflicting-outputs'));
    });
  });

  // #2347 — both nightlies must pin the same Flutter version as ci.yml,
  // so a floating stable-channel bump can't silently change the nightly
  // SDK and spam the tracking issues with spurious red.
  group('nightly Flutter version pin (#2347)', () {
    // Single source of truth: whatever ci.yml pins, the nightlies match.
    late String pinnedVersion;

    setUpAll(() {
      final match =
          RegExp(r'''flutter-version:\s*["']([\d.]+)["']''').firstMatch(ciYaml);
      expect(match, isNotNull,
          reason: 'ci.yml must pin a flutter-version');
      pinnedVersion = match!.group(1)!;
    });

    test('nightly-full pins the same flutter-version as ci.yml', () {
      final yaml = File('.github/workflows/nightly-full.yml').readAsStringSync();
      expect(yaml, contains('flutter-version: "$pinnedVersion"'));
    });

    test('nightly-flaky pins the same flutter-version as ci.yml', () {
      final yaml =
          File('.github/workflows/nightly-flaky.yml').readAsStringSync();
      expect(yaml, contains('flutter-version: "$pinnedVersion"'));
    });
  });
}
