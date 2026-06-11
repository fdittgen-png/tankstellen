// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/obd2_connect_trace.dart';

/// One connect-attempt trace rendered on the OBD2 health screen (#2969).
///
/// This is the card that is NON-EMPTY on a FAILED connect — the artefact the
/// user's #1 complaint was about. Shows the origin, requested vs resolved
/// transport + the decision reason, the scan list (device + RSSI), the per-step
/// timeline (incl. the AT exchange), and the BOLD final outcome + failureDetail.
///
/// Dev-only (the host screen is debugMode-gated). The enum names shown for the
/// outcome / origin / transport are debug content — the same category as a raw
/// `ATZ` transcript token — so they are exempt from ARB; the surrounding field
/// labels are localised.
class Obd2ConnectTraceCard extends StatelessWidget {
  const Obd2ConnectTraceCard({super.key, required this.trace});

  final Obd2ConnectTrace trace;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final failed = trace.outcome != Obd2ConnectOutcome.success;
    final accent = failed ? cs.error : cs.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // #3014 — ADAPTER NAME headline (the maintainer's #1 trace-tool ask:
            // a by-MAC / self-test attempt showed only the redacted MAC, so you
            // couldn't tell WHICH adapter failed). Falls back to the redacted
            // MAC when the name couldn't be resolved (an anonymous advertiser).
            Text(
              trace.adapterName ??
                  trace.requestedMac ??
                  (l.obd2HealthConnectUnknownAdapter),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Outcome headline (bold) — the answer to "why didn't it connect".
            Row(
              children: [
                Icon(
                  failed ? Icons.error_outline : Icons.check_circle_outline,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l.obd2HealthConnectOutcome}: '
                    '${trace.outcome?.name ?? 'in progress'}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trace.totalMs != null)
                  Text(
                    '${trace.totalMs} ms', // i18n-ignore: ms unit format mask
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (trace.failureDetail != null) ...[
              const SizedBox(height: 4),
              Text(
                trace.failureDetail!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 6),
            _kv(theme, l.obd2HealthConnectOrigin, trace.origin.name),
            _kv(theme, l.obd2HealthConnectTransport, _transportLine(trace)),
            if (trace.requestedMac != null)
              _kv(theme, 'MAC', trace.requestedMac!), // i18n-ignore: MAC label
            if (trace.scanned.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                l.obd2HealthConnectScanList,
                style: theme.textTheme.labelMedium,
              ),
              for (final d in trace.scanned)
                Text(
                  '· ${d.name ?? d.redactedMac ?? '?'}'
                  '${d.rssi != null ? ' (${d.rssi} dBm)' : ''}' // i18n-ignore: dBm unit mask
                  '${d.matchedProfileId != null ? ' → ${d.matchedProfileId}' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
            if (trace.steps.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                l.obd2HealthConnectSteps,
                style: theme.textTheme.labelMedium,
              ),
              for (final s in trace.steps)
                Text(
                  '· ${s.label} — ${s.status.name}'
                  '${s.endMs != null ? ' @${s.endMs}ms' : ''}' // i18n-ignore: ms unit mask
                  '${s.detail != null && s.detail!.isNotEmpty ? ' — ${s.detail}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: s.status == Obd2ConnectStepStatus.ok
                        ? cs.onSurfaceVariant
                        : cs.error,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _transportLine(Obd2ConnectTrace t) {
    final req = t.requestedTransport.name;
    final res = t.resolvedTransport?.name;
    final reason = t.transportDecisionReason;
    final base = res != null && res != req ? '$req → $res' : req;
    return reason != null ? '$base ($reason)' : base;
  }

  Widget _kv(ThemeData theme, String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$k: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextSpan(text: v, style: theme.textTheme.bodySmall),
        ],
      ),
    ),
  );
}
