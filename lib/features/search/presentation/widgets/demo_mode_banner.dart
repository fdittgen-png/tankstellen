// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Shows a demo-mode banner for API-key countries, or a country info bar for free APIs.
class DemoModeBanner extends ConsumerWidget {
  final CountryConfig country;

  const DemoModeBanner({super.key, required this.country});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(apiKeyStorageProvider);
    final l10n = AppLocalizations.of(context);

    if (country.requiresApiKey && !storage.hasApiKey()) {
      // #1696 — jargon-free copy: the banner names neither "API key"
      // nor any technical term; the user just learns prices are sample
      // data and that Settings is where live prices are turned on.
      return MaterialBanner(
        // #1696 — `forceActionsBelow` keeps the action on its own row.
        // In the default single-row layout the action button takes its
        // intrinsic width and the content `Expanded` gets whatever is
        // left; in a narrow pane (e.g. the wide-screen two-pane search
        // layout) that leftover collapses to a few pixels and the
        // content text wraps one glyph per line — an 800+ dp tall
        // banner. Dropping the action below gives the content the full
        // banner width at every size.
        forceActionsBelow: true,
        content: Text(
          '${country.flag} ${country.name} — '
          '${l10n?.demoModeBanner ?? 'Demo mode — showing sample prices.'}',
        ),
        leading: const Icon(Icons.science_outlined),
        actions: [
          TextButton(
            onPressed: () => context.go('/profile'),
            child: Text(l10n?.demoModeBannerAction ?? 'Get live prices'),
          ),
        ],
      );
    }

    if (!country.requiresApiKey) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        // #1698 \u2014 let the country / provider label wrap instead of
        // ellipsis-clipping the provider name under large text scaling.
        // `start` cross-alignment keeps the flag pinned to the first
        // line when the label spills onto a second.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${country.name} \u2014 ${country.apiProvider}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
