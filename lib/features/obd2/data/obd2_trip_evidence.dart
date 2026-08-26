// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// What a recorded trip can prove about its OBD2 session WITHOUT the per-PID
/// communication instrument (#3824).
///
/// The field report that motivated this: a trip with 324 engine-bearing
/// samples at 99.7% coverage, `fuelSource: "measured"`, protocol `answered`
/// and a named adapter rendered as *"No OBD2 session recorded — connect an
/// adapter and record a trip with developer mode enabled."*
///
/// The cause is a conflation. [Obd2SessionDiagnostic] measures per-PID poll
/// outcomes and exists only while the `Obd2CommDiagnostics` collector is
/// armed; it is NOT the answer to "did this trip have OBD2". A trip can
/// record a flawless session and still carry no PID diagnostic, and the card
/// printed the strongest possible negative claim from that much weaker
/// absence.
///
/// This type carries the evidence the trip record *does* always have, so the
/// card can say something true instead. Deliberately primitives-only: it is
/// built at the trip-detail call site and passed down, so the OBD2 feature
/// never imports `TripHistoryEntry` (see the feature-boundary rule that
/// `feature_boundary_test` enforces).
class Obd2TripEvidence {
  const Obd2TripEvidence({
    required this.engineSamples,
    required this.totalSamples,
    required this.coverageShare,
    this.adapterName,
    this.adapterMac,
    this.protocolVerdict,
    this.terminationReason,
    this.duration,
    this.fuelMeasured = false,
  });

  /// Samples carrying at least one engine PID — `Obd2EngineCoverage`'s
  /// `engineSamples`, computed with the same predicate the fuel pipeline
  /// uses, so the card can never disagree with the fuel chart.
  final int engineSamples;

  /// All recorded samples, engine-bearing or not.
  final int totalSamples;

  /// `engineSamples / totalSamples`, 0..1.
  final double coverageShare;

  final String? adapterName;

  /// Raw adapter MAC. Rendered through [redactedMac] — never in full.
  final String? adapterMac;

  /// Verdict from the link journal's `protocolVerdict` event, e.g.
  /// `answered`. Null on trips recorded before the #3797/#3798 journal.
  final String? protocolVerdict;

  /// `TripTermination.reason.name`, e.g. `userStopped`.
  final String? terminationReason;

  final Duration? duration;

  /// True when fuel came from the adapter rather than GPS physics — the
  /// single most persuasive proof that OBD2 genuinely worked.
  final bool fuelMeasured;

  /// Whether this trip carries ANY proof of an OBD2 session.
  ///
  /// One engine-bearing sample is enough: it cannot exist without the
  /// adapter having answered. A trip with a named adapter but zero engine
  /// samples is deliberately NOT evidence — that is the genuine
  /// "connected but delivered nothing" case, which the existing empty
  /// state already describes correctly.
  bool get hasObd2 => engineSamples > 0;

  /// Coverage as a whole percent, for display.
  int get coveragePercent => (coverageShare * 100).round();

  /// Last four MAC characters only, matching how `Obd2SessionDiagnostic`
  /// reports adapter identity. Null when there is no MAC to redact.
  String? get redactedMac {
    final mac = adapterMac;
    if (mac == null || mac.isEmpty) return null;
    final compact = mac.replaceAll(':', '').replaceAll('-', '');
    if (compact.length <= 4) return compact.toUpperCase();
    return '…${compact.substring(compact.length - 4).toUpperCase()}';
  }

  /// Adapter identity for display: name, MAC tail, or null when neither
  /// was recorded.
  String? get adapterLabel {
    final name = adapterName?.trim();
    final mac = redactedMac;
    if (name != null && name.isNotEmpty && mac != null) return '$name ($mac)';
    if (name != null && name.isNotEmpty) return name;
    return mac;
  }
}
