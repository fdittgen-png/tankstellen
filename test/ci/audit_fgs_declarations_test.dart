// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #4352 (Epic #4351) — shell-level test of `scripts/audit_fgs_declarations.sh`
/// against the **checked-in manifest overlays**.
///
/// ## Why this is a real assertion and not ceremony
///
/// `FGS_FORM_APPROVED` is a build define. The repository variable is not set,
/// so the Play artifact ships with **no** foreground service while the F-Droid
/// and dev APKs ship with one: two artifacts from one commit, different
/// background-recording capability. The only checked-in statement of what a
/// capable artifact declares is the `*FgsApproved` overlay — and the Dart side
/// (`RecordingProtectionBuild.supports`) makes a claim about exactly that.
///
/// Running the audit against both overlays needs no emulator, no Gradle and no
/// signing, so it is a genuine CI assertion at unit-test cost. Each positive
/// case is paired with a **negative** one: an audit that cannot fail is not an
/// audit, and pointing expect-exactly at the wrong manifest is the cheapest
/// mutation test there is.
void main() {
  const script = 'scripts/audit_fgs_declarations.sh';

  ProcessResult run(List<String> args) =>
      Process.runSync('bash', [script, ...args]);

  String out(ProcessResult r) => '${r.stdout}${r.stderr}';

  setUpAll(() {
    expect(File(script).existsSync(), isTrue,
        reason: 'the per-artifact FGS audit must exist');
  });

  group('expect-zero — the default Play artifact (#2947 / #1498)', () {
    test('the play source-set overlay declares no foreground service', () {
      final r = run(['--profile', 'play-overlay-default']);
      expect(r.exitCode, 0, reason: out(r));
      expect(out(r), contains('FGS permission(s) declared: (none)'));
      expect(out(r), contains('foreground service(s) declared: (none)'));
    });

    test(
        'the comment-stripper still works — the overlay names '
        'FOREGROUND_SERVICE many times in prose', () {
      final xml =
          File('android/app/src/play/AndroidManifest.xml').readAsStringSync();
      expect(xml, contains('FOREGROUND_SERVICE'),
          reason: 'if the rationale prose ever goes away this test is '
              'vacuous and the stripper is no longer exercised');
      expect(run(['--profile', 'play-overlay-default']).exitCode, 0);
    });

    // The MERGED manifest is not the overlay: WorkManager and geolocator
    // add their own `foregroundServiceType` entries that no `tools:node`
    // in our manifest removes. CI audits the merged artifact with
    // `--merged`, which pins those two EXACTLY rather than ignoring
    // services — so the gate still catches an app-declared one. (What the
    // pin records is uncomfortable and deliberate: the default Play
    // artifact declares two service *types* while requesting none of the
    // matching FOREGROUND_SERVICE_* permissions, which on Android 14+
    // cannot be promoted at all — failure mode M1 of #4351.)
    group('--merged — the real Play artifact', () {
      File? tmp;

      String write(String services) {
        final dir = Directory.systemTemp.createTempSync('fgs_merged_');
        addTearDown(() => dir.deleteSync(recursive: true));
        final f = File('${dir.path}/AndroidManifest.xml')
          ..writeAsStringSync('<manifest><application>$services'
              '</application></manifest>');
        tmp = f;
        return f.path;
      }

      const work = '<service android:name='
          '"androidx.work.impl.foreground.SystemForegroundService" '
          'android:foregroundServiceType="shortService"/>';
      const geo = '<service android:name='
          '"com.baseflow.geolocator.GeolocatorLocationService" '
          'android:foregroundServiceType="location"/>';

      test('the two library services are the accepted baseline', () {
        final r = run(['--expect-zero', '--merged', write('$work$geo')]);
        expect(r.exitCode, 0, reason: out(r));
        expect(tmp, isNotNull);
      });

      test('NEGATIVE — an APP-declared service still fails', () {
        const ours = '<service android:name='
            '".recording.TripRecordingForegroundService" '
            'android:foregroundServiceType="location"/>';
        final r = run(['--expect-zero', '--merged', write('$work$geo$ours')]);
        expect(r.exitCode, 1, reason: out(r));
        expect(out(r), contains('UNEXPECTED'));
        expect(out(r), contains('TripRecordingForegroundService'));
      });

      test('NEGATIVE — a library service disappearing also fails', () {
        final r = run(['--expect-zero', '--merged', write(work)]);
        expect(r.exitCode, 1, reason: out(r));
        expect(out(r), contains('MISSING'));
      });

      test('an FGS permission is still a failure even with --merged', () {
        const perm = '<uses-permission android:name='
            '"android.permission.FOREGROUND_SERVICE_LOCATION"/>';
        final dir = Directory.systemTemp.createTempSync('fgs_perm_');
        addTearDown(() => dir.deleteSync(recursive: true));
        final f = File('${dir.path}/AndroidManifest.xml')
          ..writeAsStringSync('<manifest>$perm<application>$work$geo'
              '</application></manifest>');
        final r = run(['--expect-zero', '--merged', f.path]);
        expect(r.exitCode, 1, reason: out(r));
      });
    });

    test('NEGATIVE — expect-zero fails on the FGS-approved overlay', () {
      final r = run([
        '--expect-zero',
        'android/app/src/play/AndroidManifestFgsApproved.xml',
      ]);
      expect(r.exitCode, 1, reason: out(r));
      expect(out(r), contains('UNEXPECTED'));
      expect(out(r), contains('FOREGROUND_SERVICE_CONNECTED_DEVICE'));
    });
  });

  group('expect-exactly — an FGS_FORM_APPROVED=true artifact', () {
    test('the play overlay declares exactly the three FGS permissions plus '
        'the connectedDevice service', () {
      final r = run(['--profile', 'play-fgs-approved']);
      expect(r.exitCode, 0, reason: out(r));
      final text = out(r);
      expect(text, contains('android.permission.FOREGROUND_SERVICE\n'));
      expect(text, contains('android.permission.FOREGROUND_SERVICE_LOCATION'));
      expect(text,
          contains('android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE'));
      expect(
          text,
          contains(
              '.autorecord.AutoRecordForegroundService=connectedDevice'));
    });

    test(
        'the CDM background-start exemption is reported as related, not '
        'counted as a foreground-service permission', () {
      final text = out(run(['--profile', 'play-fgs-approved']));
      expect(
          text,
          contains(
              'related permission(s) (not foreground-service permissions)'));
      expect(
          text,
          contains(
              'REQUEST_COMPANION_START_FOREGROUND_SERVICES_FROM_BACKGROUND'));
    });

    test('the fdroid overlay is location-only and that is asserted, not '
        'assumed', () {
      final r = run(['--profile', 'fdroid-fgs-approved']);
      expect(r.exitCode, 0, reason: out(r));
      expect(out(r), contains('foreground service(s) declared: (none)'));
      expect(out(r),
          isNot(contains('FOREGROUND_SERVICE_CONNECTED_DEVICE')));
    });

    test('NEGATIVE — a MISSING declaration fails (the silent screen-off '
        'failure mode)', () {
      // Point the play expectation at the fdroid overlay: connectedDevice and
      // the service are absent there.
      final r = run([
        '--profile',
        'play-fgs-approved',
        'android/app/src/fdroid/AndroidManifestFgsApproved.xml',
      ]);
      expect(r.exitCode, 1, reason: out(r));
      expect(out(r), contains('MISSING expected'));
      expect(out(r),
          contains('android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE'));
      expect(out(r),
          contains('.autorecord.AutoRecordForegroundService=connectedDevice'));
    });

    test('NEGATIVE — an EXTRA declaration fails (a type nobody declared to '
        'Play)', () {
      final r = run([
        '--profile',
        'fdroid-fgs-approved',
        'android/app/src/play/AndroidManifestFgsApproved.xml',
      ]);
      expect(r.exitCode, 1, reason: out(r));
      expect(out(r), contains('UNEXPECTED'));
    });

    test('NEGATIVE — expect-exactly against the bare default overlay fails '
        'on every expected entry', () {
      final r = run([
        '--profile',
        'play-fgs-approved',
        'android/app/src/play/AndroidManifest.xml',
      ]);
      expect(r.exitCode, 1, reason: out(r));
      expect(out(r), contains('MISSING expected'));
    });
  });

  group('usage errors are distinguishable from audit failures', () {
    test('a missing manifest exits 2, not 1', () {
      final r = run(['--expect-zero', 'android/app/src/nope/Missing.xml']);
      expect(r.exitCode, 2, reason: out(r));
    });

    test('an unknown profile exits 2', () {
      final r = run(['--profile', 'not-a-profile']);
      expect(r.exitCode, 2, reason: out(r));
    });
  });

  group('CI runs both halves in the existing build-android step', () {
    late String ciYaml;

    setUpAll(() {
      ciYaml = File('.github/workflows/ci.yml').readAsStringSync();
    });

    test('the merged Play manifest is still audited expect-zero', () {
      expect(ciYaml,
          contains('bash scripts/audit_fgs_declarations.sh --expect-zero'));
    });

    test('both FGS-approved overlays are audited expect-exactly', () {
      expect(
          ciYaml,
          contains('bash scripts/audit_fgs_declarations.sh '
              '--profile play-fgs-approved'));
      expect(
          ciYaml,
          contains('bash scripts/audit_fgs_declarations.sh '
              '--profile fdroid-fgs-approved'));
    });

    test('no new job was added for it — a job-level skip of a matrix job '
        'blocks required checks forever', () {
      expect(ciYaml, isNot(contains('audit-fgs:')));
      expect(ciYaml, isNot(contains('fgs-audit:')));
    });
  });
}
