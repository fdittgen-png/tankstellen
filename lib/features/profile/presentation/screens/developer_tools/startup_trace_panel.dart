// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/perf/startup_timer.dart';
import '../../../../../core/perf/startup_trace_export.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/section_header.dart';
import '../../../../../core/widgets/snackbar_helper.dart';
import '../../../../../l10n/app_localizations.dart';

/// #3383 — the startup-initialization trace panel inside Developer tools.
///
/// Visibility is the host screen's call (it gates on `Feature.startupTrace`),
/// so this widget stays free of any feature_management dependency (#3132
/// boundary). Shows the [StartupTimer] milestones as a waterfall (each phase
/// offset by its start + sized by its duration, so serial bottlenecks are
/// obvious) and a button that exports the trace JSON to Downloads via
/// [StartupTraceExport] — the same files-only path every other trace uses.
class StartupTracePanel extends StatelessWidget {
  const StartupTracePanel({super.key});

  @override
  Widget build(BuildContext context) {
    // Registering here is idempotent — it makes the trace ride the standard
    // error-log export the moment the user opens the panel.
    StartupTraceExport.ensureExtraExportSectionRegistered();

    final l = AppLocalizations.of(context);
    final timer = StartupTimer.instance;
    final phases = StartupTraceExport.phases(timer.milestones);
    final totalMs = timer.totalMs ??
        (timer.milestones.isEmpty ? 0 : timer.milestones.last.elapsedMs);
    // #3445 — the launch-sync spans recorded AFTER StartupTimer.finish().
    // They extend the shared waterfall timeline past the first frame.
    final spans = timer.spans;
    final timelineMs = spans.fold(totalMs, (m, s) => math.max(m, s.endMs));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          leadingIcon: Icons.timer_outlined,
          title: l.startupTraceSectionTitle,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        if (phases.isEmpty)
          Text(
            l.startupTraceEmpty,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else ...[
          Text(
            l.startupTraceTotalMs(totalMs),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          for (final p in phases)
            _PhaseRow(
              name: p['name'] as String,
              atMs: p['atMs'] as int,
              durationMs: p['durationMs'] as int,
              totalMs: math.max(1, timelineMs),
            ),
          for (final s in spans)
            _PhaseRow(
              name: s.name,
              atMs: s.endMs,
              durationMs: s.durationMs,
              totalMs: math.max(1, timelineMs),
            ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const ValueKey('startup-trace-export'),
            onPressed: () => _export(context),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(l.startupTraceExportButton),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _export(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final ok = await StartupTraceExport.export();
    if (!context.mounted) return;
    if (ok) {
      SnackBarHelper.showSuccess(context, l.startupTraceExportSuccess);
    } else {
      SnackBarHelper.showError(context, l.startupTraceExportFailure);
    }
  }
}

/// One waterfall row: the phase label, a bar offset by [atMs] − [durationMs]
/// and sized by [durationMs] (both as a fraction of [totalMs]), and the
/// duration in ms. The leading/trailing flex spacers place the bar on the
/// shared timeline so a long serial phase reads at a glance.
class _PhaseRow extends StatelessWidget {
  const _PhaseRow({
    required this.name,
    required this.atMs,
    required this.durationMs,
    required this.totalMs,
  });

  final String name;
  final int atMs;
  final int durationMs;
  final int totalMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startMs = math.max(0, atMs - durationMs);
    final restMs = math.max(0, totalMs - atMs);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              name,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  if (startMs > 0) Flexible(flex: startMs, child: const SizedBox()),
                  Flexible(
                    flex: math.max(1, durationMs),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: AppRadius.sm,
                      ),
                    ),
                  ),
                  if (restMs > 0) Flexible(flex: restMs, child: const SizedBox()),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              AppLocalizations.of(context).startupTraceMs(durationMs),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
