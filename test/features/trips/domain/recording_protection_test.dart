// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/api.dart';

/// #4352 (Epic #4351) — the protection contract's algebra.
///
/// Three things are proved here, and each one is a defect the programme
/// exists to prevent:
///
///   1. **Unknown is not ready.** Only an acknowledged promotion may claim
///      background recording; every other verdict — including silence —
///      must not.
///   2. **The build decides before the platform does.** An artifact without
///      the `FGS_FORM_APPROVED` define can never promote, so no owner is
///      called, no permission is prompted and no notification is posted on
///      it. The F-Droid overlay's missing `connectedDevice` permission is
///      part of that answer.
///   3. **A late answer is not this session's answer** — and a throwing
///      platform channel is a verdict, not a crash (the never-throws
///      fault-injection sibling `acquireProtection` documents).
///
/// The manifest assertions at the end pin the Dart capability claim to the
/// checked-in overlays, so `RecordingProtectionBuild.supports()` cannot
/// out-claim what ships. `scripts/audit_fgs_declarations.sh` makes the same
/// assertion from the shell side (see `test/ci/`).

const _playApproved = RecordingProtectionBuild(
  foregroundServiceCompiled: true,
  libre: false,
);
const _fdroidApproved = RecordingProtectionBuild(
  foregroundServiceCompiled: true,
  libre: true,
);
const _playDefault = RecordingProtectionBuild(
  foregroundServiceCompiled: false,
  libre: false,
);

void main() {
  group('verdict algebra (#4352)', () {
    test('only `acknowledged` may claim background recording', () {
      for (final v in RecordingProtectionVerdict.values) {
        expect(v.isProtected, v == RecordingProtectionVerdict.acknowledged,
            reason: '$v must not claim protection unless acknowledged');
      }
    });

    test('unknown is the least capable verdict — silence is not acceptance',
        () {
      expect(RecordingProtectionVerdict.unknown.index, 0);
      for (final v in RecordingProtectionVerdict.values) {
        expect(
          RecordingProtectionVerdict.worst(
              RecordingProtectionVerdict.unknown, v),
          RecordingProtectionVerdict.unknown,
        );
      }
    });

    test('worst() takes the less capable of two observations', () {
      expect(
        RecordingProtectionVerdict.worst(
          RecordingProtectionVerdict.acknowledged,
          RecordingProtectionVerdict.foregroundOnly,
        ),
        RecordingProtectionVerdict.foregroundOnly,
      );
      expect(
        RecordingProtectionVerdict.worst(
          RecordingProtectionVerdict.refusedByOs,
          RecordingProtectionVerdict.unsupportedBuild,
        ),
        RecordingProtectionVerdict.unsupportedBuild,
      );
    });

    test('a status belongs to exactly one generation', () {
      const s = RecordingProtectionStatus.acknowledged(
        sourceMode: RecordingSourceMode.both,
        sessionGeneration: 7,
      );
      expect(s.matchesGeneration(7), isTrue);
      expect(s.matchesGeneration(8), isFalse);
      expect(s.superseded().verdict, RecordingProtectionVerdict.unknown);
      expect(s.superseded().isProtected, isFalse);
      expect(s.superseded().reason,
          RecordingProtectionReason.generationSuperseded);
    });

    test('the export shape carries verdict, reason, mode and generation', () {
      const s = RecordingProtectionStatus.foregroundOnly(
        sourceMode: RecordingSourceMode.connectedDeviceOnly,
        sessionGeneration: 3,
      );
      expect(s.toJson(), {
        'verdict': 'foregroundOnly',
        'reason': 'policyForegroundOnly',
        'sourceMode': 'connectedDeviceOnly',
        'sessionGeneration': 3,
      });
    });

    test('value equality — two identical answers are one answer', () {
      const a = RecordingProtectionStatus.unknown(
          sourceMode: RecordingSourceMode.locationOnly);
      const b = RecordingProtectionStatus.unknown(
          sourceMode: RecordingSourceMode.locationOnly);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('source mode → required service type', () {
    test('an OBD2-only trip needs no location at all (M3, #4352 §4)', () {
      expect(RecordingSourceMode.connectedDeviceOnly.needsLocation, isFalse);
      expect(
          RecordingSourceMode.connectedDeviceOnly.needsConnectedDevice, isTrue);
    });

    test('a GPS-only trip needs no connectedDevice type', () {
      expect(RecordingSourceMode.locationOnly.needsLocation, isTrue);
      expect(RecordingSourceMode.locationOnly.needsConnectedDevice, isFalse);
    });

    test('a mixed trip needs both', () {
      expect(RecordingSourceMode.both.needsLocation, isTrue);
      expect(RecordingSourceMode.both.needsConnectedDevice, isTrue);
    });
  });

  group('build capability (the artifact, not the device)', () {
    test('without the FGS define nothing is supported — any mode', () {
      for (final mode in RecordingSourceMode.values) {
        expect(_playDefault.supports(mode), isFalse);
        expect(_playDefault.verdictFor(mode),
            RecordingProtectionVerdict.unsupportedBuild);
        expect(_playDefault.reasonFor(mode),
            RecordingProtectionReason.foregroundServiceNotCompiled);
      }
    });

    test('an FGS-approved Play build supports every mode', () {
      for (final mode in RecordingSourceMode.values) {
        expect(_playApproved.supports(mode), isTrue);
        expect(_playApproved.verdictFor(mode), isNull);
      }
    });

    test(
        'an FGS-approved F-Droid build is location-only — connectedDevice is '
        'not declared there yet (S4)', () {
      expect(_fdroidApproved.supports(RecordingSourceMode.locationOnly),
          isTrue);
      expect(_fdroidApproved.supports(RecordingSourceMode.connectedDeviceOnly),
          isFalse);
      expect(_fdroidApproved.supports(RecordingSourceMode.both), isFalse);
      expect(
        _fdroidApproved.reasonFor(RecordingSourceMode.connectedDeviceOnly),
        RecordingProtectionReason.serviceTypeNotDeclared,
      );
    });

    test('the channel label distinguishes the two artifacts', () {
      expect(_playApproved.channel, 'play');
      expect(_fdroidApproved.channel, 'fdroid');
      expect(_playDefault.toJson(),
          {'channel': 'play', 'foregroundServiceCompiled': false});
    });

    test('the running build is the default the export stamps', () {
      // The test binary carries no --dart-define, i.e. exactly the shape a
      // default Play artifact ships with: no foreground service.
      expect(RecordingProtectionBuild.current.foregroundServiceCompiled,
          isFalse);
      expect(RecordingProtectionBuild.current.channel, 'play');
    });
  });

  group('the Dart capability claim matches the shipped manifest overlays', () {
    String overlay(String path) => File(path).readAsStringSync();

    test(
        'the play FGS-approved overlay declares the connectedDevice '
        'permission the Play build claims', () {
      final xml = overlay('android/app/src/play/AndroidManifestFgsApproved.xml');
      expect(
        xml,
        contains(
            '"android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE"'),
        reason: 'RecordingProtectionBuild.supports() says a non-libre '
            'FGS-approved build can host a connectedDevice service',
      );
      expect(_playApproved.supports(RecordingSourceMode.connectedDeviceOnly),
          isTrue);
    });

    test(
        'the fdroid FGS-approved overlay does NOT — and supports() agrees '
        'rather than out-claiming it', () {
      final xml =
          overlay('android/app/src/fdroid/AndroidManifestFgsApproved.xml');
      expect(
        xml,
        isNot(contains(
            '"android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE"')),
      );
      expect(_fdroidApproved.supports(RecordingSourceMode.connectedDeviceOnly),
          isFalse);
    });

    test('the DEFAULT play overlay declares no FGS permission at all (#1498)',
        () {
      final xml = overlay('android/app/src/play/AndroidManifest.xml');
      final withoutComments =
          xml.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
      expect(withoutComments, isNot(contains('uses-permission')));
    });
  });
}
