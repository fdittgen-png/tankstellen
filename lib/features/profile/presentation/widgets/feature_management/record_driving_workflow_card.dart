// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/guarded.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/theme/app_text.dart';
import '../../../../../core/widgets/panel_card.dart';
import '../../../../../core/widgets/snackbar_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../feature_management/api.dart';
import 'feature_localization.dart';

/// First process-first activation slice (#4226). The capability DAG remains
/// authoritative; the card stores only its in-flight interaction state.
class RecordDrivingWorkflowCard extends ConsumerStatefulWidget {
  const RecordDrivingWorkflowCard({super.key});

  @override
  ConsumerState<RecordDrivingWorkflowCard> createState() =>
      _RecordDrivingWorkflowCardState();
}

class _RecordDrivingWorkflowCardState
    extends ConsumerState<RecordDrivingWorkflowCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final manifest = ref.watch(featureManifestProvider);
    final preview = FeatureActivationPreview.resolve(
      target: Feature.showConsumptionTab,
      manifest: manifest,
      channel: ref.watch(buildChannelProvider),
      enabled: ref.watch(enabledFeaturesProvider),
    );
    if (preview == null) return const SizedBox.shrink();
    final loaded = ref.watch(featureFlagsProvider).hasValue;
    final active = preview.activated.isEmpty;
    return PanelCard(
      key: const Key('recordDrivingWorkflow'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.processWorkflowsDriving,
            style: AppText.title(context),
          ),
          const SizedBox(height: Spacing.sm),
          Text(l.processWorkflowsRecordDescription),
          const SizedBox(height: Spacing.sm),
          Text(
            active ? l.processWorkflowsEnabled : l.processWorkflowsNotEnabled,
          ),
          const SizedBox(height: Spacing.sm),
          OutlinedButton(
            key: const Key('reviewRecordDrivingWorkflow'),
            onPressed: _busy || !loaded ? null : () => _review(preview),
            child: Text(
              active ? l.processWorkflowsDetails : l.processWorkflowsEnable,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _review(FeatureActivationPreview preview) async {
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    final flags = ref.read(featureFlagsProvider.notifier);
    final profile = ref.read(activeAppProfileProvider.notifier);
    final manifest = ref.read(featureManifestProvider);
    final usedBy = manifest.entries.values
        .where(
          (entry) =>
              !preview.required.contains(entry.feature) &&
              entry.requires.any(preview.required.contains),
        )
        .map((entry) => entry.feature);
    final active = preview.activated.isEmpty;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.processWorkflowsDriving),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.processWorkflowsRequired),
            for (final feature in preview.required)
              Text(featureLabel(l, feature)),
            const SizedBox(height: Spacing.md),
            Text(l.processWorkflowsNeeds),
            if (preview.activated.isNotEmpty) ...[
              const SizedBox(height: Spacing.md),
              Text(l.processWorkflowsImpact),
              for (final feature in preview.activated)
                Text(featureLabel(l, feature)),
            ],
            if (usedBy.isNotEmpty) ...[
              const SizedBox(height: Spacing.md),
              Text(l.processWorkflowsUsedBy),
              for (final feature in usedBy) Text(featureLabel(l, feature)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(active ? l.close : l.cancel),
          ),
          if (!active)
            FilledButton(
              key: const Key('confirmRecordDrivingWorkflow'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l.processWorkflowsConfirm),
            ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirm != true) {
      setState(() => _busy = false);
      return;
    }
    var applied = false;
    final success = await runGuarded(
      context,
      where: 'RecordDrivingWorkflowCard: activate',
      errorText: l.processWorkflowsFailed,
      action: () async {
        applied = await flags.activateReviewed(preview);
        if (applied) await profile.reconcile();
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarHelper.infoSnackBar(
          applied ? l.processWorkflowsActivated : l.processWorkflowsChanged,
        ),
      );
    }
  }
}
