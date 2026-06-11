// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/station.dart';
import '../../providers/station_detail_provider.dart';
import '../widgets/price_history_foldable.dart';
import '../widgets/station_brand_header.dart';
import '../widgets/station_detail_app_bar_actions.dart';
import '../widgets/station_info_section.dart';
import '../widgets/station_prices_section.dart';
import '../widgets/station_rating_section.dart';
import '../widgets/station_status_row.dart';
import 'station_detail_wide_layout.dart';

/// Detail screen for a single fuel station.
///
/// #1539 — the data state uses a `CustomScrollView` + `SliverAppBar`
/// (pinned, `expandedHeight: 196`) so the rich status-row + brand-header
/// block collapses out of view on scroll, leaving a 1-row compact bar
/// (back arrow + actions). Loading and error states keep a plain fixed
/// `AppBar` since there is no scroll content to sticky-collapse against.
///
/// #2161 — the AppBar no longer renders the station name or the
/// cheapest-price chip in its title slot. Both pieces of information
/// are already prominent in the body (`StationBrandHeader` +
/// `StationPricesSection`); the truncated `"Péz…"` in the title was
/// distracting and the Hero fly-in from the search card was noise.
class StationDetailScreen extends ConsumerWidget {
  final String stationId;

  const StationDetailScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stationDetailProvider(stationId));

    return detailAsync.when(
      data: (result) => _StationDetailLoaded(
        stationId: stationId,
        detail: result.data,
        serviceResult: result,
      ),
      loading: () => const _StationDetailPlain(body: ShimmerStationDetail()),
      error: (error, _) => _StationDetailPlain(
        body: ServiceChainErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(stationDetailProvider(stationId)),
        ),
      ),
    );
  }
}

/// Scaffold used by the loading and error states — fixed AppBar via
/// `PageScaffold` (required by the #923 design-system lint), back
/// button, no title (#2161). No sliver / collapse behaviour.
class _StationDetailPlain extends StatelessWidget {
  final Widget body;

  const _StationDetailPlain({required this.body});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageScaffold(
      title: '',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
        tooltip: l10n.tooltipBack,
      ),
      bodyPadding: EdgeInsets.zero,
      body: body,
    );
  }
}

/// Loaded state — adaptive on screen size (#2531, Epic #2525).
///
/// On **compact** (< 600dp / portrait phone) this is the original
/// `CustomScrollView` + `SliverAppBar(pinned: true, expandedHeight: 196)`:
/// status row and brand header live inside the `flexibleSpace.background`,
/// so they fade out as the bar collapses to its compact form on scroll past
/// the prices card. This path is byte-for-byte unchanged.
///
/// On **medium / expanded** (≥ 600dp / landscape / tablet) it delegates to
/// [StationDetailWideLayout] — a normal (non-expanding) `PageScaffold`
/// AppBar over a two-pane `Row` (status + brand header | prices + info +
/// rating + history), each pane self-scrolling. Same section widgets, no
/// route change (deep-link safe).
class _StationDetailLoaded extends StatelessWidget {
  final String stationId;
  final StationDetail detail;
  final ServiceResult<StationDetail> serviceResult;

  const _StationDetailLoaded({
    required this.stationId,
    required this.detail,
    required this.serviceResult,
  });

  @override
  Widget build(BuildContext context) {
    // Wide screens get the two-column layout; compact keeps the sliver
    // header below, unchanged.
    if (screenSizeOf(context) != ScreenSize.compact) {
      return StationDetailWideLayout(
        stationId: stationId,
        detail: detail,
        serviceResult: serviceResult,
      );
    }

    final l10n = AppLocalizations.of(context);
    final station = detail.station;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            // #1989 — trimmed from 220: the status row + brand header
            // do not fill that much, leaving dead space below the name.
            expandedHeight: 196,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
              tooltip: l10n.tooltipBack,
            ),
            actions: [
              StationDetailAppBarActions(
                stationId: stationId,
                station: station,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  // Keep the rich block clear of the pinned toolbar at the
                  // top — the leading / title / actions sit in the first
                  // kToolbarHeight (56dp) of the SliverAppBar regardless of
                  // expansion state, so the background has to inset by that
                  // much to avoid overlap when fully expanded.
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    kToolbarHeight + 8,
                    16,
                    8,
                  ),
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
            ),
          ),
          SliverToBoxAdapter(child: ServiceStatusBanner(result: serviceResult)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding + 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                StationPricesSection(station: station),
                const SizedBox(height: 8),
                StationInfoSection(station: station, detail: detail),
                const SizedBox(height: 8),
                StationRatingSection(stationId: stationId),
                const SizedBox(height: 8),
                // #1957 — the price-history chart is a tall,
                // detail-on-demand block; show it in a foldable that is
                // collapsed by default so it does not dominate the page.
                PriceHistoryFoldable(stationId: stationId, station: station),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
