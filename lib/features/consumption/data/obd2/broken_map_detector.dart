import '../../../../core/logging/error_logger.dart';
import 'broken_map_belief.dart';
import 'broken_map_belief_updater.dart';
import 'elm327_parsers.dart';
import 'oem_pid_table.dart';

/// Idle-probe detector for broken-MAP adapters (#1423 phase 2).
///
/// Composes [BrokenMapBeliefUpdater]'s membership functions and EMA
/// updater (phase 1) with a deterministic, side-effect-free probe over
/// an [Obd2RawCommandPort]. One round of [probe] reads PID 0x0B (intake
/// MAP), PID 0x33 (absolute barometric pressure) and PID 0x11 (throttle
/// position) from the connected adapter and folds the resulting score
/// into [prior].
///
/// ## Petrol path
/// At idle on a healthy NA petrol engine, intake MAP sits ~30-40 kPa
/// while baro is ~100 kPa — i.e. delta is large (strong vacuum). A
/// broken / clamped MAP sensor returns ~atmospheric, collapsing the
/// delta to ≤ 5 kPa. We compute
/// [BrokenMapBeliefUpdater.vacuumMissingScore] and tag the resulting
/// strong observation as [BrokenMapReason.idleVacuumMissing].
///
/// ## Diesel path
/// Diesels run unthrottled, so idle MAP is already near baro — the
/// vacuum check is meaningless. The discriminator is how much MAP
/// *changes* under a brief rev. Phase 2 cannot actually drive the
/// engine, so the rev step is a soft second read of PID 0x0B after a
/// short delay (1.5 s placeholder). Whether the user actually revved
/// is up to them — the spec acknowledges this is a driver-assistance
/// path. The result feeds
/// [BrokenMapBeliefUpdater.revDeltaMissingScore] tagged
/// [BrokenMapReason.revDeltaMissing].
///
/// ## Idle gating
/// Both paths require the throttle to be confirmed closed (TPS < 5%).
/// If the user's foot is on the pedal when the probe fires, the read
/// MAP would be misleading — we return [prior] unchanged and document
/// in the API that the caller is expected to retry once the user is
/// stationary.
///
/// ## Failure mode
/// Any transport hiccup, malformed response or thrown exception causes
/// [probe] to return [prior] unchanged after logging via
/// [errorLogger.log] (`op: 'brokenMapDetector.probe'`). Never throws.
/// Callers (typically the VIN auto-populator) can wire it as an
/// optional best-effort step at adapter pair time.
class BrokenMapDetector {
  const BrokenMapDetector();

  /// Mode 01 PID 0B request (intake manifold absolute pressure, kPa).
  static const String _mapCommand = '010B\r';

  /// Mode 01 PID 33 request (absolute barometric pressure, kPa). Single
  /// byte, 0-255 kPa scaling (raw).
  static const String _baroCommand = '0133\r';

  /// Mode 01 PID 11 request (absolute throttle position, percent of
  /// 100/255). Used to gate the probe on a confirmed-closed throttle.
  static const String _tpsCommand = '0111\r';

  /// Closed-throttle threshold in percent. The SAE-J1979 idle stop is
  /// usually ≤ 12 %; we set 5 % to require a clearly released pedal so
  /// a partial throttle confounds nothing. Below this the MAP reading
  /// is treated as a real idle observation.
  static const double _closedThrottlePercent = 5.0;

  /// Delay between the idle MAP read and the rev MAP read on the
  /// diesel path. Long enough that a cooperating user has time to blip
  /// the throttle; short enough to keep the round trip under the
  /// spec's 30 s budget. Phase 2 placeholder — phase 5 (UI) will
  /// supersede this with an actual user prompt.
  static const Duration _revDelay = Duration(milliseconds: 1500);

  /// Run one probe round against [port] and return the updated belief.
  ///
  /// [isDiesel] selects the petrol vacuum check vs diesel rev-delta
  /// branch. [prior] is folded with the new observation via
  /// [BrokenMapBeliefUpdater.update]. [now] is injected for tests; in
  /// production callers pass `DateTime.now()`.
  ///
  /// Returns [prior] unchanged when:
  ///   * any of the three PID reads fails / returns malformed bytes,
  ///   * the throttle isn't confirmed closed (TPS ≥ 5 %),
  ///   * the [port] throws.
  ///
  /// Errors and the throttle-not-closed retry signal are surfaced via
  /// [errorLogger.log] under `op: 'brokenMapDetector.probe'` so the
  /// diagnostic overlay can see whether the probe actually ran.
  Future<BrokenMapBelief> probe(
    Obd2RawCommandPort port, {
    required bool isDiesel,
    required BrokenMapBelief prior,
    required DateTime now,
  }) async {
    try {
      // Throttle gate first — cheapest way to bail on a bad sample.
      final tpsRaw = await port.sendRaw(_tpsCommand);
      final tps = Elm327Parsers.parseThrottlePercent(tpsRaw);
      if (tps == null) {
        // Malformed response — treat as no observation, leave the
        // belief alone so the caller can retry next pair.
        return prior;
      }
      if (tps >= _closedThrottlePercent) {
        // Foot is on the pedal. Don't score; caller retries when the
        // user is stationary. Log so the diagnostic overlay can see
        // why the probe didn't update the belief.
        await errorLogger.log(
          ErrorLayer.background,
          StateError('throttle not closed at probe time (tps=$tps%)'),
          StackTrace.current,
          context: const {
            'op': 'brokenMapDetector.probe',
            'reason': 'tpsNotClosed',
          },
        );
        return prior;
      }

      // Idle MAP read — required for both branches.
      final mapIdleRaw = await port.sendRaw(_mapCommand);
      final mapIdle = Elm327Parsers.parseManifoldPressureKpa(mapIdleRaw);
      if (mapIdle == null) return prior;

      double observationScore;
      BrokenMapReason reason;

      if (isDiesel) {
        // Soft "rev" step — phase 2 placeholder. Wait, then re-read
        // PID 0x0B. A cooperating user blipped the throttle in this
        // window; an uncooperative one didn't and the delta will be
        // small (which biases toward false positive on diesels — by
        // design, since a single low score won't push confidence past
        // the 0.7 user-warning threshold on its own).
        await Future<void>.delayed(_revDelay);
        final mapRevRaw = await port.sendRaw(_mapCommand);
        final mapRev = Elm327Parsers.parseManifoldPressureKpa(mapRevRaw);
        if (mapRev == null) return prior;
        observationScore = BrokenMapBeliefUpdater.revDeltaMissingScore(
          mapIdleKpa: mapIdle,
          mapRevvedKpa: mapRev,
        );
        reason = BrokenMapReason.revDeltaMissing;
      } else {
        // Petrol path: need baro to know the delta.
        final baroRaw = await port.sendRaw(_baroCommand);
        final baro = _parseBaroPressureKpa(baroRaw);
        if (baro == null) return prior;
        observationScore = BrokenMapBeliefUpdater.vacuumMissingScore(
          baroKpa: baro,
          mapKpa: mapIdle,
        );
        reason = BrokenMapReason.idleVacuumMissing;
      }

      return BrokenMapBeliefUpdater.update(
        prior,
        observationScore,
        now: now,
        reason: reason,
      );
    } catch (e, st) {
      // Transport blew up. Surface the failure but never derail the
      // caller — the populator finishes the pair flow either way.
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: const {
          'op': 'brokenMapDetector.probe',
        },
      );
      return prior;
    }
  }

  /// Weight on the discrepancy-severity term in the combined plein-
  /// complet observation. Spec § E pairs this with a 0.4 weight on the
  /// η_v implausibility term — discrepancy carries more signal because
  /// it's measured against pump receipts (ground truth) while the η_v
  /// path is one inferential step removed (depends on the integrator).
  static const double _discrepancyWeight = 0.6;

  /// Weight on the η_v-implausibility term. See [_discrepancyWeight].
  static const double _etaWeight = 0.4;

  /// Fold a plein-complet (full-tank reconciliation) observation into
  /// [prior] (#1423 phase 3).
  ///
  /// Combined score per spec § E:
  /// ```
  /// observationScore = 0.6 * discrepancySeverityScore(ratio)
  ///                  + 0.4 * etaImplausibilityScore(proposedEta)
  /// ```
  /// where `ratio = reconciledLPer100km / estimatedLPer100km`.
  ///
  /// When [proposedEta] is null (the [VeLearner] had no candidate to
  /// propose this cycle — e.g. distance under the gate, no integrated
  /// fuel) the η_v term drops out and the score collapses to the pure
  /// discrepancy severity. This avoids spuriously punishing a sensor
  /// just because the learner didn't have enough data to opine; it
  /// also avoids needing to invent a sentinel η_v value.
  ///
  /// Returns [prior] unchanged when:
  ///   * [estimatedLPer100km] is non-positive (can't form a ratio),
  ///   * [reconciledLPer100km] is non-positive (degenerate window).
  ///
  /// Pure — no I/O, no Hive, no Riverpod. Phase 4 will wrap the call
  /// in a persistence pathway; phase 3 stays caller-driven so unit
  /// tests can assert the score math without mocking storage.
  BrokenMapBelief recordPleinCompletObservation({
    required BrokenMapBelief prior,
    required double reconciledLPer100km,
    required double estimatedLPer100km,
    required double? proposedEta,
    required DateTime now,
  }) {
    if (estimatedLPer100km <= 0 || reconciledLPer100km <= 0) {
      return prior;
    }
    final ratio = reconciledLPer100km / estimatedLPer100km;
    final discrepancyScore = BrokenMapBeliefUpdater.discrepancySeverityScore(
      ratio: ratio,
    );

    double observationScore;
    BrokenMapReason reason;
    if (proposedEta == null) {
      // Learner had nothing to propose — fall back to discrepancy-only
      // weight (full weight on the only available signal). Reason tag
      // mirrors the dominant input so the diagnostic overlay can
      // explain the trigger.
      observationScore = discrepancyScore;
      reason = BrokenMapReason.pleinCompletDiscrepancy;
    } else {
      final etaScore = BrokenMapBeliefUpdater.etaImplausibilityScore(
        proposedEta: proposedEta,
      );
      observationScore =
          _discrepancyWeight * discrepancyScore + _etaWeight * etaScore;
      // Attribute the trigger to whichever input contributed more.
      // The updater gates [lastTrigger] on its own strong-observation
      // threshold, so passing the reason unconditionally is safe: weak
      // combined scores leave the prior trigger sticky.
      reason = etaScore > discrepancyScore
          ? BrokenMapReason.etaImplausible
          : BrokenMapReason.pleinCompletDiscrepancy;
    }

    return BrokenMapBeliefUpdater.update(
      prior,
      observationScore,
      now: now,
      reason: reason,
    );
  }
}

/// Parse Mode 01 PID 0x33 (absolute barometric pressure) response.
/// Single-byte payload, raw kPa (range 0-255). Returns null on NO DATA
/// / malformed / wrong-PID echo. Inlined here because the existing
/// [Elm327Parsers] catalog doesn't carry PID 0x33 (it isn't used
/// elsewhere yet — this detector is the first consumer).
double? _parseBaroPressureKpa(String raw) {
  final clean = Elm327Parsers.cleanResponse(raw);
  if (clean == null) return null;
  // Tokens look like '41 33 XX' — split on whitespace, validate the
  // mode-01 echo + PID, return the third byte.
  final tokens = clean
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.length < 3) return null;
  final mode = int.tryParse(tokens[0], radix: 16);
  final pid = int.tryParse(tokens[1], radix: 16);
  final value = int.tryParse(tokens[2], radix: 16);
  if (mode != 0x41 || pid != 0x33 || value == null) return null;
  return value.toDouble();
}
