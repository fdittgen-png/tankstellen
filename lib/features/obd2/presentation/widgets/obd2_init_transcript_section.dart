// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/obd2_session_diagnostic.dart';

/// The "Dongle init transcript" section of [Obd2DiagnosticsCard] (#2511,
/// Epic #2463) — renders the timed ELM327 initialization handshake that the
/// #2479 tees already captured into [Obd2SessionDiagnostic.initTranscript].
///
/// A summary header (`Protocol {digit} · warm|cold · firmware {ev} ·
/// {tier} · {N} PIDs`) over one monospace `cmd → response (latency ms)`
/// line per captured [Obd2HandshakeLine], oldest-first. Pulled out of the
/// card itself so the card stays under the 400-line file-length norm and
/// the handshake view is independently testable.
///
/// Purely presentational: it reads only the already-captured snapshot, adds
/// no new capture and touches no network/clipboard (the optional
/// handshake-only export lives on the dev-tools health screen). The caller
/// omits this widget entirely when the transcript is empty, so it always
/// has at least one line to draw.
///
/// The AT commands (`ATZ`, `ATE0`, …) and hex replies it shows are raw
/// adapter wire data, surfaced verbatim — not translatable copy.
class Obd2InitTranscriptSection extends StatelessWidget {
  /// The session whose [Obd2SessionDiagnostic.initTranscript] +
  /// adapter-identity fields this section renders.
  final Obd2SessionDiagnostic session;

  /// Discovered-supported PID count for the header (already tallied by
  /// `computeObd2DiagnosticsSummary` so this widget does no math).
  final int supportedCount;

  const Obd2InitTranscriptSection({
    super.key,
    required this.session,
    required this.supportedCount,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const dash = '—';

    final start = (session.warmStart ?? false)
        ? (l?.obd2DiagnosticsInitWarm ?? 'warm')
        : (l?.obd2DiagnosticsInitCold ?? 'cold');
    final header = l?.obd2DiagnosticsInitHeader(
          session.protocolDigit ?? dash,
          start,
          session.elmVersion ?? dash,
          session.capabilityTier ?? dash,
          supportedCount,
        ) ??
        'Protocol ${session.protocolDigit ?? dash} · $start · '
            'firmware ${session.elmVersion ?? dash} · '
            '${session.capabilityTier ?? dash} · $supportedCount PIDs';

    final mono = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Courier New'],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l?.obd2DiagnosticsInitSection ?? 'Dongle init transcript',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        Align(
          key: const Key('obd2_diag_init_header'),
          alignment: AlignmentDirectional.centerStart,
          child: Text(header, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < session.initTranscript.length; i++)
          Align(
            key: Key('obd2_diag_init_line_$i'),
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l?.obd2DiagnosticsInitLine(
                    session.initTranscript[i].cmd,
                    session.initTranscript[i].response,
                    session.initTranscript[i].latencyMs,
                  ) ??
                  '${session.initTranscript[i].cmd} → '
                      '${session.initTranscript[i].response} '
                      '(${session.initTranscript[i].latencyMs} ms)',
              style: mono,
            ),
          ),
      ],
    );
  }
}
