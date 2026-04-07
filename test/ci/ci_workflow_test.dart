import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
      expect(ciYaml, contains('flutter test --coverage'));
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

    test('contains build-android job gated on analyze and test', () {
      expect(ciYaml, contains('build-android:'));
      expect(ciYaml, contains('needs: [analyze, test]'));
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
}
