// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The recognition-priority table of #4213 (Epic #4211), as one pure
/// function over primitive signals.
///
/// The whole point of this file is that the app **never silently
/// guesses**. GPS, an OBD2 adapter or a VIN read can *propose* a
/// vehicle; only the driver can choose one. When two machine signals
/// disagree the resolver refuses to pick — the surface shows "vehicle
/// needs confirmation" and automatic attribution pauses until the
/// driver resolves it.
///
/// Signals arrive as plain strings (an adapter device id, a VIN), so
/// nothing here imports another feature.
library;

import '../../../core/time/app_clock.dart';
import 'vehicle_attribution.dart';

export 'vehicle_attribution.dart';

/// One piece of evidence pointing at a fleet vehicle.
class VehicleSignal {
  const VehicleSignal({
    required this.source,
    required this.fleetVehicleId,
    required this.confidence,
    this.localVehicleId,
    this.evidence = const <String>[],
  });

  final VehicleAttributionSource source;
  final String fleetVehicleId;

  /// The driver's local `VehicleProfile.id`, when the signal knows it.
  final String? localVehicleId;

  /// 0..1. An automatic signal below
  /// [VehicleAttributionResolver.minimumAutomaticConfidence] is never
  /// attributed on its own — #4213: "Low-confidence attribution must
  /// not enter fleet reporting as fact."
  final double confidence;

  /// Short, non-personal strings naming what was observed
  /// (`adapter:AA:BB…`, `vin:WVW…`). They are persisted with the
  /// attribution and shown in the confirmation state.
  final List<String> evidence;
}

/// What [VehicleAttributionResolver.resolve] concluded.
enum VehicleAttributionVerdict {
  /// A vehicle is attributed. [VehicleAttributionResolution.attribution]
  /// is non-null.
  confirmed,

  /// Signals exist but the app refuses to choose — conflicting
  /// automatic evidence, an automatic signal too weak to stand alone,
  /// or a search hit (which never attributes). The UI shows the
  /// "vehicle needs confirmation" state and automatic attribution
  /// pauses.
  needsConfirmation,

  /// No signal at all. Not an error, and not a conflict.
  none,
}

/// The outcome of resolving a set of signals.
class VehicleAttributionResolution {
  const VehicleAttributionResolution._(
    this.verdict, {
    this.attribution,
    this.candidates = const <String>[],
    this.evidence = const <String>[],
  });

  const VehicleAttributionResolution.none()
      : this._(VehicleAttributionVerdict.none);

  const VehicleAttributionResolution.confirmed(VehicleAttribution attribution)
      : this._(VehicleAttributionVerdict.confirmed, attribution: attribution);

  const VehicleAttributionResolution.needsConfirmation({
    required List<String> candidates,
    List<String> evidence = const <String>[],
  }) : this._(VehicleAttributionVerdict.needsConfirmation,
            candidates: candidates, evidence: evidence);

  final VehicleAttributionVerdict verdict;

  /// Non-null exactly when [verdict] is
  /// [VehicleAttributionVerdict.confirmed].
  final VehicleAttribution? attribution;

  /// The fleet vehicle ids the signals pointed at, in priority order.
  /// Populated on [VehicleAttributionVerdict.needsConfirmation] so the
  /// sheet can offer exactly the cars that were proposed.
  final List<String> candidates;

  /// The conflicting evidence, for the confirmation state's detail.
  final List<String> evidence;

  bool get needsConfirmation =>
      verdict == VehicleAttributionVerdict.needsConfirmation;
}

/// The recognition-priority table of #4213, as one pure function.
class VehicleAttributionResolver {
  const VehicleAttributionResolver._();

  /// An automatic signal weaker than this never attributes on its own.
  /// Corroboration does not raise a signal past it: two weak signals
  /// agreeing are still two weak signals.
  static const double minimumAutomaticConfidence =
      kMinimumAutomaticAttributionConfidence;

  /// Apply the priority table to [signals].
  ///
  /// In order:
  ///
  ///   1. **Any explicit signal wins.** If two explicit signals name
  ///      different vehicles the resolver still refuses (a caller bug
  ///      must not become a silent pick), otherwise the explicit
  ///      vehicle is confirmed at confidence 1.0 whatever the adapter,
  ///      VIN or QR say.
  ///   2. Otherwise only [VehicleAttributionSource.adapterIdentity],
  ///      [VehicleAttributionSource.vin] and
  ///      [VehicleAttributionSource.qr] can attribute. A
  ///      [VehicleAttributionSource.search] hit is a search aid and is
  ///      ignored here — it reaches an attribution only by the driver
  ///      tapping the result, which arrives as `explicit`.
  ///   3. Automatic signals naming **different** vehicles →
  ///      [VehicleAttributionVerdict.needsConfirmation]. This is the
  ///      adapter-vs-VIN case #4213 names explicitly.
  ///   4. Automatic signals that agree → confirmed on the
  ///      highest-priority source, at the best confidence among them,
  ///      with every agreeing signal's evidence attached — unless that
  ///      confidence is below [minimumAutomaticConfidence], which is
  ///      again `needsConfirmation`.
  ///   5. Nothing usable at all → [VehicleAttributionVerdict.none],
  ///      except that a search-only set asks for confirmation (there
  ///      *is* something on screen to confirm).
  static VehicleAttributionResolution resolve(
    Iterable<VehicleSignal> signals, {
    required AppClock clock,
  }) {
    final all = signals.toList()
      ..sort((a, b) => a.source.index.compareTo(b.source.index));
    if (all.isEmpty) return const VehicleAttributionResolution.none();

    final explicit = [
      for (final s in all)
        if (s.source == VehicleAttributionSource.explicit) s,
    ];
    if (explicit.isNotEmpty) {
      final ids = {for (final s in explicit) s.fleetVehicleId};
      if (ids.length > 1) {
        return VehicleAttributionResolution.needsConfirmation(
          candidates: ids.toList()..sort(),
          evidence: [for (final s in explicit) ...s.evidence],
        );
      }
      final winner = explicit.first;
      return VehicleAttributionResolution.confirmed(
        VehicleAttribution(
          fleetVehicleId: winner.fleetVehicleId,
          localVehicleId: winner.localVehicleId,
          source: VehicleAttributionSource.explicit,
          confidence: 1,
          evidence: _evidenceOf(all, winner.fleetVehicleId),
          at: clock.now().toUtc(),
        ),
      );
    }

    final automatic = [
      for (final s in all)
        if (s.source.isAutomaticEvidence) s,
    ];
    if (automatic.isEmpty) {
      // Search-only: something is on screen, nothing is attributed.
      return VehicleAttributionResolution.needsConfirmation(
        candidates: _idsOf(all),
        evidence: [for (final s in all) ...s.evidence],
      );
    }

    final ids = _idsOf(automatic);
    if (ids.length > 1) {
      return VehicleAttributionResolution.needsConfirmation(
        candidates: ids,
        evidence: [for (final s in automatic) ...s.evidence],
      );
    }

    final agreeing = [
      for (final s in automatic)
        if (s.fleetVehicleId == ids.single) s,
    ];
    final best = agreeing
        .map((s) => s.confidence)
        .reduce((a, b) => a > b ? a : b);
    if (best < minimumAutomaticConfidence) {
      return VehicleAttributionResolution.needsConfirmation(
        candidates: ids,
        evidence: [for (final s in agreeing) ...s.evidence],
      );
    }
    final winner = agreeing.first; // already priority-sorted
    return VehicleAttributionResolution.confirmed(
      VehicleAttribution(
        fleetVehicleId: winner.fleetVehicleId,
        localVehicleId: agreeing
            .map((s) => s.localVehicleId)
            .firstWhere((id) => id != null, orElse: () => null),
        source: winner.source,
        confidence: best,
        evidence: _evidenceOf(all, winner.fleetVehicleId),
        at: clock.now().toUtc(),
      ),
    );
  }

  /// Distinct fleet vehicle ids of [signals], in priority order.
  static List<String> _idsOf(List<VehicleSignal> signals) {
    final seen = <String>[];
    for (final s in signals) {
      if (!seen.contains(s.fleetVehicleId)) seen.add(s.fleetVehicleId);
    }
    return seen;
  }

  /// Evidence of every signal that agreed on [fleetVehicleId],
  /// priority-ordered and de-duplicated.
  static List<String> _evidenceOf(
      List<VehicleSignal> signals, String fleetVehicleId) {
    final out = <String>[];
    for (final s in signals) {
      if (s.fleetVehicleId != fleetVehicleId) continue;
      for (final e in s.evidence) {
        if (!out.contains(e)) out.add(e);
      }
    }
    return out;
  }
}
