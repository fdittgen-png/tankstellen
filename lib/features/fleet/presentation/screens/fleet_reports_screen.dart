// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/fleet/claim_class.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/fleet_metrics_export.dart';
import '../../domain/fleet_kpis.dart';
import '../../providers/fleet_manager_providers.dart';
import '../widgets/fleet_figure.dart';

/// The period report — CO2e with its scope and factor, and the export
/// (#4216, #4219).
///
/// The CO2 card has exactly two shapes and no third. Either there is a
/// figure, and it prints the boundary it was computed under and the
/// factor's own citation in the same card; or there is none, and it
/// says **"not calculated"** with the reason. #4219 forbids the middle
/// ground — a number with no source, or a zero standing in for an
/// absence — so the widget tree has no branch that could produce one.
///
/// The export is audited BEFORE the file exists. ADR 0025 D5.4 makes
/// the audit row part of the export rather than a side effect of it,
/// so a trail the server refused to write means no CSV at all.
class FleetReportsScreen extends ConsumerWidget {
  const FleetReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final period = ref.watch(fleetReportPeriodProvider);
    return PageScaffold(
      title: l.fleetManagerReportsTitle,
      subtitle: l.fleetManagerPeriod(
        UnitFormatter.formatMediumDate(period.from, locale: locale),
        UnitFormatter.formatMediumDate(period.to, locale: locale),
      ),
      bodyPadding: EdgeInsets.zero,
      body: ref.watch(fleetPeriodKpisProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: l.fleetManagerUnavailableTitle,
              subtitle: l.fleetManagerUnavailableBody,
            ),
            data: (kpis) => kpis == null
                ? EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: l.fleetManagerUnavailableTitle,
                    subtitle: l.fleetManagerUnavailableBody,
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      Spacing.lg,
                      Spacing.lg,
                      Spacing.lg,
                      shellScrollClearance(context),
                    ),
                    children: [
                      _Co2Card(kpis: kpis),
                      const SizedBox(height: Spacing.lg),
                      _ExportCard(kpis: kpis),
                    ],
                  ),
          ),
    );
  }
}

/// The CO2e figure, its boundary and its factor — or an explicit "not
/// calculated" (#4219).
class _Co2Card extends StatelessWidget {
  const _Co2Card({required this.kpis});

  final FleetKpis kpis;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final version = kpis.co2FactorVersion;
    final known = kpis.co2eKg.value.isKnown && version != null;
    return SectionCard(
      title: l.fleetManagerKpiCo2,
      leadingIcon: Icons.eco_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            known
                ? fleetFigure(l, kpis.co2eKg, FleetFormats.co2eKg)
                : l.fleetManagerNotCalculated,
            // The one number this card exists to show.
            style: AppText.display(context),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            fleetClaimLabel(l, ClaimClass.environmentalEstimate),
            style: theme.textTheme.labelSmall?.copyWith(color: muted),
          ),
          const SizedBox(height: Spacing.md),
          if (known) ...[
            _Line(label: l.fleetManagerCo2ScopeLabel,
                value: l.fleetManagerCo2ScopeWtw),
            _Line(label: l.fleetManagerCo2FactorLabel, value: version),
            const SizedBox(height: Spacing.xs),
            Text(l.fleetManagerSamples(kpis.sampleCount),
                style: theme.textTheme.labelSmall?.copyWith(color: muted)),
          ] else
            Text(
              // A fleet that disagreed about the version is a different
              // absence from a grade with no factor, and the manager is
              // told which one they have.
              _mixedVersions ? l.fleetManagerCo2MixedVersions
                  : l.fleetManagerCo2NotCalculatedBody,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
        ],
      ),
    );
  }

  /// More than one factor version in the period: the roll-up refused
  /// to add two methodologies, so there is no figure and the reason is
  /// not "no factor".
  bool get _mixedVersions {
    final versions = <String>{
      for (final v in kpis.reported)
        if (v.co2FactorVersion != null) v.co2FactorVersion!,
    };
    return versions.length > 1;
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: Spacing.md),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// The audited export (#4216, ADR 0025 D5.2 / D5.4).
class _ExportCard extends ConsumerStatefulWidget {
  const _ExportCard({required this.kpis});

  final FleetKpis kpis;

  @override
  ConsumerState<_ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends ConsumerState<_ExportCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      title: l.fleetManagerExport,
      leadingIcon: Icons.download_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.fleetManagerExportAudited,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: Spacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.download_outlined),
              label: Text(l.fleetManagerExport),
            ),
          ),
        ],
      ),
    );
  }

  /// Audit first, file second. A refusal produces neither.
  Future<void> _export() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final directory = ref.read(fleetManagerDirectoryProvider);
    if (directory == null) return;
    setState(() => _busy = true);
    final recorded = await ref.read(fleetMetricsReaderProvider).logExport(
          orgId: directory.orgId,
          kind: 'period_metrics_csv',
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!recorded) {
      messenger.showSnackBar(
          SnackBar(content: Text(l.fleetManagerExportFailed)));
      return;
    }
    // `encodeFleetCsv` refuses a header that could carry a location, so
    // the exclusion is enforced here and not merely intended.
    _lastCsv = fleetMetricsCsv(widget.kpis);
    messenger
        .showSnackBar(SnackBar(content: Text(l.fleetManagerExportReady)));
  }

  /// The rendered CSV, held so a share sheet (F10) can pick it up. It
  /// is deliberately not written to disk here: this slice owns the
  /// content and the audit, not the file-system story.
  String? _lastCsv;

  /// Whether an export has been produced in this session — read by
  /// tests, and by the share affordance when it lands.
  bool get hasExport => _lastCsv != null;
}
