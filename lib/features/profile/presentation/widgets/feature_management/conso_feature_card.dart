// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../feature_management/application/app_profile_provider.dart';
import '../../../../feature_management/application/feature_flags_provider.dart';
import '../../../../feature_management/domain/conso_mode.dart';
import '../../../../feature_management/domain/feature.dart';
import '../../../../feature_management/domain/feature_manifest.dart';
import 'feature_group_card.dart';

/// Conso group card (#1571). Renders the 3-way [ConsoMode] segmented
/// control at the top followed by the Trajets-tier dependent toggles
/// indented beneath it. The dependents render as [FeatureToggle]s just
/// like in [FeatureGroupCard] so the cascading-disable behaviour (#1447)
/// keeps applying — when mode is Off or Fuel, the dependents stay
/// visually disabled with the standard blocked-enable tooltip.
///
/// #2681 — the card is pinned to the top of the Consumption category
/// section and additionally renders the [extraRows] (e.g. `obd2Optional`)
/// as always-enabled indented rows beneath the Trajets-tier dependents,
/// so the OBD2-required toggle reads as part of the consumption hierarchy
/// rather than floating elsewhere in the list.
///
/// Extracted from feature_management_section.dart for #2681 (file-length).
class ConsoFeatureCard extends ConsumerWidget {
  final ConsoMode mode;
  final List<Feature> dependents;

  /// Features rendered as always-enabled indented rows after the
  /// Trajets-tier [dependents] (#2681 — `obd2Optional`). They have no
  /// manifest `requires` edge so they are never blocked.
  final List<Feature> extraRows;
  final FeatureManifest manifest;
  final Set<Feature> currentlyEnabled;

  const ConsoFeatureCard({
    super.key,
    required this.mode,
    required this.dependents,
    this.extraRows = const <Feature>[],
    required this.manifest,
    required this.currentlyEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      key: const Key('featureGroup_conso'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<ConsoMode>(
              segments: <ButtonSegment<ConsoMode>>[
                ButtonSegment<ConsoMode>(
                  value: ConsoMode.off,
                  label: Text(l?.consoModeOff ?? 'Off'),
                ),
                ButtonSegment<ConsoMode>(
                  value: ConsoMode.fuel,
                  label: Text(l?.consoModeFuel ?? 'Fuel'),
                ),
                ButtonSegment<ConsoMode>(
                  value: ConsoMode.fuelAndTrips,
                  label: Text(l?.consoModeFuelAndTrips ?? 'Fuel + Trips'),
                ),
              ],
              selected: <ConsoMode>{mode},
              showSelectedIcon: false,
              onSelectionChanged: (selected) {
                final next = selected.first;
                if (next == mode) return;
                unawaited(_applyConsoMode(ref, next));
              },
            ),
            const SizedBox(height: 8),
            Text(
              _modeDescription(l, mode),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (dependents.isNotEmpty || extraRows.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(
                height: 1,
                thickness: 1,
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
              for (final child in dependents)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: FeatureToggle(
                    feature: child,
                    isEnabled: currentlyEnabled.contains(child),
                    manifest: manifest,
                    currentlyEnabled: currentlyEnabled,
                  ),
                ),
              for (final extra in extraRows)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: FeatureToggle(
                    feature: extra,
                    isEnabled: currentlyEnabled.contains(extra),
                    manifest: manifest,
                    currentlyEnabled: currentlyEnabled,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _modeDescription(AppLocalizations? l, ConsoMode m) {
    switch (m) {
      case ConsoMode.off:
        return l?.consoModeOffDescription ??
            'No Conso tab and no Conso settings section.';
      case ConsoMode.fuel:
        return l?.consoModeFuelDescription ??
            'Manual fill-ups only. Useful without an OBD2 adapter.';
      case ConsoMode.fuelAndTrips:
        return l?.consoModeFuelAndTripsDescription ??
            'Adds automatic OBD2 trip recording. Requires a paired adapter.';
    }
  }

  Future<void> _applyConsoMode(WidgetRef ref, ConsoMode next) async {
    final delta = consoModeFlagDelta(next);
    // #1808 — capture both notifiers before the awaits. The widget's
    // `ref` must not be touched after an `await`: the user can leave
    // this screen mid-apply, which unmounts the element and makes any
    // later `ref.read` throw a disposed-ref StateError.
    final notifier = ref.read(featureFlagsProvider.notifier);
    final profile = ref.read(activeAppProfileProvider.notifier);
    for (final f in delta.toAdd) {
      await notifier.enable(f);
    }
    for (final f in delta.toRemove) {
      await notifier.disable(f);
    }
    await profile.reconcile();
  }
}
