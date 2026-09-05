// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// The demo-mode call to action for a key-gated country without a key
/// ("prices are sample data — get live prices").
///
/// #3955 — this used to double as the open-data credit for free-API
/// countries and cross-border routes; those branches are now the leading
/// segment of `SearchSummaryBar`, so this banner is the ONE conditional
/// notice it always was, and renders nothing otherwise.
class DemoModeBanner extends ConsumerWidget {
  final CountryConfig country;

  const DemoModeBanner({super.key, required this.country});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(apiKeyStorageProvider);
    final l10n = AppLocalizations.of(context);

    if (country.requiresApiKey && !storage.hasApiKey(country.code)) {
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
          '${l10n.demoModeBanner}',
        ),
        leading: const Icon(Icons.science_outlined),
        actions: [
          TextButton(
            onPressed: () => context.go(RoutePaths.profile),
            child: Text(l10n.demoModeBannerAction),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
