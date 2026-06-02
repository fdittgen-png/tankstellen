// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/snackbar_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../feature_management/application/app_profile_provider.dart';
import '../../../../feature_management/application/feature_flags_provider.dart';
import '../../../../feature_management/domain/feature.dart';
import '../../../../feature_management/domain/feature_dependency_graph.dart';
import '../../../../feature_management/domain/feature_manifest.dart';
import 'feature_grouping.dart';
import 'feature_localization.dart';

/// Renders one [FeatureGroup] as a [Card] containing the parent toggle
/// at full width followed by any dependent rows indented beneath it
/// (#1440). When the group has no children the card collapses to just
/// the parent row — no divider, no indent.
///
/// Extracted from feature_management_section.dart for #2681 (file-length).
class FeatureGroupCard extends StatelessWidget {
  final FeatureGroup group;
  final FeatureManifest manifest;
  final Set<Feature> currentlyEnabled;

  const FeatureGroupCard({
    super.key,
    required this.group,
    required this.manifest,
    required this.currentlyEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChildren = group.children.isNotEmpty;
    return Card(
      key: Key('featureGroup_${group.parent.name}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FeatureToggle(
              feature: group.parent,
              isEnabled: currentlyEnabled.contains(group.parent),
              manifest: manifest,
              currentlyEnabled: currentlyEnabled,
            ),
            if (hasChildren)
              Divider(
                height: 1,
                thickness: 1,
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
            for (final child in group.children)
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: FeatureToggle(
                  feature: child,
                  isEnabled: currentlyEnabled.contains(child),
                  manifest: manifest,
                  currentlyEnabled: currentlyEnabled,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One row in the Feature management section. Extracted so the per-feature
/// `Tooltip` + `SwitchListTile` block stays readable.
class FeatureToggle extends ConsumerWidget {
  final Feature feature;
  final bool isEnabled;
  final FeatureManifest manifest;
  final Set<Feature> currentlyEnabled;

  const FeatureToggle({
    super.key,
    required this.feature,
    required this.isEnabled,
    required this.manifest,
    required this.currentlyEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final title = featureLabel(l, feature);
    final subtitle = featureDescription(l, feature);

    // Pre-check the next transition. The row is disabled with a tooltip
    // when:
    //   * the feature is OFF and its prerequisites are missing — tapping
    //     would call `enable(feature)` which throws, OR
    //   * any ancestor on the `requires` chain is OFF (cascading-disable
    //     #1447) — the row is effectively-disabled even when the stored
    //     value is `true`. We let the child stay "switch-on visually" so
    //     the user can see what their preference WAS, but the toggle is
    //     non-interactive until they re-enable the parent.
    String? blockedReason;
    if (!isEffectivelyEnabled(feature, manifest, currentlyEnabled) &&
        !canEnable(feature, manifest, currentlyEnabled)) {
      blockedReason = blockedEnableMessage(l, feature);
    }

    final tile = SwitchListTile(
      key: Key('featureToggle_${feature.name}'),
      value: isEnabled,
      title: Text(title),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      contentPadding: EdgeInsets.zero,
      onChanged: blockedReason != null
          ? null
          : (next) {
              final notifier = ref.read(featureFlagsProvider.notifier);
              // The pre-check above guarantees the call won't throw; the
              // future only completes the Hive write. Fire-and-forget is
              // acceptable for a settings toggle — Riverpod surfaces the
              // new state synchronously.
              unawaited(toggleAndReconcile(ref, notifier, feature, next));
            },
    );

    if (blockedReason == null) {
      return tile;
    }
    // The switch's onChanged is null (disabled) so taps would be
    // swallowed silently. Wrap the row in a GestureDetector that
    // surfaces the blocker via SnackBar (#1440) — long-press still
    // shows the existing Tooltip.
    final reason = blockedReason;
    return Tooltip(
      message: reason,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (messenger == null) return;
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBarHelper.infoSnackBar(reason));
        },
        child: tile,
      ),
    );
  }
}

/// Toggles [feature] then asks [activeAppProfileProvider] to reconcile
/// the active profile against the new flag set (#1517 / #1519).
///
/// When the user toggles a flag manually here and the new set no
/// longer matches the active preset, the active profile flips to
/// [AppProfile.custom] and the Use-mode section above re-renders to
/// show the Custom card. Re-selecting a preset later overwrites the
/// flag set back to the canonical bundle.
Future<void> toggleAndReconcile(
  WidgetRef ref,
  FeatureFlags notifier,
  Feature feature,
  bool next,
) async {
  // #1808 — capture the profile notifier before the await. The widget
  // `ref` is unsafe to use once the user has left the screen mid-apply.
  final profile = ref.read(activeAppProfileProvider.notifier);
  if (next) {
    await notifier.enable(feature);
  } else {
    await notifier.disable(feature);
  }
  await profile.reconcile();
}
