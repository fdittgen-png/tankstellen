import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/star_rating.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/providers/station_rating_provider.dart';

/// User rating section showing interactive star rating for a station.
///
/// #923 phase 3f — migrated from an inline `Text(…, titleMedium)` +
/// Column layout to the canonical [SectionCard] so the rating block
/// matches the other section surfaces on the station-detail screen
/// (same radius, tint, padding, and header role).
class StationRatingSection extends StatelessWidget {
  final String stationId;

  const StationRatingSection({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      title: l10n?.yourRating ?? 'Your rating',
      child: Consumer(builder: (context, ref, _) {
        final rating = ref.watch(stationRatingProvider(stationId));
        return Row(
          children: [
            StarRating(
              rating: rating,
              onRatingChanged: (stars) {
                ref.read(stationRatingsProvider.notifier).rate(stationId, stars);
              },
            ),
            if (rating != null) ...[
              const SizedBox(width: 12),
              Text('$rating/5', style: theme.textTheme.bodyMedium),
            ],
          ],
        );
      }),
    );
  }
}
