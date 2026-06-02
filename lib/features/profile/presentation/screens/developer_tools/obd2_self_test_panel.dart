// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/section_header.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../consumption/data/obd2/obd2_self_test_driver.dart';
import '../../../../consumption/providers/obd2_self_test_controller.dart';

/// The #2645 active-adapter-self-test panel on the OBD2 communication-health
/// screen: a Run button (disabled while running), a live per-step list with
/// status icons + latencies, and a pass/fail summary banner.
///
/// Watches [obd2SelfTestControllerProvider] so it animates live as the
/// driver pushes each step transition. The persisted trace lands in the
/// screen's Recent-sessions + Copy-as-JSON sections for free (the driver
/// `endSession()`s into the same collector the screen reads).
///
/// Extracted into its own widget file so the host screen stays under the
/// #2351 file-length cap (the OCR pump-tester widgets precedent).
class Obd2SelfTestPanel extends ConsumerWidget {
  const Obd2SelfTestPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final test = ref.watch(obd2SelfTestControllerProvider);
    final running = test.phase == Obd2SelfTestPhase.running;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          leadingIcon: Icons.play_circle_outline,
          title: l?.obd2TestRunTitle ?? 'Run adapter test',
          padding: EdgeInsets.zero,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const ValueKey('obd2-self-test-run'),
            onPressed: running
                ? null
                : ref.read(obd2SelfTestControllerProvider.notifier).run,
            icon: running
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_outlined, size: 18),
            label: Text(l?.obd2TestRunButton ?? 'Run adapter test'),
          ),
        ),
        if (test.phase == Obd2SelfTestPhase.blockedByRecording)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l?.obd2TestRunCannotWhileRecording ??
                  'Stop the active recording before running the adapter test.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        if (test.phase == Obd2SelfTestPhase.running ||
            test.phase == Obd2SelfTestPhase.done) ...[
          const SizedBox(height: 8),
          for (final step in test.steps)
            _StepRow(key: ValueKey('obd2-self-test-step-${step.id.name}'), step: step),
        ],
        if (test.phase == Obd2SelfTestPhase.done)
          _SummaryBanner(
            key: const ValueKey('obd2-self-test-summary'),
            state: test,
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// One row of the live step list: a status icon (with a11y semanticLabel),
/// the localised step name, and the trailing latency in ms.
class _StepRow extends StatelessWidget {
  const _StepRow({super.key, required this.step});

  final Obd2SelfTestStep step;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          _statusIcon(context, l),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _stepLabel(l),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (step.latencyMs != null)
            Text(
              '${step.latencyMs} ms', // i18n-ignore: ms unit format mask
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusIcon(BuildContext context, AppLocalizations? l) {
    final cs = Theme.of(context).colorScheme;
    if (step.running) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    switch (step.status) {
      case Obd2SelfTestStepStatus.ok:
        return Icon(Icons.check_circle, size: 18, color: cs.primary,
            semanticLabel: l?.obd2TestStatusOk ?? 'OK');
      case Obd2SelfTestStepStatus.timeout:
        return Icon(Icons.timer_off, size: 18, color: cs.error,
            semanticLabel: l?.obd2TestStatusTimeout ?? 'Timed out');
      case Obd2SelfTestStepStatus.garbage:
        return Icon(Icons.help_outline, size: 18, color: cs.error,
            semanticLabel: l?.obd2TestStatusGarbage ?? 'Unreadable reply');
      case Obd2SelfTestStepStatus.noResponse:
        return Icon(Icons.do_not_disturb_on_outlined, size: 18,
            color: cs.onSurfaceVariant,
            semanticLabel: l?.obd2TestStatusNoResponse ?? 'No response');
      case Obd2SelfTestStepStatus.fail:
      case Obd2SelfTestStepStatus.skipped:
        return Icon(Icons.error, size: 18, color: cs.error,
            semanticLabel: l?.obd2TestStatusFail ?? 'Failed');
    }
  }

  String _stepLabel(AppLocalizations? l) {
    switch (step.id) {
      case Obd2SelfTestStepId.scan:
        return l?.obd2TestStepScan ?? 'Scan for adapter';
      case Obd2SelfTestStepId.connect:
        return l?.obd2TestStepConnect ?? 'Connect & init';
      case Obd2SelfTestStepId.info:
        return l?.obd2TestStepInfo ?? 'Adapter info';
      case Obd2SelfTestStepId.supportedPids:
        return l?.obd2TestStepSupportedPids ?? 'Supported PIDs';
      case Obd2SelfTestStepId.sampleReads:
        return l?.obd2TestStepSampleReads ?? 'Sample reads';
      case Obd2SelfTestStepId.reconnect:
        return l?.obd2TestStepReconnect ?? 'Reconnect test';
      case Obd2SelfTestStepId.disconnect:
        return l?.obd2TestStepDisconnect ?? 'Disconnect';
    }
  }
}

/// The pass/fail summary banner shown once a run completes.
class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({super.key, required this.state});

  final Obd2SelfTestState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final passed = state.passed;
    final bg = passed ? cs.primaryContainer : cs.errorContainer;
    final fg = passed ? cs.onPrimaryContainer : cs.onErrorContainer;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(passed ? Icons.check_circle : Icons.error, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  passed
                      ? (l?.obd2TestRunPassed ?? 'Adapter test passed')
                      : (l?.obd2TestRunFailed ?? 'Adapter test failed'),
                  style: theme.textTheme.titleSmall?.copyWith(color: fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l?.obd2TestRunSummary(
                  state.passCount,
                  state.steps.length,
                  state.elapsedMs ?? 0,
                ) ??
                '${state.passCount} of ${state.steps.length} steps OK · '
                    '${state.elapsedMs ?? 0} ms',
            style: theme.textTheme.bodySmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
