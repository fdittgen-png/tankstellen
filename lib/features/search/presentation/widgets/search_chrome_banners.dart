// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/country_config.dart';
import 'demo_mode_banner.dart';
import 'search_summary_bar.dart';
import 'unsupported_region_notice.dart';

/// The search screen's chrome column above the results.
///
/// #3615 extracted it from `search_screen.dart` under the 400-line norm and
/// wrapped the group in [AnimatedSize] so banners appear and disappear as a
/// motion instead of a post-frame layout jump.
///
/// #3926 reduced it to **one** row: the demo-mode call to action and the
/// unsupported-region notice are conditional notices, and everything else
/// collapsed into [SearchSummaryBar] (row A). The country/source
/// attribution moved to the footer under the list, and the user-position
/// strip — with the screen's second refresh icon — became a segment of row
/// A, its refresh folded into the single app-bar refresh.
class SearchChromeBanners extends ConsumerWidget {
  const SearchChromeBanners({
    super.key,
    required this.hidden,
    required this.country,
    required this.corridorCountryCodes,
  });

  /// #3372 — landscape radar owns the pane: collapse the chrome.
  final bool hidden;
  final CountryConfig country;
  final Set<String> corridorCountryCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // #3926 — only the demo-mode branch of [DemoModeBanner] belongs at the
    // top: it is a call to action ("turn on live prices"), not a credit.
    // Its attribution branches render in `SearchResultsFooter`.
    final showsDemoBanner =
        country.requiresApiKey && corridorCountryCodes.length <= 1;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: hidden
          ? const SizedBox(width: double.infinity)
          : Column(
              children: [
                if (showsDemoBanner) DemoModeBanner(country: country),
                // #3361 — honest "no coverage for your country" notice
                // (replaces the silent fall-back to Germany that read
                // as a geo-restriction).
                const UnsupportedRegionNotice(),
                // ROW A — fuel · radius/route · position or address ·
                // price freshness; tap opens the criteria sheet.
                const SearchSummaryBar(),
              ],
            ),
    );
  }
}
