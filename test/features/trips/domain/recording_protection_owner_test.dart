// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/api.dart';

/// #4352 (Epic #4351) — the platform seam and its two guards.
///
/// `acquireProtection` documents a **never-throws** contract
/// (`test/lint/never_throws_contract_test.dart` requires this sibling to
/// inject the fault), and it enforces the two rules no owner implementation
/// is trusted to remember:
///
///   1. the **build** decides before the platform does — an artifact that
///      cannot promote never starts a service, prompts a permission or posts
///      a notification;
///   2. an answer carrying **another generation** is a retired session's
///      answer and can never resurrect it (#4344's fence, reused).
///
/// [NoopRecordingProtectionOwner] is tested here as what it is: the honest
/// default that answers `foregroundOnly`, never a stub that pretends.

/// An owner that always throws — the fault injection for the never-throws
/// contract on [acquireProtection] / [releaseProtection].
class _ThrowingOwner implements RecordingProtectionOwner {
  @override
  Future<RecordingProtectionStatus> acquire({
    required RecordingSourceMode sourceMode,
    required int sessionGeneration,
  }) async =>
      throw StateError('startForeground refused');

  @override
  Future<void> release(int sessionGeneration) async =>
      throw StateError('service already gone');
}

/// An owner that answers for a DIFFERENT generation — the late native
/// acknowledgement that must never resurrect a finished session.
class _LateOwner implements RecordingProtectionOwner {
  @override
  Future<RecordingProtectionStatus> acquire({
    required RecordingSourceMode sourceMode,
    required int sessionGeneration,
  }) async =>
      RecordingProtectionStatus.acknowledged(
        sourceMode: sourceMode,
        sessionGeneration: sessionGeneration - 1,
      );

  @override
  Future<void> release(int sessionGeneration) async {}
}

/// An owner that acknowledges the generation it was asked about.
class _AcknowledgingOwner implements RecordingProtectionOwner {
  int? acquiredFor;

  @override
  Future<RecordingProtectionStatus> acquire({
    required RecordingSourceMode sourceMode,
    required int sessionGeneration,
  }) async {
    acquiredFor = sessionGeneration;
    return RecordingProtectionStatus.acknowledged(
      sourceMode: sourceMode,
      sessionGeneration: sessionGeneration,
    );
  }

  @override
  Future<void> release(int sessionGeneration) async {}
}

const _playApproved = RecordingProtectionBuild(
  foregroundServiceCompiled: true,
  libre: false,
);
const _playDefault = RecordingProtectionBuild(
  foregroundServiceCompiled: false,
  libre: false,
);

void main() {
  group('acquireProtection — the two hard rules + never-throws', () {
    test('an incapable build is answered without calling the owner', () async {
      final owner = _AcknowledgingOwner();
      final status = await acquireProtection(
        owner,
        sourceMode: RecordingSourceMode.both,
        sessionGeneration: 1,
        build: _playDefault,
      );
      expect(status.verdict, RecordingProtectionVerdict.unsupportedBuild);
      expect(status.isProtected, isFalse);
      expect(owner.acquiredFor, isNull,
          reason: 'a build that cannot promote must not start anything');
    });

    test('a capable build reaches the owner and acknowledges', () async {
      final owner = _AcknowledgingOwner();
      final status = await acquireProtection(
        owner,
        sourceMode: RecordingSourceMode.locationOnly,
        sessionGeneration: 4,
        build: _playApproved,
      );
      expect(status.verdict, RecordingProtectionVerdict.acknowledged);
      expect(status.isProtected, isTrue);
      expect(owner.acquiredFor, 4);
    });

    test('an answer for another generation can never resurrect a session',
        () async {
      final status = await acquireProtection(
        _LateOwner(),
        sourceMode: RecordingSourceMode.both,
        sessionGeneration: 9,
        build: _playApproved,
      );
      expect(status.isProtected, isFalse);
      expect(status.verdict, RecordingProtectionVerdict.unknown);
      expect(status.reason, RecordingProtectionReason.generationSuperseded);
    });

    // FAULT INJECTION — `acquireProtection` documents a never-throws
    // contract (test/lint/never_throws_contract_test.dart).
    test('a throwing owner becomes a verdict, not an exception', () async {
      final call = acquireProtection(
        _ThrowingOwner(),
        sourceMode: RecordingSourceMode.connectedDeviceOnly,
        sessionGeneration: 2,
        build: _playApproved,
      );
      await expectLater(call, completes);
      final status = await call;
      expect(status.verdict, RecordingProtectionVerdict.refusedByOs);
      expect(status.reason, RecordingProtectionReason.nativeStartThrew);
      expect(status.detail, contains('startForeground refused'));
      expect(status.isProtected, isFalse);
    });

    test('a throwing release is swallowed and reported, never rethrown',
        () async {
      final call = releaseProtection(_ThrowingOwner(), 5);
      await expectLater(call, completes);
      expect(await call, contains('service already gone'));
      expect(
        await releaseProtection(const NoopRecordingProtectionOwner(), 5),
        isNull,
      );
    });

    test('the fault description carries no stack dump, just one frame', () {
      final text = describeProtectionFault(
          StateError('boom'), StackTrace.fromString('#0 a\n#1 b\n#2 c'));
      expect(text, contains('boom'));
      expect(text, contains('#0 a'));
      expect(text, isNot(contains('#2 c')));
      expect(text.split('\n'), hasLength(1));
    });
  });

  group('NoopRecordingProtectionOwner — the honest default', () {
    test('answers foregroundOnly, never acknowledged', () async {
      for (final mode in RecordingSourceMode.values) {
        final status = await const NoopRecordingProtectionOwner()
            .acquire(sourceMode: mode, sessionGeneration: 11);
        expect(status.verdict, RecordingProtectionVerdict.foregroundOnly);
        expect(status.isProtected, isFalse);
        expect(status.sessionGeneration, 11);
        expect(status.sourceMode, mode);
      }
    });

    test('release is a bounded no-op', () async {
      await expectLater(
          const NoopRecordingProtectionOwner().release(1), completes);
    });
  });
}
