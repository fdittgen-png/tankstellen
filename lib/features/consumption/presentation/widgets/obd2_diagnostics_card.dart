// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/obd2/obd2_diagnostics_summary.dart';
import '../../data/obd2/obd2_session_diagnostic.dart';

/// Read-only inspector card for one OBD2 communication-health session
/// (#2470, TAIL of Epic #2463) — the dev-tools analogue of
/// `GpsDiagnosticsCard`.
///
/// Renders the current [Obd2SessionDiagnostic] when [enabled] (the
/// `Obd2CommDiagnostics.instance.enabled` / `Feature.debugMode` gate) and
/// a session has been captured. When developer mode is off, or no session
/// exists yet, it renders a compact empty state instead — so a production
/// build (gate off) never shows a populated card.
///
/// The card is purely presentational. All math (per-PID worst-first
/// ordering, tri-state tally, per-tier rollup, header triple) lives in the
/// pure [computeObd2DiagnosticsSummary] helper so tests can assert the
/// numbers without pumping a widget tree.
///
/// Like `GpsDiagnosticsCard` it collapses by default; the collapsed header
/// gives the at-a-glance completeness · duty · drops triple and the
/// expanded body surfaces the full per-section breakdown the developer
/// clicks for.
class Obd2DiagnosticsCard extends StatelessWidget {
  /// The session to render — the live or last-finished
  /// `Obd2CommDiagnostics.snapshot()`.
  final Obd2SessionDiagnostic session;

  /// Whether the diagnostics collector is armed
  /// (`Obd2CommDiagnostics.instance.enabled`). When false the card always
  /// renders the empty state regardless of [session].
  final bool enabled;

  const Obd2DiagnosticsCard({
    super.key,
    required this.session,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary =
        enabled ? computeObd2DiagnosticsSummary(session) : Obd2DiagnosticsSummary.empty;

    final title = l?.obd2DiagnosticsTitle ?? 'OBD2 communication health';

    if (!summary.presentable) {
      return Card(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: ListTile(
          key: const Key('obd2_diagnostics_empty'),
          leading: const Icon(Icons.bluetooth_disabled_outlined),
          title: Text(title, style: theme.textTheme.titleMedium),
          subtitle: Text(
            l?.obd2DiagnosticsEmpty ??
                'No OBD2 session recorded yet — connect an adapter and '
                    'record a trip with Developer mode on.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final headerLine = l?.obd2DiagnosticsHeader(
          summary.completenessPercent.toString(),
          summary.activeDutyPercent.toString(),
          summary.drops,
        ) ??
        '${summary.completenessPercent}% complete · '
            '${summary.activeDutyPercent}% duty · ${summary.drops} drops';

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: ExpansionTile(
        // Stable selector for widget tests.
        key: const Key('obd2_diagnostics_tile'),
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(
          headerLine,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          _adapterSection(context, l, theme),
          _connectionSection(context, l, theme, summary),
          _pidSection(context, l, theme, summary),
          _schedulerSection(context, l, theme),
          _completenessSection(context, l, theme, summary),
          _supportSection(context, l, theme, summary),
          if (summary.fuelTotal > 0) _fuelSection(context, l, theme, summary),
          const SizedBox(height: 12),
          Text(
            l?.obd2DiagnosticsExplain ??
                'Captured while recording to debug the dongle↔app '
                    'communication — only collected in Developer mode.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );

  Widget _line(ThemeData theme, String text, {Key? key}) => Align(
        key: key,
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, style: theme.textTheme.bodyMedium),
      );

  // ---- Adapter identity -------------------------------------------------
  Widget _adapterSection(
    BuildContext context,
    AppLocalizations? l,
    ThemeData theme,
  ) {
    const dash = '—';
    final identity = l?.obd2DiagnosticsAdapterIdentity(
          session.redactedMac ?? dash,
          session.elmVersion ?? dash,
          session.protocolDigit ?? dash,
          session.mtu?.toString() ?? dash,
        ) ??
        '${session.redactedMac ?? dash} · ${session.elmVersion ?? dash} · '
            'protocol ${session.protocolDigit ?? dash} · '
            'MTU ${session.mtu?.toString() ?? dash}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          theme,
          l?.obd2DiagnosticsAdapterSection ?? 'Adapter',
        ),
        _line(theme, identity, key: const Key('obd2_diag_adapter_line')),
      ],
    );
  }

  // ---- Connection lifecycle --------------------------------------------
  Widget _connectionSection(
    BuildContext context,
    AppLocalizations? l,
    ThemeData theme,
    Obd2DiagnosticsSummary summary,
  ) {
    const dash = '—';
    final conn = session.connection;
    final p50 = conn.timeToConnectP50Ms?.toString() ?? dash;
    final p95 = conn.timeToConnectP95Ms?.toString() ?? dash;
    final line = l?.obd2DiagnosticsConnectionLine(
          conn.attempts,
          conn.successes,
          conn.drops,
          p50,
          p95,
        ) ??
        '${conn.attempts} attempts · ${conn.successes} ok · '
            '${conn.drops} drops · time-to-connect p50 $p50 / p95 $p95';
    final reconnects = l?.obd2DiagnosticsReconnectLine(
          conn.silentReconnects,
          conn.visibleReconnects,
        ) ??
        'Reconnects: ${conn.silentReconnects} silent · '
            '${conn.visibleReconnects} visible';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          theme,
          l?.obd2DiagnosticsConnectionSection ?? 'Connection lifecycle',
        ),
        _line(theme, line, key: const Key('obd2_diag_connection_line')),
        const SizedBox(height: 4),
        _line(theme, reconnects),
      ],
    );
  }

  // ---- Per-PID outcome table -------------------------------------------
  Widget _pidSection(
    BuildContext context,
    AppLocalizations? l,
    ThemeData theme,
    Obd2DiagnosticsSummary summary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          theme,
          l?.obd2DiagnosticsPidSection ?? 'Per-PID outcomes',
        ),
        for (final row in summary.pidRows)
          _line(
            theme,
            _pidRowText(l, row),
            key: Key('obd2_diag_pid_${row.pid}'),
          ),
      ],
    );
  }

  String _pidRowText(AppLocalizations? l, Obd2PidRowView row) {
    final s = row.stat;
    final eff = s.effectiveHz.toStringAsFixed(2);
    final target = s.targetHz.toStringAsFixed(2);
    return l?.obd2DiagnosticsPidRow(
          row.pid,
          s.polled,
          s.ok,
          s.noData,
          s.timeout,
          s.error,
          s.latencyP50Ms,
          s.latencyP95Ms,
          eff,
          target,
        ) ??
        '${row.pid}: ${s.polled} polled · ${s.ok} ok · ${s.noData} ND · '
            '${s.timeout} TO · ${s.error} err · '
            'p50 ${s.latencyP50Ms} / p95 ${s.latencyP95Ms} ms · '
            '$eff/$target Hz';
  }

  // ---- Scheduler health -------------------------------------------------
  Widget _schedulerSection(
    BuildContext context,
    AppLocalizations? l,
    ThemeData theme,
  ) {
    final sch = session.scheduler;
    final tickRate = sch.tickRateHz.toStringAsFixed(1);
    final line = l?.obd2DiagnosticsSchedulerLine(
          tickRate,
          sch.backpressureSkips,
          sch.demotions,
        ) ??
        '$tickRate Hz tick · ${sch.backpressureSkips} back-pressure skips · '
            '${sch.demotions} demotions';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          theme,
          l?.obd2DiagnosticsSchedulerSection ?? 'Scheduler health',
        ),
        _line(theme, line, key: const Key('obd2_diag_scheduler_line')),
        if (sch.starved) ...[
          const SizedBox(height: 4),
          Align(
            key: const Key('obd2_diag_starved'),
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l?.obd2DiagnosticsStarved ??
                  'Dynamics tier starved — RPM / speed fell below the '
                      'governor floor.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---- Completeness rollup ---------------------------------------------
  Widget _completenessSection(
    BuildContext context,
    AppLocalizations? l,
    ThemeData theme,
    Obd2DiagnosticsSummary summary,
  ) {
    final overall = l?.obd2DiagnosticsCompletenessLine(
          summary.completenessPercent.toString(),
          summary.activeDutyPercent.toString(),
        ) ??
        'Overall ${summary.completenessPercent}% · '
            'active duty ${summary.activeDutyPercent}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          theme,
          l?.obd2DiagnosticsCompletenessSection ?? 'Completeness',
        ),
        _line(theme, overall, key: const Key('obd2_diag_completeness_line')),
        for (final entry in summary.perTierPercent.entries)
          _line(
            theme,
            l?.obd2DiagnosticsTierLine(entry.key, entry.value.toString()) ??
                '${entry.key}: ${entry.value}%',
            key: Key('obd2_diag_tier_${entry.key}'),
          ),
      ],
    );
  }

  // ---- Discovered-supported tri-state ----------------------------------
  Widget _supportSection(
    BuildContext context,
    AppLocalizations? l,
    ThemeData theme,
    Obd2DiagnosticsSummary summary,
  ) {
    final line = l?.obd2DiagnosticsSupportLine(
          summary.supportedCount,
          summary.unsupportedCount,
          summary.unknownCount,
        ) ??
        '${summary.supportedCount} supported · '
            '${summary.unsupportedCount} unsupported · '
            '${summary.unknownCount} unknown';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          theme,
          l?.obd2DiagnosticsSupportSection ?? 'Discovered-supported PIDs',
        ),
        _line(theme, line, key: const Key('obd2_diag_support_line')),
      ],
    );
  }

  // ---- Fuel-tier rollup -------------------------------------------------
  Widget _fuelSection(
    BuildContext context,
    AppLocalizations? l,
    ThemeData theme,
    Obd2DiagnosticsSummary summary,
  ) {
    final line = l?.obd2DiagnosticsFuelLine(
          summary.fuelSuspicious,
          summary.fuelTotal,
        ) ??
        'Suspicious ${summary.fuelSuspicious} of ${summary.fuelTotal} '
            'samples';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          theme,
          l?.obd2DiagnosticsFuelSection ?? 'Fuel-tier rollup',
        ),
        _line(theme, line, key: const Key('obd2_diag_fuel_line')),
      ],
    );
  }
}
