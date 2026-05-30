// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_comm_diagnostics.dart';

/// Redact a raw adapter MAC for the diagnostics session (#2465).
///
/// MAC is a stable hardware identifier (PII). Everything before the
/// final four characters is replaced with the middle-dot `·` so the
/// length stays visible without leaking the address — the same form the
/// XML/report exporters already use (`obd2_debug_session_xml.dart`,
/// `obd2_diagnostic_report.dart`). A string of four characters or fewer
/// is returned unchanged (there is nothing to hide); null passes through.
String? redactObd2Mac(String? mac) {
  if (mac == null) return null;
  if (mac.length <= 4) return mac;
  final visible = mac.substring(mac.length - 4);
  return '${'·' * (mac.length - 4)}$visible';
}

/// Mutable live-session accumulator. Converted to the immutable
/// [Obd2SessionDiagnostic] on `snapshot()`/`endSession()`.
class _LiveSession {
  _LiveSession({this.linkKind, this.redactedMac, required this.startedAt});

  final String? linkKind;
  final String? redactedMac;

  /// Wall-clock start, used to derive
  /// [Obd2SessionDiagnostic.sessionActiveSeconds].
  final DateTime startedAt;

  String? elmVersion;
  String? protocolDigit;
  int? mtu;
  bool? warmStart;
  String? capabilityTier;

  final List<Obd2HandshakeLine> transcript = <Obd2HandshakeLine>[];
  final Map<String, _PidAccumulator> _pids = <String, _PidAccumulator>{};

  int connAttempts = 0;
  int connSuccesses = 0;
  final Map<String, int> connFailuresByReason = <String, int>{};
  int connDrops = 0;
  int silentReconnects = 0;
  int visibleReconnects = 0;
  final _LatencyReservoir timeToConnect = _LatencyReservoir();
  final _LatencyReservoir timeToReconnect = _LatencyReservoir();

  int partialFrames = 0;
  int leftoverBytes = 0;
  int strayPrompts = 0;
  int garbageReads = 0;

  final Map<String, int> fuelTierTicks = <String, int>{};
  int fuelTotalSamples = 0;
  int fuelSuspiciousSamples = 0;

  // Scheduler health (#2468).
  int backpressureSkips = 0;
  int schedulerTicks = 0;
  double tickRateHz = 0.0;
  double achievedReadsPerSecond = 0.0;
  double dynamicsEffectiveHz = 0.0;
  int demotions = 0;
  int backedOffCount = 0;
  bool starved = false;

  // Discovered-supported tri-state (#2469): command → state string.
  final Map<String, String> discoveredSupported = <String, String>{};

  _PidAccumulator pidRow(String pid) =>
      _pids.putIfAbsent(pid, _PidAccumulator.new);

  Obd2SessionDiagnostic toDiagnostic(int activeSeconds) =>
      Obd2SessionDiagnostic(
        linkKind: linkKind,
        redactedMac: redactedMac,
        elmVersion: elmVersion,
        protocolDigit: protocolDigit,
        mtu: mtu,
        warmStart: warmStart,
        capabilityTier: capabilityTier,
        initTranscript: List.unmodifiable(transcript),
        pidStats: {
          for (final entry in _pids.entries) entry.key: entry.value.toStat(),
        },
        connection: Obd2ConnectionStats(
          attempts: connAttempts,
          successes: connSuccesses,
          failuresByReason: Map.unmodifiable(connFailuresByReason),
          drops: connDrops,
          silentReconnects: silentReconnects,
          visibleReconnects: visibleReconnects,
          timeToConnectP50Ms: timeToConnect.percentileOrNull(50),
          timeToConnectP95Ms: timeToConnect.percentileOrNull(95),
          timeToReconnectP50Ms: timeToReconnect.percentileOrNull(50),
          timeToReconnectP95Ms: timeToReconnect.percentileOrNull(95),
        ),
        scheduler: Obd2SchedulerStats(
          tickRateHz: tickRateHz,
          backpressureSkips: backpressureSkips,
          demotions: demotions,
          ticks: schedulerTicks,
          achievedReadsPerSecond: achievedReadsPerSecond,
          dynamicsEffectiveHz: dynamicsEffectiveHz,
          backedOffCount: backedOffCount,
          starved: starved,
        ),
        framing: Obd2FramingStats(
          partialFrames: partialFrames,
          leftoverBytes: leftoverBytes,
          strayPrompts: strayPrompts,
          garbageReads: garbageReads,
        ),
        fuelTierTicks: Map.unmodifiable(fuelTierTicks),
        fuelDowngrade: Obd2FuelDowngradeStats(
          totalSamples: fuelTotalSamples,
          suspiciousSamples: fuelSuspiciousSamples,
        ),
        sessionActiveSeconds: activeSeconds < 0 ? 0 : activeSeconds,
        discoveredSupported: Map.unmodifiable(discoveredSupported),
      );
}

/// Mutable per-PID accumulator backing one [Obd2PidStat] row.
class _PidAccumulator {
  int polled = 0;
  int ok = 0;
  int noData = 0;
  int timeout = 0;
  int error = 0;
  double targetHz = 0.0;
  String? tier;
  int consecutiveFailures = 0;
  bool backedOff = false;
  final _LatencyReservoir latency = _LatencyReservoir();

  Obd2PidStat toStat() => Obd2PidStat(
        polled: polled,
        ok: ok,
        noData: noData,
        timeout: timeout,
        error: error,
        latencyP50Ms: latency.percentileOrNull(50) ?? 0,
        latencyP95Ms: latency.percentileOrNull(95) ?? 0,
        targetHz: targetHz,
        tier: tier,
        consecutiveFailures: consecutiveFailures,
        backedOff: backedOff,
      );
}

/// Bounded streaming latency reservoir. Retains at most [capacity]
/// samples; once full, new samples evict via reservoir sampling so the
/// retained set stays a uniform random sample of the whole stream — the
/// percentile estimate stays representative without storing every read.
class _LatencyReservoir {
  /// Maximum retained samples — never grows beyond this. 128 samples is
  /// ample for a stable p50/p95 estimate while keeping the per-PID
  /// footprint tiny.
  static const int capacity = 128;

  final List<int> _samples = <int>[];
  int _seen = 0;
  // Deterministic LCG so percentiles are reproducible in tests (no
  // dependency on dart:math Random's global seed).
  int _rng = 0x2545F4914F6CDD1D;

  /// Fold one sample into the reservoir.
  void add(int value) {
    _seen++;
    if (_samples.length < capacity) {
      _samples.add(value);
      return;
    }
    // Reservoir sampling: replace a random slot with decreasing
    // probability so the retained set stays uniform over the stream.
    final j = _nextInt(_seen);
    if (j < capacity) _samples[j] = value;
  }

  /// The [p]-th percentile (0–100) of the retained samples, or null when
  /// empty. Nearest-rank on the sorted retained set.
  int? percentileOrNull(int p) {
    if (_samples.isEmpty) return null;
    final sorted = [..._samples]..sort();
    final clamped = p.clamp(0, 100);
    // Nearest-rank: rank = ceil(p/100 * n), 1-based.
    final rank = ((clamped / 100.0) * sorted.length).ceil();
    final index = (rank <= 0 ? 1 : rank) - 1;
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  /// Deterministic xorshift-based bounded RNG in `[0, bound)`.
  int _nextInt(int bound) {
    var x = _rng;
    x ^= (x << 13) & 0x7FFFFFFFFFFFFFFF;
    x ^= x >> 7;
    x ^= (x << 17) & 0x7FFFFFFFFFFFFFFF;
    _rng = x & 0x7FFFFFFFFFFFFFFF;
    return _rng % bound;
  }
}
