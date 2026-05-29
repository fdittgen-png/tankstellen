// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/page_scaffold.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../feature_management/application/feature_flags_provider.dart';
import '../../../../feature_management/domain/feature.dart';

/// Read-only inspector listing every [Feature] flag and its current
/// enabled / disabled state (#2248). Gated behind Developer / Debug mode
/// via the Developer tools screen that pushes it.
///
/// Watches [enabledFeaturesProvider] so the list updates live if a flag
/// is toggled elsewhere while the screen is open.
class FeatureFlagDumpScreen extends ConsumerWidget {
  const FeatureFlagDumpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final enabled = ref.watch(enabledFeaturesProvider);
    final on = l?.developerToolsFlagOn ?? 'On';
    final off = l?.developerToolsFlagOff ?? 'Off';

    final features = Feature.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return PageScaffold(
      title: l?.developerToolsFeatureFlagDump ?? 'Feature flag inspector',
      bodyPadding: EdgeInsets.zero,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: features.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final f = features[index];
          final isOn = enabled.contains(f);
          return ListTile(
            key: Key('flagDump_${f.name}'),
            dense: true,
            leading: Icon(
              isOn ? Icons.check_circle : Icons.remove_circle_outline,
              color: isOn ? theme.colorScheme.primary : theme.disabledColor,
              size: 20,
            ),
            title: Text(f.name, style: theme.textTheme.bodyMedium),
            trailing: Text(
              isOn ? on : off,
              style: theme.textTheme.labelMedium?.copyWith(
                color:
                    isOn ? theme.colorScheme.primary : theme.disabledColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
