// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/dark_mode_colors.dart';
import '../../../../../core/widgets/section_header.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../consumption/data/obd2/adapter_registry.dart';
import '../../../../consumption/data/obd2/obd2_connect_trace.dart';
import '../../../../consumption/data/obd2/obd2_self_test_driver.dart';
import '../../../../consumption/providers/obd2_self_test_controller.dart';
import '../../../../vehicle/providers/vehicle_providers.dart';
import 'obd2_self_test_adapter_choice.dart';

/// The #2645 active-adapter-self-test panel on the OBD2 communication-health
/// screen: an adapter CHOICE (#2938), a Run button (disabled while running), a
/// live per-step list with status icons + latencies, and a pass/fail summary
/// banner.
///
/// The adapter choice defaults to the active vehicle's paired adapter
/// (`VehicleProfile.obd2AdapterMac`) and offers every paired adapter the user
/// has stored across their vehicle profiles, plus a "Scan for adapter"
/// fallback. When an adapter (MAC) is chosen the self-test connects BY MAC via
/// the reliable `connectByMacDirect` path — fixing the blind-scan timeout
/// (~6001 ms) that made the original Run button report "0 of 7 OK". With the
/// scan fallback selected the legacy blind scan still runs.
///
/// Watches [obd2SelfTestControllerProvider] so it animates live as the
/// driver pushes each step transition. The persisted trace lands in the
/// screen's Recent-sessions + Download sections for free (the driver
/// `endSession()`s into the same collector the screen reads).
///
/// Extracted into its own widget file so the host screen stays under the
/// #2351 file-length cap (the OCR pump-tester widgets precedent).
class Obd2SelfTestPanel extends ConsumerWidget {
  const Obd2SelfTestPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final test = ref.watch(obd2SelfTestControllerProvider);
    final running = test.phase == Obd2SelfTestPhase.running;

    final adapters = _pairedAdapters(ref);
    final defaultMac = _defaultMac(ref, adapters);
    final selectedMac =
        ref.watch(obd2SelfTestSelectedAdapterProvider(defaultMac));
    final selectedName = _nameForMac(adapters, selectedMac);
    // #2969 — route the run over the inferred transport of the chosen adapter.
    final selectedTransport = _transportHintForMac(adapters, selectedMac);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          leadingIcon: Icons.play_circle_outline,
          title: l?.obd2TestRunTitle ?? 'Run adapter test',
          padding: EdgeInsets.zero,
        ),
        Obd2SelfTestAdapterChoice(
          adapters: adapters,
          selectedMac: selectedMac,
          enabled: !running,
          onChanged: (mac) => ref
              .read(obd2SelfTestSelectedAdapterProvider(defaultMac).notifier)
              .set(mac),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const ValueKey('obd2-self-test-run'),
            onPressed: running
                ? null
                : () => ref
                    .read(obd2SelfTestControllerProvider.notifier)
                    .run(
                        targetMac: selectedMac,
                        transportHint: selectedTransport,
                        // #3014 — name the trace headline with the chosen
                        // adapter's human name (already resolved for the row
                        // relabel), not just the redacted MAC.
                        adapterName: selectedName),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        if (test.phase == Obd2SelfTestPhase.running ||
            test.phase == Obd2SelfTestPhase.done) ...[
          const SizedBox(height: 8),
          for (final step in test.steps)
            _StepRow(
              key: ValueKey('obd2-self-test-step-${step.id.name}'),
              step: step,
              connectAdapterName: selectedName,
            ),
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

  /// Deduplicated paired adapters across every stored vehicle profile,
  /// keyed by MAC (#2938). The display name falls back to the MAC when a
  /// legacy profile carries a MAC with no name.
  List<Obd2PairedAdapter> _pairedAdapters(WidgetRef ref) {
    final profiles = ref.watch(vehicleProfileListProvider);
    // #2969 — infer each adapter's transport from its stored name (a paired
    // profile stores MAC + name, never a transport) so the self-test can take
    // the RFCOMM path for a Classic-SPP adapter instead of a doomed BLE
    // 4 s-timeout.
    final registry = Obd2AdapterRegistry.defaults();
    final byMac = <String, Obd2PairedAdapter>{};
    for (final p in profiles) {
      final mac = p.obd2AdapterMac;
      if (mac == null || mac.isEmpty) continue;
      final name = p.obd2AdapterName;
      byMac.putIfAbsent(
        mac,
        () => Obd2PairedAdapter(
          mac: mac,
          name: (name != null && name.isNotEmpty) ? name : mac,
          transport: registry.transportForName(name),
        ),
      );
    }
    return byMac.values.toList(growable: false);
  }

  /// The inferred connect-transport hint for the selected MAC (#2969), mapped
  /// from the paired adapter's registry-inferred [BluetoothTransport]. Null ⇒
  /// no paired adapter selected / no name match → the run defaults to BLE and
  /// records `no-hint-defaulted-ble`.
  Obd2ConnectTransport? _transportHintForMac(
      List<Obd2PairedAdapter> adapters, String? mac) {
    if (mac == null) return null;
    for (final a in adapters) {
      if (a.mac != mac) continue;
      switch (a.transport) {
        case BluetoothTransport.classic:
          return Obd2ConnectTransport.classic;
        case BluetoothTransport.ble:
          return Obd2ConnectTransport.ble;
        case null:
          return null;
      }
    }
    return null;
  }

  /// The default selection: the active vehicle's paired adapter when set and
  /// still present in the list, else the first paired adapter, else null
  /// (the scan fallback).
  String? _defaultMac(WidgetRef ref, List<Obd2PairedAdapter> adapters) {
    final active = ref.watch(activeVehicleProfileProvider);
    final activeMac = active?.obd2AdapterMac;
    if (activeMac != null &&
        activeMac.isNotEmpty &&
        adapters.any((a) => a.mac == activeMac)) {
      return activeMac;
    }
    return adapters.isNotEmpty ? adapters.first.mac : null;
  }

  String? _nameForMac(List<Obd2PairedAdapter> adapters, String? mac) {
    if (mac == null) return null;
    for (final a in adapters) {
      if (a.mac == mac) return a.name;
    }
    return mac;
  }
}

/// One row of the live step list: a status icon (with a11y semanticLabel),
/// the localised step name, and the trailing latency in ms.
class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.step,
    this.connectAdapterName,
  });

  final Obd2SelfTestStep step;

  /// When non-null, the first ("scan") step is relabelled "Connect to
  /// [adapter]" because the run took the no-scan connect-by-MAC path (#2938).
  final String? connectAdapterName;

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
        // #2938 — when the run connected by MAC, the first step is a direct
        // connect, not a scan; relabel it so the trace matches what ran.
        final name = connectAdapterName;
        if (name != null) {
          return l?.obd2TestStepConnectTo(name) ?? 'Connect to $name';
        }
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

/// The tri-state summary banner shown once a run completes (#3009).
///
/// Three distinct verdicts, never conflated:
///   * passed   — green check, "Adapter test passed".
///   * engineOff — AMBER info, "Adapter OK — engine off; start the engine to
///     read live data". The adapter answered every capability step; only the
///     live-data steps were ECU-silent because the engine is off. NOT a red
///     failure — the hardware is fine.
///   * failed   — red error, "Adapter test failed" (a genuine fault).
class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({super.key, required this.state});

  final Obd2SelfTestState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (bg, fg, icon, headline) = switch (state.verdict) {
      Obd2SelfTestVerdict.passed => (
          cs.primaryContainer,
          cs.onPrimaryContainer,
          Icons.check_circle,
          l?.obd2TestRunPassed ?? 'Adapter test passed',
        ),
      Obd2SelfTestVerdict.engineOff => (
          DarkModeColors.warningSurface(context),
          DarkModeColors.warning(context),
          Icons.info_outline,
          l?.obd2TestRunEngineOff ??
              'Adapter OK — engine off; start the engine to read live data',
        ),
      Obd2SelfTestVerdict.failed => (
          cs.errorContainer,
          cs.onErrorContainer,
          Icons.error,
          l?.obd2TestRunFailed ?? 'Adapter test failed',
        ),
    };
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
              Icon(icon, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headline,
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
