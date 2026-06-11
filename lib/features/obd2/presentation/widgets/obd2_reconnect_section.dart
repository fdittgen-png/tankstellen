// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/obd2_diagnostics_summary.dart';

/// The "Reconnect telemetry" section of [Obd2DiagnosticsCard] (#2905, head
/// of Epic #2904).
///
/// Surfaces the per-reconnect-attempt + session-state-transition rollup the
/// pure [computeObd2DiagnosticsSummary] pre-computed: the attempt / success /
/// transition / typed-drop counts, the failed-attempt reason tally, and the
/// GPS-only-fallback-activation marker. The aggregate connection block can't
/// diagnose a reconnect failure — this can.
///
/// Pulled into its own widget so the card stays under the 400-line norm and
/// the reconnect view is independently testable. Purely presentational — it
/// reads only the already-computed summary and adds no new capture. The
/// caller omits it entirely when there is no reconnect signal.
class Obd2ReconnectSection extends StatelessWidget {
  /// The pre-rolled summary whose reconnect fields this section renders.
  final Obd2DiagnosticsSummary summary;

  const Obd2ReconnectSection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final line = l.obd2DiagnosticsReconnectAttemptsLine(
      summary.reconnectAttemptCount,
      summary.reconnectSuccessCount,
      summary.transitionCount,
      summary.disconnectExceptions,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l.obd2DiagnosticsReconnectSection,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        _line(theme, line, key: const Key('obd2_diag_reconnect_line')),
        for (final entry in summary.reconnectReasonCounts.entries)
          _line(
            theme,
            l.obd2DiagnosticsReconnectReasonLine(entry.key, entry.value),
            key: Key('obd2_diag_reconnect_reason_${entry.key}'),
          ),
        if (summary.fallbackActivated) ...[
          const SizedBox(height: 4),
          _line(
            theme,
            l.obd2DiagnosticsFallbackLine,
            key: const Key('obd2_diag_fallback_line'),
          ),
        ],
      ],
    );
  }

  Widget _line(ThemeData theme, String text, {Key? key}) => Align(
    key: key,
    alignment: AlignmentDirectional.centerStart,
    child: Text(text, style: theme.textTheme.bodyMedium),
  );
}
