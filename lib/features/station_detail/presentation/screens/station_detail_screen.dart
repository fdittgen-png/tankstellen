import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
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

class StationDetailScreen extends ConsumerWidget {
  final String stationId;

  const StationDetailScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stationDetailProvider(stationId));

    // #595 — derive a display title from the loaded station so the Hero
    // flight from the search card lands on the matching brand/name.
    // Falls back to the generic "Station" label until data loads.
    final station = detailAsync.value?.data.station;
    final String appBarTitle = station != null
        ? (hasRealBrand(station) ? station.brand : station.street)
        : (AppLocalizations.of(context)?.search ?? 'Station');

    return PageScaffold(
      titleWidget: Semantics(
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
                  appBarTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              appBarTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
        tooltip: AppLocalizations.of(context)?.tooltipBack ?? 'Back',
      ),
      actions: [
        StationDetailAppBarActions(
          stationId: stationId,
          station: station,
        ),
      ],
      bodyPadding: EdgeInsets.zero,
      body: detailAsync.when(
        data: (result) => Column(
          children: [
            ServiceStatusBanner(result: result),
            Expanded(child: _buildContent(context, ref, result.data, result)),
          ],
        ),
        loading: () => const ShimmerStationDetail(),
        error: (error, _) => ServiceChainErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(stationDetailProvider(stationId)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    StationDetail detail,
    ServiceResult<StationDetail> serviceResult,
  ) {
    final station = detail.station;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Open/closed status + freshness inline + rating stars (top-right)
          StationStatusRow(
            station: station,
            serviceResult: serviceResult,
            stationId: stationId,
          ),
          const SizedBox(height: 12),

          // Brand logo + Name (+ "Independent station" subtitle — #482)
          StationBrandHeader(station: station),
          const SizedBox(height: 16),

          // Prices (compact) + "Log fill-up" CTA
          StationPricesSection(station: station),
          const SizedBox(height: 16),

          // Address, opening hours, fuels, location (services moved to bottom)
          StationInfoSection(station: station, detail: detail),

          // Rating (interactive)
          const SizedBox(height: 16),
          StationRatingSection(stationId: stationId),

          // Price History
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(l10n?.priceHistory ?? 'Price History',
                style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          PriceHistorySection(stationId: stationId, station: station),
        ],
      ),
    );
  }
}
