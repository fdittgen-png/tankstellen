// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/station.dart';
import '../widgets/price_history_foldable.dart';
import '../widgets/station_brand_header.dart';
import '../widgets/station_detail_app_bar_actions.dart';
import '../widgets/station_info_section.dart';
import '../widgets/station_prices_section.dart';
import '../widgets/station_rating_section.dart';
import '../widgets/station_status_row.dart';

/// Two-column station-detail layout for medium / expanded screens (#2531,
/// Epic #2525).
///
/// In landscape / wide / tablet the compact `CustomScrollView` +
/// `SliverAppBar(expandedHeight: 196)` layout just stretches the portrait
/// single column — the 196dp header band dominates and the body content is
/// cramped into the same narrow column with the rest of the width wasted.
///
/// This variant drops the expanding header band for a normal (non-expanding)
/// `PageScaffold` AppBar (back button + [StationDetailAppBarActions]) over a
/// two-pane `Row`:
///
/// * LEFT pane (`flex: 2`) — the status row + brand header that used to live
///   in the collapsing `flexibleSpace`, now in a self-scrolling column.
/// * `VerticalDivider`.
/// * RIGHT pane (`flex: 3`) — the service-status banner, prices, info,
///   rating and the price-history foldable, also self-scrolling.
///
/// The SAME section widgets are reused verbatim — only the container
/// changes. Each pane is its own [SingleChildScrollView] so the two panes
/// scroll independently with no nested-scroll jank. The existing 16dp
/// padding / 8dp inter-section spacing conventions are preserved.
///
/// Compact (< 600dp) keeps the original sliver layout — this widget is only
/// reached when `screenSizeOf(context) != ScreenSize.compact`.
class StationDetailWideLayout extends StatelessWidget {
  final String stationId;
  final StationDetail detail;
  final ServiceResult<StationDetail> serviceResult;

  const StationDetailWideLayout({
    super.key,
    required this.stationId,
    required this.detail,
    required this.serviceResult,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final station = detail.station;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return PageScaffold(
      // No title (#2161 — the brand lives in the body header, not the
      // AppBar title slot). The empty-string title is the escape hatch the
      // plain loading / error states already use.
      title: '',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
        tooltip: l10n?.tooltipBack ?? 'Back',
      ),
      actions: [
        StationDetailAppBarActions(
          stationId: stationId,
          station: station,
        ),
      ],
      bodyPadding: EdgeInsets.zero,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StationStatusRow(
                    station: station,
                    serviceResult: serviceResult,
                    stationId: stationId,
                  ),
                  const SizedBox(height: 8),
                  StationBrandHeader(station: station),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ServiceStatusBanner(result: serviceResult),
                  StationPricesSection(station: station),
                  const SizedBox(height: 8),
                  StationInfoSection(station: station, detail: detail),
                  const SizedBox(height: 8),
                  StationRatingSection(stationId: stationId),
                  const SizedBox(height: 8),
                  // #1957 — the price-history chart is a tall,
                  // detail-on-demand block; the foldable is collapsed by
                  // default so it does not dominate the pane.
                  PriceHistoryFoldable(stationId: stationId, station: station),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
