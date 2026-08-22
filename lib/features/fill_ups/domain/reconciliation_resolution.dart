// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// Which path the user chose in the guided reconciliation workflow
/// (Epic #2439 / #2442). The workflow NEVER creates a correction or a
/// virtual trajet without the user landing on one of the apply paths —
/// [deferred] explicitly creates nothing and keeps the gap.
enum ReconciliationPath {
  /// Path A (#2443) — the user said a fill-up is missing/mistyped, so
  /// the gap is closed by a consented correction fill-up.
  correctFillUp,

  /// Path B (#2444) — the user confirmed their fill-ups are correct and
  /// a drive went unrecorded (this also covers the "both sides
  /// individually correct → by elimination the gap is unrecorded
  /// driving" case), so the gap is closed by a virtual trajet.
  virtualTrajet,

  /// "Decide later" — nothing is created and the pending gap is kept
  /// intact (#2445 owns the full re-entry surface). The workflow simply
  /// returns without applying anything.
  deferred,
}

/// The outcome of the guided reconciliation workflow (#2442) — the
/// chosen [path] plus the minimal user-gathered figures the apply step
/// needs.
///
/// Immutable value object, codegen-free (mirrors the hand-written
/// `@immutable` style of the other reconciliation domain types) so it
/// stays trivially unit-testable.
@immutable
class ReconciliationResolution {
  /// Which resolution the user landed on.
  final ReconciliationPath path;

  /// Path A — the (possibly user-edited) litres for the correction
  /// fill-up. Null for the other paths.
  final double? correctionLiters;

  /// Path B — the (possibly user-edited) distance of the unrecorded
  /// drive, in km. Null for the other paths.
  final double? virtualDistanceKm;

  const ReconciliationResolution._({
    required this.path,
    this.correctionLiters,
    this.virtualDistanceKm,
  });

  /// Path A resolution carrying the consented (possibly edited)
  /// correction litres.
  const ReconciliationResolution.correctFillUp(double liters)
      : this._(
          path: ReconciliationPath.correctFillUp,
          correctionLiters: liters,
        );

  /// Path B resolution carrying the consented gap litres + the
  /// user-supplied distance of the unrecorded drive.
  const ReconciliationResolution.virtualTrajet({
    required double distanceKm,
  }) : this._(
          path: ReconciliationPath.virtualTrajet,
          virtualDistanceKm: distanceKm,
        );

  /// "Decide later" — nothing is created, the gap is kept.
  const ReconciliationResolution.deferred()
      : this._(path: ReconciliationPath.deferred);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReconciliationResolution &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          correctionLiters == other.correctionLiters &&
          virtualDistanceKm == other.virtualDistanceKm;

  @override
  int get hashCode => Object.hash(path, correctionLiters, virtualDistanceKm);
}
