import 'eco_route_candidate.dart';

/// Pure scoring math for the eco strategy (#1123).
///
/// Pulled out of [`EcoRouteSearchStrategy`] so the weighting
/// formula and its tuning constants live in one short, well-tested
/// file. The strategy class delegates to these helpers; they have
/// no Flutter or networking dependencies and are trivial to fuzz.
///
/// Formula:
///
///     weight = time_minutes
///            + alpha × elevationGainMeters
///            + beta  × speedVariancePenalty
///
/// When OSRM returns no elevation profile (the public demo server
/// strips it), the elevation term is dropped and the formula
/// degrades to `time + beta × speedVariance` — see [scoreCandidate].
class EcoRouteScoring {
  const EcoRouteScoring._();

  /// Cost in `score units` per metre of cumulative elevation gain.
  ///
  /// Tuning rationale: a typical 100 km highway leg with 200 m of
  /// gain represents ~+0.3 L of fuel for a 7 L/100 km vehicle.
  /// We want that to *outweigh* a +5 minute detour penalty around
  /// the gain — so 1 m ≈ 0.05 minutes of equivalent "cost" puts
  /// 200 m of climb on par with a 10 minute detour. That feels
  /// right for "ship the flatter route unless it's wildly slower".
  static const double alpha = 0.05;

  /// Cost in `score units` per (km/h)² of speed variance across
  /// route legs. Highway-only candidates have variance ≈ 0;
  /// city + highway mixes can hit 600–900 km²/h². The constant
  /// 0.02 makes a variance of 500 worth ~10 minutes of equivalent
  /// detour, which discourages stop-and-go shortcuts.
  static const double beta = 0.02;

  /// Cap on how much slower the eco choice may be vs the fastest
  /// candidate. Above this ratio the eco strategy gives up on the
  /// alternative and re-selects the fastest, on the theory that
  /// the user came to drive, not to crawl. Matches the issue's
  /// "≤ 15 % slower" acceptance bullet.
  static const double maxSlowdownRatio = 1.15;

  /// Score a single candidate. Public so tests can pin the
  /// weighting math without going through OSRM.
  static double scoreCandidate(EcoRouteCandidate c) {
    final elevTerm =
        c.elevationGainMeters == null ? 0.0 : alpha * c.elevationGainMeters!;
    final variance = speedVariance(c.legSpeedsKmh);
    final varianceTerm = beta * variance;
    return c.durationMinutes + elevTerm + varianceTerm;
  }

  /// Select the eco-best candidate from a list. Returns the
  /// fastest candidate when:
  ///   * the list is empty (caller-side error — never hits here
  ///     in practice),
  ///   * only one candidate exists,
  ///   * every alternative is more than [maxSlowdownRatio] slower
  ///     than the fastest.
  ///
  /// Otherwise returns the lowest-weight candidate within the
  /// slowdown cap.
  static EcoRouteCandidate selectEcoRoute(List<EcoRouteCandidate> candidates) {
    if (candidates.isEmpty) {
      throw ArgumentError('selectEcoRoute requires at least one candidate');
    }
    if (candidates.length == 1) return candidates.first;

    final fastest = candidates
        .reduce((a, b) => a.durationMinutes <= b.durationMinutes ? a : b);
    final cap = fastest.durationMinutes * maxSlowdownRatio;

    EcoRouteCandidate best = fastest;
    double bestScore = scoreCandidate(fastest);
    for (final c in candidates) {
      if (c.durationMinutes > cap) continue;
      final s = scoreCandidate(c);
      if (s < bestScore) {
        bestScore = s;
        best = c;
      }
    }
    return best;
  }

  /// Population variance of the per-leg speeds. Returns 0 for
  /// empty/single-element lists (no penalty when we have no signal).
  static double speedVariance(List<double> speeds) {
    if (speeds.length < 2) return 0;
    final mean = speeds.reduce((a, b) => a + b) / speeds.length;
    double sumSq = 0;
    for (final s in speeds) {
      final d = s - mean;
      sumSq += d * d;
    }
    return sumSq / speeds.length;
  }
}
