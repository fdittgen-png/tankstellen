// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../data/obd2/obd2_comm_diagnostics.dart';
import 'obd2_diagnostics_card.dart';

/// Trip-detail mounting of the [Obd2DiagnosticsCard] (#2470, Epic #2463),
/// beside the GPS diagnostics card.
///
/// Dev-only and self-hiding: it renders nothing unless [Feature.debugMode]
/// is on, so production trip-detail screens are byte-unchanged. When the
/// gate is on it shows the most recent finished session from the gated
/// `Obd2CommDiagnostics` collector (or the live one if none finished yet);
/// the card itself renders its empty state when the collector captured no
/// session, so a dev who never connected an adapter still sees a clean
/// "no session" hint rather than a blank.
///
/// The collector is a process-wide in-memory singleton (the OBD2 data
/// layer is Riverpod-free), so this widget reads it directly rather than
/// through a provider — matching how the dev-tools `Obd2HealthScreen`
/// surfaces it.
class Obd2DiagnosticsTripCard extends ConsumerWidget {
  const Obd2DiagnosticsTripCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugOn =
        ref.watch(enabledFeaturesProvider).contains(Feature.debugMode);
    if (!debugOn) return const SizedBox.shrink();

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
