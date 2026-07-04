// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression guards for #48 — the Android signing config must:
///
/// 1. Resolve release signing from environment variables first (CI path)
/// 2. Fall back to `android/key.properties` if env vars are missing
///    (legacy local-dev path)
/// 3. **Fail the build** if neither is present, instead of silently
///    dropping to the debug signing key. That silent fallback was the
///    bug that made every master CI release artifact debug-signed
///    without anyone noticing.
///
/// These are source-level invariants (not runtime gradle execution)
/// because spinning up gradle inside the Flutter test harness is
/// impractical. The tests read `android/app/build.gradle.kts` and assert
/// the right structural patterns are present.
void main() {
  late String gradleSource;
  late String ciSource;

  setUpAll(() {
    gradleSource = File('android/app/build.gradle.kts').readAsStringSync();
    ciSource = File('.github/workflows/ci.yml').readAsStringSync();
  });

  group('Android release signing — no silent debug fallback (#48)', () {
    test(
      'build.gradle.kts throws a GradleException when no signing config '
      'can be resolved, instead of falling back to the debug key',
      () {
        // The old bug was an `else` branch that assigned the debug signing
        // config. The fix throws GradleException with a message that names
        // every env var the user needs to set.
        expect(
          gradleSource,
          contains('GradleException'),
          reason: 'release signingConfig must throw GradleException on miss',
        );
        expect(
          gradleSource,
          isNot(contains('signingConfigs.getByName("debug")')),
          reason:
              'build must never route release output through the debug '
              'signing config — that was the original #48 bug',
        );
      },
    );

    test(
      'signing config resolution checks env vars BEFORE the legacy '
      'key.properties file, so CI secrets always win over a stale local file',
      () {
        // The resolveReleaseSigning() helper must read the env var names
        // expected by the CI workflow.
        expect(gradleSource, contains('ANDROID_KEYSTORE_PATH'));
        expect(gradleSource, contains('ANDROID_KEYSTORE_PASSWORD'));
        expect(gradleSource, contains('ANDROID_KEY_ALIAS'));
        // And the env-var branch must appear before the legacy-file branch
        // in source order so the environment wins.
        final envIdx = gradleSource.indexOf('ANDROID_KEYSTORE_PATH');
        final legacyIdx = gradleSource.indexOf('legacyKeystoreProperties');
        expect(envIdx, isNonNegative);
        expect(legacyIdx, isNonNegative);
        expect(
          envIdx,
          lessThan(legacyIdx),
          reason: 'env-var resolution path must precede the legacy file path',
        );
      },
    );

    test(
      'the error message names every env var the user must set so failed '
      'builds self-document the fix',
      () {
        final errorBlock = gradleSource
            .split('GradleException')
            .elementAt(1); // text after the throw keyword
        expect(errorBlock, contains('ANDROID_KEYSTORE_PATH'));
        expect(errorBlock, contains('ANDROID_KEYSTORE_PASSWORD'));
        expect(errorBlock, contains('ANDROID_KEY_ALIAS'));
        expect(errorBlock, contains('key.properties'));
        expect(errorBlock, contains('#48'));
      },
    );
  });

  group('F-Droid flavor builds unsigned without a keystore (#3471)', () {
    test(
      'an fdroid-only release is detected and NOT thrown on — F-Droid '
      'supplies the signature, so the build must proceed unsigned',
      () {
        // The guard scopes the #48 throw to non-fdroid releases. The tell is
        // the fdroid-only detection feeding an `all { it.contains("fdroid") }`
        // check that suppresses the throw for that one path.
        expect(
          gradleSource,
          contains('isFdroidOnlyRelease'),
          reason:
              'the fdroid flavor must be allowed to build an unsigned release '
              'APK for F-Droid to sign — see #3471',
        );
        expect(
          gradleSource,
          contains('releaseTasks.all { it.contains("fdroid") }'),
          reason:
              'the unsigned path must require EVERY requested release task to '
              'be an fdroid task, so a mixed fdroid+play invocation without a '
              'keystore still throws rather than shipping an unsigned Play APK',
        );
        // Belt-and-braces: the throw must still be conditional on a
        // non-fdroid release, never unconditional.
        expect(
          gradleSource,
          contains('if (isReleaseRequested && !isFdroidOnlyRelease)'),
          reason: 'the #48 throw must still fire for every non-fdroid release',
        );
      },
    );

    test(
      'the unsigned fdroid path is NOT a debug-key fallback — the debug '
      'signing config must never be referenced for a release build',
      () {
        // Re-assert the #48 invariant explicitly in the #3471 context: the fix
        // routes fdroid releases through `null` (unsigned), never the debug key.
        expect(
          gradleSource,
          isNot(contains('signingConfigs.getByName("debug")')),
          reason:
              'the fdroid-unsigned path must use a null signing config, not '
              'the debug key — that was the original #48 bug',
        );
      },
    );
  });

  group('CI workflow writes the decoded keystore + env vars (#48)', () {
    test(
      'ci.yml has a "Decode signing keystore" step that reads three '
      'GitHub Secrets and exports env vars before the APK/AAB build',
      () {
        // The step name is the contract — don't rename it without
        // updating this test.
        expect(ciSource, contains('Decode signing keystore'));
        // The three secrets the CI workflow must consume.
        expect(ciSource, contains('secrets.ANDROID_KEYSTORE_BASE64'));
        expect(ciSource, contains('secrets.ANDROID_KEYSTORE_PASSWORD'));
        expect(ciSource, contains('secrets.ANDROID_KEY_ALIAS'));
        // The three env vars gradle reads, written to GITHUB_ENV.
        expect(ciSource, contains('ANDROID_KEYSTORE_PATH='));
        expect(ciSource, contains('ANDROID_KEYSTORE_PASSWORD='));
        expect(ciSource, contains('ANDROID_KEY_ALIAS='));
      },
    );

    test(
      'ci.yml decode step fails FAST with a descriptive error if any of '
      'the three secrets are empty — we do not want silent debug signing',
      () {
        final decodeStep = ciSource
            .split('Decode signing keystore')
            .elementAt(1)
            .split('- name: Build APK')
            .first;
        expect(decodeStep, contains('exit 1'),
            reason: 'missing secret must fail the step');
        expect(decodeStep, contains('#48'),
            reason: 'error message should reference the issue for grep');
      },
    );

    test(
      'ci.yml has a cleanup step that unconditionally removes the decoded '
      'keystore from the runner so it never ends up in an artifact or log',
      () {
        expect(ciSource, contains('Clean up decoded keystore'));
        expect(ciSource, contains('if: always()'));
        expect(ciSource, contains('rm -f "\$RUNNER_TEMP/tankstellen-release.jks"'));
      },
    );
  });
}
