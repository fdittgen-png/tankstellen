// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/country_service_registry.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Shows a demo-mode banner for API-key countries, or a country info bar for free APIs.
class DemoModeBanner extends ConsumerWidget {
  final CountryConfig country;

  /// #2622 — the upper-cased ISO codes of every country a cross-border route
  /// search actually queried (see `RouteSearchResult.corridorCountryCodes`).
  ///
  /// When this carries MORE THAN ONE code, the banner renders a multi-source
  /// attribution header crediting each crossed country's data provider
  /// (e.g. "France — Prix-Carburants · Spain — Geoportal Gasolineras")
  /// instead of the single active-country header — fixing the visible
  /// inconsistency where a FR→ES route credited only France. For nearby mode
  /// or a single-country route this is empty and the historical
  /// single-country header is shown unchanged.
  final Set<String> corridorCountryCodes;

  const DemoModeBanner({
    super.key,
    required this.country,
    this.corridorCountryCodes = const {},
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(apiKeyStorageProvider);
    final l10n = AppLocalizations.of(context);

    // #2622 — a cross-border route crosses >1 data source; credit them all.
    if (corridorCountryCodes.length > 1) {
      return _MultiSourceHeader(countryCodes: corridorCountryCodes);
    }

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

    if (!country.requiresApiKey) {
      // #2373 \u2014 the country-service header doubles as the open-data
      // attribution: it credits the upstream provider and, when that
      // provider has a canonical homepage on its FuelServicePolicy, opens
      // it in the browser. This relocates the attribution that used to sit
      // in a bottom footer (the open-data licences \u2014 CC BY / Licence
      // Ouverte / OGL / IODL \u2014 only require a *visible* credit, not a
      // specific position).
      final policy = CountryServiceRegistry.policyFor(country.code);
      return _CountryServiceHeader(
        country: country,
        sourceUrl: policy?.sourceUrl,
        attribution: policy?.attribution,
        license: policy?.license,
      );
    }

    return const SizedBox.shrink();
  }
}

/// The top country-service header on the search screen \u2014 "France \u2014
/// Prix-Carburants (gouv.fr)".
///
/// When the active country's [FuelServicePolicy] carries a [sourceUrl] this
/// renders as a tappable link (underline + an `open_in_new` affordance) that
/// opens the upstream data source in the browser. The accessibility label and
/// tooltip spell out the provider name and licence so the open-data
/// attribution stays available to screen-reader and long-press users \u2014 the
/// credit is preserved, just relocated from the old bottom footer (#2373).
///
/// With no source URL (e.g. a demo / unsupported-country fallback) it falls
/// back to the plain, non-interactive label it has always shown.
class _CountryServiceHeader extends StatelessWidget {
  const _CountryServiceHeader({
    required this.country,
    required this.sourceUrl,
    required this.attribution,
    required this.license,
  });

  final CountryConfig country;
  final String? sourceUrl;
  final String? attribution;
  final String? license;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    // The provider name shown to the user. Prefer the country config's
    // display string; both it and the policy attribution are proper-noun
    // provider names, not translatable copy.
    final providerLabel = country.apiProvider; // i18n-ignore: provider name
    final labelText = '${country.name} \u2014 $providerLabel';

    // #1698 \u2014 let the label wrap rather than ellipsis-clip the provider name
    // under large text scaling; `start` cross-alignment keeps the flag pinned
    // to the first line when the label spills onto a second.
    final flag = Text(country.flag, style: const TextStyle(fontSize: 14));

    final url = sourceUrl;
    if (url == null || url.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            flag,
            const SizedBox(width: 6),
            Expanded(child: Text(labelText, style: theme.textTheme.labelSmall)),
          ],
        ),
      );
    }

    final linkColor = theme.colorScheme.primary;
    // Attribution / licence preserved in the link's a11y label + tooltip so
    // screen-reader users still get the full open-data credit (#2373).
    final source = attribution ?? providerLabel ?? country.name;
    final lic = license ?? '';
    final semanticLabel = l10n.dataSourceLinkSemantic(source, lic);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          flag,
          const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              link: true,
              label: semanticLabel,
              child: Tooltip(
                message: semanticLabel,
                child: InkWell(
                  onTap: () => _open(url),
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          labelText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: linkColor,
                            decoration: TextDecoration.underline,
                            decorationColor: linkColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.open_in_new, size: 12, color: linkColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// #2622 — the multi-source attribution header shown above a CROSS-BORDER
/// route result. Joins each crossed corridor country's data-source credit —
/// "France — Prix-Carburants · Spain — Geoportal Gasolineras" — so a result
/// that surfaces stations from several countries (#2626) no longer credits
/// only the active country.
///
/// Each segment is `<country name> — <policy.attribution>` resolved from the
/// registry (the same single source of truth `_CountryServiceHeader` uses);
/// the joined string is then formatted through the `routeDataSourceMulti`
/// ARB key. Country names + provider names are proper nouns, so only the
/// join itself is localized. Codes with no registered policy are skipped.
class _MultiSourceHeader extends StatelessWidget {
  const _MultiSourceHeader({required this.countryCodes});

  final Set<String> countryCodes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final flags = <String>[];
    final segments = <String>[];
    // Sorted for a stable, deterministic order regardless of corridor
    // detection order (FR before ES → "France … · Spain …").
    for (final code in countryCodes.toList()..sort()) {
      final config = Countries.byCode(code);
      final policy = CountryServiceRegistry.policyFor(code);
      if (config == null || policy == null) continue;
      flags.add(config.flag);
      // i18n-ignore: country name + provider attribution are proper nouns.
      segments.add('${config.name} — ${policy.attribution}');
    }

    if (segments.isEmpty) return const SizedBox.shrink();

    final joined = segments.join(' · ');
    final labelText = l10n.routeDataSourceMulti(joined);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(flags.join(' '), style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(child: Text(labelText, style: theme.textTheme.labelSmall)),
        ],
      ),
    );
  }
}
