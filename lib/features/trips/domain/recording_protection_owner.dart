// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4352 / Epic #4351 — the **platform seam** of the protection contract,
/// and the two guards every caller goes through.
///
/// The types live in `recording_protection.dart`; this file is the part a
/// platform implementation plugs into. Kept separate so the contract's
/// vocabulary can be read (and depended on) without dragging in the
/// acquisition machinery — and so S4's Android owner has an obvious, small
/// surface to implement against.
library;

import 'recording_protection.dart';

/// The platform seam a recording session acquires its protection through.
///
/// One owner per session. Implementations are expected to be **idempotent**:
/// acquiring twice for the same generation returns the same answer and starts
/// nothing twice, and releasing a generation that is not held is a no-op.
abstract interface class RecordingProtectionOwner {
  /// Ask the platform to protect a session acquiring [sourceMode], tagged
  /// with [sessionGeneration].
  ///
  /// Implementations report failure as a [RecordingProtectionStatus], never as
  /// an exception — but they are not trusted to get that right: callers go
  /// through [acquireProtection], which enforces it.
  Future<RecordingProtectionStatus> acquire({
    required RecordingSourceMode sourceMode,
    required int sessionGeneration,
  });

  /// Release the protection held for [sessionGeneration]. Releasing a
  /// generation that is not the held one must do nothing — that is how a late
  /// teardown from a retired session cannot drop the live session's lease.
  Future<void> release(int sessionGeneration);
}

/// The honest default owner: no native protection exists, so recording is
/// foreground-only and says so.
///
/// Used on iOS and desktop, in tests, and on any Android artifact until S4
/// (#4352b) lands the real lease. It is deliberately not a "pretend
/// acknowledged" stub — a stub that lies is how #4351 happened.
class NoopRecordingProtectionOwner implements RecordingProtectionOwner {
  /// Const-constructible so it can be a default argument.
  const NoopRecordingProtectionOwner();

  @override
  Future<RecordingProtectionStatus> acquire({
    required RecordingSourceMode sourceMode,
    required int sessionGeneration,
  }) async =>
      RecordingProtectionStatus.foregroundOnly(
        sourceMode: sourceMode,
        sessionGeneration: sessionGeneration,
      );

  @override
  Future<void> release(int sessionGeneration) async {}
}

/// Acquire protection from [owner] under the contract's two hard rules, and
/// **never throw**: a protection failure is a verdict, not an exception, and a
/// throwing platform channel must not be able to abort a recording that is
/// otherwise fine.
///
/// The two rules enforced here, so no implementation can forget them:
///
///   1. **The build decides first.** If [build] cannot host the service
///      [sourceMode] needs, the owner is never called and the answer is
///      [RecordingProtectionVerdict.unsupportedBuild]. No permission prompt,
///      no notification, no native start on a build that cannot promote.
///   2. **A late answer is not this session's answer.** An owner that replies
///      with a different `sessionGeneration` is superseded: the result is
///      downgraded to [RecordingProtectionVerdict.unknown] with
///      [RecordingProtectionReason.generationSuperseded], never propagated as
///      a live acknowledgement.
///
/// A thrown error becomes [RecordingProtectionVerdict.refusedByOs] with the
/// fault recorded in `detail`, so the evidence lands in the diagnostics export
/// rather than in a log nobody exported.
Future<RecordingProtectionStatus> acquireProtection(
  RecordingProtectionOwner owner, {
  required RecordingSourceMode sourceMode,
  required int sessionGeneration,
  RecordingProtectionBuild build = RecordingProtectionBuild.current,
}) async {
  if (build.verdictFor(sourceMode) != null) {
    return RecordingProtectionStatus.unsupportedBuild(
      sourceMode: sourceMode,
      sessionGeneration: sessionGeneration,
      reason: build.reasonFor(sourceMode),
    );
  }
  try {
    final status = await owner.acquire(
      sourceMode: sourceMode,
      sessionGeneration: sessionGeneration,
    );
    if (!status.matchesGeneration(sessionGeneration)) return status.superseded();
    return status;
  } catch (e, st) {
    return RecordingProtectionStatus(
      verdict: RecordingProtectionVerdict.refusedByOs,
      reason: RecordingProtectionReason.nativeStartThrew,
      sourceMode: sourceMode,
      sessionGeneration: sessionGeneration,
      detail: describeProtectionFault(e, st),
    );
  }
}

/// Release [sessionGeneration]'s protection. **Never throws** — teardown must
/// stay bounded even when the platform side is already gone. Returns the fault
/// description when one was swallowed, `null` on a clean release, so a caller
/// can stamp it into the export.
Future<String?> releaseProtection(
  RecordingProtectionOwner owner,
  int sessionGeneration,
) async {
  try {
    await owner.release(sessionGeneration);
    return null;
  } catch (e, st) {
    return describeProtectionFault(e, st);
  }
}

/// A one-line, export-safe rendering of a fault: the error plus its first
/// stack frame. Carries no coordinates, adapter identifiers or keys — the
/// export's sanitisation rule (#4352) applies to this field too.
String describeProtectionFault(Object error, StackTrace stack) {
  final frames = stack.toString().split('\n');
  final first = frames.isEmpty ? '' : frames.first.trim();
  return first.isEmpty ? '$error' : '$error @ $first';
}
