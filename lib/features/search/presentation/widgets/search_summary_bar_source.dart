// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'search_summary_bar.dart';

/// The band's leading segment: the open-data credit (#3955).
///
/// Before #3955 the credit was the pinned `SearchResultsFooter` under the
/// results list ("🇫🇷 France — Prix-Carburants (gouv.fr) ↗"), holding a
/// row of height above the bottom bar at every scroll position. The
/// open-data licences (Licence Ouverte, CC BY, OGL, IODL) mandate a
/// *visible* credit, not a position, so it moved up here as one summary
/// chip: the country flag as the glyph, the provider name as the value,
/// the full "source · licence" sentence as tooltip + screen-reader label,
/// and — when the country's [FuelServicePolicy] has a `sourceUrl` — a tap
/// that opens the upstream source, with the `open_in_new` affordance.
///
/// Three branches, the same three the footer had:
///  * a CROSS-BORDER route result (#2622) credits every country that
///    produced a station — flags joined, providers joined with `·`;
///  * a free-API country credits its provider (tappable when a URL exists);
///  * a key-gated country (Germany) shows no credit here — the demo-mode
///    banner above the band is its call to action, as before.
class _DataSourceSegment extends ConsumerWidget {
  const _DataSourceSegment();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final country = ref.watch(activeCountryProvider);
    final l10n = AppLocalizations.of(context);

    // #2622 / #2680 — in route mode, the countries that actually PRODUCED
    // a station for the selected fuel (a leg that returned nothing is not
    // credited). Empty for nearby mode and single-country routes.
    final isRoute = ref.watch(activeSearchModeProvider) == SearchMode.route;
    final corridor = isRoute
        ? (ref
                .watch(routeSearchStateProvider)
                .value
                ?.contributingCountryCodes(ref.watch(selectedFuelTypeProvider)) ??
            const <String>{})
        : const <String>{};
    if (corridor.length > 1) return _multiSource(l10n, corridor);

    if (country.requiresApiKey) return const SizedBox.shrink();

    final policy = CountryServiceRegistry.policyFor(country.code);
    final provider = country.apiProvider; // i18n-ignore: provider name
    final source = policy?.attribution ?? provider ?? country.name;
    final shown = _shortProvider(provider ?? country.name);
    final credit = l10n.dataSourceLinkSemantic(source, policy?.license ?? '');
    final url = policy?.sourceUrl;
    final linked = url != null && url.isNotEmpty;
    final theme = Theme.of(context);
    return SummaryChip(
      key: const Key('search_summary_source'),
      icon: Text(country.flag, style: const TextStyle(fontSize: 11)),
      label: shown,
      tooltip: credit,
      onTap: linked ? () => unawaited(_open(url)) : null,
      trailing: linked
          ? Icon(
              Icons.open_in_new,
              size: 10,
              color: theme.colorScheme.onSecondaryContainer,
            )
          : null,
    );
  }

  /// The joined credit of a cross-border corridor: "🇫🇷 🇪🇸" +
  /// "Prix-Carburants · Geoportal Gasolineras"; the sentence with the
  /// country names rides in the tooltip. Sorted by code for a stable order.
  Widget _multiSource(AppLocalizations l10n, Set<String> codes) {
    final flags = <String>[];
    final providers = <String>[];
    final segments = <String>[];
    for (final code in codes.toList()..sort()) {
      final config = Countries.byCode(code);
      final policy = CountryServiceRegistry.policyFor(code);
      if (config == null || policy == null) continue;
      flags.add(config.flag);
      providers.add(_shortProvider(policy.attribution));
      // i18n-ignore: country name + provider attribution are proper nouns.
      segments.add('${config.name} — ${policy.attribution}');
    }
    if (segments.isEmpty) return const SizedBox.shrink();
    return SummaryChip(
      key: const Key('search_summary_source'),
      icon: Text(flags.join(' '), style: const TextStyle(fontSize: 11)),
      label: providers.join(' · '),
      tooltip: l10n.routeDataSourceMulti(segments.join(' · ')),
    );
  }

  /// The provider name as the PILL shows it: without a trailing
  /// parenthetical — `Prix-Carburants (gouv.fr)` reads `Prix-Carburants`
  /// (#3957). Display only: the full name and the licence stay in the
  /// tooltip and the spoken label, so the open-data credit is unchanged,
  /// and the pill stops spending its whole 132 dp on a suffix it then
  /// truncates ("Prix-Carburants (go…").
  static String _shortProvider(String name) {
    final cut = name.indexOf(' (');
    return cut > 0 ? name.substring(0, cut) : name;
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      logFailure(e, st, where: 'SearchSummaryBar: open data-source URL');
    }
  }
}
