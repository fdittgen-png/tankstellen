import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/station.dart';
import '../../providers/station_detail_provider.dart';
import '../widgets/price_history_section.dart';
import '../widgets/station_brand_header.dart';
import '../widgets/station_brand_helpers.dart';
import '../widgets/station_detail_app_bar_actions.dart';
import '../widgets/station_info_section.dart';
import '../widgets/station_prices_section.dart';
import '../widgets/station_rating_section.dart';
import '../widgets/station_status_row.dart';
import '../widgets/wait_time_section.dart';

/// Detail screen for a single fuel station.
///
/// #1539 — the data state uses a `CustomScrollView` + `SliverAppBar`
/// (pinned, `expandedHeight: 220`) so the rich status-row + brand-header
/// block collapses out of view on scroll, leaving a 1-row compact bar
/// (back arrow + station name + cheapest-price chip + actions). Loading
/// and error states keep a plain fixed `AppBar` since there is no scroll
/// content to sticky-collapse against.
class StationDetailScreen extends ConsumerWidget {
  final String stationId;

  const StationDetailScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stationDetailProvider(stationId));
    final l10n = AppLocalizations.of(context);

    // #595 — derive a display title from the loaded station so the Hero
    // flight from the search card lands on the matching brand/name.
    // Falls back to the generic "Station" label until data loads.
    final station = detailAsync.value?.data.station;
    final appBarTitle = station != null
        ? (hasRealBrand(station) ? station.brand : station.street)
        : (l10n?.search ?? 'Station');

    return detailAsync.when(
      data: (result) => _StationDetailLoaded(
        stationId: stationId,
        detail: result.data,
        serviceResult: result,
        appBarTitle: appBarTitle,
      ),
      loading: () => _StationDetailPlain(
        stationId: stationId,
        appBarTitle: appBarTitle,
        body: const ShimmerStationDetail(),
      ),
      error: (error, _) => _StationDetailPlain(
        stationId: stationId,
        appBarTitle: appBarTitle,
        body: ServiceChainErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(stationDetailProvider(stationId)),
        ),
      ),
    );
  }
}

/// Scaffold used by the loading and error states — fixed AppBar via
/// `PageScaffold` (required by the #923 design-system lint), Hero-tagged
/// title, back button. No sliver / collapse behaviour.
class _StationDetailPlain extends StatelessWidget {
  final String stationId;
  final String appBarTitle;
  final Widget body;

  const _StationDetailPlain({
    required this.stationId,
    required this.appBarTitle,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageScaffold(
      titleWidget: _HeroTitle(stationId: stationId, title: appBarTitle),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
        tooltip: l10n?.tooltipBack ?? 'Back',
      ),
      bodyPadding: EdgeInsets.zero,
      body: body,
    );
  }
}

/// Loaded state — `CustomScrollView` + `SliverAppBar(pinned: true,
/// expandedHeight: 220)`. Status row and brand header live inside the
/// `flexibleSpace.background`, so they fade out as the bar collapses
/// to its compact form on scroll past the prices card.
class _StationDetailLoaded extends StatelessWidget {
  final String stationId;
  final StationDetail detail;
  final ServiceResult<StationDetail> serviceResult;
  final String appBarTitle;

  const _StationDetailLoaded({
    required this.stationId,
    required this.detail,
    required this.serviceResult,
    required this.appBarTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final station = detail.station;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final cheapest = _cheapestPrice(station);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
              tooltip: l10n?.tooltipBack ?? 'Back',
            ),
            title: Row(
              children: [
                Flexible(
                  child: _HeroTitle(
                    stationId: stationId,
                    title: appBarTitle,
                  ),
                ),
                if (cheapest != null) ...[
                  const SizedBox(width: 8),
                  _CheapestPriceChip(price: cheapest),
                ],
              ],
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
                      const SizedBox(height: 12),
                      StationBrandHeader(station: station),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ServiceStatusBanner(result: serviceResult),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding + 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                StationPricesSection(station: station),
                const SizedBox(height: 16),
                // #1119 phase 2 — community wait-time hint + "Track my wait"
                // toggle. Hidden entirely when consent is OFF; renders the
                // toggle alone when consent is ON but the aggregate row is
                // still sparse (< 5 samples server-side).
                WaitTimeSection(stationId: stationId),
                const SizedBox(height: 16),
                StationInfoSection(station: station, detail: detail),
                const SizedBox(height: 16),
                StationRatingSection(stationId: stationId),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    l10n?.priceHistory ?? 'Price History',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                PriceHistorySection(stationId: stationId, station: station),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero-flighted station-name text. Wraps the title in the same Hero
/// tag the search card uses so the brand label appears to fly into the
/// detail screen header on push. Centralised here so all three states
/// (loading, error, data) share the same animation source.
class _HeroTitle extends StatelessWidget {
  final String stationId;
  final String title;

  const _HeroTitle({required this.stationId, required this.title});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Hero(
        tag: 'station-name-$stationId',
        flightShuttleBuilder: (ctx, animation, direction, fromCtx, toCtx) {
          final theme = Theme.of(ctx);
          return Material(
            type: MaterialType.transparency,
            child: DefaultTextStyle(
              style: theme.appBarTheme.titleTextStyle ??
                  theme.textTheme.titleLarge ??
                  const TextStyle(fontWeight: FontWeight.bold),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
        child: Material(
          type: MaterialType.transparency,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Small pill next to the station name showing the cheapest fuel price
/// at this station. Visible in both the expanded and collapsed
/// SliverAppBar states so the user keeps a reference to the headline
/// price after scrolling past the dedicated prices card.
class _CheapestPriceChip extends StatelessWidget {
  final double price;

  const _CheapestPriceChip({required this.price});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        PriceFormatter.formatPrice(price),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Lowest non-null fuel price across the station's published fuels.
/// Returns null when the station reports no prices.
double? _cheapestPrice(Station s) {
  final candidates = <double>[
    if (s.e5 != null && s.e5! > 0) s.e5!,
    if (s.e10 != null && s.e10! > 0) s.e10!,
    if (s.diesel != null && s.diesel! > 0) s.diesel!,
    if (s.dieselPremium != null && s.dieselPremium! > 0) s.dieselPremium!,
    if (s.e98 != null && s.e98! > 0) s.e98!,
    if (s.e85 != null && s.e85! > 0) s.e85!,
    if (s.lpg != null && s.lpg! > 0) s.lpg!,
    if (s.cng != null && s.cng! > 0) s.cng!,
  ];
  if (candidates.isEmpty) return null;
  return candidates.reduce((a, b) => a < b ? a : b);
}
