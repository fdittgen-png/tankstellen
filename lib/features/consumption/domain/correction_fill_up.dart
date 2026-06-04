// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'entities/fill_up.dart';

/// Identity + filtering helpers for OBD2-estimate reconciliation
/// "correction" fill-ups (#1361 / #2834).
///
/// A correction record is the synthetic stand-in the reconciler emits to
/// close the gap between OBD-integrated trip fuel and pumped litres over a
/// plein-to-plein window. It is DERIVED data — `TotalCost = 0`,
/// `IsFullTank = false`, an unrounded litres figure — not a fuel purchase
/// the user made. It must never surface as a real fill-up nor land in a
/// backup, where it would be re-imported as a phantom zero-cost fill-up and
/// re-exported forever.

/// Id prefix the reconciler stamps on every correction fill-up
/// (`correction_<closingPleinId>`). This is the DURABLE signal: the v1
/// backup XML round-trip does not carry the [FillUp.isCorrection] flag, so
/// a restored correction comes back with `isCorrection == false`. Matching
/// the id prefix recovers its true nature regardless of the flag.
const String correctionFillUpIdPrefix = 'correction_';

/// True when [fillUp] is a reconciliation correction record (#2834).
///
/// Recognised by EITHER the explicit [FillUp.isCorrection] flag (the
/// in-app path) OR the `correction_` id prefix (the durable backup-safe
/// signal, since the flag is lost across a v1 backup round-trip).
bool isReconciliationCorrection(FillUp fillUp) =>
    fillUp.isCorrection || fillUp.id.startsWith(correctionFillUpIdPrefix);

/// [fillUps] with every reconciliation correction removed (#2834).
///
/// Used by the backup export + import paths so a correction is neither
/// written into a backup nor restored from one as a real fill-up.
List<FillUp> withoutReconciliationCorrections(Iterable<FillUp> fillUps) =>
    fillUps.where((f) => !isReconciliationCorrection(f)).toList(growable: false);
