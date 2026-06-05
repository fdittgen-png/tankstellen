// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../data/obd2/obd2_comm_diagnostics.dart';
import '../../data/obd2/obd2_session_diagnostic.dart';
import 'obd2_diagnostics_card.dart';

/// Trip-detail mounting of the [Obd2DiagnosticsCard] (#2470, Epic #2463),
/// beside the GPS diagnostics card.
///
/// Dev-only and self-hiding: it renders nothing unless [Feature.debugMode]
/// is on, so production trip-detail screens are byte-unchanged.
///
/// #2912 — the card used to read the process-wide in-memory
/// `Obd2CommDiagnostics.instance` singleton (its `finishedSessions.last` /
/// live `snapshot()`), which is **NOT** the viewed trip's diagnostic: it is
/// wiped on app restart and not tied to a trip, so every past trip showed the
/// same global last-session / live snapshot — i.e. "always empty" once the
/// process restarted, the field-reported bug. The fix persists an
/// [Obd2SessionDiagnostic] on the trip record at trip finish and threads it
/// in here as [tripDiagnostic]:
///   * when the viewed trip carries a persisted diagnostic, the card renders
///     THAT trip's health — per-trip, restart-durable;
///   * when it is null (the just-finished / in-progress trip whose record
///     hasn't been re-read, or a debug session captured this run), the card
///     falls back to the live singleton — the same source the dev-tools
///     `Obd2HealthScreen` keeps using.
///
/// The collector is a process-wide singleton (the OBD2 data layer is
/// Riverpod-free), so the live fallback reads it directly rather than through
/// a provider.
class Obd2DiagnosticsTripCard extends ConsumerWidget {
  /// The diagnostic persisted with the viewed trip (#2912), or null for a
  /// trip recorded before this field landed / with developer mode off / that
  /// never touched OBD2. Null falls back to the live singleton.
  final Obd2SessionDiagnostic? tripDiagnostic;

  const Obd2DiagnosticsTripCard({super.key, this.tripDiagnostic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugOn =
        ref.watch(enabledFeaturesProvider).contains(Feature.debugMode);
    if (!debugOn) return const SizedBox.shrink();

    // Prefer the trip's own persisted diagnostic; the card renders its empty
    // state when nothing is presentable, so the persisted path is always
    // "enabled" (the trip captured it under the same debug gate). Only when
    // the trip carries none do we fall back to the live collector for the
    // just-finished / in-progress trip.
    final persisted = tripDiagnostic;
    if (persisted != null) {
      return Obd2DiagnosticsCard(session: persisted, enabled: true);
    }

    final collector = Obd2CommDiagnostics.instance;
    final session = collector.finishedSessions.isNotEmpty
        ? collector.finishedSessions.last
        : collector.snapshot();
    return Obd2DiagnosticsCard(
      session: session,
      enabled: collector.enabled,
    );
  }
}
