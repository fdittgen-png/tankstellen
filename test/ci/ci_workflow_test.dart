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

  // #2336 — fast l10n gate exists in ci.yml and is stubbed for docs PRs.
  group('l10n-gate job (#2336)', () {
    late String l10nJob;

    setUpAll(() {
      l10nJob = _jobBody(ciYaml, 'l10n-gate');
      expect(l10nJob, isNotEmpty, reason: 'l10n-gate job must exist in ci.yml');
    });

    test('runs the ARB rebuild trio', () {
      expect(l10nJob, contains('dart tool/build_arb.dart'));
      expect(l10nJob, contains('dart tool/gen_pseudo_arb.dart'));
      expect(l10nJob, contains('flutter gen-l10n'));
    });

    test('diffs lib/l10n and runs the l10n + lint buckets', () {
      expect(l10nJob, contains('git diff --exit-code -- lib/l10n/'));
      expect(l10nJob,
          contains('flutter test test/l10n/ test/lint/ --exclude-tags=network'));
    });

    test('does NOT run Android or build_runner (kept fast)', () {
      expect(l10nJob.contains('build_runner'), isFalse);
      expect(l10nJob.contains('setup-java'), isFalse);
      expect(l10nJob.contains('flutter build'), isFalse);
    });

    test('has a matching pass-through stub in ci-docs-stub.yml', () {
      final stub = File('.github/workflows/ci-docs-stub.yml').readAsStringSync();
      expect(_jobBody(stub, 'l10n-gate'), isNotEmpty,
          reason: 'docs-only PRs need an l10n-gate stub — ci.yml is '
              'path-ignored on them.');
    });
  });

  // #2333 / docs-PR safety — ci.yml is path-ignored on docs-only PRs, so
  // the ONLY workflow that runs is ci-docs-stub.yml. Every context that
  // is (or will be) a required status check must therefore have a stub
  // job there whose name matches the context EXACTLY, or the docs PR
  // sits BLOCKED forever.
  group('ci-docs-stub covers every required check (#2333)', () {
    late String stubYaml;

    // The target required_status_checks set after the post-merge API
    // change: build-android / integration / startup-budget / l10n-gate
    // become required, the phantom coverage-merge is dropped. Matrix
    // jobs (`test (0)..test (3)`) are covered by the `test` job header.
    const requiredJobNames = <String>[
      'analyze',
      'test',
      'codegen-drift',
      'l10n-gate',
      'build-android',
      'integration',
      'startup-budget',
    ];

    setUpAll(() {
      final file = File('.github/workflows/ci-docs-stub.yml');
      expect(file.existsSync(), isTrue,
          reason: 'docs-stub workflow must exist');
      stubYaml = file.readAsStringSync();
    });

    test('declares a stub job for every required check name', () {
      for (final job in requiredJobNames) {
        expect(_jobBody(stubYaml, job), isNotEmpty,
            reason: 'ci-docs-stub.yml must declare a `$job:` stub job so '
                'the `$job` required context resolves on docs-only PRs.');
      }
    });

    test('the test stub keeps the 4-shard matrix so test (0..3) resolve',
        () {
      final testJob = _jobBody(stubYaml, 'test');
      expect(testJob, contains('shard: [0, 1, 2, 3]'));
    });

    test('triggers only on docs paths (mirrors ci.yml paths-ignore)', () {
      expect(stubYaml, contains("- '**/*.md'"));
      expect(stubYaml, contains("- 'docs/**'"));
    });
  });

  // #2342 — Parses TARGET_CHECKS from scripts/configure_branch_protection.sh
  // and asserts incident-critical checks are present. Removal surfaces in CI
  // before a broken PR can auto-merge. Incidents: #2360, #2361.
  group('required-check-set completeness (#2342, incidents #2360 #2361)', () {
    late List<String> targetChecks;

    setUpAll(() {
      final file = File('scripts/configure_branch_protection.sh');
      expect(file.existsSync(), isTrue,
          reason: 'Branch-protection script must exist');
      final script = file.readAsStringSync();
      expect(script.length, greaterThan(200));
      expect(script, contains('TARGET_CHECKS=('));
      final start = script.indexOf('TARGET_CHECKS=(') + 'TARGET_CHECKS=('.length;
      final end = script.indexOf('\n)', start);
      expect(end, greaterThan(start),
          reason: 'TARGET_CHECKS must be closed with a bare )');
      targetChecks = RegExp(r'"([^"]+)"')
          .allMatches(script.substring(start, end))
          .map((m) => m.group(1)!)
          .toList();
      expect(targetChecks, isNotEmpty);
    });

    // Incident #2360: codegen-drift was non-required → PR #2322 merged RED.
    test('includes codegen-drift (incident #2360)', () {
      expect(targetChecks, contains('codegen-drift'),
          reason: 'see #2360 — stale *.g.dart poisoned master when non-required');
    });

    // Incident #2361: l10n-gate absent → ARB conflict recurred every wave.
    test('includes l10n-gate (incident #2361)', () {
      expect(targetChecks, contains('l10n-gate'),
          reason: 'see #2361 — broken ARB fan-out blocked rebases when absent');
    });

    test('includes core quality gates', () {
      for (final check in ['analyze', 'build-android', 'integration']) {
        expect(targetChecks, contains(check));
      }
    });

    test('includes all 4 test shards', () {
      for (var i = 0; i < 4; i++) {
        expect(targetChecks, contains('test ($i)'));
      }
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

  group('one scheduled tester cut for BOTH stores (#3792)', () {
    // The two store legs used to carry their own crons 11.5 h apart, so
    // Play beta and TestFlight shipped DIFFERENT master commits and no
    // field report could be pinned to one code state. The Release Train is
    // now the single scheduled entry point; these tests fail the moment a
    // per-leg cron creeps back and silently re-splits the tester base.
    String read(String name) =>
        File('.github/workflows/$name').readAsStringSync();

    /// True when the workflow declares its own `schedule:` trigger. Scans
    /// only the `on:` block — a `schedule` word inside a comment or a job
    /// body must not count.
    bool hasOwnCron(String yaml) {
      final lines = yaml.split('\n');
      var inOn = false;
      for (final line in lines) {
        if (RegExp(r'^on:\s*$').hasMatch(line)) {
          inOn = true;
          continue;
        }
        if (inOn) {
          // A new top-level key (unindented, not a comment) ends `on:`.
          if (RegExp(r'^[A-Za-z]').hasMatch(line)) break;
          if (RegExp(r'^  schedule:\s*$').hasMatch(line)) return true;
        }
      }
      return false;
    }

    test('release-train owns the only cron, at the Play-beta hour', () {
      final yaml = read('release-train.yml');
      expect(hasOwnCron(yaml), isTrue,
          reason: 'the train must carry the nightly schedule');
      expect(yaml, contains("- cron: '0 16 * * *'"));
    });

    test('neither store leg keeps its own cron', () {
      for (final leg in ['daily-beta.yml', 'ios-testflight.yml']) {
        expect(hasOwnCron(read(leg)), isFalse,
            reason: '$leg must NOT schedule itself — a second cron cuts a '
                'different commit than the train and re-splits Android vs '
                'iOS testers (and double-uploads to Play)');
      }
    });

    test('both store legs stay callable + manually dispatchable', () {
      for (final leg in ['daily-beta.yml', 'ios-testflight.yml']) {
        final yaml = read(leg);
        expect(yaml, contains('workflow_call:'),
            reason: '$leg must stay callable by the train');
        expect(yaml, contains('workflow_dispatch:'),
            reason: '$leg must stay dispatchable for single-store hotfixes');
      }
    });

    test('the train ships BOTH stores on the beta channel, from one commit',
        () {
      final yaml = read('release-train.yml');
      for (final leg in ['android-beta', 'ios-testflight']) {
        expect(_jobBody(yaml, leg), contains("(inputs.channel || 'beta')"),
            reason: 'a `schedule` event carries NO inputs, so a bare '
                '`inputs.channel == ...` guard skips the leg and the '
                'nightly train would silently ship nothing');
      }
      expect(_jobBody(yaml, 'ios-testflight'), contains('distribute: true'),
          reason: 'the nightly iOS build must reach the external testers');
    });
  });

  group('fdroid lockfile regen (#3806)', () {
    String read(String n) =>
        File('.github/workflows/$n').readAsStringSync();

    /// The workflow's `on:` block only — the file's own rationale comment
    /// names the trigger it deliberately avoids, and a whole-file match
    /// would read that prose as a declaration.
    String triggerBlock(String yaml) {
      final out = StringBuffer();
      var inOn = false;
      for (final line in yaml.split('\n')) {
        if (RegExp(r'^on:\s*$').hasMatch(line)) {
          inOn = true;
          continue;
        }
        if (inOn) {
          if (RegExp(r'^[A-Za-z]').hasMatch(line)) break;
          out.writeln(line);
        }
      }
      return out.toString();
    }

    test('the regen workflow is dispatch-only — never pull_request_target',
        () {
      final triggers = triggerBlock(read('fdroid-lock-regen.yml'));
      expect(triggers, contains('workflow_dispatch:'));
      expect(triggers, isNot(contains('pull_request_target')),
          reason: 'that trigger would run `pub get` — and therefore '
              'arbitrary package build hooks — from an untrusted branch '
              'with a write-scoped token');
      expect(triggers, isNot(contains('pull_request:')),
          reason: 'a Dependabot PR token is read-only — it could not push');
    });

    test('it pins the SAME Flutter as ci.yml — a lock resolved by another '
        'SDK is not the one F-Droid reproduces', () {
      final pin = RegExp('flutter-version:\\s*"([0-9.]+)"')
          .firstMatch(read('ci.yml'))!
          .group(1)!;
      expect(read('fdroid-lock-regen.yml'),
          contains('flutter-version: "$pin"'));
    });

    test('it verifies with the very step that fails in build-fdroid', () {
      expect(read('fdroid-lock-regen.yml'),
          contains('flutter pub get --enforce-lockfile'),
          reason: 'regenerating without re-checking would let a bad lock '
              'through and the PR would still be red');
    });

    test('build-fdroid names the fix when the lock is stale', () {
      final yaml = read('fdroid.yml');
      expect(yaml, contains('Regenerate fdroid lockfile'),
          reason: 'the failure must point at the dispatch instead of '
              'making the next person rediscover the cause');
      expect(yaml, contains('#3806'));
    });
  });

  group('the App Store version state is checkable, not guessed (#3851)', () {
    test('the status lane exists and stays read-only', () {
      final fastfile = File('ios/fastlane/Fastfile').readAsStringSync();
      expect(fastfile, contains('lane :app_store_status'));
      // A report that can mutate is not a report. Anything that creates a
      // version, selects a build or submits belongs in the deliver path,
      // behind the #3849 demo-video guard — never in a status check the
      // maintainer runs casually to answer a question.
      final lane = fastfile.substring(fastfile.indexOf('lane :app_store_status'));
      final body = lane.substring(0, lane.indexOf('\n  lane :'));
      // Strip comments and string literals before looking for mutating
      // calls: the lane's own guidance text says "submit" and "submitting"
      // a lot, and matching prose would make this test about wording
      // rather than about behaviour.
      final code = body
          .split('\n')
          .map((l) => l.replaceFirst(RegExp(r'#.*$'), ''))
          .join('\n')
          .replaceAll(RegExp(r'"[^"]*"'), '""')
          .replaceAll(RegExp(r"'[^']*'"), "''");
      for (final call in [
        'Spaceship::ConnectAPI.post',
        'Spaceship::ConnectAPI.patch',
        'Spaceship::ConnectAPI.delete',
        '.create',
        '.save!',
        'upload_to_app_store',
        'deliver(',
        'pilot(',
      ]) {
        expect(code, isNot(contains(call)),
            reason: 'app_store_status called $call — a report that can '
                'mutate is not a report; anything that creates a version, '
                'selects a build or submits belongs in the deliver path '
                'behind the #3849 demo-video guard');
      }
    });

    test('it names whether an editable version exists, not just a table', () {
      final fastfile = File('ios/fastlane/Fastfile').readAsStringSync();
      expect(fastfile, contains('EDITABLE_APP_STORE_STATES'),
          reason: 'the editable set must be declared once, not re-guessed '
              'at each call site');
      expect(fastfile, contains('PREPARE_FOR_SUBMISSION'),
          reason: 'that is the state deliver --submit_for_review requires');
      expect(fastfile, contains('NO editable version'),
          reason: 'the whole point is a verdict line — a version table '
              'leaves the reader to infer the answer, which is how the '
              'question went unanswered in the first place');
    });

    test('the workflow is dispatch-only and needs no macOS runner', () {
      final yaml =
          File('.github/workflows/app-store-status.yml').readAsStringSync();
      expect(yaml, contains('workflow_dispatch'));
      expect(yaml, isNot(contains('schedule:')),
          reason: 'a status report on a timer is noise nobody reads');
      expect(yaml, contains('runs-on: ubuntu-latest'),
          reason: 'API-only — a macOS runner would cost minutes for '
              'nothing (the ios-testflight-status.yml precedent)');
      expect(yaml, contains('rm -f'),
          reason: 'the decoded ASC key must be cleaned up');
    });
  });

  group('an App Store submission carries the demo video (#3849, #3537)', () {
    String readWorkflow(String n) =>
        File('.github/workflows/$n').readAsStringSync();

    test('review notes exist as committed metadata deliver can find', () {
      // Without this directory `deliver` submits with NO review notes at
      // all, so the demo-video link cannot reach App Review however the
      // secret is set — a guaranteed repeat of the 6.0.0 guideline 2.1
      // rejection.
      final notes =
          File('ios/fastlane/metadata/review_information/notes.txt');
      expect(notes.existsSync(), isTrue,
          reason: 'deliver reads App Store review notes from '
              'metadata/review_information/, NOT from the Fastfile '
              'beta_review_notes that feeds TestFlight');
      final text = notes.readAsStringSync();
      expect(text, contains('anonymous auth'),
          reason: 'App Review must be told no sign-in is needed, or they '
              'ask for demo credentials that do not exist');
      expect(text.toLowerCase(), contains('background'),
          reason: 'the background location / Bluetooth justification is '
              'what guideline 2.1 turned on');
      // The link itself is a secret and must never be committed.
      expect(text, isNot(contains('http')),
          reason: 'the demo-video URL belongs in the DEMO_VIDEO_URL '
              'secret, appended at run time — never in git');
    });

    test('submitting without a demo video is refused, not attempted', () {
      final yaml = readWorkflow('app-store-listing.yml');
      expect(yaml, contains('DEMO_VIDEO_URL'),
          reason: 'Apple: "updated demo videos will need to be provided '
              'for EVERY app submission"');
      expect(yaml, contains('secret is empty'),
          reason: 'a submit with no video is a known repeatable rejection '
              '— it must fail the run, not ship');
      // The refusal has to happen BEFORE deliver runs, or the submission
      // is already away by the time anyone reads the error.
      // Anchor on the STEP declarations — 'fastlane deliver' also appears
      // in the file header comment, which would make this pass on order
      // that does not exist.
      final guardStep = yaml.indexOf('- name: Compose App Review notes');
      final deliverStep = yaml.indexOf('- name: fastlane deliver');
      expect(guardStep, greaterThan(-1));
      expect(deliverStep, greaterThan(-1));
      expect(guardStep, lessThan(deliverStep),
          reason: 'the guard must precede the submission it guards');
    });

    test('a submission names the build it means', () {
      final yaml = readWorkflow('app-store-listing.yml');
      expect(yaml, contains('--app_version'),
          reason: 'otherwise deliver acts on whatever version ASC has '
              'open');
      expect(yaml, contains('--build_number'),
          reason: 'otherwise the submitted build is whatever happened to '
              'be selected in the console');
    });

    test('release notes exist for every shipped App Store locale', () {
      final locales = Directory('ios/fastlane/metadata')
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path.split(Platform.pathSeparator).last)
          .where((n) => n != 'review_information')
          .toList()
        ..sort();
      expect(locales, isNotEmpty);
      for (final loc in locales) {
        final f = File('ios/fastlane/metadata/$loc/release_notes.txt');
        expect(f.existsSync(), isTrue, reason: '$loc has no release notes');
        final text = f.readAsStringSync().trim();
        expect(text, isNotEmpty, reason: '$loc release notes are empty');
        // App Store hard limit.
        expect(text.length, lessThanOrEqualTo(4000),
            reason: '$loc release notes exceed the App Store limit');
      }
    });
  });

  group('TestFlight delivery is asserted, not assumed (#3814)', () {
    String read(String n) =>
        File('.github/workflows/$n').readAsStringSync();

    test('an externally-distributing iOS build asserts testers can install',
        () {
      final yaml = read('ios-testflight.yml');
      expect(yaml, contains('testflight_assert_delivery'),
          reason: 'pilot\'s "Successfully distributed build to External '
              'testers" means SUBMITTED, not DELIVERED — taking it as '
              'proof left the extern group on a 2026-07-04 build for '
              'seven weeks with every run green');
      // The assert needs the decoded key, so it must come BEFORE the
      // cleanup step or it can only ever fail on auth.
      expect(yaml.indexOf('testflight_assert_delivery'),
          lessThan(yaml.indexOf('Clean up decoded API key')),
          reason: 'the assert must run while the ASC key still exists');
    });

    test('a historical stranding backlog cannot pin the train red (#3823)',
        () {
      final fastfile = File('ios/fastlane/Fastfile').readAsStringSync();
      // The guard's first live run found ELEVEN historical orphans and
      // failed the release train on them. Real, but unfixable in
      // retrospect — and a permanently red train is exactly as ignorable
      // as the green log line this guard replaced.
      expect(fastfile, contains('fresh_stranded'),
          reason: 'the stranding check must be scoped to the freshness '
              'window so only a NEW stranding fails the run');
      expect(fastfile, contains('old_stranded'),
          reason: 'older orphans must still be reported, just not fatal');
      final failIndex = fastfile.indexOf('never submitted for external review');
      expect(fastfile.substring(0, failIndex), contains('partition'),
          reason: 'the fatal branch must consume the partitioned fresh '
              'set, not the whole history');
    });

    test('the assert lane exists and fails loudly rather than warning', () {
      final fastfile = File('ios/fastlane/Fastfile').readAsStringSync();
      expect(fastfile, contains('lane :testflight_assert_delivery'));
      expect(fastfile, contains('UI.user_error!'),
          reason: 'a warning would have been ignored for seven weeks just '
              'as effectively as no check at all');
      expect(fastfile, contains('READY_FOR_BETA_SUBMISSION'),
          reason: 'build 2026061211 stranded in exactly that state while '
              'its ~30 neighbours were approved');
      expect(fastfile, contains('require "time"'),
          reason: 'without it Time.parse raises, the rescue swallows it, '
              'and the staleness check silently stops running');
    });
  });

  group('build numbers — the #3513 shared wall-clock scheme (#3812)', () {
    String read(String n) =>
        File('.github/workflows/$n').readAsStringSync();

    // The formula both release-build workflows must share, character for
    // character: minutes since 2025-07-06 UTC on a 2026100000 base.
    const formula =
        r'BN=$(( 2026100000 + ( $(date -u +%s) - 1751760000 ) / 60 ))';

    for (final wf in ['daily-beta.yml', 'ios-testflight.yml']) {
      test('$wf derives its build number from wall clock, not a run '
          'counter', () {
        final yaml = read(wf);
        expect(yaml, contains(formula),
            reason: 'per-workflow counters leapfrog each other (#3513); '
                'wall clock is the one source that cannot');
        expect(yaml, isNot(contains(r'github.run_number }} * 10')),
            reason: 'the old counter scheme — and under `workflow_call` '
                '`run_number` is the CALLER\'s, which is exactly how '
                '#3792 walked the iOS build number BACKWARDS (#3812)');
      });
    }

    test('a workflow_call-ed leg never reads github.run_number for a '
        'build number', () {
      // release-train calls both legs, so either one reading its "own"
      // counter is really reading the train's.
      final train = read('release-train.yml');
      for (final wf in ['daily-beta.yml', 'ios-testflight.yml']) {
        expect(train, contains('uses: ./.github/workflows/$wf'),
            reason: 'the train is expected to call $wf');
      }
      for (final wf in ['daily-beta.yml', 'ios-testflight.yml']) {
        final bnLines = read(wf)
            .split('\n')
            .where((l) => l.contains('BN=') && l.contains('run_number'));
        expect(bnLines, isEmpty,
            reason: '$wf must not compute a build number from a run '
                'counter it does not own');
      }
    });
  });
}
