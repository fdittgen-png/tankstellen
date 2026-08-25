// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../time/app_clock.dart';

/// Per-launch process identity + the previous process's cause of death
/// (#3796, Epic #3794).
///
/// ## The problem it solves
///
/// A recording killed by the OS used to be indistinguishable from a
/// Bluetooth drop: the WAL snapshot survived, the recovery service
/// rehydrated it as `pausedDueToDrop`, and the finished trip carried no
/// hint that the app had died. The user's own logs show `low_memory_kill`
/// repeatedly while recording, so this was the COMMON case being
/// mislabelled, not a corner.
///
/// ## The join
///
/// [instanceId] is minted once per process launch and stamped onto every
/// active-trip snapshot flush. At the next launch the rule is exact and
/// needs no timing heuristic:
///
/// > a surviving snapshot whose `processInstanceId` differs from the
/// > current [instanceId] was written by a process that ended without
/// > clearing it — i.e. the process died while recording.
///
/// A normal stop always clears the snapshot, so a stale id cannot be
/// produced by an orderly shutdown.
///
/// [lastExitReason] then adds the OS's own word for it
/// (`low_memory_kill`, `anr`, `crash`, …) when the crash-forensics
/// harvest found a qualifying record. It is a nice-to-have: the
/// attribution above stands on its own, so recovery never waits on the
/// harvest and an absent reason simply means "died, cause not reported".
class ProcessDeathContext {
  ProcessDeathContext._();

  static String? _instanceId;
  static String? _lastExitReason;
  static int? _lastExitRssKb;

  /// Identity of THIS process launch. Generated on first read.
  ///
  /// Deliberately not a UUID package call: the value only has to be
  /// distinct from the previous launch's and readable in an export.
  /// Read through the #3660 [SystemClock] seam rather than the wall
  /// clock directly, and kept provider-free so the WAL layer can stamp
  /// it from anywhere.
  static String get instanceId =>
      _instanceId ??= 'p${const SystemClock().now().microsecondsSinceEpoch}';

  /// The OS-reported reason the PREVIOUS process ended, when the crash
  /// forensics harvest reported one this launch (Android only).
  static String? get lastExitReason => _lastExitReason;

  /// Resident-set size at that exit, in kB — the memory-pressure trend
  /// behind a `low_memory_kill`.
  static int? get lastExitRssKb => _lastExitRssKb;

  /// Record the previous process's death, newest wins. Called by the
  /// crash-forensics harvester as it walks the native exit records.
  static void noteExit({required String reason, int? rssKb}) {
    _lastExitReason = reason;
    if (rssKb != null) _lastExitRssKb = rssKb;
  }

  /// True when [snapshotInstanceId] belongs to an EARLIER process — the
  /// definitive "died while recording" signal. A null id means the
  /// snapshot predates this field (written before #3796): unknowable, so
  /// it reports false rather than guessing a crash.
  static bool diedWhileRecording(String? snapshotInstanceId) =>
      snapshotInstanceId != null && snapshotInstanceId != instanceId;

  /// A short supplementary detail for the termination record — the OS
  /// reason plus the RSS when we have them, else null (the termination
  /// CLASS already says a process death happened, and per the OTel
  /// error-recording convention the detail must not restate it).
  static String? terminationDetail() {
    final reason = _lastExitReason;
    if (reason == null) return null;
    final rss = _lastExitRssKb;
    return rss == null ? reason : '$reason (rss=${rss}kB)';
  }

  /// Test seam: forget the harvested exit + re-mint the instance id.
  static void resetForTest() {
    _instanceId = null;
    _lastExitReason = null;
    _lastExitRssKb = null;
  }
}
