// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/privacy_controls_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// #3870 (Epic #3865) — Settings → Privacy & data: the two disclosed,
/// switchable third-party flows that are not consents (the map tile
/// proxy and internet brand logos). Sits right under
/// `ConsentSettingsSection`.
class PrivacyControlsSection extends ConsumerWidget {
  const PrivacyControlsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final proxyOn = ref.watch(tileProxyEnabledProvider);
    final logosOn = ref.watch(remoteBrandLogosProvider);
    // No proxy exists on a libre build: the switch would be a lie.
    final proxyAvailable = AppConstants.tileProxyUrl.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(l.privacyControlsTitle,
              style: theme.textTheme.titleSmall),
        ),
        if (proxyAvailable)
          SwitchListTile(
            key: const Key('privacyTileProxySwitch'),
            secondary: const Icon(Icons.map_outlined, size: 20),
            title: Text(l.tileProxyToggleTitle),
            subtitle: Text(l.tileProxyToggleSubtitle,
                style: theme.textTheme.bodySmall),
            value: proxyOn,
            onChanged: (v) =>
                ref.read(tileProxyEnabledProvider.notifier).set(v),
          ),
        SwitchListTile(
          key: const Key('privacyRemoteLogosSwitch'),
          secondary: const Icon(Icons.image_outlined, size: 20),
          title: Text(l.remoteLogosToggleTitle),
          subtitle: Text(l.remoteLogosToggleSubtitle,
              style: theme.textTheme.bodySmall),
          value: logosOn,
          onChanged: (v) =>
              ref.read(remoteBrandLogosProvider.notifier).set(v),
        ),
      ],
    );
  }
}
