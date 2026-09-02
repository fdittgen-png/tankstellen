// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/privacy_controls_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// #3870 (Epic #3865) / #3909 (Epic #3907) — the two disclosed,
/// switchable third-party flows that are not consents (the map tile
/// proxy and internet brand logos), rendered with the same row shape as
/// the consent switches: icon, title, a short wrapping subtitle, and an
/// info icon that opens the full explanation in a dialog.
class PrivacyControlRows extends ConsumerWidget {
  const PrivacyControlRows({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final proxyOn = ref.watch(tileProxyEnabledProvider);
    final logosOn = ref.watch(remoteBrandLogosProvider);
    // No proxy exists on a libre build: the switch would be a lie.
    final proxyAvailable = AppConstants.tileProxyUrl.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (proxyAvailable)
          PrivacyControlRow(
            switchKey: const Key('privacyTileProxySwitch'),
            infoKey: const Key('privacyTileProxyInfo'),
            icon: Icons.map_outlined,
            title: l.tileProxyToggleTitle,
            subtitle: l.tileProxyToggleShort,
            details: l.tileProxyToggleSubtitle,
            value: proxyOn,
            onChanged: (v) =>
                ref.read(tileProxyEnabledProvider.notifier).set(v),
          ),
        PrivacyControlRow(
          switchKey: const Key('privacyRemoteLogosSwitch'),
          infoKey: const Key('privacyRemoteLogosInfo'),
          icon: Icons.image_outlined,
          title: l.remoteLogosToggleTitle,
          subtitle: l.remoteLogosToggleShort,
          details: l.remoteLogosToggleSubtitle,
          value: logosOn,
          onChanged: (v) =>
              ref.read(remoteBrandLogosProvider.notifier).set(v),
        ),
      ],
    );
  }
}

/// One privacy-control row: a [ListTile] whose trailing holds the info
/// icon and the switch, so the subtitle keeps the full remaining width
/// and wraps instead of truncating.
class PrivacyControlRow extends StatelessWidget {
  final Key switchKey;
  final Key infoKey;
  final IconData icon;
  final String title;
  final String subtitle;

  /// The full disclosure text, shown in a dialog from the info icon.
  final String details;
  final bool value;
  final ValueChanged<bool> onChanged;

  const PrivacyControlRow({
    super.key,
    required this.switchKey,
    required this.infoKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      onTap: () => onChanged(!value),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: infoKey,
            icon: const Icon(Icons.info_outline, size: 20),
            tooltip: l.privacyLearnMore,
            onPressed: () => _showDetails(context),
          ),
          Switch(key: switchKey, value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(details)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).close),
          ),
        ],
      ),
    );
  }
}
