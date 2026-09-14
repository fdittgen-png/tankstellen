// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../l10n/app_localizations.dart';
import '../domain/data_value.dart';
import 'duration_formatter.dart';

/// How a [DataValue] reaches the user (#4160).
///
/// The `≈` of `docs/specs/refuel-economics.md` trust rule 2 is a property
/// of the TYPE here, not of each call site remembering to add it: a
/// widget formats the number and hands it to [qualify], and an
/// [Estimated] comes back qualified whether or not the author thought
/// about it. That is the whole reason the provenance travels with the
/// value.
///
/// [DataUnknownReason] and [DataBasis] are closed enums precisely so the
/// text they produce is an ARB key (HARD RULE #1) rather than the
/// developer prose a free-form `String reason` invites.
extension DataValueLabels<T> on DataValue<T> {
  /// [formatted] — already a display string for the value — wrapped in
  /// whatever caveat this provenance requires, or the reason when there
  /// is no value to show.
  ///
  /// Measured passes through untouched: a figure the user themselves
  /// produced should not be decorated as though we were hedging.
  String qualify(AppLocalizations l, String Function(T value) formatted) =>
      switch (this) {
        Measured<T>(:final value) => formatted(value),
        Estimated<T>(:final value) => l.dataApproximate(formatted(value)),
        Stale<T>(:final value, :final age) =>
          l.dataStale(formatted(value), formatElapsedDuration(l, age)),
        Unknown<T>(:final reason) => reason.label(l),
      };

  /// The one-line caveat to put UNDER a figure, or null when none is
  /// needed. For surfaces that want the number unadorned and the
  /// qualification as its own line (the stat tiles of #3950, whose
  /// figures are a tied visual grammar that `≈` inside would break).
  String? caveat(AppLocalizations l) => switch (this) {
        Measured<T>() => null,
        Estimated<T>(:final basis) => basis.label(l),
        Stale<T>(:final age) => l.dataLastSeen(formatElapsedDuration(l, age)),
        Unknown<T>(:final reason) => reason.label(l),
      };
}

/// Why a value is missing, in the user's language.
extension DataUnknownReasonLabel on DataUnknownReason {
  String label(AppLocalizations l) => switch (this) {
        DataUnknownReason.notPublishedByProvider => l.dataUnknownProvider,
        DataUnknownReason.notPublishedForThisItem => l.dataUnknownItem,
        DataUnknownReason.notMeasuredYet => l.dataUnknownNotMeasured,
        DataUnknownReason.missingVehicleData => l.dataUnknownVehicle,
        DataUnknownReason.unreadable => l.dataUnknownUnreadable,
      };
}

/// What an estimate rests on, in the user's language.
extension DataBasisLabel on DataBasis {
  String label(AppLocalizations l) => switch (this) {
        DataBasis.vehicleCatalog => l.dataBasisCatalog,
        DataBasis.fleetAverage => l.dataBasisFleetAverage,
        DataBasis.derived => l.dataBasisDerived,
      };
}
