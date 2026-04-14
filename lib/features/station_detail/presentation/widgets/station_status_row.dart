import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_result.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/station.dart';
import '../../../search/providers/station_rating_provider.dart';

/// Top row of the station detail screen — open/closed dot + freshness
/// text on the left, compact 5-star rating on the right.
///
/// Stateless apart from watching `stationRatingProvider` (which the parent
/// previously did inline via `Consumer`). Pulled out of
/// `station_detail_screen.dart` so the screen's `_buildContent` helper
/// drops the 49-line inline `Row(...)` block and so the row can be
/// covered by widget tests in isolation.
class StationStatusRow extends ConsumerWidget {
  final Station station;
  final ServiceResult<dynamic> serviceResult;

  /// ID used to look up the rating from `stationRatingProvider`. Usually
  /// the `stationId` field on the screen.
  final String stationId;

  const StationStatusRow({
    super.key,
    required this.station,
    required this.serviceResult,
    required this.stationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final rating = ref.watch(stationRatingProvider(stationId));

    final color = station.isOpen
        ? DarkModeColors.success(context)
        : DarkModeColors.error(context);

    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: 'Station is ${station.isOpen ? 'open' : 'closed'}',
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ExcludeSemantics(
                  child: Text(
                    _buildStatusText(station, serviceResult, l10n),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (rating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Icon(
                i < rating ? Icons.star : Icons.star_border,
                size: 16,
                color: i < rating ? Colors.amber : Colors.grey.shade400,
              ),
            ),
          ),
      ],
    );
  }

  /// Combines open/closed with freshness, e.g. "Open — < 1 min ago".
  /// Visible-for-testing.
  static String _buildStatusText(
    Station station,
    ServiceResult<dynamic> result,
    AppLocalizations? l10n,
  ) {
    final status = station.isOpen
        ? (l10n?.open ?? 'Open')
        : (l10n?.closed ?? 'Closed');
    final agoSuffix = l10n?.freshnessAgo ?? 'ago';
    final freshness = result.freshnessLabel;
    return '$status — $freshness $agoSuffix';
  }
}
