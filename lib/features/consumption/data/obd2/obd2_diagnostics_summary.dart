// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'obd2_session_diagnostic.dart';

/// Pure, framework-free presentation aggregate for the
/// [Obd2DiagnosticsCard] (#2470, TAIL of Epic #2463) — the OBD2 analogue
/// of `GpsDiagnosticsSummary`.
///
/// Computed by [computeObd2DiagnosticsSummary] from a raw (or
/// completeness-summarised) [Obd2SessionDiagnostic]. Holds everything the
/// card renders, pre-rolled so the widget tree does no math and the tests
/// can assert on a single value type rather than pumping a tree:
///
///   * the header triple (completeness% · active-duty% · drops);
///   * the per-PID rows (already sorted worst-first by error+timeout) and
///     the top-failing PID;
///   * the discovered-supported tri-state tallies;
///   * the per-tier completeness rollup;
///   * the fuel-tier rollup (suspicious / total).
///
/// `presentable` is false when there is genuinely nothing to show (no
/// session yet) — the card uses it to pick the empty-state branch without
/// having to peek at the raw snapshot.
@immutable
class Obd2DiagnosticsSummary {
  /// True when the underlying session carries at least one signal worth
  /// rendering (a PID row, a connection attempt, a recorded adapter).
  /// False for the const-default empty snapshot.
  final bool presentable;

  /// Overall completeness percentage (0–100), rounded to a whole number.
  final int completenessPercent;

  /// Active-duty-cycle percentage (0–100), rounded to a whole number.
  final int activeDutyPercent;

  /// Detected mid-session link drops.
  final int drops;

  /// Per-PID rows in render order (worst-first: most error+timeout first,
  /// then most polled). Each row carries its PID command + the raw stat.
  final List<Obd2PidRowView> pidRows;

  /// The single worst-performing PID command (most error+timeout), or null
  /// when no PID was polled. Surfaced in the collapsed-detail header.
  final String? topFailingPid;

  /// Discovered-supported tri-state tallies (supported / unsupported /
  /// unknown) across the polled command set.
  final int supportedCount;
  final int unsupportedCount;
  final int unknownCount;

  /// Per-tier completeness percentages keyed by tier name, rounded to a
  /// whole number, sorted by tier name for a stable render order.
  final Map<String, int> perTierPercent;

  /// Fuel-tier downgrade rollup: suspicious samples out of total seen.
  final int fuelSuspicious;
  final int fuelTotal;

  /// #2905 — reconnect-attempt timeline rollup: total attempts recorded,
  /// how many succeeded, and the failed-attempt reason tally (reason → count)
  /// sorted by count desc for a stable render order.
  final int reconnectAttemptCount;
  final int reconnectSuccessCount;
  final Map<String, int> reconnectReasonCounts;

  /// #2905 — session-state-transition count + the typed-drop
  /// (`Obd2DisconnectedException`) count + whether GPS-only fallback
  /// activated this session.
  final int transitionCount;
  final int disconnectExceptions;
  final bool fallbackActivated;

  const Obd2DiagnosticsSummary({
    required this.presentable,
    required this.completenessPercent,
    required this.activeDutyPercent,
    required this.drops,
    required this.pidRows,
    required this.topFailingPid,
    required this.supportedCount,
    required this.unsupportedCount,
    required this.unknownCount,
    required this.perTierPercent,
    required this.fuelSuspicious,
    required this.fuelTotal,
    this.reconnectAttemptCount = 0,
    this.reconnectSuccessCount = 0,
    this.reconnectReasonCounts = const <String, int>{},
    this.transitionCount = 0,
    this.disconnectExceptions = 0,
    this.fallbackActivated = false,
  });

  /// Stable empty value — the not-presentable sentinel the card renders as
  /// the empty state, and the value tests assert against for an empty /
  /// disabled session.
  static const Obd2DiagnosticsSummary empty = Obd2DiagnosticsSummary(
    presentable: false,
    completenessPercent: 0,
    activeDutyPercent: 0,
    drops: 0,
    pidRows: <Obd2PidRowView>[],
    topFailingPid: null,
    supportedCount: 0,
    unsupportedCount: 0,
    unknownCount: 0,
    perTierPercent: <String, int>{},
    fuelSuspicious: 0,
    fuelTotal: 0,
  );

  @override
  bool operator ==(Object other) {
    if (other is! Obd2DiagnosticsSummary) return false;
    if (other.presentable != presentable) return false;
    if (other.completenessPercent != completenessPercent) return false;
    if (other.activeDutyPercent != activeDutyPercent) return false;
    if (other.drops != drops) return false;
    if (other.topFailingPid != topFailingPid) return false;
    if (other.supportedCount != supportedCount) return false;
    if (other.unsupportedCount != unsupportedCount) return false;
    if (other.unknownCount != unknownCount) return false;
    if (other.fuelSuspicious != fuelSuspicious) return false;
    if (other.fuelTotal != fuelTotal) return false;
    if (other.reconnectAttemptCount != reconnectAttemptCount) return false;
    if (other.reconnectSuccessCount != reconnectSuccessCount) return false;
    if (other.transitionCount != transitionCount) return false;
    if (other.disconnectExceptions != disconnectExceptions) return false;
    if (other.fallbackActivated != fallbackActivated) return false;
    if (other.reconnectReasonCounts.length != reconnectReasonCounts.length) {
      return false;
    }
    for (final entry in reconnectReasonCounts.entries) {
      if (other.reconnectReasonCounts[entry.key] != entry.value) return false;
    }
    if (!listEquals(other.pidRows, pidRows)) return false;
    if (other.perTierPercent.length != perTierPercent.length) return false;
    for (final entry in perTierPercent.entries) {
      if (other.perTierPercent[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        presentable,
        completenessPercent,
        activeDutyPercent,
        drops,
        topFailingPid,
        supportedCount,
        unsupportedCount,
        unknownCount,
        fuelSuspicious,
        fuelTotal,
        Object.hashAll(pidRows),
        Object.hashAllUnordered(
          perTierPercent.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        Object.hash(
          reconnectAttemptCount,
          reconnectSuccessCount,
          transitionCount,
          disconnectExceptions,
          fallbackActivated,
          Object.hashAllUnordered(
            reconnectReasonCounts.entries.map((e) => Object.hash(e.key, e.value)),
          ),
        ),
      );
}

/// One per-PID render row: the poll command + its stat. A thin value
/// wrapper so the card can iterate `(pid, stat)` pairs in a stable,
/// pre-sorted order with structural equality for tests.
@immutable
class Obd2PidRowView {
  final String pid;
  final Obd2PidStat stat;

  const Obd2PidRowView({required this.pid, required this.stat});

  /// Failure weight used to sort rows worst-first: errors + timeouts.
  int get failureWeight => stat.error + stat.timeout;

  @override
  bool operator ==(Object other) =>
      other is Obd2PidRowView && other.pid == pid && other.stat == stat;

  @override
  int get hashCode => Object.hash(pid, stat);
}

/// Compute the read-only [Obd2DiagnosticsSummary] for one session.
///
/// Pure — allocates no platform handles, depends on nothing in the
/// framework, safe to call from a unit test or a build method. Runs the
/// completeness summariser first only when the snapshot has not already
/// been summarised (its `completeness` is still the default), so a
/// settled session that was summarised at `endSession` is not re-rolled.
Obd2DiagnosticsSummary computeObd2DiagnosticsSummary(
  Obd2SessionDiagnostic session,
) {
  // A session with no PID rows, no connection attempts and no adapter is
  // the const-default empty snapshot — nothing worth rendering.
  final hasSignal = session.pidStats.isNotEmpty ||
      session.connection.attempts > 0 ||
      session.redactedMac != null ||
      session.elmVersion != null ||
      // #2905 — a reconnect-only / drop-only session (no successful cold
      // connect, ran entirely on fallback) is exactly the field case worth
      // surfacing — it must NOT be the empty sentinel.
      session.reconnectAttempts.isNotEmpty ||
      session.transitions.isNotEmpty ||
      session.disconnectExceptions > 0 ||
      session.fallbackActivatedAtMs != null;
  if (!hasSignal) return Obd2DiagnosticsSummary.empty;

  final completeness = session.completeness;

  // Per-PID rows, worst-first (errors+timeouts desc, then polled desc, then
  // PID asc for a fully-deterministic order).
  final rows = session.pidStats.entries
      .map((e) => Obd2PidRowView(pid: e.key, stat: e.value))
      .toList(growable: false)
    ..sort((a, b) {
      final byFailure = b.failureWeight.compareTo(a.failureWeight);
      if (byFailure != 0) return byFailure;
      final byPolled = b.stat.polled.compareTo(a.stat.polled);
      if (byPolled != 0) return byPolled;
      return a.pid.compareTo(b.pid);
    });

  final topFailing = rows.isEmpty || rows.first.failureWeight == 0
      ? null
      : rows.first.pid;

  // Discovered-supported tri-state tallies.
  var supported = 0;
  var unsupported = 0;
  var unknown = 0;
  for (final state in session.discoveredSupported.values) {
    switch (state) {
      case 'supported':
        supported++;
      case 'unsupported':
        unsupported++;
      default:
        unknown++;
    }
  }

  // Per-tier completeness, rounded + sorted by tier name.
  final tierEntries = completeness.perTierPercent.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final perTier = <String, int>{
    for (final e in tierEntries) e.key: e.value.round(),
  };

  // #2905 — reconnect-attempt rollup: success count + failed-reason tally,
  // sorted by count desc then reason for a deterministic render order.
  final attempts = session.reconnectAttempts;
  final reconnectSuccesses = attempts.where((a) => a.succeeded).length;
  final reasonTally = <String, int>{};
  for (final a in attempts) {
    final reason = a.reasonCode;
    if (a.succeeded || reason == null) continue;
    reasonTally[reason] = (reasonTally[reason] ?? 0) + 1;
  }
  final reasonEntries = reasonTally.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  final reasonCounts = <String, int>{
    for (final e in reasonEntries) e.key: e.value,
  };

  return Obd2DiagnosticsSummary(
    presentable: true,
    completenessPercent: completeness.overallPercent.round(),
    activeDutyPercent: (completeness.activeDutyCycle * 100).round(),
    drops: session.connection.drops,
    pidRows: rows,
    topFailingPid: topFailing,
    supportedCount: supported,
    unsupportedCount: unsupported,
    unknownCount: unknown,
    perTierPercent: perTier,
    fuelSuspicious: session.fuelDowngrade.suspiciousSamples,
    fuelTotal: session.fuelDowngrade.totalSamples,
    reconnectAttemptCount: attempts.length,
    reconnectSuccessCount: reconnectSuccesses,
    reconnectReasonCounts: reasonCounts,
    transitionCount: session.transitions.length,
    disconnectExceptions: session.disconnectExceptions,
    fallbackActivated: session.fallbackActivatedAtMs != null,
  );
}
