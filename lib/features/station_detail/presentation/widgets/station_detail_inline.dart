import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/station_detail_provider.dart';
import 'price_history_section.dart';
import 'station_info_section.dart';

/// Inline station detail view for split-screen layouts.
///
/// Shows the same content as [StationDetailScreen] but without its own
/// Scaffold/AppBar — designed to be embedded in a [Row] alongside the
/// search results list.
class StationDetailInline extends ConsumerWidget {
  final String stationId;
  final VoidCallback? onClose;

  const StationDetailInline({
    super.key,
    required this.stationId,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stationDetailProvider(stationId));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // Mini toolbar with close button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Row(
            children: [
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  tooltip: l10n?.tooltipClose ?? 'Close',
                ),
              Expanded(
                child: Text(
                  detailAsync.value?.data.station.brand ?? '',
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Detail content
        Expanded(
          child: detailAsync.when(
            data: (result) {
              final detail = result.data;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StationInfoSection(
                      station: detail.station,
                      detail: detail,
                    ),
                    const SizedBox(height: 16),
                    PriceHistorySection(
                      stationId: stationId,
                      station: detail.station,
                    ),
                  ],
                ),
              );
            },
            loading: () => const ShimmerStationDetail(),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
